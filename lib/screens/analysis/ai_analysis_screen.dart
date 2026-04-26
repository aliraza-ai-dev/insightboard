import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../services/ai_service.dart';
import '../../services/data_service.dart';
import '../../widgets/charts/chart_widgets.dart';

class AIAnalysisScreen extends StatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _queryController = TextEditingController();
  final _chatMessages = <_ChatMessage>[];
  bool _isAnalyzing = false;
  ForecastResult? _forecastResult;
  List<AnomalyResult> _anomalies = [];
  String? _selectedForecastCol;
  bool _isForecastLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _sendQuery() async {
    final question = _queryController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _chatMessages.add(_ChatMessage(text: question, isUser: true));
      _isAnalyzing = true;
    });
    _queryController.clear();

    final provider = context.read<AppProvider>();
    final response = await provider.askAI(question);

    setState(() {
      _chatMessages.add(_ChatMessage(text: response, isUser: false));
      _isAnalyzing = false;
    });
  }

  Future<void> _runForecast() async {
    if (_selectedForecastCol == null) return;
    final provider = context.read<AppProvider>();
    if (provider.activeDataset == null) return;

    setState(() => _isForecastLoading = true);

    final values = provider.dataService.getColumnValues(
        provider.activeDataRows, _selectedForecastCol!);
    final labels = List.generate(values.length, (i) => 'P${i + 1}');

    final result = await provider.aiService.forecast(
      historicalValues: values.take(50).toList(),
      labels: labels.take(50).toList(),
      periods: 6,
    );

    setState(() {
      _forecastResult = result;
      _isForecastLoading = false;
    });
  }

  void _detectAnomalies() {
    final provider = context.read<AppProvider>();
    if (provider.activeDataset == null) return;

    final allAnomalies = <AnomalyResult>[];
    for (int i = 0; i < provider.activeDataset!.columns.length; i++) {
      if (provider.activeDataset!.columnTypes[i] == 'numeric') {
        final col = provider.activeDataset!.columns[i];
        final values = provider.dataService.getColumnValues(
            provider.activeDataRows, col);
        final labels = List.generate(values.length, (i) => 'Row ${i + 1}');
        final results = provider.aiService.detectAnomalies(
          values: values, labels: labels, columnName: col,
        );
        allAnomalies.addAll(results);
      }
    }

    setState(() => _anomalies = allAnomalies);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Ask AI'),
              Tab(text: 'Forecast'),
              Tab(text: 'Anomalies'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAskAITab(provider, isDark),
              _buildForecastTab(provider, isDark),
              _buildAnomaliesTab(provider, isDark),
            ],
          ),
        ),
      ],
    );
  }

  // ====================================
  // Ask AI Tab
  // ====================================
  Widget _buildAskAITab(AppProvider provider, bool isDark) {
    if (provider.activeDataset == null) {
      return _buildNoDataState('Ask questions about your data using natural language',
          'Upload data first to start asking questions');
    }

    return Column(
      children: [
        // Dataset info bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.dataset, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Active: ${provider.activeDataset!.name} (${provider.activeDataset!.rowCount} rows)',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              )),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Suggested queries
        if (_chatMessages.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Suggested Questions',
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _suggestChip('What are the top 5 values?'),
                    _suggestChip('Show me a summary of all columns'),
                    _suggestChip('What trends do you see?'),
                    _suggestChip('Which category has the highest total?'),
                    _suggestChip('Are there any outliers?'),
                    _suggestChip('Compare performance across regions'),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Chat messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length + (_isAnalyzing ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _chatMessages.length && _isAnalyzing) {
                return _buildTypingIndicator(isDark);
              }
              return _buildChatBubble(_chatMessages[i], isDark);
            },
          ),
        ),

        // Input field
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            border: Border(top: BorderSide(
              color: isDark ? const Color(0xFF313244) : Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    hintText: 'Ask anything about your data...',
                    prefixIcon: const Icon(Icons.auto_awesome, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF313244) : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendQuery(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isAnalyzing ? null : _sendQuery,
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _suggestChip(String text) {
    return ActionChip(
      label: Text(text, style: GoogleFonts.inter(fontSize: 12)),
      onPressed: () {
        _queryController.text = text;
        _sendQuery();
      },
      backgroundColor: Colors.transparent,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
    );
  }

  Widget _buildChatBubble(_ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: msg.isUser
              ? AppColors.primary
              : isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 16),
          ),
          border: msg.isUser ? null : Border.all(
            color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
        ),
        child: msg.isUser
            ? Text(msg.text, style: GoogleFonts.inter(
                color: Colors.white, fontSize: 14))
            : SelectableText(msg.text,
                style: GoogleFonts.inter(fontSize: 13, height: 1.6)),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2,
                  color: AppColors.primary)),
            const SizedBox(width: 10),
            Text('Analyzing your data...',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ====================================
  // Forecast Tab
  // ====================================
  Widget _buildForecastTab(AppProvider provider, bool isDark) {
    if (provider.activeDataset == null) {
      return _buildNoDataState('AI Predictions & Forecasting',
          'Upload data to generate forecasts from historical patterns');
    }

    final numericCols = <String>[];
    for (int i = 0; i < provider.activeDataset!.columns.length; i++) {
      if (provider.activeDataset!.columnTypes[i] == 'numeric') {
        numericCols.add(provider.activeDataset!.columns[i]);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Forecast Configuration',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Column selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select column to forecast',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: numericCols.map((col) => ChoiceChip(
                    label: Text(col),
                    selected: _selectedForecastCol == col,
                    onSelected: (sel) {
                      setState(() => _selectedForecastCol = sel ? col : null);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedForecastCol != null && !_isForecastLoading
                        ? _runForecast : null,
                    icon: _isForecastLoading
                        ? const SizedBox(width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.auto_graph),
                    label: Text(_isForecastLoading
                        ? 'Generating...' : 'Generate Forecast'),
                  ),
                ),
              ],
            ),
          ),

          // Forecast results
          if (_forecastResult != null) ...[
            const SizedBox(height: 24),
            ChartWidgets.buildForecastChart(
              historical: provider.dataService.getColumnValues(
                  provider.activeDataRows, _selectedForecastCol!).take(30).toList(),
              histLabels: List.generate(
                  min(30, provider.activeDataRows.length), (i) => 'P${i + 1}'),
              forecast: _forecastResult!.predictions,
              forecastLabels: _forecastResult!.labels,
              title: '$_selectedForecastCol Forecast',
              confidence: _forecastResult!.confidence,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Forecast insights
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.06),
                  AppColors.secondary.withValues(alpha: isDark ? 0.1 : 0.03),
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('AI Forecast Insights',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    _forecastResult!.insights,
                    style: GoogleFonts.inter(fontSize: 13, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ====================================
  // Anomalies Tab
  // ====================================
  Widget _buildAnomaliesTab(AppProvider provider, bool isDark) {
    if (provider.activeDataset == null) {
      return _buildNoDataState('Anomaly Detection',
          'Upload data to automatically detect unusual patterns');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Anomaly Detection',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _detectAnomalies,
                icon: const Icon(Icons.radar, size: 18),
                label: const Text('Scan Data'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('Detects values outside expected statistical range (>2σ)',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 20),

          if (_anomalies.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.radar, size: 48,
                    color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No anomalies detected yet',
                    style: GoogleFonts.inter(color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text('Tap "Scan Data" to analyze',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey[400])),
                ],
              ),
            )
          else ...[
            // Summary
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.warning, size: 22),
                  const SizedBox(width: 10),
                  Text('${_anomalies.length} anomalies detected',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  Text(
                    '${_anomalies.where((a) => a.severity == "critical").length} critical',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.error,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Anomaly list
            ..._anomalies.map((a) => _buildAnomalyCard(a, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(AnomalyResult anomaly, bool isDark) {
    final severityColor = anomaly.severity == 'critical'
        ? AppColors.error
        : anomaly.severity == 'high'
            ? AppColors.warning
            : AppColors.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(anomaly.severity.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10,
                      fontWeight: FontWeight.w700, color: severityColor)),
              ),
              const SizedBox(width: 8),
              Text(anomaly.label, style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('z=${anomaly.zScore.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(anomaly.description,
            style: GoogleFonts.inter(fontSize: 12, height: 1.4)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Value: ${anomaly.value.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 11, color: severityColor,
                    fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Text('Expected: ${anomaly.expectedMin.toStringAsFixed(0)} — ${anomaly.expectedMax.toStringAsFixed(0)}',
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.psychology,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.inter(
                fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

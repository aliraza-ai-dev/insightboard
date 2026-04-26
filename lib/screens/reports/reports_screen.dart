import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../services/report_pdf_service.dart';
import '../../services/ai_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _titleController = TextEditingController(text: 'Business Intelligence Report');
  bool _isGenerating = false;
  String? _aiSummary;
  String _exportFormat = 'PDF';
  String? _scheduleType;
  final _scheduleEmailController = TextEditingController();

  // Report history
  final _reportHistory = [
    {'title': 'Weekly Sales Report', 'date': 'Apr 12, 2026', 'status': 'ready',
     'schedule': 'Weekly'},
    {'title': 'Q1 Performance Analysis', 'date': 'Apr 1, 2026', 'status': 'ready',
     'schedule': null},
    {'title': 'Monthly Customer Report', 'date': 'Mar 31, 2026', 'status': 'ready',
     'schedule': 'Monthly'},
  ];

  Future<void> _generateReport() async {
    final provider = context.read<AppProvider>();
    if (provider.activeDataset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a dataset first'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      // Generate AI summary
      _aiSummary = await provider.aiService.generateReport(
        title: _titleController.text,
        columns: provider.activeDataset!.columns,
        columnTypes: provider.activeDataset!.columnTypes,
        summary: provider.parsedData?.getSummary() ?? {},
        sampleRows: provider.activeDataRows.take(30).toList(),
      );

      // Generate PDF
      final pdfService = ReportPdfService();
      final pdfBytes = await pdfService.generateReport(
        title: _titleController.text,
        workspaceName: provider.currentWorkspace?.name ?? 'Default',
        generatedBy: provider.currentUser?.name ?? 'Unknown',
        kpis: _buildKpiData(provider),
        aiSummary: _aiSummary ?? '',
        tables: [
          TableData(
            title: 'Data Overview - ${provider.activeDataset!.name}',
            headers: provider.activeDataset!.columns,
            rows: provider.activeDataRows.take(50).map((row) =>
                provider.activeDataset!.columns.map((c) =>
                    row[c]?.toString() ?? '').toList()).toList(),
          ),
        ],
      );

      // Show print/share dialog
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: _titleController.text,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  List<KpiData> _buildKpiData(AppProvider provider) {
    final kpis = <KpiData>[];
    if (provider.activeDataset == null) return kpis;

    for (int i = 0; i < provider.activeDataset!.columns.length; i++) {
      if (provider.activeDataset!.columnTypes[i] == 'numeric') {
        final col = provider.activeDataset!.columns[i];
        final values = provider.dataService.getColumnValues(
            provider.activeDataRows, col);
        final total = values.fold(0.0, (a, b) => a + b);
        final avg = total / values.length;
        kpis.add(KpiData(
          title: 'Total $col',
          value: _formatNum(total),
          change: 'Avg: ${_formatNum(avg)}',
          isPositive: true,
        ));
        if (kpis.length >= 6) break;
      }
    }
    return kpis;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Generate AI-powered reports and schedule automated delivery',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Report Generator Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.06),
                AppColors.secondary.withValues(alpha: isDark ? 0.08 : 0.03),
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Report Generator',
                            style: GoogleFonts.inter(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                          Text('Auto-generate comprehensive business reports',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Report Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 14),

                // Export format
                Row(
                  children: [
                    Text('Format: ', style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 8),
                    ...<String>['PDF', 'PNG', 'CSV'].map((fmt) =>
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(fmt),
                          selected: _exportFormat == fmt,
                          onSelected: (sel) =>
                              setState(() => _exportFormat = fmt),
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Schedule
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Schedule Reports',
                            style: GoogleFonts.inter(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [null, 'Daily', 'Weekly', 'Monthly'].map((s) =>
                          ChoiceChip(
                            label: Text(s ?? 'One-time'),
                            selected: _scheduleType == s,
                            onSelected: (sel) =>
                                setState(() => _scheduleType = sel ? s : null),
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ).toList(),
                      ),
                      if (_scheduleType != null) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _scheduleEmailController,
                          decoration: const InputDecoration(
                            hintText: 'Email to send reports to',
                            prefixIcon: Icon(Icons.email_outlined),
                            isDense: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateReport,
                    icon: _isGenerating
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.description),
                    label: Text(_isGenerating
                        ? 'Generating Report...' : 'Generate Report'),
                  ),
                ),
              ],
            ),
          ),

          // AI Summary Preview
          if (_aiSummary != null) ...[
            const SizedBox(height: 24),
            Text('AI Summary Preview', style: GoogleFonts.inter(
                fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
              ),
              child: SelectableText(_aiSummary!,
                style: GoogleFonts.inter(fontSize: 13, height: 1.6)),
            ),
          ],

          // Report History
          const SizedBox(height: 24),
          Text('Report History', style: GoogleFonts.inter(
              fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._reportHistory.map((r) => _buildReportHistoryItem(r, isDark)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildReportHistoryItem(Map<String, dynamic> report, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.description, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report['title'] as String,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(report['date'] as String,
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey[600])),
                    if (report['schedule'] != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(report['schedule'] as String,
                          style: GoogleFonts.inter(fontSize: 10,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.share, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _formatNum(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);
  }
}

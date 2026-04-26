import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../services/ai_service.dart';
import '../../widgets/charts/chart_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isUploading = false;
  String? _uploadError;
  List<ChartSuggestion> _suggestions = [];
  bool _showDataPreview = false;
  String _selectedConnector = '';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      setState(() => _uploadError = 'Could not read file data. Please try again.');
      return;
    }

    setState(() { _isUploading = true; _uploadError = null; });

    try {
      final provider = context.read<AppProvider>();
      final dataset = await provider.uploadFile(file.bytes!, file.name);
      if (dataset != null) {
        _suggestions = provider.aiService.suggestCharts(
          columns: dataset.columns,
          columnTypes: dataset.columnTypes,
          rowCount: dataset.rowCount,
        );
        _showDataPreview = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${dataset.name} loaded — ${dataset.rowCount} rows, ${dataset.colCount} columns'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } else {
        _uploadError = 'Failed to parse file. Please check the format.';
      }
    } catch (e) {
      _uploadError = 'Error: $e';
    } finally {
      setState(() => _isUploading = false);
    }
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
          Text('Data Upload', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Upload CSV/Excel files or connect data sources',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 24),

          // Upload zone
          GestureDetector(
            onTap: _isUploading ? null : _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : AppColors.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                  // style: BorderStyle.solid, // dashed not supported in Flutter
                ),
              ),
              child: Column(
                children: [
                  if (_isUploading)
                    const CircularProgressIndicator()
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.cloud_upload_outlined,
                          size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text('Tap to upload CSV or Excel file',
                      style: GoogleFonts.inter(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Supported: .csv, .xlsx, .xls',
                      style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey[500])),
                  ],
                ],
              ),
            ),
          ),

          if (_uploadError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_uploadError!,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Data Source Connectors
          Text('Data Source Connectors', style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              _connectorCard('Google Sheets', Icons.table_chart, Colors.green, isDark),
              const SizedBox(width: 12),
              _connectorCard('REST API', Icons.api, Colors.blue, isDark),
              const SizedBox(width: 12),
              _connectorCard('Database', Icons.storage, Colors.orange, isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _connectorCard('PostgreSQL', Icons.dns, Colors.blueGrey, isDark),
              const SizedBox(width: 12),
              _connectorCard('MySQL', Icons.cloud, Colors.teal, isDark),
              const SizedBox(width: 12),
              _connectorCard('MongoDB', Icons.hub, Colors.green.shade700, isDark),
            ],
          ),

          // Google Sheets connector form
          if (_selectedConnector == 'Google Sheets') ...[
            const SizedBox(height: 16),
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
                  Text('Connect Google Sheets',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Paste Google Sheets URL or ID',
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Sheet name (default: Sheet1)',
                          prefixIcon: const Icon(Icons.tab),
                        ),
                      )),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Connect'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // API Endpoint connector
          if (_selectedConnector == 'REST API') ...[
            const SizedBox(height: 16),
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
                  Text('Connect REST API',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'API Endpoint URL',
                      prefixIcon: Icon(Icons.http),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: 'GET',
                          items: ['GET', 'POST'].map((m) =>
                            DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (_) {},
                          decoration: const InputDecoration(labelText: 'Method'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Auth Token (optional)',
                            prefixIcon: Icon(Icons.key),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Headers (JSON, optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Test & Connect'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => setState(() => _selectedConnector = ''),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Data Preview & Chart Suggestions
          if (_showDataPreview && provider.activeDataset != null) ...[
            Text('Data Preview', style: GoogleFonts.inter(
                fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            _buildDataInfo(provider, isDark),
            const SizedBox(height: 16),
            _buildDataTable(provider, isDark),
            const SizedBox(height: 24),

            // Auto-generated chart suggestions
            if (_suggestions.isNotEmpty) ...[
              Text('Suggested Charts', style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('AI-generated chart recommendations based on your data',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 16),
              ..._suggestions.where((s) => s.type != 'kpi').map((s) =>
                _buildSuggestionCard(s, isDark)),
            ],
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _connectorCard(String name, IconData icon, Color color, bool isDark) {
    final isSelected = _selectedConnector == name;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() =>
            _selectedConnector = isSelected ? '' : name),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : (isDark
                  ? const Color(0xFF313244) : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(name, style: GoogleFonts.inter(fontSize: 11,
                  fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataInfo(AppProvider provider, bool isDark) {
    final ds = provider.activeDataset!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ds.name, style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text('${ds.rowCount} rows • ${ds.colCount} columns • ${ds.sourceType.toUpperCase()}',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(AppProvider provider, bool isDark) {
    final ds = provider.activeDataset!;
    final rows = provider.activeDataRows.take(10).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDark ? const Color(0xFF313244) : const Color(0xFFF8FAFC)),
          columnSpacing: 20,
          columns: ds.columns.map((col) => DataColumn(
            label: Text(col, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600)),
          )).toList(),
          rows: rows.map((row) => DataRow(
            cells: ds.columns.map((col) => DataCell(
              Text(row[col]?.toString() ?? '',
                style: GoogleFonts.inter(fontSize: 12),
                overflow: TextOverflow.ellipsis),
            )).toList(),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(ChartSuggestion suggestion, bool isDark) {
    final iconMap = {
      'bar': Icons.bar_chart,
      'line': Icons.show_chart,
      'pie': Icons.pie_chart,
      'heatmap': Icons.grid_on,
      'scatter': Icons.scatter_plot,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            child: Icon(iconMap[suggestion.type] ?? Icons.bar_chart,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(suggestion.type.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10,
                            fontWeight: FontWeight.w600)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(suggestion.title,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(suggestion.description,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              // Add chart to dashboard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Chart "${suggestion.title}" added to dashboard!'),
                  behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Add', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

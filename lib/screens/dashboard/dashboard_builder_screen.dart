import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:uuid/uuid.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../models/all_models.dart';

class DashboardBuilderScreen extends StatefulWidget {
  const DashboardBuilderScreen({super.key});

  @override
  State<DashboardBuilderScreen> createState() => _DashboardBuilderScreenState();
}

class _DashboardBuilderScreenState extends State<DashboardBuilderScreen> {
  final _uuid = const Uuid();
  final _nameController = TextEditingController(text: 'My Dashboard');
  List<_DashWidget> _widgets = [];
  bool _isAddingWidget = false;
  String? _dragTargetId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Builder', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isAddingWidget = !_isAddingWidget),
            icon: Icon(_isAddingWidget ? Icons.close : Icons.add_circle_outline, size: 20),
            label: Text(_isAddingWidget ? 'Cancel' : 'Add Widget'),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _saveDashboard,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Dashboard name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF8FAFC),
            child: Row(
              children: [
                const Icon(Icons.edit, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Dashboard name',
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text('${_widgets.length} widgets',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),

          // Widget palette (when adding)
          if (_isAddingWidget)
            Container(
              height: 110,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primary.withValues(alpha: 0.04),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _paletteItem('KPI Card', Icons.speed, 'kpi', AppColors.primary),
                  _paletteItem('Bar Chart', Icons.bar_chart, 'bar', AppColors.chartColors[0]),
                  _paletteItem('Line Chart', Icons.show_chart, 'line', AppColors.chartColors[1]),
                  _paletteItem('Pie Chart', Icons.pie_chart, 'pie', AppColors.chartColors[2]),
                  _paletteItem('Heatmap', Icons.grid_on, 'heatmap', AppColors.chartColors[3]),
                  _paletteItem('Text Note', Icons.text_fields, 'text', AppColors.chartColors[4]),
                  _paletteItem('AI Insight', Icons.auto_awesome, 'ai_insight', AppColors.chartColors[5]),
                  _paletteItem('Scatter Plot', Icons.scatter_plot, 'scatter', AppColors.chartColors[6]),
                  _paletteItem('Area Chart', Icons.area_chart, 'area', AppColors.chartColors[7]),
                ],
              ),
            ),

          // Dashboard canvas
          Expanded(
            child: _widgets.isEmpty
                ? _buildEmptyCanvas(isDark)
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _widgets.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final item = _widgets.removeAt(oldIndex);
                        _widgets.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (ctx, i) => _buildDashWidget(_widgets[i], i, isDark),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _paletteItem(String label, IconData icon, String type, Color color) {
    return GestureDetector(
      onTap: () => _addWidget(type),
      child: Container(
        width: 85,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 10,
                fontWeight: FontWeight.w600),
              textAlign: TextAlign.center, maxLines: 2),
          ],
        ),
      ),
    );
  }

  void _addWidget(String type) {
    final id = _uuid.v4();
    String title;
    switch (type) {
      case 'kpi': title = 'KPI Card'; break;
      case 'bar': title = 'Bar Chart'; break;
      case 'line': title = 'Line Chart'; break;
      case 'pie': title = 'Pie Chart'; break;
      case 'heatmap': title = 'Heatmap'; break;
      case 'text': title = 'Text Note'; break;
      case 'ai_insight': title = 'AI Insight'; break;
      case 'scatter': title = 'Scatter Plot'; break;
      case 'area': title = 'Area Chart'; break;
      default: title = 'Widget';
    }
    setState(() {
      _widgets.add(_DashWidget(id: id, type: type, title: title));
      _isAddingWidget = false;
    });
  }

  Widget _buildEmptyCanvas(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize, size: 64,
            color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text('Start building your dashboard',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600,
                color: Colors.grey)),
          const SizedBox(height: 8),
          Text('Tap "Add Widget" to add charts, KPIs, and more',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _isAddingWidget = true),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Widget'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashWidget(_DashWidget widget, int index, bool isDark) {
    return Container(
      key: ValueKey(widget.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Widget header with drag handle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.title,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                // Config button
                IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  onPressed: () => _showWidgetConfig(widget),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                  onPressed: () => setState(() => _widgets.removeAt(index)),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          // Widget content
          SizedBox(
            height: widget.type == 'kpi' ? 100 : widget.type == 'text' ? 80 : 200,
            child: _buildWidgetContent(widget, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetContent(_DashWidget widget, bool isDark) {
    switch (widget.type) {
      case 'kpi':
        return _buildSampleKpi(isDark);
      case 'bar':
        return _buildSampleBar(isDark);
      case 'line':
      case 'area':
        return _buildSampleLine(isDark, isArea: widget.type == 'area');
      case 'pie':
        return _buildSamplePie(isDark);
      case 'heatmap':
        return _buildSampleHeatmap(isDark);
      case 'text':
        return _buildTextWidget(widget, isDark);
      case 'ai_insight':
        return _buildAIInsightWidget(isDark);
      case 'scatter':
        return _buildSampleScatter(isDark);
      default:
        return const Center(child: Text('Widget'));
    }
  }

  Widget _buildSampleKpi(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _kpiMini('Revenue', '\$284K', '+12%', AppColors.primary, true)),
          const SizedBox(width: 10),
          Expanded(child: _kpiMini('Users', '2,847', '+8%', AppColors.secondary, true)),
          const SizedBox(width: 10),
          Expanded(child: _kpiMini('Conv.', '3.4%', '-0.8%', AppColors.warning, false)),
        ],
      ),
    );
  }

  Widget _kpiMini(String label, String val, String change, Color color, bool up) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(val, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(change, style: GoogleFonts.inter(fontSize: 10,
              color: up ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSampleBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        titlesData: const FlTitlesData(
          show: false,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: List.generate(8, (i) => BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(
            toY: 30 + Random(i * 5).nextDouble() * 65,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            color: AppColors.chartColors[i % AppColors.chartColors.length],
          )],
        )),
      )),
    );
  }

  Widget _buildSampleLine(bool isDark, {bool isArea = false}) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LineChart(LineChartData(
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(12, (i) =>
              FlSpot(i.toDouble(), 20 + i * 4 + Random(i * 3).nextDouble() * 25)),
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: isArea ? BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [AppColors.primary.withValues(alpha: 0.3),
                         AppColors.primary.withValues(alpha: 0.0)],
              ),
            ) : null,
          ),
        ],
      )),
    );
  }

  Widget _buildSamplePie(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: PieChart(PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 30,
        sections: [
          PieChartSectionData(value: 35, color: AppColors.chartColors[0], radius: 40,
              title: '35%', titleStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white,
                  fontWeight: FontWeight.w600)),
          PieChartSectionData(value: 25, color: AppColors.chartColors[1], radius: 38,
              title: '25%', titleStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white,
                  fontWeight: FontWeight.w600)),
          PieChartSectionData(value: 22, color: AppColors.chartColors[2], radius: 36,
              title: '22%', titleStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white,
                  fontWeight: FontWeight.w600)),
          PieChartSectionData(value: 18, color: AppColors.chartColors[3], radius: 34,
              title: '18%', titleStyle: GoogleFonts.inter(fontSize: 10, color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ],
      )),
    );
  }

  Widget _buildSampleHeatmap(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10, crossAxisSpacing: 3, mainAxisSpacing: 3),
        itemCount: 50,
        itemBuilder: (_, i) => Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
                alpha: 0.1 + Random(i * 7).nextDouble() * 0.7),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildSampleScatter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ScatterChart(ScatterChartData(
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        scatterSpots: List.generate(20, (i) => ScatterSpot(
          Random(i * 3).nextDouble() * 10,
          Random(i * 7).nextDouble() * 10,
          dotPainter: FlDotCirclePainter(
            radius: 4 + Random(i).nextDouble() * 4,
            color: AppColors.chartColors[i % AppColors.chartColors.length]
                .withValues(alpha: 0.7),
            strokeWidth: 0,
          ),
        )),
      )),
    );
  }

  Widget _buildTextWidget(_DashWidget widget, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: TextField(
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'Type your note here...',
          border: InputBorder.none,
          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
        ),
        style: GoogleFonts.inter(fontSize: 13),
      ),
    );
  }

  Widget _buildAIInsightWidget(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16,
                  color: AppColors.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text('AI Insight', style: GoogleFonts.inter(fontSize: 12,
                  fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Revenue growth is accelerating — 12.5% increase over last quarter. '
              'South region shows declining trend that needs attention.',
            style: GoogleFonts.inter(fontSize: 12, height: 1.5, color: Colors.grey[700]),
            maxLines: 5, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text('Generated just now', style: GoogleFonts.inter(
              fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  void _showWidgetConfig(_DashWidget widget) {
    final titleCtrl = TextEditingController(text: widget.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configure Widget',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Widget Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),
            Text('Widget Type: ${widget.type.toUpperCase()}',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 12),
            Text('Data Source', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: 'sample',
              items: [
                const DropdownMenuItem(value: 'sample', child: Text('Sample Data')),
                const DropdownMenuItem(value: 'dataset', child: Text('Active Dataset')),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(prefixIcon: Icon(Icons.dataset)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => widget.title = titleCtrl.text);
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveDashboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dashboard "${_nameController.text}" saved with ${_widgets.length} widgets!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _DashWidget {
  final String id;
  final String type;
  String title;
  _DashWidget({required this.id, required this.type, required this.title});
}

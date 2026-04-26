import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  String _timeRange = 'This Month';
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  TextStyle _f(double s, {FontWeight w = FontWeight.w500, Color? c}) =>
      GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c);

  BoxDecoration _card(bool dk) => BoxDecoration(
    color: dk ? const Color(0xFF1A1A2E) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: dk ? const Color(0xFF2A2A3E) : Colors.grey.shade100),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: dk ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4))],
  );

  // ══════════════════════════════════════════════
  // DATA HELPERS
  // ══════════════════════════════════════════════
  bool _hasRealData(AppProvider p) => p.activeDataset != null && p.activeDataRows.isNotEmpty;

  List<String> _numCols(AppProvider p) {
    if (!_hasRealData(p)) return [];
    final ds = p.activeDataset!;
    return List.generate(ds.columns.length, (i) => i)
        .where((i) => ds.columnTypes[i] == 'numeric')
        .map((i) => ds.columns[i]).toList();
  }

  List<String> _txtCols(AppProvider p) {
    if (!_hasRealData(p)) return [];
    final ds = p.activeDataset!;
    return List.generate(ds.columns.length, (i) => i)
        .where((i) => ds.columnTypes[i] == 'text')
        .map((i) => ds.columns[i]).toList();
  }

  double _colSum(AppProvider p, String col) =>
      p.activeDataRows.fold(0.0, (s, r) => s + (double.tryParse(r[col]?.toString().replaceAll(',', '') ?? '') ?? 0));

  double _colAvg(AppProvider p, String col) {
    final rows = p.activeDataRows;
    if (rows.isEmpty) return 0;
    return _colSum(p, col) / rows.length;
  }

  double _colMax(AppProvider p, String col) =>
      p.activeDataRows.map((r) => double.tryParse(r[col]?.toString().replaceAll(',', '') ?? '') ?? 0).fold(0.0, max);

  Map<String, double> _groupSum(AppProvider p, String groupCol, String valCol) {
    final map = <String, double>{};
    for (final r in p.activeDataRows) {
      final key = r[groupCol]?.toString() ?? 'Other';
      final val = double.tryParse(r[valCol]?.toString().replaceAll(',', '') ?? '') ?? 0;
      map[key] = (map[key] ?? 0) + val;
    }
    return map;
  }

  String _fmt(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }

  // ══════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final p = context.watch<AppProvider>();
    final hasData = _hasRealData(p);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _heroHeader(dk, p, hasData),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 24),

              // Source indicator
              if (hasData) _dataSourceBanner(p, dk),

              // KPI CARDS
              SizedBox(height: 160, child: ListView(
                scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none, children: _buildKpiCards(p, hasData, dk),
              )),
              const SizedBox(height: 28),

              // BAR CHART
              _secHead(hasData ? 'Data Overview' : 'Revenue Analytics',
                  hasData ? '${p.activeDataset!.name}' : 'Last 12 months performance', dk),
              const SizedBox(height: 14),
              hasData ? _realBarChart(p, dk) : _demoBarChart(dk),
              const SizedBox(height: 28),

              // AI INSIGHTS
              _aiCard(dk, p, hasData),
              const SizedBox(height: 28),

              // PIE CHART
              _secHead(hasData ? 'Distribution' : 'Revenue Distribution',
                  hasData ? 'Category breakdown' : 'By region breakdown', dk),
              const SizedBox(height: 14),
              hasData ? _realPieChart(p, dk) : _demoPieChart(dk),
              const SizedBox(height: 28),

              // LINE / TREND
              _secHead(hasData ? 'Value Trend' : 'Growth Trend',
                  hasData ? 'Numeric columns over rows' : 'Users vs Revenue', dk),
              const SizedBox(height: 14),
              hasData ? _realLineChart(p, dk) : _demoLineChart(dk),
              const SizedBox(height: 28),

              // DATA TABLE (only for real data)
              if (hasData) ...[
                _secHead('Data Preview', 'First 10 rows', dk),
                const SizedBox(height: 14),
                _dataTable(p, dk),
                const SizedBox(height: 28),
              ],

              // HEATMAP (demo only)
              if (!hasData) ...[
                _secHead('Weekly Activity', 'Peak hours analysis', dk),
                const SizedBox(height: 14),
                _heatmap(dk),
                const SizedBox(height: 28),
              ],

              // RESET BUTTON
              _resetButton(p, hasData, dk),
              const SizedBox(height: 40),
            ],
          )),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // DATA SOURCE BANNER
  // ══════════════════════════════════════════════
  Widget _dataSourceBanner(AppProvider p, bool dk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.dataset_rounded, size: 18, color: Color(0xFF10B981)),
        const SizedBox(width: 10),
        Expanded(child: Text('${p.activeDataset!.name} — ${p.activeDataset!.rowCount} rows × ${p.activeDataset!.colCount} cols',
          style: _f(12, w: FontWeight.w600, c: const Color(0xFF10B981)))),
        GestureDetector(
          onTap: () { p.activeDataRows.clear(); setState(() {}); },
          child: const Icon(Icons.close, size: 16, color: Color(0xFF10B981)),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // KPI CARDS — dynamic or demo
  // ══════════════════════════════════════════════
  List<Widget> _buildKpiCards(AppProvider p, bool hasData, bool dk) {
    if (!hasData) {
      return [
        _kpi('Total Revenue', '\$284.5K', '+12.5%', true, Icons.account_balance_wallet_rounded,
            [const Color(0xFF6366F1), const Color(0xFF8B5CF6)], [30,45,35,55,40,65,50,70,60,80,75,90], dk),
        _kpi('Active Users', '2,847', '+8.2%', true, Icons.people_alt_rounded,
            [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)], [20,25,30,28,35,40,38,45,50,48,55,60], dk),
        _kpi('Conversion', '3.42%', '-0.8%', false, Icons.trending_up_rounded,
            [const Color(0xFFF59E0B), const Color(0xFFF97316)], [40,38,42,35,30,33,28,32,25,30,27,22], dk),
        _kpi('Avg. Order', '\$67.30', '+4.1%', true, Icons.shopping_bag_rounded,
            [const Color(0xFF10B981), const Color(0xFF34D399)], [25,30,28,35,40,38,42,45,50,48,55,58], dk),
      ];
    }

    final nCols = _numCols(p);
    final icons = [Icons.analytics_rounded, Icons.bar_chart_rounded, Icons.show_chart_rounded,
        Icons.pie_chart_rounded, Icons.stacked_line_chart_rounded, Icons.data_usage_rounded];
    final grads = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFF06B6D4), const Color(0xFF0EA5E9)],
      [const Color(0xFF10B981), const Color(0xFF34D399)],
      [const Color(0xFFF59E0B), const Color(0xFFF97316)],
      [const Color(0xFFEF4444), const Color(0xFFF87171)],
      [const Color(0xFF8B5CF6), const Color(0xFFA78BFA)],
    ];

    return nCols.take(5).toList().asMap().entries.map((e) {
      final col = e.value;
      final i = e.key;
      final total = _colSum(p, col);
      final avg = _colAvg(p, col);
      final vals = p.activeDataRows.take(12).map((r) =>
          (double.tryParse(r[col]?.toString().replaceAll(',', '') ?? '') ?? 0).toInt()).toList();
      if (vals.isEmpty) vals.addAll([0, 0, 0]);

      return _kpi(
        col.length > 14 ? '${col.substring(0, 12)}..' : col,
        _fmt(total), 'avg ${_fmt(avg)}', true,
        icons[i % icons.length], grads[i % grads.length], vals, dk,
      );
    }).toList();
  }

  // ══════════════════════════════════════════════
  // REAL CHARTS — from uploaded data
  // ══════════════════════════════════════════════
  Widget _realBarChart(AppProvider p, bool dk) {
    final nCols = _numCols(p);
    final tCols = _txtCols(p);
    if (nCols.isEmpty) return _emptyChart('No numeric columns found', dk);

    final valCol = nCols.first;
    final groupCol = tCols.isNotEmpty ? tCols.first : null;

    if (groupCol != null) {
      final grouped = _groupSum(p, groupCol, valCol);
      final entries = grouped.entries.take(12).toList();
      final maxY = entries.map((e) => e.value).fold(0.0, max) * 1.2;

      return Container(height: 280, padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), decoration: _card(dk),
        child: Column(children: [
          Row(children: [
            _dot(const Color(0xFF6366F1), '$valCol by $groupCol'),
            const Spacer(),
            Text('${entries.length} categories', style: _f(10, c: Colors.grey)),
          ]),
          const SizedBox(height: 16),
          Expanded(child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround, maxY: maxY,
            barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(tooltipRoundedRadius: 10,
              getTooltipItem: (g, gi, r, ri) => BarTooltipItem('${entries[g.x].key}\n${_fmt(r.toY)}',
                _f(12, w: FontWeight.w700, c: Colors.white)))),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                getTitlesWidget: (v, m) { final idx = v.toInt(); if (idx >= entries.length) return const SizedBox.shrink();
                  final lbl = entries[idx].key; return Padding(padding: const EdgeInsets.only(top: 8),
                    child: Text(lbl.length > 5 ? '${lbl.substring(0, 4)}..' : lbl, style: _f(9, w: FontWeight.w600, c: Colors.grey))); })),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44,
                getTitlesWidget: (v, m) => Text(_fmt(v), style: _f(9, c: Colors.grey)))),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(color: (dk ? Colors.white : Colors.black).withValues(alpha: 0.04), strokeWidth: 1, dashArray: [4, 4])),
            barGroups: entries.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(toY: e.value.value, width: max(8, 120 / entries.length),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  colors: [AppColors.chartColors[e.key % AppColors.chartColors.length].withValues(alpha: 0.7),
                           AppColors.chartColors[e.key % AppColors.chartColors.length]])),
            ])).toList(),
          ))),
        ]),
      );
    }

    // No text column — show values as sequential bars
    final values = p.activeDataRows.take(20).map((r) =>
        double.tryParse(r[valCol]?.toString().replaceAll(',', '') ?? '') ?? 0).toList();
    final maxY = values.fold(0.0, max) * 1.2;

    return Container(height: 280, padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), decoration: _card(dk),
      child: Column(children: [
        Row(children: [_dot(const Color(0xFF6366F1), valCol), const Spacer(), Text('${values.length} rows', style: _f(10, c: Colors.grey))]),
        const SizedBox(height: 16),
        Expanded(child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround, maxY: maxY,
          titlesData: FlTitlesData(
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44,
              getTitlesWidget: (v, m) => Text(_fmt(v), style: _f(9, c: Colors.grey)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
          borderData: FlBorderData(show: false), gridData: FlGridData(drawVerticalLine: false),
          barGroups: values.asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(toY: e.value, width: max(6, 200 / values.length),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              color: AppColors.chartColors[e.key % AppColors.chartColors.length]),
          ])).toList(),
        ))),
      ]),
    );
  }

  Widget _realPieChart(AppProvider p, bool dk) {
    final nCols = _numCols(p); final tCols = _txtCols(p);
    if (nCols.isEmpty || tCols.isEmpty) return _emptyChart('Need numeric + text columns for pie chart', dk);

    final grouped = _groupSum(p, tCols.first, nCols.first);
    final entries = grouped.entries.take(8).toList();
    final total = entries.fold(0.0, (s, e) => s + e.value);

    return Container(padding: const EdgeInsets.all(20), decoration: _card(dk),
      child: SizedBox(height: 200, child: Row(children: [
        Expanded(child: PieChart(PieChartData(
          pieTouchData: PieTouchData(touchCallback: (ev, resp) {
            setState(() { _touchedPieIndex = resp?.touchedSection?.touchedSectionIndex ?? -1; }); }),
          sectionsSpace: 3, centerSpaceRadius: 38,
          sections: entries.asMap().entries.map((e) {
            final t = e.key == _touchedPieIndex;
            final pct = total > 0 ? (e.value.value / total * 100) : 0;
            return PieChartSectionData(value: e.value.value, title: '${pct.toStringAsFixed(0)}%',
              color: AppColors.chartColors[e.key % AppColors.chartColors.length], radius: t ? 60 : 50,
              titleStyle: _f(t ? 13 : 11, w: FontWeight.w700, c: Colors.white));
          }).toList(),
        ))),
        const SizedBox(width: 16),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: entries.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(
                color: AppColors.chartColors[e.key % AppColors.chartColors.length], borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.value.key, style: _f(11, w: FontWeight.w600, c: dk ? Colors.white : const Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis),
                Text(_fmt(e.value.value), style: _f(10, c: Colors.grey)),
              ])),
            ]),
          )).toList(),
        )),
      ])),
    );
  }

  Widget _realLineChart(AppProvider p, bool dk) {
    final nCols = _numCols(p);
    if (nCols.isEmpty) return _emptyChart('No numeric columns for line chart', dk);

    final cols = nCols.take(3).toList();
    return Container(height: 260, padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), decoration: _card(dk),
      child: Column(children: [
        Row(children: cols.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(right: 14),
          child: _dot(AppColors.chartColors[e.key], e.value.length > 12 ? '${e.value.substring(0, 10)}..' : e.value))).toList()),
        const SizedBox(height: 16),
        Expanded(child: LineChart(LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: (dk ? Colors.white : Colors.black).withValues(alpha: 0.04), dashArray: [4, 4])),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
              getTitlesWidget: (v, m) { final idx = v.toInt(); if (idx % max(1, p.activeDataRows.length ~/ 6) != 0) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 8), child: Text('${idx + 1}', style: _f(9, c: Colors.grey))); })),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
          borderData: FlBorderData(show: false),
          lineBarsData: cols.asMap().entries.map((colEntry) {
            final col = colEntry.value; final ci = colEntry.key;
            final spots = p.activeDataRows.take(50).toList().asMap().entries.map((e) {
              final v = double.tryParse(e.value[col]?.toString().replaceAll(',', '') ?? '') ?? 0;
              return FlSpot(e.key.toDouble(), v);
            }).toList();
            return LineChartBarData(spots: spots, isCurved: true, curveSmoothness: 0.3,
              color: AppColors.chartColors[ci], barWidth: 2.5, dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: ci == 0, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [AppColors.chartColors[ci].withValues(alpha: 0.12), AppColors.chartColors[ci].withValues(alpha: 0.0)])));
          }).toList(),
        ))),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // DATA TABLE
  // ══════════════════════════════════════════════
  Widget _dataTable(AppProvider p, bool dk) {
    final ds = p.activeDataset!;
    final rows = p.activeDataRows.take(10).toList();
    return Container(decoration: _card(dk), clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(dk ? const Color(0xFF2A2A3E) : const Color(0xFFF1F5F9)),
          columnSpacing: 20,
          columns: ds.columns.map((c) => DataColumn(label: Text(
            c.length > 12 ? '${c.substring(0, 10)}..' : c,
            style: _f(11, w: FontWeight.w700)))).toList(),
          rows: rows.map((r) => DataRow(cells: ds.columns.map((c) => DataCell(
            Text(r[c]?.toString() ?? '', style: _f(11), overflow: TextOverflow.ellipsis),
          )).toList())).toList(),
        ),
      ),
    );
  }

  Widget _emptyChart(String msg, bool dk) => Container(
    height: 150, decoration: _card(dk),
    child: Center(child: Text(msg, style: _f(13, c: Colors.grey))),
  );

  // ══════════════════════════════════════════════
  // RESET BUTTON
  // ══════════════════════════════════════════════
  Widget _resetButton(AppProvider p, bool hasData, bool dk) {
    return SizedBox(width: double.infinity, height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          if (hasData) {
            // Clear real data → show demo
            p.clearData();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Reset to demo dashboard'),
              behavior: SnackBarBehavior.floating, backgroundColor: AppColors.primary));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Already showing demo data. Upload a file to see your data here!'),
              behavior: SnackBarBehavior.floating));
          }
        },
        icon: Icon(hasData ? Icons.restart_alt_rounded : Icons.info_outline, size: 20),
        label: Text(hasData ? 'Reset to Demo Dashboard' : 'Upload data to see it here'),
        style: OutlinedButton.styleFrom(
          foregroundColor: hasData ? AppColors.error : Colors.grey,
          side: BorderSide(color: hasData ? AppColors.error.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // HERO HEADER
  // ══════════════════════════════════════════════
  Widget _heroHeader(bool dk, AppProvider p, bool hasData) {
    final name = p.currentUser?.name ?? 'User';
    final h = DateTime.now().hour;
    final greet = h < 12 ? 'Good Morning' : h < 17 ? 'Good Afternoon' : 'Good Evening';
    return Container(
      width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: dk ? [const Color(0xFF1E1B4B), const Color(0xFF312E81), const Color(0xFF1A1A2E)]
                     : [const Color(0xFF6366F1), const Color(0xFF818CF8), const Color(0xFF6366F1)]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: dk ? 0.3 : 0.25), blurRadius: 30, offset: const Offset(0, 10))]),
      child: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(greet, style: _f(14, c: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text(name, style: _f(26, w: FontWeight.w800, c: Colors.white)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: _timeRange, isDense: true,
              dropdownColor: dk ? const Color(0xFF1A1A2E) : AppColors.primary,
              style: _f(12, w: FontWeight.w600, c: Colors.white),
              icon: const Icon(Icons.expand_more, color: Colors.white, size: 18),
              items: ['Today','This Week','This Month','This Quarter','This Year'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => setState(() => _timeRange = v!),
            )),
          ),
        ]),
        const SizedBox(height: 20),
        // Header stats — dynamic or demo
        Row(children: hasData ? [
          _hStat('Rows', '${p.activeDataset!.rowCount}'), const SizedBox(width: 6),
          _hStat('Columns', '${p.activeDataset!.colCount}'), const SizedBox(width: 6),
          _hStat('Source', p.activeDataset!.sourceType.toUpperCase()),
        ] : [
          _hStat('Revenue', '\$284.5K'), const SizedBox(width: 6),
          _hStat('Orders', '1,284'), const SizedBox(width: 6),
          _hStat('Growth', '12.5%'),
        ]),
      ])),
    );
  }

  Widget _hStat(String l, String v) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l, style: _f(11, c: Colors.white.withValues(alpha: 0.7))),
      const SizedBox(height: 4),
      Text(v, style: _f(15, w: FontWeight.w800, c: Colors.white)),
    ]),
  ));

  // ══════════════════════════════════════════════
  // KPI CARD WIDGET
  // ══════════════════════════════════════════════
  Widget _kpi(String title, String val, String chg, bool up, IconData ico, List<Color> grad, List<int> spark, bool dk) {
    return Container(
      width: 180, margin: const EdgeInsets.only(right: 14), padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: dk ? const Color(0xFF1A1A2E) : Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: dk ? const Color(0xFF2A2A3E) : Colors.grey.shade100),
        boxShadow: [BoxShadow(color: grad[0].withValues(alpha: dk ? 0.15 : 0.08), blurRadius: 24, offset: const Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
            gradient: LinearGradient(colors: [grad[0].withValues(alpha: 0.15), grad[1].withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(10)), child: Icon(ico, color: grad[0], size: 18)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(
            color: (up ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(chg, style: _f(10, w: FontWeight.w700, c: up ? const Color(0xFF10B981) : const Color(0xFFEF4444)))),
        ]),
        const Spacer(),
        SizedBox(height: 28, child: CustomPaint(size: const Size(double.infinity, 28),
          painter: _SparkPainter(data: spark.map((e) => e.toDouble()).toList(), maxVal: spark.reduce(max).toDouble(), color: grad[0]))),
        const SizedBox(height: 10),
        Text(val, style: _f(20, w: FontWeight.w800, c: dk ? Colors.white : const Color(0xFF0F172A))),
        const SizedBox(height: 2),
        Text(title, style: _f(11, c: const Color(0xFF9CA3AF))),
      ]),
    );
  }

  // ══════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════
  Widget _secHead(String t, String s, bool dk) => Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: _f(18, w: FontWeight.w800, c: dk ? Colors.white : const Color(0xFF0F172A))),
      const SizedBox(height: 2),
      Text(s, style: _f(12, c: const Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
    ])),
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(
      color: dk ? const Color(0xFF2A2A3E) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
      child: Icon(Icons.more_horiz, size: 18, color: Colors.grey[500])),
  ]);

  Widget _dot(Color c, String l) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6), Text(l, style: _f(11, c: Colors.grey)),
  ]);

  // ══════════════════════════════════════════════
  // DEMO CHARTS (unchanged design)
  // ══════════════════════════════════════════════
  Widget _demoBarChart(bool dk) => Container(
    height: 280, padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), decoration: _card(dk),
    child: Column(children: [
      Row(children: [_dot(const Color(0xFF6366F1), 'Revenue'), const SizedBox(width: 16), _dot(const Color(0xFF06B6D4), 'Expenses'), const Spacer(), Text('in thousands (\$)', style: _f(10, c: Colors.grey))]),
      const SizedBox(height: 16),
      Expanded(child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround, maxY: 100,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28,
            getTitlesWidget: (v, m) { const mo = ['J','F','M','A','M','J','J','A','S','O','N','D']; return Padding(padding: const EdgeInsets.only(top: 8), child: Text(mo[v.toInt()], style: _f(11, w: FontWeight.w600, c: Colors.grey))); })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36,
            getTitlesWidget: (v, m) { if (v % 25 != 0) return const SizedBox.shrink(); return Text('${v.toInt()}', style: _f(10, c: Colors.grey)); })),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 25,
          getDrawingHorizontalLine: (v) => FlLine(color: (dk ? Colors.white : Colors.black).withValues(alpha: 0.04), dashArray: [4, 4])),
        barGroups: List.generate(12, (i) { final r = 45 + Random(i * 7).nextDouble() * 50; final e = r * (0.4 + Random(i * 3).nextDouble() * 0.2);
          return BarChartGroupData(x: i, barsSpace: 3, barRods: [
            BarChartRodData(toY: r, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF6366F1), Color(0xFF818CF8)])),
            BarChartRodData(toY: e, width: 10, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xFF06B6D4), Color(0xFF67E8F9)])),
          ]); }),
      ))),
    ]),
  );

  Widget _demoPieChart(bool dk) {
    final d = [{'l':'North America','v':35.0,'a':'\$99.6K','c':const Color(0xFF6366F1)},{'l':'Europe','v':28.0,'a':'\$79.7K','c':const Color(0xFF06B6D4)},
      {'l':'Asia Pacific','v':22.0,'a':'\$62.6K','c':const Color(0xFF10B981)},{'l':'Latin America','v':15.0,'a':'\$42.7K','c':const Color(0xFFF59E0B)}];
    return Container(padding: const EdgeInsets.all(20), decoration: _card(dk),
      child: SizedBox(height: 200, child: Row(children: [
        Expanded(child: PieChart(PieChartData(sectionsSpace: 3, centerSpaceRadius: 38,
          sections: d.asMap().entries.map((e) => PieChartSectionData(value: e.value['v'] as double,
            title: '${(e.value['v'] as double).toInt()}%', color: e.value['c'] as Color, radius: 50,
            titleStyle: _f(11, w: FontWeight.w700, c: Colors.white))).toList()))),
        const SizedBox(width: 16),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
          children: d.map((x) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: x['c'] as Color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8), Text('${x['l']} ${x['a']}', style: _f(11, w: FontWeight.w500, c: dk ? Colors.white : const Color(0xFF0F172A))),
          ]))).toList()),
      ])));
  }

  Widget _demoLineChart(bool dk) => Container(
    height: 260, padding: const EdgeInsets.fromLTRB(16, 20, 16, 12), decoration: _card(dk),
    child: Column(children: [
      Row(children: [_dot(const Color(0xFF6366F1), 'Users'), const SizedBox(width: 16), _dot(const Color(0xFF10B981), 'Revenue')]),
      const SizedBox(height: 16),
      Expanded(child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: (dk ? Colors.white : Colors.black).withValues(alpha: 0.04), dashArray: [4, 4])),
        titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(spots: List.generate(12, (i) => FlSpot(i.toDouble(), 25 + i * 5.5 + Random(i * 3).nextDouble() * 18)),
            isCurved: true, color: const Color(0xFF6366F1), barWidth: 3, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [const Color(0xFF6366F1).withValues(alpha: 0.15), const Color(0xFF6366F1).withValues(alpha: 0.0)]))),
          LineChartBarData(spots: List.generate(12, (i) => FlSpot(i.toDouble(), 15 + i * 4 + Random(i * 5).nextDouble() * 12)),
            isCurved: true, color: const Color(0xFF10B981), barWidth: 3, dotData: const FlDotData(show: false)),
        ],
      ))),
    ]),
  );

  Widget _aiCard(bool dk, AppProvider p, bool hasData) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: dk ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)] : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AI Insights', style: _f(16, w: FontWeight.w800, c: Colors.white)),
          Text(hasData ? 'Analysis of ${p.activeDataset!.name}' : 'Powered by Claude AI',
            style: _f(11, c: Colors.white.withValues(alpha: 0.6))),
        ]),
      ]),
      const SizedBox(height: 18),
      if (hasData) ...[
        _iRow('📊', 'Dataset has ${p.activeDataset!.rowCount} rows across ${p.activeDataset!.colCount} columns'),
        const SizedBox(height: 10),
        if (_numCols(p).isNotEmpty)
          _iRow('📈', 'Top metric: ${_numCols(p).first} — Total ${_fmt(_colSum(p, _numCols(p).first))}, Avg ${_fmt(_colAvg(p, _numCols(p).first))}'),
        if (_numCols(p).isNotEmpty) const SizedBox(height: 10),
        _iRow('💡', 'Go to AI tab to ask natural language questions about your data'),
      ] else ...[
        _iRow('📈', 'Revenue trending 12.5% higher than last quarter — strongest growth in 6 months'),
        const SizedBox(height: 10),
        _iRow('⚡', 'Tuesday & Wednesday have 2.3x higher conversion — focus ad spend here'),
        const SizedBox(height: 10),
        _iRow('🎯', 'South region churn up 15% — recommend targeted retention campaign'),
      ],
    ]),
  );

  Widget _iRow(String e, String t) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(e, style: const TextStyle(fontSize: 16)), const SizedBox(width: 10),
    Expanded(child: Text(t, style: _f(12.5, c: Colors.white.withValues(alpha: 0.85), w: FontWeight.w500))),
  ]);

  Widget _heatmap(bool dk) {
    final days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    final hrs = ['9AM','10','11','12P','1','2','3','4','5'];
    return Container(padding: const EdgeInsets.all(16), decoration: _card(dk), child: Column(children: [
      Row(children: [const SizedBox(width: 32), ...hrs.map((h) => Expanded(child: Center(child: Text(h, style: _f(9, c: Colors.grey)))))]),
      const SizedBox(height: 6),
      ...days.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
        SizedBox(width: 32, child: Text(e.value, style: _f(10, c: Colors.grey))),
        ...hrs.asMap().entries.map((h) { final intensity = Random(e.key * 17 + h.key * 11).nextDouble();
          return Expanded(child: Container(height: 26, margin: const EdgeInsets.all(1.5), decoration: BoxDecoration(
            color: Color.lerp(dk ? const Color(0xFF2A2A3E) : const Color(0xFFEEF2FF), const Color(0xFF6366F1), intensity * 0.85),
            borderRadius: BorderRadius.circular(5)))); }),
      ]))),
    ]));
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> data; final double maxVal; final Color color;
  _SparkPainter({required this.data, required this.maxVal, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()..color = color..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fill = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
      colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final path = Path(); final fPath = Path(); final step = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * step; final y = size.height - (data[i] / maxVal) * size.height;
      if (i == 0) { path.moveTo(x, y); fPath.moveTo(x, size.height); fPath.lineTo(x, y); }
      else { final px = (i-1)*step; final py = size.height-(data[i-1]/maxVal)*size.height;
        path.cubicTo(px+step*0.4, py, x-step*0.4, y, x, y); fPath.cubicTo(px+step*0.4, py, x-step*0.4, y, x, y); }
    }
    fPath.lineTo(size.width, size.height); fPath.close();
    canvas.drawPath(fPath, fill); canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

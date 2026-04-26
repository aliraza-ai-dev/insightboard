import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class ChartWidgets {
  static Widget buildBarChart({
    required Map<String, double> data,
    required String title,
    bool isDark = false,
  }) {
    final entries = data.entries.toList();
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    if (val.toInt() >= entries.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        entries[val.toInt()].key.length > 6
                            ? '${entries[val.toInt()].key.substring(0, 6)}..'
                            : entries[val.toInt()].key,
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                  reservedSize: 28,
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 44,
                  getTitlesWidget: (v, m) => Text(_formatNum(v),
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(drawVerticalLine: false),
              barGroups: entries.asMap().entries.map((e) =>
                BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value.value,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    color: AppColors.chartColors[e.key % AppColors.chartColors.length],
                  ),
                ])).toList(),
            )),
          ),
        ],
      ),
    );
  }

  static Widget buildLineChart({
    required List<double> data,
    required List<String> labels,
    required String title,
    List<double>? data2,
    String? label1,
    String? label2,
    bool isDark = false,
  }) {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (label1 != null) ...[
                _dot(AppColors.primary), const SizedBox(width: 4),
                Text(label1, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
              if (label2 != null) ...[
                const SizedBox(width: 12),
                _dot(AppColors.secondary), const SizedBox(width: 4),
                Text(label2, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(LineChartData(
              lineTouchData: const LineTouchData(enabled: true),
              gridData: FlGridData(drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, m) {
                    final idx = v.toInt();
                    if (idx >= labels.length || idx % max(1, labels.length ~/ 6) != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(labels[idx],
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                    );
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 44,
                  getTitlesWidget: (v, m) => Text(_formatNum(v),
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [AppColors.primary.withValues(alpha: 0.15),
                               AppColors.primary.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
                if (data2 != null)
                  LineChartBarData(
                    spots: data2.asMap().entries.map((e) =>
                      FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 2,
                    dashArray: [5, 3],
                    dotData: const FlDotData(show: false),
                  ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  static Widget buildPieChart({
    required Map<String, double> data,
    required String title,
    bool isDark = false,
  }) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final entries = data.entries.toList();

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: PieChart(PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: entries.asMap().entries.map((e) {
                      final pct = (e.value.value / total * 100);
                      return PieChartSectionData(
                        value: e.value.value,
                        title: '${pct.toStringAsFixed(0)}%',
                        color: AppColors.chartColors[e.key % AppColors.chartColors.length],
                        radius: 50,
                        titleStyle: GoogleFonts.inter(fontSize: 10,
                            fontWeight: FontWeight.w600, color: Colors.white),
                      );
                    }).toList(),
                  )),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.chartColors[e.key % AppColors.chartColors.length],
                            borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 6),
                        Text(e.value.key,
                          style: GoogleFonts.inter(fontSize: 11)),
                      ],
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildForecastChart({
    required List<double> historical,
    required List<String> histLabels,
    required List<double> forecast,
    required List<String> forecastLabels,
    required String title,
    required double confidence,
    bool isDark = false,
  }) {
    final allData = [...historical, ...forecast];
    final allLabels = [...histLabels, ...forecastLabels];

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: GoogleFonts.inter(
                  fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${(confidence * 100).toStringAsFixed(0)}% confidence',
                  style: GoogleFonts.inter(fontSize: 11,
                      color: AppColors.primary, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _dot(AppColors.primary), const SizedBox(width: 4),
              Text('Historical', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 16),
              _dot(AppColors.success), const SizedBox(width: 4),
              Text('Forecast', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(LineChartData(
              gridData: FlGridData(drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 28,
                  getTitlesWidget: (v, m) {
                    final idx = v.toInt();
                    if (idx >= allLabels.length || idx % max(1, allLabels.length ~/ 8) != 0) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(allLabels[idx],
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.grey)),
                    );
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 44,
                  getTitlesWidget: (v, m) => Text(_formatNum(v),
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                verticalLines: [
                  VerticalLine(
                    x: (historical.length - 1).toDouble(),
                    color: Colors.grey.withValues(alpha: 0.3),
                    dashArray: [4, 4],
                    strokeWidth: 1,
                  ),
                ],
              ),
              lineBarsData: [
                // Historical
                LineChartBarData(
                  spots: historical.asMap().entries.map((e) =>
                    FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: const FlDotData(show: false),
                ),
                // Forecast
                LineChartBarData(
                  spots: forecast.asMap().entries.map((e) =>
                    FlSpot((historical.length - 1 + e.key).toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 2.5,
                  dashArray: [6, 4],
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, pct, bar, idx) =>
                      FlDotCirclePainter(radius: 3, color: AppColors.success,
                          strokeColor: Colors.white, strokeWidth: 1.5),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [AppColors.success.withValues(alpha: 0.1),
                               AppColors.success.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
              ],
            )),
          ),
        ],
      ),
    );
  }

  static BoxDecoration _cardDecoration(bool isDark) => BoxDecoration(
    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isDark ? const Color(0xFF313244) : Colors.grey.shade200),
  );

  static Widget _dot(Color c) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
  );

  static String _formatNum(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/dashboard.dart';

class TrendChart extends StatelessWidget {
  final List<DailyTrend> data;

  const TrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No data')),
      );
    }

    final today = DateTime.now();
    final maxY = data.map((d) => d.total).fold(0, (a, b) => a > b ? a : b);
    final yMax = (maxY < 5 ? 5 : maxY + 2).toDouble();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.divider,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormatter.formatChartLabel(data[i].date),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: data.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            final isToday = _isToday(d.date, today);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: d.total.toDouble(),
                  color: isToday ? AppColors.primary : AppColors.primaryMid,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.onBackground,
              getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                  BarTooltipItem(
                '${rod.toY.toInt()} calls',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(String dateStr, DateTime today) {
    try {
      final d = DateTime.parse(dateStr);
      return d.year == today.year && d.month == today.month && d.day == today.day;
    } catch (_) {
      return false;
    }
  }
}

import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/riverpod/general/theme_provider.dart';
import 'package:kronk/utility/extensions.dart';

class StatsBarChart extends ConsumerWidget {
  final Map<String, int> stats;

  const StatsBarChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MyTheme theme = ref.watch(themeProvider);

    final maxValue = stats.values.isNotEmpty ? stats.values.reduce(max).toDouble() : 10.0;
    final maxY = _calculateNiceMaxY(maxValue);

    final barGroups = stats.entries.map((entry) {
      final index = stats.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entry.value.toDouble(),
            width: 16,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(4.dp), topRight: Radius.circular(4.dp)),
            gradient: LinearGradient(colors: [theme.primaryText, theme.secondaryBackground], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: theme.outline)),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            fitInsideVertically: true,
            getTooltipColor: (BarChartGroupData group) => theme.primaryText,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${stats.values.elementAt(group.x)}',
              TextStyle(color: theme.secondaryBackground),
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: false,
              interval: _calculateInterval(maxY),
              reservedSize: 36.dp,
              maxIncluded: false,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 4.dp,
                  child: Text(_formatYValue(value), style: TextStyle(color: theme.primaryText, fontSize: 10)),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _calculateInterval(maxY),
              reservedSize: 36.dp,
              maxIncluded: false,
              getTitlesWidget: (double value, TitleMeta meta) {
                return SideTitleWidget(
                  meta: meta,
                  space: 4.dp,
                  child: Text(
                    _formatYValue(value),
                    style: TextStyle(color: theme.primaryText, fontSize: 10.dp),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < stats.keys.length) {
                  return SideTitleWidget(
                    meta: meta,
                    space: 0,
                    child: Text(
                      stats.keys.elementAt(index),
                      style: TextStyle(color: theme.primaryText, fontSize: 10.dp),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }

  String _formatYValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  double _calculateInterval(double maxY) {
    if (maxY <= 50) return 10;
    if (maxY <= 200) return 50;
    if (maxY <= 1000) return 100;
    return 1000;
  }

  double _calculateNiceMaxY(double maxVal) {
    int base;
    if (maxVal < 100) {
      base = 10;
    } else if (maxVal < 1000) {
      base = 100;
    } else {
      base = 1000;
    }

    // Round up to nearest multiple of `base`
    double rounded = ((maxVal + base - 1) / base).floor() * base.toDouble();

    // Add one more base unit (so final maxY = closest upper multiple + base)
    return rounded + base;
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'gradient_card.dart';

class AdherenceChart extends StatelessWidget {
  final List<double> adherenceData;
  final bool isLoading;
  
  const AdherenceChart({
    super.key,
    required this.adherenceData,
    this.isLoading = false,
  });

  Color _getBarColor(double percentage) {
    if (percentage >= 80) {
      return AppColors.success;
    } else if (percentage >= 50) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(20),
        child: const SizedBox(
          height: 250,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    if (adherenceData.isEmpty || adherenceData.length != 7) {
      return GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 250,
          child: Center(
            child: Text(
              'No data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 250,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => AppColors.surface,
                tooltipBorderRadius: BorderRadius.circular(8),
                tooltipPadding: const EdgeInsets.all(8),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()}%',
                    TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                      return Text(
                        days[value.toInt()],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  interval: 20,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}%',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: AppColors.surface2,
                width: 1,
              ),
            ),
            barGroups: adherenceData.asMap().entries.map((entry) {
              final index = entry.key;
              final percentage = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: percentage,
                    color: _getBarColor(percentage),
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        _getBarColor(percentage),
                        _getBarColor(percentage).withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}


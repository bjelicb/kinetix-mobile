import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'gradient_card.dart';

class StrengthProgressionChart extends StatefulWidget {
  const StrengthProgressionChart({super.key});

  @override
  State<StrengthProgressionChart> createState() => _StrengthProgressionChartState();
}

class _StrengthProgressionChartState extends State<StrengthProgressionChart> {
  String _selectedExercise = 'Bench Press';
  
  final List<String> _exercises = ['Bench Press', 'Squat', 'Deadlift'];
  
  // Mock data for last 30 days
  final Map<String, List<FlSpot>> _exerciseData = {
    'Bench Press': List.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: 29 - index));
      final weight = 80.0 + (index * 0.5) + (index % 7) * 2.0; // Progressive increase
      return FlSpot(index.toDouble(), weight);
    }),
    'Squat': List.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: 29 - index));
      final weight = 100.0 + (index * 0.7) + (index % 7) * 2.5;
      return FlSpot(index.toDouble(), weight);
    }),
    'Deadlift': List.generate(30, (index) {
      final date = DateTime.now().subtract(Duration(days: 29 - index));
      final weight = 140.0 + (index * 0.8) + (index % 7) * 3.0;
      return FlSpot(index.toDouble(), weight);
    }),
  };

  @override
  Widget build(BuildContext context) {
    final selectedData = _exerciseData[_selectedExercise] ?? [];
    
    return GradientCard(
      gradient: AppGradients.card,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise Filter Dropdown
          DropdownButton<String>(
            value: _selectedExercise,
            isExpanded: true,
            underline: Container(),
            dropdownColor: AppColors.surface,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            items: _exercises.map((exercise) {
              return DropdownMenuItem<String>(
                value: exercise,
                child: Text(exercise),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedExercise = value!;
              });
            },
            icon: const Icon(
              Icons.arrow_drop_down_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Chart
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.surface2,
                      strokeWidth: 1,
                    );
                  },
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
                      interval: 5,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 5 == 0) {
                          return Text(
                            'Day ${value.toInt()}',
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
                          '${value.toInt()}kg',
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
                minX: 0,
                maxX: 29,
                minY: 70,
                maxY: 180,
                lineBarsData: [
                  LineChartBarData(
                    spots: selectedData,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryStart,
                        AppColors.primaryEnd,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


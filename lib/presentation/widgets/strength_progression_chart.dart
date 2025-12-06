import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import 'gradient_card.dart';

class StrengthProgressionChart extends StatefulWidget {
  final Map<String, List<Map<String, double>>> exerciseData;
  final bool isLoading;
  
  const StrengthProgressionChart({
    super.key,
    required this.exerciseData,
    this.isLoading = false,
  });

  @override
  State<StrengthProgressionChart> createState() => _StrengthProgressionChartState();
}

class _StrengthProgressionChartState extends State<StrengthProgressionChart> {
  String? _selectedExercise;
  
  List<String> get _exercises => widget.exerciseData.keys.toList();
  
  Map<String, List<FlSpot>> get _exerciseSpots {
    final result = <String, List<FlSpot>>{};
    for (final entry in widget.exerciseData.entries) {
      result[entry.key] = entry.value.map((point) {
        return FlSpot(point['x'] ?? 0.0, point['y'] ?? 0.0);
      }).toList();
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    if (_exercises.isNotEmpty) {
      _selectedExercise = _exercises.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(20),
        child: const SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    if (_exercises.isEmpty || _selectedExercise == null) {
      return GradientCard(
        gradient: AppGradients.card,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 300,
          child: Center(
            child: Text(
              'No progression data available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    
    final selectedData = _exerciseSpots[_selectedExercise] ?? [];
    final allSpots = _exerciseSpots.values.expand((e) => e).toList();
    final maxY = allSpots.isEmpty 
        ? 180.0 
        : (allSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1);
    final minY = allSpots.isEmpty 
        ? 70.0 
        : (allSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.9);
    final maxX = allSpots.isEmpty 
        ? 29.0 
        : (allSpots.map((s) => s.x).reduce((a, b) => a > b ? a : b));
    
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
                maxX: maxX > 0 ? maxX : 29,
                minY: minY > 0 ? minY : 70,
                maxY: maxY > 0 ? maxY : 180,
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


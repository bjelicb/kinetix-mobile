import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_mobile/presentation/widgets/strength_progression_chart.dart';

void main() {
  group('StrengthProgressionChart', () {
    testWidgets('renders with provided data', (WidgetTester tester) async {
      final exerciseData = {
        'Bench Press': [
          {'x': 0.0, 'y': 80.0},
          {'x': 1.0, 'y': 82.0},
        ],
      };
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StrengthProgressionChart(exerciseData: exerciseData),
          ),
        ),
      );
      
      expect(find.byType(StrengthProgressionChart), findsOneWidget);
    });
    
    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrengthProgressionChart(
              exerciseData: {},
              isLoading: true,
            ),
          ),
        ),
      );
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('shows empty state when data is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StrengthProgressionChart(exerciseData: {}),
          ),
        ),
      );
      
      expect(find.text('No progression data available'), findsOneWidget);
    });
  });
}

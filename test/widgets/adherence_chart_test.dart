import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_mobile/presentation/widgets/adherence_chart.dart';

void main() {
  group('AdherenceChart', () {
    testWidgets('renders with provided data', (WidgetTester tester) async {
      const adherenceData = [85.0, 90.0, 75.0, 100.0, 80.0, 95.0, 70.0];
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdherenceChart(adherenceData: adherenceData),
          ),
        ),
      );
      
      expect(find.byType(AdherenceChart), findsOneWidget);
    });
    
    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdherenceChart(
              adherenceData: [],
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
            body: AdherenceChart(adherenceData: []),
          ),
        ),
      );
      
      expect(find.text('No data available'), findsOneWidget);
    });
  });
}

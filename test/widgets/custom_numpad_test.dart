import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinetix_mobile/presentation/widgets/custom_numpad.dart';

void main() {
  group('CustomNumpad', () {
    testWidgets('renders numpad buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MediaQuery(
                data: const MediaQueryData(size: Size(800, 1200)), // Dovoljno visine za quick-select buttons
                child: CustomNumpad(
                  onValueChanged: (value) {},
                  onConfirm: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify numpad buttons are rendered
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });
}

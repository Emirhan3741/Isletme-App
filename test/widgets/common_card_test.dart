import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locapo/core/widgets/common_widgets.dart';

void main() {
  group('CommonCard Widget Tests', () {
    testWidgets('should display child widget correctly',
        (WidgetTester tester) async {
      // Arrange
      const testText = 'Test Content';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonCard(
              child: Text(testText),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testText), findsOneWidget);
      expect(find.byType(Material), findsAtLeastNWidgets(1));
    });

    testWidgets('should apply custom padding when provided',
        (WidgetTester tester) async {
      // Arrange
      const customPadding = EdgeInsets.all(32.0);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonCard(
              padding: customPadding,
              child: Text('Test'),
            ),
          ),
        ),
      );

      // Assert
      final paddingWidgets = find.descendant(
        of: find.byType(CommonCard),
        matching: find.byType(Padding),
      );
      expect(paddingWidgets, findsAtLeastNWidgets(1));
      
      // Son (en içteki) Padding widget'ını al - bu CommonCard'ın asıl padding'i
      final padding = tester.widget<Padding>(paddingWidgets.last);
      expect(padding.padding, customPadding);
    });

    testWidgets('should use default elevation when none provided',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommonCard(
              child: Text('Test'),
            ),
          ),
        ),
      );

      // Assert
      final materialWidgets = find.descendant(
        of: find.byType(CommonCard),
        matching: find.byType(Material),
      );
      
      expect(materialWidgets, findsAtLeastNWidgets(1));
      
      final material = tester.widget<Material>(materialWidgets.first);
      expect(material.elevation, 2.0); // Default elevation
    });
  });
}

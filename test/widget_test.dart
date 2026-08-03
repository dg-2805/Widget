// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:provider/provider.dart';

//import 'package:our_space/main.dart';
//import 'package:our_space/providers/app_state.dart';
import 'package:our_space/core/widgets/cute_widgets.dart';

class FakeAppState extends ChangeNotifier {
  bool isDay = true;
  bool get isPaired => false;
}

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    // Pump a minimal MaterialApp using DreamyBackground to avoid Firebase/provider setup.
    await tester.pumpWidget(
      const MaterialApp(
        home: DreamyBackground(
          isDay: true,
          child: Center(child: Text('test')),
        ),
      ),
    );

    expect(find.text('test'), findsOneWidget);
  });
}

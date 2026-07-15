import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecosmartbin_frontend/main.dart';

void main() {
  testWidgets('Smoke test for EcoSmartBin App', (WidgetTester tester) async {
    // Set a larger viewport to avoid layout overflows during test
    tester.view.physicalSize = const Size(1280, 1024);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(startRoute: '/login'));

    // Verify that the login screen title and button are present.
    expect(find.text('EcoSmartBin'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);

    // Reset view settings
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

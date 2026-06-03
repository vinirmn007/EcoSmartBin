import 'package:flutter_test/flutter_test.dart';
import 'package:ecosmartbin_frontend/main.dart';

void main() {
  testWidgets('Smoke test for EcoSmartBin App', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(startRoute: '/login'));

    // Verify that the login screen title and button are present.
    expect(find.text('EcoSmartBin'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}

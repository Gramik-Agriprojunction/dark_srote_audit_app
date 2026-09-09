import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_audit/features/auth/presentation/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows Gramik Darkstore login screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Apna Number Daalo'), findsOneWidget);
    expect(find.text('Dark Store'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_audit/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('shows StockShield branded login screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('Welcome Back! 👋'), findsOneWidget);
    expect(find.text('StockShield'), findsOneWidget);
    expect(find.text('Smart Inventory • Accurate Stock'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Why StockShield?'), findsOneWidget);
  });
}

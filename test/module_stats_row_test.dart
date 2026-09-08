import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stock_audit/core/widgets/module_ui.dart';

void main() {
  testWidgets('ModuleStatsRow shows full long labels without ellipsis', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ModuleStatsRow(
              stats: [
                ModuleStat(
                  icon: Icons.local_shipping_outlined,
                  label: 'Pickup Orders',
                  value: '1',
                  background: Color(0xFFEC5800),
                  labelColor: Color(0xFFFFE4D2),
                ),
                ModuleStat(
                  icon: Icons.undo_rounded,
                  label: 'RTO Delivered',
                  value: '0',
                  background: Color(0xFFB45309),
                  labelColor: Color(0xFFFED7AA),
                ),
                ModuleStat(
                  icon: Icons.category_outlined,
                  label: 'SKU Moved',
                  value: '3',
                  background: Color(0xFF1D4ED8),
                  labelColor: Color(0xFFBFDBFE),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('PICKUP ORDERS'), findsOneWidget);
    expect(find.text('RTO DELIVERED'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('SKU MOVED'), findsOneWidget);
    expect(find.textContaining('...'), findsNothing);
  });

  testWidgets('ModuleStatsRow shows full money value', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ModuleStatsRow(
              stats: [
                ModuleStat(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total Orders',
                  value: '792',
                  background: Color(0xFFEC5800),
                  labelColor: Color(0xFFFFE4D2),
                ),
                ModuleStat(
                  icon: Icons.schedule_rounded,
                  label: 'Pending',
                  value: '19',
                  background: Color(0xFFB45309),
                  labelColor: Color(0xFFFED7AA),
                ),
                ModuleStat(
                  icon: Icons.payments_outlined,
                  label: 'Total Value',
                  value: '₹7,86,450',
                  background: Color(0xFF1D4ED8),
                  labelColor: Color(0xFFBFDBFE),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('TOTAL ORDERS'), findsOneWidget);
    expect(find.text('TOTAL VALUE'), findsOneWidget);
    expect(find.text('₹7,86,450'), findsOneWidget);
  });
}

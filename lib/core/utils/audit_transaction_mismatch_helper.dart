import '../../features/stock_audit/data/models/product_model.dart';

class AuditTransactionMismatchHelper {
  AuditTransactionMismatchHelper._();

  static int baselineQty(ProductVariantModel variant) => variant.auditQty;

  static int expectedQty({
    required int baselineQty,
    required int inventoryChangeQty,
  }) {
    final expected = baselineQty + inventoryChangeQty;
    return expected < 0 ? 0 : expected;
  }

  static bool requiresReason({
    required int newQty,
    required int baselineQty,
    required int inventoryChangeQty,
  }) {
    return newQty !=
        expectedQty(
          baselineQty: baselineQty,
          inventoryChangeQty: inventoryChangeQty,
        );
  }
}

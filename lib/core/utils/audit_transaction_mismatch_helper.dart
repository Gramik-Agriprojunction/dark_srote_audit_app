import '../../features/stock_audit/data/models/product_model.dart';

class AuditTransactionMismatchHelper {
  AuditTransactionMismatchHelper._();

  static const int reasonMinLength = 25;
  static const int reasonMaxLength = 1000;

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

  static bool isValidReason(String? reason) {
    final trimmed = reason?.trim() ?? '';
    return trimmed.length >= reasonMinLength &&
        trimmed.length <= reasonMaxLength;
  }
}

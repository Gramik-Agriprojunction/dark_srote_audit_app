import '../utils/date_formatter.dart';
import '../../features/stock_audit/data/models/product_model.dart';

class AuditQtyHelper {
  AuditQtyHelper._();

  static int savedAuditQty(ProductVariantModel variant) => variant.auditQty;

  static int todayAuditQty(ProductVariantModel variant) {
    if (!DateFormatter.isAuditUpdatedToday(variant.auditUpdatedAt)) return 0;
    return savedAuditQty(variant);
  }

  static int displayPcsQty(ProductVariantModel variant) {
    if (variant.auditUpdatedAt != null) return savedAuditQty(variant);
    return 0;
  }

  static String formatInputValue({
    required ProductVariantModel variant,
    required int qty,
    required bool hasDraft,
  }) {
    if (qty > 0) return qty.toString();
    if (qty == 0) {
      if (hasDraft) return '0';
      if (DateFormatter.isAuditUpdatedToday(variant.auditUpdatedAt)) {
        return '0';
      }
    }
    return '';
  }

  static bool isQtyChanged({
    required ProductVariantModel variant,
    required int? draftQty,
    required bool hasDraft,
  }) {
    if (!hasDraft || draftQty == null) return false;
    final baseline = todayAuditQty(variant);
    if (draftQty == 0 &&
        draftQty == baseline &&
        !DateFormatter.isAuditUpdatedToday(variant.auditUpdatedAt)) {
      return true;
    }
    return draftQty != baseline;
  }
}

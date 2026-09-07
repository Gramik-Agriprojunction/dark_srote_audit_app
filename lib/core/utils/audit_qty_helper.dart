import '../utils/date_formatter.dart';
import '../../features/stock_audit/data/models/product_model.dart';
import 'v2_backlog_helper.dart';

class AuditQtyHelper {
  AuditQtyHelper._();

  static int physicalStock(ProductVariantModel variant) {
    final totalPhysicalStock = variant.auditQty;
    final damageStock = variant.damageQty;
    return (totalPhysicalStock - damageStock).clamp(0, totalPhysicalStock);
  }

  /// Lens full-report / plot-run baseline (`v2PlotRunDiff`).
  /// Prefer API `lastAuditSystemStock`; else the SYSTEM column value.
  static int? reconciledLastAuditSystemStock(ProductVariantModel variant) {
    if (variant.auditUpdatedAt == null) return null;
    if (variant.lastAuditSystemStock != null) {
      return variant.lastAuditSystemStock;
    }
    if (variant.systemOnHandQty > 0) {
      return V2BacklogHelper.applyAdjustment(
        baseQty: variant.systemOnHandQty,
        backlog: variant.backlog,
        type: variant.inventoryType,
      );
    }
    // Live API may omit last-audit fields — match visible SYSTEM column.
    if (variant.availableStock > 0 || variant.currentStock > 0) {
      return variant.availableStock > 0
          ? variant.availableStock
          : variant.currentStock;
    }
    return 0;
  }

  /// Lens `v2PlotRunDiff`: Total Physical Stock − System Stock at Last Audit.
  /// Damage stays inside Total Physical (not subtracted before diff).
  static int reconciliationDifference(ProductVariantModel variant) {
    final lastAuditBase = reconciledLastAuditSystemStock(variant);
    if (lastAuditBase == null) return 0;
    return variant.auditQty - lastAuditBase;
  }

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

  /// Lens parity: Total Physical vs last-audit system (`v2PlotRunDiff`).
  static bool hasVariance(ProductVariantModel variant) {
    if (variant.auditUpdatedAt == null) return false;
    return reconciliationDifference(variant) != 0;
  }
}

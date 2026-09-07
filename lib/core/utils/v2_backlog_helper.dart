/// V2 backlog adjustment — mirrors Lens / `v2ReconLastAuditSystemStock`.
class V2BacklogHelper {
  V2BacklogHelper._();

  static int applyAdjustment({
    required int baseQty,
    required int backlog,
    required String type,
  }) {
    final delta = backlog < 0 ? 0 : backlog;
    final normalized = type.trim().toUpperCase();
    if (normalized == 'MINUS') return baseQty - delta;
    if (normalized == 'PLUS') return baseQty + delta;
    return baseQty;
  }

  static int? lastAuditSystemStock({
    required int systemOnHandQty,
    required int backlog,
    required String type,
    int? precomputed,
  }) {
    if (precomputed != null) return precomputed;
    return applyAdjustment(
      baseQty: systemOnHandQty,
      backlog: backlog,
      type: type,
    );
  }
}

class RoleHelper {
  RoleHelper._();

  static const viewOnlyMessage =
      'SuperAdmin sirf view kar sakte hain. Koi action allowed nahi hai.';

  static String normalizeRoleName(String? roleName) {
    return (roleName ?? '').trim().toUpperCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '',
    );
  }

  static bool isDarkStoreRole(String? roleName) {
    return normalizeRoleName(roleName) == 'DARKSTORE';
  }

  static bool isSuperAdminRole(String? roleName) {
    return normalizeRoleName(roleName) == 'SUPERADMIN';
  }

  /// SuperAdmin can browse every screen but must not mutate data.
  static bool isViewOnlyRole(String? roleName) => isSuperAdminRole(roleName);

  static bool canPerformActions(String? roleName) => !isViewOnlyRole(roleName);

  /// Stock Audit app login: Dark Store + SuperAdmin.
  static bool isStockAuditAllowedRole(String? roleName) {
    return isDarkStoreRole(roleName) || isSuperAdminRole(roleName);
  }

  static bool isMobileWebAllowedRole(String? roleName) {
    final role = normalizeRoleName(roleName);
    return role == 'DSO' ||
        role == 'BSO' ||
        role == 'DARKSTORE' ||
        role == 'LOGISTICS' ||
        role == 'LOGISTICSMANAGER' ||
        role == 'MANAGER';
  }
}

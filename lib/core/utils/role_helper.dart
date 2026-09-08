class RoleHelper {
  RoleHelper._();

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

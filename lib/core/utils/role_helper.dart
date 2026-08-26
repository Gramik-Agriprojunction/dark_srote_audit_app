class RoleHelper {
  RoleHelper._();

  static String normalizeRoleName(String? roleName) {
    return (roleName ?? '')
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[\s_-]+'), '');
  }

  static bool isDarkStoreRole(String? roleName) {
    return normalizeRoleName(roleName) == 'DARKSTORE';
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

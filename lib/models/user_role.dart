enum UserRole {
  neighbor,
  subcityModerator,
  securityAuditor,
  systemAdmin;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'subcitymoderator':
        return UserRole.subcityModerator;
      case 'securityauditor':
        return UserRole.securityAuditor;
      case 'systemadmin':
        return UserRole.systemAdmin;
      case 'neighbor':
      default:
        return UserRole.neighbor;
    }
  }

  String get value {
    switch (this) {
      case UserRole.subcityModerator:
        return 'SubcityModerator';
      case UserRole.securityAuditor:
        return 'SecurityAuditor';
      case UserRole.systemAdmin:
        return 'SystemAdmin';
      case UserRole.neighbor:
        return 'Neighbor';
    }
  }
}
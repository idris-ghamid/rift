/// Fine-grained access control for box operations.
///
/// Provides permission-based access control for Rift boxes and
/// individual keys. Supports roles, deny-by-default, and
/// context-aware authorization.
///
/// Usage:
/// ```dart
/// final ac = AccessControl();
///
/// // Define roles
/// ac.addRole(Role('admin', permissions: {Permission.read, Permission.write, Permission.delete, Permission.admin}));
/// ac.addRole(Role('viewer', permissions: {Permission.read}));
///
/// // Grant access
/// ac.grant('users', 'user_1', 'admin');
///
/// // Check access
/// final ctx = AccessContext(userId: 'user_1', roles: ['admin']);
/// if (ac.isAllowed(ctx, 'users', Permission.write)) {
///   await box.put('key', value);
/// }
/// ```
library;

/// Permissions for box operations.
enum Permission {
  /// Read access (get operations).
  read,

  /// Write access (put operations).
  write,

  /// Delete access (delete operations).
  delete,

  /// Administrative access (schema changes, configuration).
  admin,
}

/// A named set of permissions.
class Role {
  /// The role name.
  final String name;

  /// The permissions granted by this role.
  final Set<Permission> permissions;

  /// Optional description of the role.
  final String? description;

  /// Creates a [Role].
  Role(this.name, {required this.permissions, this.description});

  /// Whether this role grants the given [permission].
  bool hasPermission(Permission permission) => permissions.contains(permission);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Role && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() =>
      'Role($name: ${permissions.map((p) => p.name).join(', ')})';
}

/// The current access context (user/session).
class AccessContext {
  /// The user identifier.
  final String userId;

  /// The roles assigned to this context.
  final Set<String> roles;

  /// Additional attributes for context-aware authorization.
  final Map<String, dynamic> attributes;

  /// Creates an [AccessContext].
  AccessContext({
    required this.userId,
    Iterable<String>? roles,
    Map<String, dynamic>? attributes,
  }) : roles = Set.from(roles ?? {}),
       attributes = Map.from(attributes ?? {});

  /// Creates an admin context with all permissions.
  factory AccessContext.admin(String userId) =>
      AccessContext(userId: userId, roles: {'admin'});

  /// Creates a read-only context.
  factory AccessContext.readOnly(String userId) =>
      AccessContext(userId: userId, roles: {'viewer'});

  /// Whether this context has the given [role].
  bool hasRole(String role) => roles.contains(role);

  /// Gets an attribute value.
  dynamic getAttribute(String key) => attributes[key];

  @override
  String toString() => 'AccessContext($userId, roles: $roles)';
}

/// An access control rule.
class AccessRule {
  /// The box name this rule applies to (empty for all boxes).
  final String boxName;

  /// The key pattern this rule applies to (null for all keys).
  final String? keyPattern;

  /// The role this rule applies to.
  final String role;

  /// The permissions granted by this rule.
  final Set<Permission> permissions;

  /// Whether this is a deny rule (overrides grants).
  final bool deny;

  /// Creates an [AccessRule].
  const AccessRule({
    required this.boxName,
    this.keyPattern,
    required this.role,
    required this.permissions,
    this.deny = false,
  });

  /// Whether this rule matches the given [boxName] and [key].
  bool matches(String boxName, dynamic key) {
    if (this.boxName.isNotEmpty && this.boxName != boxName) return false;
    if (keyPattern != null) {
      final keyStr = key.toString();
      // Simple glob matching
      if (keyPattern!.contains('*')) {
        final regex = RegExp(
          '^${keyPattern!.replaceAll('*', '.*').replaceAll('?', '.')}\$',
        );
        if (!regex.hasMatch(keyStr)) return false;
      } else if (keyPattern != keyStr) {
        return false;
      }
    }
    return true;
  }
}

/// Manages fine-grained access control for box operations.
///
/// [AccessControl] implements a deny-by-default policy: all access
/// is denied unless explicitly granted. Deny rules take precedence
/// over grant rules.
class AccessControl {
  /// The registered roles.
  final Map<String, Role> _roles = {};

  /// The access rules.
  final List<AccessRule> _rules = [];

  /// Whether the super admin role bypasses all checks.
  final bool superAdminBypass;

  /// The name of the super admin role.
  final String superAdminRole;

  /// Creates an [AccessControl].
  AccessControl({this.superAdminBypass = true, this.superAdminRole = 'admin'}) {
    // Register default roles
    addRole(
      Role(
        superAdminRole,
        permissions: {
          Permission.read,
          Permission.write,
          Permission.delete,
          Permission.admin,
        },
        description: 'Super administrator with all permissions',
      ),
    );
    addRole(
      Role(
        'viewer',
        permissions: {Permission.read},
        description: 'Read-only access',
      ),
    );
    addRole(
      Role(
        'editor',
        permissions: {Permission.read, Permission.write},
        description: 'Read and write access',
      ),
    );
  }

  /// Registers a [role].
  void addRole(Role role) {
    _roles[role.name] = role;
  }

  /// Removes a role by [name].
  void removeRole(String name) {
    _roles.remove(name);
    _rules.removeWhere((r) => r.role == name && !r.deny);
  }

  /// Gets a role by [name].
  Role? getRole(String name) => _roles[name];

  /// All registered role names.
  Iterable<String> get roleNames => _roles.keys;

  /// Grants [permissions] to a [role] for a [boxName].
  ///
  /// Optionally restricts to keys matching [keyPattern].
  void grant(
    String boxName,
    String role,
    Set<Permission> permissions, {
    String? keyPattern,
  }) {
    _rules.add(
      AccessRule(
        boxName: boxName,
        keyPattern: keyPattern,
        role: role,
        permissions: permissions,
        deny: false,
      ),
    );
  }

  /// Denies [permissions] to a [role] for a [boxName].
  ///
  /// Deny rules override grant rules.
  void deny(
    String boxName,
    String role,
    Set<Permission> permissions, {
    String? keyPattern,
  }) {
    _rules.add(
      AccessRule(
        boxName: boxName,
        keyPattern: keyPattern,
        role: role,
        permissions: permissions,
        deny: true,
      ),
    );
  }

  /// Checks if [context] is allowed [permission] on [boxName] for [key].
  ///
  /// Returns true if access is allowed, false otherwise.
  /// Deny rules take precedence over grant rules.
  bool isAllowed(
    AccessContext context,
    String boxName,
    Permission permission, [
    dynamic key,
  ]) {
    // Super admin bypass
    if (superAdminBypass && context.hasRole(superAdminRole)) {
      return true;
    }

    // Check deny rules first (they take precedence)
    for (final rule in _rules) {
      if (!rule.deny) continue;
      if (!_contextMatchesRule(context, rule)) continue;
      if (!rule.matches(boxName, key)) continue;
      if (rule.permissions.contains(permission)) {
        return false; // Explicitly denied
      }
    }

    // Check grant rules
    for (final rule in _rules) {
      if (rule.deny) continue;
      if (!_contextMatchesRule(context, rule)) continue;
      if (!rule.matches(boxName, key)) continue;
      if (rule.permissions.contains(permission)) {
        return true; // Explicitly granted
      }
    }

    // Check role permissions directly
    for (final roleName in context.roles) {
      final role = _roles[roleName];
      if (role != null && role.hasPermission(permission)) {
        // Role has the permission, but check if there's a box-specific deny
        return true;
      }
    }

    // Deny by default
    return false;
  }

  /// Asserts that [context] is allowed [permission], throwing if not.
  void checkAccess(
    AccessContext context,
    String boxName,
    Permission permission, [
    dynamic key,
  ]) {
    if (!isAllowed(context, boxName, permission, key)) {
      throw AccessDeniedException(
        context: context,
        boxName: boxName,
        permission: permission,
        key: key,
      );
    }
  }

  /// Gets all permissions granted to [context] for [boxName].
  Set<Permission> getPermissions(
    AccessContext context,
    String boxName, [
    dynamic key,
  ]) {
    final permissions = <Permission>{};
    for (final p in Permission.values) {
      if (isAllowed(context, boxName, p, key)) {
        permissions.add(p);
      }
    }
    return permissions;
  }

  bool _contextMatchesRule(AccessContext context, AccessRule rule) {
    return context.hasRole(rule.role);
  }

  /// Clears all rules (keeps roles).
  void clearRules() {
    _rules.clear();
  }

  /// Clears everything (roles and rules).
  void clearAll() {
    _roles.clear();
    _rules.clear();
  }
}

/// Exception thrown when access is denied.
class AccessDeniedException implements Exception {
  /// The access context that was denied.
  final AccessContext context;

  /// The box name that was accessed.
  final String boxName;

  /// The permission that was required.
  final Permission permission;

  /// The key that was accessed (if applicable).
  final dynamic key;

  /// Creates an [AccessDeniedException].
  const AccessDeniedException({
    required this.context,
    required this.boxName,
    required this.permission,
    this.key,
  });

  @override
  String toString() =>
      'AccessDeniedException: User ${context.userId} denied '
      '${permission.name} on $boxName${key != null ? '[$key]' : ''}';
}

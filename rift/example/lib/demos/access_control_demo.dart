import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class AccessControlDemoPage extends StatelessWidget {
  const AccessControlDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Access Control',
      description: 'Fine-grained access control with roles and permissions',
      codeExample:
          "final ac = AccessControl();\nac.grant('users', 'editor', {Permission.read, Permission.write});\nif (ac.isAllowed(ctx, 'users', Permission.write)) { ... }",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Access Control Demo ===\n');

        final ac = AccessControl();

        // Show default roles
        buf.writeln('--- Default Roles ---');
        for (final name in ac.roleNames) {
          final role = ac.getRole(name);
          buf.writeln(
              '  $name: ${role?.permissions.map((p) => p.name).toList()}');
        }

        // Add custom role
        ac.addRole(Role('moderator', permissions: {
          Permission.read,
          Permission.write,
          Permission.delete
        }));

        // Grant access
        ac.grant('users', 'editor', {Permission.read, Permission.write});
        ac.grant('users', 'viewer', {Permission.read});
        ac.grant('reports', 'viewer', {Permission.read});
        ac.deny('users', 'viewer', {Permission.write}, keyPattern: 'admin_*');

        // Test with admin context
        buf.writeln('\n--- Admin Context ---');
        final adminCtx = AccessContext.admin('user_1');
        buf.writeln('  Context: $adminCtx');
        for (final perm in Permission.values) {
          buf.writeln(
              '  ${perm.name} on users: ${ac.isAllowed(adminCtx, 'users', perm)}');
        }

        // Test with viewer context
        buf.writeln('\n--- Viewer Context ---');
        final viewerCtx = AccessContext.readOnly('user_2');
        buf.writeln('  Context: $viewerCtx');
        buf.writeln(
            '  read on users: ${ac.isAllowed(viewerCtx, 'users', Permission.read)}');
        buf.writeln(
            '  write on users: ${ac.isAllowed(viewerCtx, 'users', Permission.write)}');
        buf.writeln(
            '  delete on users: ${ac.isAllowed(viewerCtx, 'users', Permission.delete)}');

        // Key-pattern deny
        buf.writeln('\n--- Key-pattern Deny ---');
        buf.writeln(
            '  viewer read admin_settings: ${ac.isAllowed(viewerCtx, 'users', Permission.read, 'admin_settings')}');
        buf.writeln(
            '  viewer read admin_settings (write): ${ac.isAllowed(viewerCtx, 'users', Permission.write, 'admin_settings')}');
        buf.writeln(
            '  viewer read user_profile: ${ac.isAllowed(viewerCtx, 'users', Permission.read, 'user_profile')}');

        // Get all permissions
        buf.writeln('\n--- All Permissions ---');
        final editorCtx = AccessContext(userId: 'user_3', roles: ['editor']);
        final perms = ac.getPermissions(editorCtx, 'users');
        buf.writeln('  Editor on users: ${perms.map((p) => p.name).toList()}');

        // AccessDeniedException
        buf.writeln('\n--- AccessDeniedException ---');
        try {
          ac.checkAccess(viewerCtx, 'users', Permission.delete);
        } on AccessDeniedException catch (e) {
          buf.writeln('  $e');
        }

        // Custom role
        buf.writeln('\n--- Custom Role (moderator) ---');
        final modCtx = AccessContext(userId: 'user_4', roles: ['moderator']);
        buf.writeln(
            '  read: ${ac.isAllowed(modCtx, 'users', Permission.read)}');
        buf.writeln(
            '  write: ${ac.isAllowed(modCtx, 'users', Permission.write)}');
        buf.writeln(
            '  delete: ${ac.isAllowed(modCtx, 'users', Permission.delete)}');
        buf.writeln(
            '  admin: ${ac.isAllowed(modCtx, 'users', Permission.admin)}');

        return buf.toString();
      },
    );
  }
}

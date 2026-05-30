import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class TtlDemoPage extends StatelessWidget {
  const TtlDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'TTL / Auto-Expiry',
      description: 'Time-to-live for automatic data expiration',
      codeExample:
          "await ttlManager.setTTL('sessions', 'token',\n    Duration(hours: 1));\nfinal remaining =\n    ttlManager.getRemainingTTL('sessions', 'token');",
      runDemo: () async {
        final ttlStorage = TTLStorage();
        final ttlManager = TTLManager(
          storage: ttlStorage,
          onExpired: (boxName, key) {},
        );

        final buf = StringBuffer();
        buf.writeln('=== TTL / Auto-Expiry Demo ===\n');

        buf.writeln('--- Set TTL ---');
        await ttlManager.setTTL('sessions', 'token1', const Duration(hours: 1));
        await ttlManager.setTTL(
            'sessions', 'token2', const Duration(minutes: 30));
        await ttlManager.setTTL(
            'sessions', 'cache1', const Duration(seconds: 1));
        buf.writeln('  token1: 1 hour TTL');
        buf.writeln('  token2: 30 min TTL');
        buf.writeln('  cache1: 1 second TTL (will expire)');

        buf.writeln('\n--- Remaining TTL ---');
        final remaining1 = ttlManager.getRemainingTTL('sessions', 'token1');
        final remaining2 = ttlManager.getRemainingTTL('sessions', 'token2');
        buf.writeln('  token1: ${remaining1?.inSeconds}s remaining');
        buf.writeln('  token2: ${remaining2?.inSeconds}s remaining');

        buf.writeln('\n--- Is Expired? ---');
        buf.writeln('  token1: ${ttlManager.isExpired('sessions', 'token1')}');
        buf.writeln(
            '  nonexistent: ${ttlManager.isExpired('sessions', 'nokey')}');

        buf.writeln('\n--- Wait 1.5s for cache1 to expire ---');
        await Future.delayed(const Duration(milliseconds: 1500));
        buf.writeln(
            '  cache1 expired: ${ttlManager.isExpired('sessions', 'cache1')}');

        buf.writeln('\n--- Purge Expired ---');
        final purged = await ttlManager.purgeExpired('sessions');
        buf.writeln('  Purged $purged entries');

        buf.writeln('\n--- Keys with TTL ---');
        final keysWithTTL = ttlManager.getKeysWithTTL('sessions');
        buf.writeln('  ${keysWithTTL.toList()}');

        buf.writeln('\n--- Expiry Timestamp ---');
        final ts = ttlManager.getExpiryTimestamp('sessions', 'token1');
        buf.writeln(
            '  token1 expires at: $ts (${DateTime.fromMillisecondsSinceEpoch(ts!)})');

        buf.writeln('\n--- Background Purge Timer ---');
        ttlManager.startPurgeTimer(interval: const Duration(seconds: 30));
        buf.writeln('  Timer running: ${ttlManager.isPurgeTimerRunning}');
        ttlManager.stopPurgeTimer();
        buf.writeln('  Timer stopped');

        ttlManager.dispose();
        return buf.toString();
      },
    );
  }
}

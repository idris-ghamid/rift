import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class RatelimitDemoPage extends StatelessWidget {
  const RatelimitDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Rate Limiting',
      description: 'Token bucket rate limiting for operation control',
      codeExample:
          "final limiter = RateLimiter(RateLimitPolicy(\n  maxOperations: 5, timeWindow: Duration(seconds: 1),\n));\nif (limiter.tryAcquire()) { /* allowed */ }",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Rate Limiting Demo ===\n');

        // Token bucket limiter
        final limiter = RateLimiter(RateLimitPolicy(
          maxOperations: 5,
          timeWindow: const Duration(seconds: 1),
        ));

        buf.writeln('Policy: 5 ops / 1s');
        buf.writeln(
            'Initial tokens: ${limiter.availableTokens.toStringAsFixed(0)}');

        // Rapidly perform operations
        buf.writeln('\n--- Rapid Operations ---');
        int succeeded = 0;
        int failed = 0;
        for (int i = 1; i <= 10; i++) {
          if (limiter.tryAcquire()) {
            succeeded++;
            buf.writeln('  Op $i: ✅ allowed');
          } else {
            failed++;
            buf.writeln('  Op $i: ❌ rate limited');
          }
        }
        buf.writeln('  Succeeded: $succeeded, Failed: $failed');
        buf.writeln(
            '  Available tokens: ${limiter.availableTokens.toStringAsFixed(2)}');

        // RateLimitExceeded
        buf.writeln('\n--- RateLimitExceeded Exception ---');
        try {
          limiter.acquireWithTimeout(const Duration(milliseconds: 100));
        } on RateLimitExceeded catch (e) {
          buf.writeln('  $e');
        }

        // Reset
        buf.writeln('\n--- Reset ---');
        limiter.reset();
        buf.writeln(
            '  Tokens after reset: ${limiter.availableTokens.toStringAsFixed(0)}');
        buf.writeln('  Can acquire: ${limiter.canAcquire}');

        // RateLimitManager
        buf.writeln('\n--- RateLimitManager ---');
        final manager = RateLimitManager();
        manager.setBoxPolicy(
            'api_box',
            const RateLimitPolicy(
              maxOperations: 3,
              timeWindow: Duration(seconds: 1),
            ));
        buf.writeln('  Configured boxes: ${manager.configuredBoxes.toList()}');
        for (int i = 1; i <= 5; i++) {
          final ok = manager.tryAcquire('api_box');
          buf.writeln('  Op $i: ${ok ? '✅' : '❌'}');
        }

        // Preset policies
        buf.writeln('\n--- Preset Policies ---');
        buf.writeln(
            '  strictWrites: ${RateLimitPolicy.strictWrites.maxOperations} ops/${RateLimitPolicy.strictWrites.timeWindow.inSeconds}s');
        buf.writeln(
            '  moderateReads: ${RateLimitPolicy.moderateReads.maxOperations} ops/${RateLimitPolicy.moderateReads.timeWindow.inSeconds}s');

        limiter.dispose();
        manager.disposeAll();

        return buf.toString();
      },
    );
  }
}

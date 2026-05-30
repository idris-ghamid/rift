import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class PoolDemoPage extends StatelessWidget {
  const PoolDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Connection Pooling',
      description: 'Connection pool with min/max connections and stats',
      codeExample:
          "final pool = RiftPool(config: PoolConfig(maxConnections: 10), openBox: (n) => Rift.openBox<Map>(n));\nawait pool.initialize();\nfinal box = await pool.acquire('users');",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Connection Pooling Demo ===\n');

        final pool = RiftPool(
          config: const PoolConfig(
            minConnections: 1,
            maxConnections: 3,
            idleTimeout: Duration(minutes: 5),
          ),
          openBox: <E>(String name) => Rift.openBox<E>(name),
        );

        await pool.initialize();
        buf.writeln('Pool initialized');
        buf.writeln('  Max connections: ${pool.config.maxConnections}');

        // Acquire connection 1
        buf.writeln('\n--- Acquire Connection 1 ---');
        final box1 = await pool.acquire('pool_demo');
        await box1.box.put('key1', {'data': 'value1'});
        buf.writeln(
            '  Acquired: ${box1.name}, age: ${box1.age.inMilliseconds}ms');
        buf.writeln('  Stats: ${pool.stats}');

        // Acquire connection 2
        buf.writeln('\n--- Acquire Connection 2 ---');
        final box2 = await pool.acquire('pool_demo');
        buf.writeln('  Acquired: ${box2.name}');
        buf.writeln('  Active: ${pool.activeCount}, Idle: ${pool.idleCount}');

        // Acquire connection 3
        buf.writeln('\n--- Acquire Connection 3 ---');
        final box3 = await pool.acquire('pool_demo');
        buf.writeln('  Acquired: ${box3.name}');
        buf.writeln('  Active: ${pool.activeCount}, Idle: ${pool.idleCount}');

        // Release connection 1
        buf.writeln('\n--- Release Connection 1 ---');
        pool.release('pool_demo', box1);
        buf.writeln('  Active: ${pool.activeCount}, Idle: ${pool.idleCount}');

        // Release connection 2
        buf.writeln('\n--- Release Connection 2 ---');
        pool.release('pool_demo', box2);
        buf.writeln('  Active: ${pool.activeCount}, Idle: ${pool.idleCount}');

        // Acquire from idle pool
        buf.writeln('\n--- Acquire from Idle Pool ---');
        final box4 = await pool.acquire('pool_demo');
        buf.writeln('  Re-acquired: ${box4.name} (reused from idle)');
        pool.release('pool_demo', box4);

        // Release connection 3
        pool.release('pool_demo', box3);

        // Final stats
        buf.writeln('\n--- Final Pool Stats ---');
        final stats = pool.stats;
        buf.writeln('  Active: ${stats.activeCount}');
        buf.writeln('  Idle: ${stats.idleCount}');
        buf.writeln('  Total created: ${stats.totalCreated}');
        buf.writeln('  Total evicted: ${stats.totalEvicted}');
        buf.writeln('  Total waited: ${stats.totalWaited}');
        buf.writeln('  Total timeouts: ${stats.totalTimeouts}');

        await pool.close();
        buf.writeln('\n  Pool closed.');

        return buf.toString();
      },
    );
  }
}

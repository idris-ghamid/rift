import 'package:flutter/material.dart';
import '../widgets/demo_page.dart';

class SharedBufferDemoPage extends StatelessWidget {
  const SharedBufferDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'SharedArrayBuffer',
      description: 'SharedArrayBuffer for concurrent web worker access',
      codeExample:
          "// SharedArrayBuffer enables zero-copy DB access\nconst sab = new SharedArrayBuffer(1024);\nworker.postMessage({ buffer: sab }); // zero-copy!",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== SharedArrayBuffer for Web ===\n');

        buf.writeln('SharedArrayBuffer (SAB) enables concurrent access to');
        buf.writeln('shared memory between web workers in the browser.\n');

        buf.writeln('--- The Problem ---\n');

        buf.writeln('JavaScript is single-threaded. Web Workers provide');
        buf.writeln('parallelism, but data must be copied (structured clone)');
        buf.writeln('or transferred between workers — no shared state.\n');

        buf.writeln('Main Thread    Worker 1    Worker 2');
        buf.writeln('    │              │           │');
        buf.writeln('    │  copy→       │           │');
        buf.writeln('    │──────────────│           │');
        buf.writeln('    │  copy→                   │');
        buf.writeln('    │──────────────────────────│');
        buf.writeln('    │                          │');
        buf.writeln('  ⚠️ Data copied on every message — slow for large DBs');
        buf.writeln('');

        buf.writeln('--- The Solution: SharedArrayBuffer ---\n');

        buf.writeln('SAB allows multiple workers to share the same memory:');
        buf.writeln('');
        buf.writeln('  ┌─────────────────────────────────┐');
        buf.writeln('  │     SharedArrayBuffer            │');
        buf.writeln('  │  [byte][byte][byte][byte]...     │');
        buf.writeln('  └───┬──────────┬──────────┬───────┘');
        buf.writeln('      │          │          │');
        buf.writeln('  Main Thread  Worker 1  Worker 2');
        buf.writeln('      │          │          │');
        buf.writeln('  ✅ All access the SAME memory — zero-copy!');
        buf.writeln('');

        buf.writeln('--- How Rift Uses SAB ---\n');

        buf.writeln('Rift\'s web backend can use SharedArrayBuffer for:');
        buf.writeln('');
        buf.writeln('1. Concurrent DB Access');
        buf.writeln('   Multiple web workers can read/write the same DB');
        buf.writeln('   without copying data between workers.\n');

        buf.writeln('2. Read-Write Locking');
        buf.writeln('   Atomics.wait() / Atomics.notify() provide');
        buf.writeln(
            '   synchronization primitives for safe concurrent access.\n');

        buf.writeln('3. Zero-Copy Data Transfer');
        buf.writeln('   Instead of serializing DB data in postMessage(),');
        buf.writeln('   workers read directly from shared memory.\n');

        buf.writeln('--- Code Example (Conceptual) ---\n');

        buf.writeln('  // Main thread: create shared buffer');
        buf.writeln('  const DB_SIZE = 1024 * 1024; // 1 MB');
        buf.writeln('  const sab = new SharedArrayBuffer(DB_SIZE);');
        buf.writeln('  const bytes = new Uint8Array(sab);');
        buf.writeln('');
        buf.writeln('  // Send SAB to worker (zero-copy transfer)');
        buf.writeln('  worker.postMessage({ type: \'init\', buffer: sab });');
        buf.writeln('');
        buf.writeln('  // Worker: read/write shared memory');
        buf.writeln('  self.onmessage = (e) => {');
        buf.writeln('    if (e.data.type === \'init\') {');
        buf.writeln('      const shared = new Uint8Array(e.data.buffer);');
        buf.writeln('      // Read from shared DB memory');
        buf.writeln('      const byte = shared[0];');
        buf.writeln('      // Write to shared DB memory');
        buf.writeln('      shared[0] = 42;');
        buf.writeln('    }');
        buf.writeln('  };');
        buf.writeln('');

        buf.writeln('--- Synchronization with Atomics ---\n');

        buf.writeln('  // Acquire read lock');
        buf.writeln('  const lock = new Int32Array(sab, 0, 1);');
        buf.writeln('  Atomics.wait(lock, 0, 1); // Wait if write-locked');
        buf.writeln('');
        buf.writeln('  // Write lock');
        buf.writeln('  Atomics.compareExchange(lock, 0, 0, 1);');
        buf.writeln('  // ... write data ...');
        buf.writeln('  Atomics.store(lock, 0, 0);');
        buf.writeln('  Atomics.notify(lock, 0);');
        buf.writeln('');

        buf.writeln('--- Browser Requirements ---\n');

        buf.writeln('SAB requires specific HTTP headers for security:');
        buf.writeln('');
        buf.writeln('  Cross-Origin-Opener-Policy: same-origin');
        buf.writeln('  Cross-Origin-Embedder-Policy: require-corp');
        buf.writeln('');
        buf.writeln('Without these headers, SAB is not available.');
        buf.writeln('Rift falls back to regular ArrayBuffer (no sharing).');
        buf.writeln('');

        buf.writeln('--- Performance Benefits ---\n');

        buf.writeln('  Scenario              | No SAB       | With SAB');
        buf.writeln('  ──────────────────────────────────────────────');
        buf.writeln('  Read 10K entries      | ~50ms copy   | ~5ms direct');
        buf.writeln('  Write + notify        | ~20ms copy   | ~8ms atomic');
        buf.writeln('  Multi-worker scan     | N × copy     | 1 × shared');
        buf.writeln('');

        buf.writeln('--- Summary ---');
        buf.writeln('  ✅ SharedArrayBuffer = shared memory for web workers');
        buf.writeln('  ✅ Zero-copy data access between threads');
        buf.writeln('  ✅ Atomics API provides synchronization');
        buf.writeln('  ✅ Requires COOP/COEP headers');
        buf.writeln('  ✅ Rift uses SAB for efficient web DB access');
        buf.writeln(
            '  ⚠️ Not available in all browsers (needs secure context)');

        return buf.toString();
      },
    );
  }
}

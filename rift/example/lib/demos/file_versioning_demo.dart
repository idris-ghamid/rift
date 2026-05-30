import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class FileVersioningDemoPage extends StatelessWidget {
  const FileVersioningDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'File Versioning',
      description:
          'File format versioning with header containing version, flags, and metadata',
      codeExample:
          "final header = FileHeader(version: 1, flags: FileHeader.flagVarintInts);\nfinal bytes = header.toBytes(); // 17 bytes\nfinal parsed = FileHeader.fromBytes(bytes);\nfinal isRift = FileHeader.hasRiftMagic(bytes);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== File Format Versioning Demo ===\n');

        // Create a new FileHeader
        buf.writeln('--- Creating FileHeader ---');
        final header = FileHeader(
          version: FileHeader.currentVersion,
          flags: FileHeader.flagVarintInts,
        );
        buf.writeln('  Header: $header');
        buf.writeln('  Version: ${header.version}');
        buf.writeln(
            '  Flags: ${header.flags} (0x${header.flags.toRadixString(16)})');
        buf.writeln('  usesVarintInts: ${header.usesVarintInts}');
        buf.writeln('  isLegacy: ${header.isLegacy}');
        buf.writeln('  Creation timestamp: ${header.creationTimestamp}');
        buf.writeln(
            '  Creation date: ${DateTime.fromMillisecondsSinceEpoch(header.creationTimestamp)}');

        // Serialize to bytes
        buf.writeln('\n--- Serialize to Bytes ---');
        final bytes = header.toBytes();
        buf.writeln('  Total header size: ${bytes.length} bytes');
        buf.writeln('  Expected header size: ${FileHeader.headerSize} bytes');
        buf.writeln('  Raw bytes: ${bytes.toList()}');

        // Breakdown of bytes
        buf.writeln('\n--- Byte Layout ---');
        buf.writeln(
            '  [0-3] Magic: ${String.fromCharCodes(bytes.sublist(0, 4))} '
            '(0x${bytes[0].toRadixString(16)}${bytes[1].toRadixString(16)}'
            '${bytes[2].toRadixString(16)}${bytes[3].toRadixString(16)})');
        buf.writeln('  [4]   Version: ${bytes[4]}');
        buf.writeln('  [5-8] Flags: 0x${_bytesToHex(bytes.sublist(5, 9))}');
        buf.writeln('  [9-16] Timestamp: ${_bytesToHex(bytes.sublist(9, 17))}');

        // Deserialize from bytes
        buf.writeln('\n--- Deserialize from Bytes ---');
        final parsed = FileHeader.fromBytes(bytes);
        buf.writeln('  Parsed: $parsed');
        buf.writeln('  Version match: ${parsed?.version == header.version}');
        buf.writeln('  Flags match: ${parsed?.flags == header.flags}');

        // Check magic bytes
        buf.writeln('\n--- Magic Byte Check ---');
        final hasMagic = FileHeader.hasRiftMagic(bytes);
        buf.writeln('  hasRiftMagic(bytes): $hasMagic');

        // Test with invalid bytes
        final invalidBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
        final hasInvalidMagic = FileHeader.hasRiftMagic(invalidBytes);
        final parsedInvalid = FileHeader.fromBytes(invalidBytes);
        buf.writeln('  hasRiftMagic([0,1,2,3]): $hasInvalidMagic');
        buf.writeln('  fromBytes([0,1,2,3]): $parsedInvalid');

        // Too small buffer
        final smallBytes = Uint8List.fromList([0x52, 0x49]);
        final parsedSmall = FileHeader.fromBytes(smallBytes);
        buf.writeln('  fromBytes(too small): $parsedSmall (null = invalid)');

        // Legacy header
        buf.writeln('\n--- Legacy File Header ---');
        final legacy = FileHeader.legacy();
        buf.writeln('  Legacy header: $legacy');
        buf.writeln('  isLegacy: ${legacy.isLegacy}');
        buf.writeln('  version: ${legacy.version}');

        // Custom flags
        buf.writeln('\n--- Custom Flags ---');
        final customHeader = FileHeader(
          version: 1,
          flags: FileHeader.flagVarintInts | 2, // varint + custom flag
        );
        buf.writeln('  Custom flags: ${customHeader.flags}');
        buf.writeln('  usesVarintInts: ${customHeader.usesVarintInts}');

        // Equality check
        buf.writeln('\n--- Equality ---');
        final header2 = FileHeader.fromBytes(header.toBytes());
        buf.writeln('  header == parsed: ${header == header2}');

        buf.writeln('\n--- File Format Summary ---');
        buf.writeln('  Magic bytes: "RIFT" (0x52494654)');
        buf.writeln('  Header size: ${FileHeader.headerSize} bytes');
        buf.writeln('  Current version: ${FileHeader.currentVersion}');
        buf.writeln('  Legacy files auto-detected on open');
        buf.writeln('  Header added on next compaction for legacy files');

        buf.writeln('\n✅ File versioning demo complete');

        return buf.toString();
      },
    );
  }
}

String _bytesToHex(List<int> bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
}

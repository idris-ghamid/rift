import 'dart:ui';

import 'package:rift/rift.dart';
import 'package:flutter/foundation.dart';

class ColorAdapter extends TypeAdapter<Color> {
  static const _defaultTypeId = 200;

  /// Constructor
  ColorAdapter({int? typeId}) : typeId = typeId ?? _defaultTypeId;

  @override
  final int typeId;

  late final _adapter = RiftColorAdapter(typeId: typeId);

  @override
  Color read(BinaryReader reader) {
    final firstByte = reader.peekBytes(1)[0];

    // `color.value` is 4 bytes long
    // ints are written as 8 bytes
    // Therefore the first byte of old color data is 0
    // The first byte of new color data is the field count which is not 0
    // Therefore if the first byte is 0, this is old color data
    if (firstByte == 0) {
      // Support for reading data created by the old ColorAdapter
      return Color(reader.readInt());
    } else {
      return _adapter.read(reader).toColor();
    }
  }

  @override
  void write(BinaryWriter writer, Color obj) =>
      _adapter.write(writer, RiftColor.fromColor(obj));
}

/// Rift wrapper for the fields in [Color]
@immutable
class RiftColor {
  /// alpha
  final double a;

  /// red
  final double r;

  /// green
  final double g;

  /// blue
  final double b;

  /// color space
  final String colorSpace;

  /// Constructor
  const RiftColor({
    required this.a,
    required this.r,
    required this.g,
    required this.b,
    required this.colorSpace,
  });

  /// Convert a [Color] to a [RiftColor]
  RiftColor.fromColor(Color color)
      : a = color.a,
        r = color.r,
        g = color.g,
        b = color.b,
        colorSpace = color.colorSpace.name;

  /// Convert a [RiftColor] to a [Color]
  Color toColor() => Color.from(
        alpha: a,
        red: r,
        green: g,
        blue: b,
        colorSpace: ColorSpace.values.byName(colorSpace),
      );
}

/// Adapter for the new Color fields
class RiftColorAdapter extends TypeAdapter<RiftColor> {
  /// Constructor
  const RiftColorAdapter({required this.typeId});

  @override
  final int typeId;

  @override
  RiftColor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RiftColor(
      a: (fields[0] as num).toDouble(),
      r: (fields[1] as num).toDouble(),
      g: (fields[2] as num).toDouble(),
      b: (fields[3] as num).toDouble(),
      colorSpace: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RiftColor obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.a)
      ..writeByte(1)
      ..write(obj.r)
      ..writeByte(2)
      ..write(obj.g)
      ..writeByte(3)
      ..write(obj.b)
      ..writeByte(4)
      ..write(obj.colorSpace);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiftColorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

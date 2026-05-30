import 'package:meta/meta.dart';

/// An error related to Rift.
@immutable
class RiftError extends Error {
  /// A description of the error.
  final String message;

  /// Create a new Rift error (internal)
  RiftError(this.message);

  @override
  String toString() {
    return 'RiftError: $message';
  }
}

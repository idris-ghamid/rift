import 'package:rift/src/middleware/middleware.dart';

/// Field validation rule.
///
/// Defines a validation rule for a single field in a box entry.
class ValidationRule {
  /// The field name to validate.
  final String field;

  /// Whether the field is required (must be present and non-null).
  final bool required;

  /// The expected type of the field value.
  ///
  /// If set, the middleware checks that the field value is an
  /// instance of this type.
  final Type? type;

  /// Custom validation function.
  ///
  /// Receives the field value and returns an error message if
  /// validation fails, or null if validation passes.
  final String? Function(dynamic value)? validator;

  /// Minimum length (for String values) or minimum value (for num values).
  final num? min;

  /// Maximum length (for String values) or maximum value (for num values).
  final num? max;

  const ValidationRule({
    required this.field,
    this.required = false,
    this.type,
    this.validator,
    this.min,
    this.max,
  });
}

/// Schema definition for a box.
///
/// Maps box names to their validation rules.
class ValidationSchema {
  /// The name of the box this schema applies to.
  final String boxName;

  /// Validation rules for fields in this box.
  final List<ValidationRule> rules;

  /// Whether to allow extra fields not defined in the schema.
  ///
  /// When false, any field not listed in [rules] will cause
  /// validation to fail.
  final bool allowExtraFields;

  const ValidationSchema({
    required this.boxName,
    required this.rules,
    this.allowExtraFields = true,
  });
}

/// Built-in schema validation middleware.
///
/// Validates data before it is written to a box. If validation fails,
/// the put operation is cancelled and an error message is logged.
///
/// The middleware supports:
/// - Required field checks
/// - Type checking
/// - Min/max constraints for numeric values or string lengths
/// - Custom validation functions
/// - Extra field detection
///
/// Usage:
/// ```dart
/// rift.use(ValidationMiddleware(schemas: [
///   ValidationSchema(
///     boxName: 'users',
///     rules: [
///       ValidationRule(field: 'name', required: true, type: String),
///       ValidationRule(field: 'age', type: int, min: 0, max: 150),
///       ValidationRule(
///         field: 'email',
///         required: true,
///         validator: (value) {
///           if (value is! String || !value.contains('@')) {
///             return 'Invalid email format';
///           }
///           return null;
///         },
///       ),
///     ],
///   ),
/// ]));
/// ```
class ValidationMiddleware extends RiftMiddleware {
  /// Schemas indexed by box name.
  final Map<String, ValidationSchema> _schemas = {};

  /// Callback for validation errors.
  ///
  /// If provided, called with the error message when validation fails.
  /// If not provided, errors are printed to console.
  final void Function(String boxName, dynamic key, String error)? onError;

  ValidationMiddleware({
    List<ValidationSchema> schemas = const [],
    this.onError,
  }) {
    for (final schema in schemas) {
      _schemas[schema.boxName] = schema;
    }
  }

  /// Adds a schema for a box.
  void addSchema(ValidationSchema schema) {
    _schemas[schema.boxName] = schema;
  }

  /// Removes the schema for a box.
  void removeSchema(String boxName) {
    _schemas.remove(boxName);
  }

  @override
  String get name => 'ValidationMiddleware';

  @override
  Future<bool> beforePut(String boxName, dynamic key, dynamic value) async {
    final schema = _schemas[boxName];
    if (schema == null) return true; // No schema = no validation

    final errors = _validate(boxName, value, schema);
    if (errors.isNotEmpty) {
      final errorMessage = errors.join('; ');
      if (onError != null) {
        onError!(boxName, key, errorMessage);
      } else {
        print(
          '[Rift:Validation] PUT rejected for box=$boxName key=$key: '
          '$errorMessage',
        );
      }
      return false;
    }

    return true;
  }

  @override
  Future<void> afterPut(String boxName, dynamic key, dynamic value) async {
    // No post-put validation needed
  }

  @override
  Future<bool> beforeDelete(String boxName, dynamic key) async {
    // No validation needed for deletes
    return true;
  }

  @override
  Future<void> afterDelete(String boxName, dynamic key) async {
    // No post-delete validation needed
  }

  @override
  Future<bool> beforeClear(String boxName) async {
    // No validation needed for clears
    return true;
  }

  @override
  Future<void> afterClear(String boxName) async {
    // No post-clear validation needed
  }

  /// Validates a value against a schema.
  ///
  /// Returns a list of error messages. Empty list means validation passed.
  List<String> _validate(
    String boxName,
    dynamic value,
    ValidationSchema schema,
  ) {
    final errors = <String>[];

    // Only validate Map values (structured data)
    Map<String, dynamic>? data;
    if (value is Map<String, dynamic>) {
      data = value;
    } else if (value is Map) {
      data = Map<String, dynamic>.from(value);
    } else {
      // Non-Map values don't get field-level validation
      return errors;
    }

    // Check for extra fields
    if (!schema.allowExtraFields) {
      final allowedFields = schema.rules.map((r) => r.field).toSet();
      for (final field in data.keys) {
        if (!allowedFields.contains(field)) {
          errors.add('Unexpected field "$field" in box "$boxName"');
        }
      }
    }

    // Validate each rule
    for (final rule in schema.rules) {
      final fieldValue = data[rule.field];

      // Required check
      if (rule.required && (fieldValue == null)) {
        errors.add('Field "${rule.field}" is required');
        continue;
      }

      // Skip further validation if field is not present
      if (fieldValue == null) continue;

      // Type check
      if (rule.type != null) {
        bool typeMatches = false;

        // Check exact type match
        if (fieldValue.runtimeType == rule.type) {
          typeMatches = true;
        }

        // Check subtype / assignable using string comparison
        // (Dart doesn't support runtime type checking with Type objects directly)
        if (!typeMatches) {
          final expectedTypeName = rule.type.toString();
          final actualTypeName = fieldValue.runtimeType.toString();

          // Exact name match or subtype pattern
          if (expectedTypeName == actualTypeName ||
              actualTypeName.startsWith(expectedTypeName)) {
            typeMatches = true;
          }
        }

        if (!typeMatches) {
          errors.add(
            'Field "${rule.field}" expected type ${rule.type}, '
            'got ${fieldValue.runtimeType}',
          );
        }
      }

      // Min constraint
      if (rule.min != null) {
        if (fieldValue is num) {
          if (fieldValue < rule.min!) {
            errors.add(
              'Field "${rule.field}" value $fieldValue is less than '
              'minimum ${rule.min}',
            );
          }
        } else if (fieldValue is String) {
          if (fieldValue.length < rule.min!) {
            errors.add(
              'Field "${rule.field}" length ${fieldValue.length} is less '
              'than minimum ${rule.min}',
            );
          }
        }
      }

      // Max constraint
      if (rule.max != null) {
        if (fieldValue is num) {
          if (fieldValue > rule.max!) {
            errors.add(
              'Field "${rule.field}" value $fieldValue exceeds '
              'maximum ${rule.max}',
            );
          }
        } else if (fieldValue is String) {
          if (fieldValue.length > rule.max!) {
            errors.add(
              'Field "${rule.field}" length ${fieldValue.length} exceeds '
              'maximum ${rule.max}',
            );
          }
        }
      }

      // Custom validator
      if (rule.validator != null) {
        final customError = rule.validator!(fieldValue);
        if (customError != null) {
          errors.add('Field "${rule.field}": $customError');
        }
      }
    }

    return errors;
  }
}

/// Schema validation for Rift box entries.
///
/// Provides JSON Schema-style validation for box entries before they
/// are stored. Define schemas per box and validate data against them.
///
/// Usage:
/// ```dart
/// final schema = ValidationSchema(fields: {
///   'name': [FieldRule.required(), FieldRule.type(String), FieldRule.min(1)],
///   'age': [FieldRule.type(int), FieldRule.min(0), FieldRule.max(150)],
///   'email': [FieldRule.pattern(r'^\S+@\S+\.\S+$')],
/// });
///
/// final validator = SchemaValidator(schema);
/// final result = validator.validate({'name': 'Idris', 'age': 25, 'email': 'a@b.c'});
/// if (!result.isValid) {
///   for (final error in result.errors) {
///     print('${error.field}: ${error.message}');
///   }
/// }
/// ```
library;

/// Types of field validation rules.
enum FieldRuleType {
  /// Validate the field type (String, int, double, bool, List, Map).
  type,

  /// Validate that a required field is present and non-null.
  required,

  /// Validate minimum value (for numbers) or length (for strings/lists).
  min,

  /// Validate maximum value (for numbers) or length (for strings/lists).
  max,

  /// Validate against a regex pattern.
  pattern,

  /// Validate that the value is one of the allowed values.
  enumValue,

  /// Custom validation function.
  custom,
}

/// A single validation rule for a field.
class FieldRule {
  /// The type of this rule.
  final FieldRuleType ruleType;

  /// The expected type (for type rules).
  final Type? expectedType;

  /// The minimum value/length (for min rules).
  final num? minValue;

  /// The maximum value/length (for max rules).
  final num? maxValue;

  /// The regex pattern (for pattern rules).
  final RegExp? patternValue;

  /// The allowed values (for enum rules).
  final List<dynamic>? enumValues;

  /// Custom validation function (for custom rules).
  final String? Function(dynamic value)? customValidator;

  /// Custom error message override.
  final String? message;

  const FieldRule._({
    required this.ruleType,
    this.expectedType,
    this.minValue,
    this.maxValue,
    this.patternValue,
    this.enumValues,
    this.customValidator,
    this.message,
  });

  /// Creates a type validation rule.
  ///
  /// Validates that the field value is an instance of [type].
  factory FieldRule.type(Type type, {String? message}) => FieldRule._(
    ruleType: FieldRuleType.type,
    expectedType: type,
    message: message,
  );

  /// Creates a required field rule.
  ///
  /// Validates that the field is present and non-null.
  factory FieldRule.required({String? message}) =>
      FieldRule._(ruleType: FieldRuleType.required, message: message);

  /// Creates a minimum value/length rule.
  ///
  /// For numeric values, validates `value >= min`.
  /// For strings and lists, validates `value.length >= min`.
  factory FieldRule.min(num min, {String? message}) =>
      FieldRule._(ruleType: FieldRuleType.min, minValue: min, message: message);

  /// Creates a maximum value/length rule.
  ///
  /// For numeric values, validates `value <= max`.
  /// For strings and lists, validates `value.length <= max`.
  factory FieldRule.max(num max, {String? message}) =>
      FieldRule._(ruleType: FieldRuleType.max, maxValue: max, message: message);

  /// Creates a pattern validation rule.
  ///
  /// Validates that a string value matches the given [pattern].
  factory FieldRule.pattern(String pattern, {String? message}) => FieldRule._(
    ruleType: FieldRuleType.pattern,
    patternValue: RegExp(pattern),
    message: message,
  );

  /// Creates an enum validation rule.
  ///
  /// Validates that the value is one of [values].
  factory FieldRule.enumValue(List<dynamic> values, {String? message}) =>
      FieldRule._(
        ruleType: FieldRuleType.enumValue,
        enumValues: values,
        message: message,
      );

  /// Creates a custom validation rule.
  ///
  /// The [validator] function receives the field value and returns
  /// an error message if validation fails, or null if it passes.
  factory FieldRule.custom(
    String? Function(dynamic value) validator, {
    String? message,
  }) => FieldRule._(
    ruleType: FieldRuleType.custom,
    customValidator: validator,
    message: message,
  );

  /// Validates a [value] against this rule.
  ///
  /// Returns null if validation passes, or an error message if it fails.
  String? validate(dynamic value) {
    switch (ruleType) {
      case FieldRuleType.required:
        if (value == null) {
          return message ?? 'Field is required';
        }
        return null;

      case FieldRuleType.type:
        if (value == null) return null; // Use required rule for null check
        if (expectedType != null && value.runtimeType != expectedType) {
          // Allow subtype checking for num (int/double)
          if (expectedType == num && value is num) return null;
          if (expectedType == double && value is int) return null;
          return message ??
              'Expected type $expectedType, got ${value.runtimeType}';
        }
        return null;

      case FieldRuleType.min:
        if (value == null) return null;
        if (value is num) {
          if (value < minValue!) {
            return message ?? 'Value must be at least $minValue';
          }
        } else if (value is String) {
          if (value.length < minValue!) {
            return message ??
                'String length must be at least $minValue characters';
          }
        } else if (value is List) {
          if (value.length < minValue!) {
            return message ?? 'List must have at least $minValue items';
          }
        }
        return null;

      case FieldRuleType.max:
        if (value == null) return null;
        if (value is num) {
          if (value > maxValue!) {
            return message ?? 'Value must be at most $maxValue';
          }
        } else if (value is String) {
          if (value.length > maxValue!) {
            return message ??
                'String length must be at most $maxValue characters';
          }
        } else if (value is List) {
          if (value.length > maxValue!) {
            return message ?? 'List must have at most $maxValue items';
          }
        }
        return null;

      case FieldRuleType.pattern:
        if (value == null) return null;
        if (value is! String) {
          return message ?? 'Pattern validation requires a String value';
        }
        if (!patternValue!.hasMatch(value)) {
          return message ?? 'Value does not match required pattern';
        }
        return null;

      case FieldRuleType.enumValue:
        if (value == null) return null;
        if (!enumValues!.contains(value)) {
          return message ?? 'Value must be one of: ${enumValues!.join(', ')}';
        }
        return null;

      case FieldRuleType.custom:
        if (value == null) return null;
        return customValidator?.call(value);
    }
  }
}

/// A validation error for a specific field.
class ValidationError {
  /// The field name that failed validation.
  final String field;

  /// The error message.
  final String message;

  /// The rule that failed.
  final FieldRule rule;

  /// Creates a [ValidationError].
  const ValidationError({
    required this.field,
    required this.message,
    required this.rule,
  });

  @override
  String toString() => 'ValidationError($field: $message)';
}

/// Result of validating data against a schema.
class ValidationResult {
  /// The field-level errors found during validation.
  final List<ValidationError> errors;

  /// Creates a [ValidationResult].
  const ValidationResult(this.errors);

  /// Whether the data is valid (no errors).
  bool get isValid => errors.isEmpty;

  /// Whether the data is invalid (has errors).
  bool get isInvalid => errors.isNotEmpty;

  /// Gets errors for a specific [field].
  List<ValidationError> errorsFor(String field) =>
      errors.where((e) => e.field == field).toList();

  /// Gets all error messages as a list.
  List<String> get messages =>
      errors.map((e) => '${e.field}: ${e.message}').toList();

  @override
  String toString() => isValid
      ? 'ValidationResult(valid)'
      : 'ValidationResult(${errors.length} errors)';
}

/// Defines a data validation schema for a box.
///
/// A schema maps field names to lists of [FieldRule]s that define
/// the validation requirements for each field.
class DataValidationSchema {
  /// Field name → list of validation rules.
  final Map<String, List<FieldRule>> fields;

  /// Whether to allow additional fields not defined in the schema.
  final bool allowAdditionalFields;

  /// Creates a [DataValidationSchema].
  const DataValidationSchema({
    required this.fields,
    this.allowAdditionalFields = true,
  });
}

/// Validates data against a [DataValidationSchema].
///
/// The validator checks each field in the data against the rules
/// defined in the schema and collects all validation errors.
class SchemaValidator {
  /// The schema to validate against.
  final DataValidationSchema schema;

  /// Creates a [SchemaValidator] with the given [schema].
  const SchemaValidator(this.schema);

  /// Validates [data] against the schema.
  ///
  /// Returns a [ValidationResult] containing any validation errors.
  /// All fields are validated even if some fail (no short-circuiting).
  ValidationResult validate(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    for (final entry in schema.fields.entries) {
      final fieldName = entry.key;
      final rules = entry.value;
      final value = data[fieldName];

      for (final rule in rules) {
        final error = rule.validate(value);
        if (error != null) {
          errors.add(
            ValidationError(field: fieldName, message: error, rule: rule),
          );
        }
      }
    }

    // Check for unexpected fields
    if (!schema.allowAdditionalFields) {
      for (final key in data.keys) {
        if (!schema.fields.containsKey(key)) {
          errors.add(
            ValidationError(
              field: key,
              message: 'Unexpected field not defined in schema',
              rule: const FieldRule._(ruleType: FieldRuleType.required),
            ),
          );
        }
      }
    }

    return ValidationResult(errors);
  }

  /// Validates and returns the data if valid, or throws with errors.
  ///
  /// Throws [ValidationException] if validation fails.
  Map<String, dynamic> validateOrThrow(Map<String, dynamic> data) {
    final result = validate(data);
    if (result.isInvalid) {
      throw ValidationException(result.errors);
    }
    return data;
  }
}

/// Exception thrown when validation fails.
class ValidationException implements Exception {
  /// The validation errors that caused this exception.
  final List<ValidationError> errors;

  /// Creates a [ValidationException].
  const ValidationException(this.errors);

  @override
  String toString() =>
      'ValidationException: ${errors.map((e) => '${e.field}: ${e.message}').join(', ')}';
}

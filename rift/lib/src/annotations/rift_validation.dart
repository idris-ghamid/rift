/// Validation annotations for Rift code generation.
///
/// Provides annotations to automatically generate validation logic
/// for Rift types using code generation.
library;

import 'package:meta/meta_meta.dart';

/// Annotate a field with validation rules.
///
/// This annotation is used by the code generator to automatically
/// generate validation logic for Rift types.
///
/// Usage:
/// ```dart
/// @RiftType()
/// class User {
///   @RiftField(0)
///   @RiftValidation([
///     RiftValidationRule.required(),
///     RiftValidationRule.min(2),
///     RiftValidationRule.max(50),
///   ])
///   String name;
///
///   @RiftField(1)
///   @RiftValidation([
///     RiftValidationRule.required(),
///     RiftValidationRule.min(0),
///     RiftValidationRule.max(150),
///   ])
///   int age;
///
///   @RiftField(2)
///   @RiftValidation([
///     RiftValidationRule.email(),
///   ])
///   String email;
/// }
/// ```
@Target({
  TargetKind.field,
  TargetKind.getter,
})
class RiftValidation {
  /// The validation rules for this field.
  final List<RiftValidationRule> rules;

  /// Custom error message.
  final String? message;

  const RiftValidation(this.rules, {this.message});
}

/// A validation rule for code generation.
///
/// These rules are used by the code generator to create
/// validation logic for Rift types.
class RiftValidationRule {
  /// The type of validation rule.
  final ValidationRuleType type;

  /// The value for the rule (e.g., min value, pattern, etc.).
  final dynamic value;

  /// Custom error message.
  final String? message;

  const RiftValidationRule({
    required this.type,
    this.value,
    this.message,
  });

  /// Creates a required field rule.
  factory RiftValidationRule.required({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.required,
        message: message,
      );

  /// Creates a type validation rule.
  factory RiftValidationRule.type(Type type, {String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.type,
        value: type,
        message: message,
      );

  /// Creates a minimum value/length rule.
  factory RiftValidationRule.min(num min, {String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.min,
        value: min,
        message: message,
      );

  /// Creates a maximum value/length rule.
  factory RiftValidationRule.max(num max, {String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.max,
        value: max,
        message: message,
      );

  /// Creates a pattern validation rule.
  factory RiftValidationRule.pattern(String pattern, {String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: pattern,
        message: message,
      );

  /// Creates an enum validation rule.
  factory RiftValidationRule.enumValue(List<dynamic> values, {String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.enumValue,
        value: values,
        message: message,
      );

  /// Creates an email validation rule.
  factory RiftValidationRule.email({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        message: message ?? 'Invalid email address',
      );

  /// Creates a URL validation rule.
  factory RiftValidationRule.url({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
        message: message ?? 'Invalid URL',
      );

  /// Creates a phone number validation rule.
  factory RiftValidationRule.phone({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: r'^[\d\+\-\(\) ]+$',
        message: message ?? 'Invalid phone number',
      );

  /// Creates a password strength validation rule.
  factory RiftValidationRule.passwordStrength({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.custom,
        value: 'passwordStrength',
        message: message ?? 'Password does not meet strength requirements',
      );

  /// Creates a username validation rule.
  factory RiftValidationRule.username({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: r'^[a-zA-Z0-9_]{3,20}$',
        message: message ?? 'Username must be 3-20 alphanumeric characters',
      );

  /// Creates a date validation rule (YYYY-MM-DD).
  factory RiftValidationRule.date({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: r'^\d{4}-\d{2}-\d{2}$',
        message: message ?? 'Invalid date format (YYYY-MM-DD)',
      );

  /// Creates a UUID validation rule.
  factory RiftValidationRule.uuid({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        message: message ?? 'Invalid UUID format',
      );

  /// Creates a hex color validation rule.
  factory RiftValidationRule.hexColor({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$',
        message: message ?? 'Invalid hex color format',
      );

  /// Creates an IP address validation rule.
  factory RiftValidationRule.ipAddress({String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.pattern,
        value: r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
        message: message ?? 'Invalid IP address',
      );

  /// Creates a custom validation rule.
  factory RiftValidationRule.custom(String customValidator, {String? message}) =>
      RiftValidationRule(
        type: ValidationRuleType.custom,
        value: customValidator,
        message: message,
      );
}

/// Types of validation rules for code generation.
enum ValidationRuleType {
  /// Validate the field type.
  type,

  /// Validate that a required field is present.
  required,

  /// Validate minimum value/length.
  min,

  /// Validate maximum value/length.
  max,

  /// Validate against a regex pattern.
  pattern,

  /// Validate that the value is one of the allowed values.
  enumValue,

  /// Custom validation.
  custom,
}

/// Annotate a Rift type with validation schema.
///
/// This annotation is used to define a validation schema for
/// an entire Rift type, which will be generated by the code generator.
///
/// Usage:
/// ```dart
/// @RiftType()
/// @RiftValidationSchema({
///   'name': [
///     RiftValidationRule.required(),
///     RiftValidationRule.min(2),
///     RiftValidationRule.max(50),
///   ],
///   'age': [
///     RiftValidationRule.required(),
///     RiftValidationRule.min(0),
///     RiftValidationRule.max(150),
///   ],
///   'email': [
///     RiftValidationRule.email(),
///   ],
/// })
/// class User {
///   @RiftField(0)
///   String name;
///
///   @RiftField(1)
///   int age;
///
///   @RiftField(2)
///   String email;
/// }
/// ```
@Target({
  TargetKind.classType,
})
class RiftValidationSchema {
  /// The validation schema mapping field names to rules.
  final Map<String, List<RiftValidationRule>> schema;

  /// Whether to allow additional fields not defined in the schema.
  final bool allowAdditionalFields;

  const RiftValidationSchema(
    this.schema, {
    this.allowAdditionalFields = true,
  });
}

/// Annotate a field with cross-field validation.
///
/// This annotation is used to define validation rules that depend
/// on multiple fields.
///
/// Usage:
/// ```dart
/// @RiftType()
/// class User {
///   @RiftField(0)
///   String password;
///
///   @RiftField(1)
///   @RiftCrossField(['password'], 'passwordConfirmation')
///   String passwordConfirmation;
/// }
/// ```
@Target({
  TargetKind.field,
  TargetKind.getter,
})
class RiftCrossField {
  /// The fields involved in this validation.
  final List<String> fields;

  /// The validation function name.
  final String validator;

  /// Custom error message.
  final String? message;

  const RiftCrossField(
    this.fields,
    this.validator, {
    this.message,
  });
}

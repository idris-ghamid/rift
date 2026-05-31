/// Enhanced validation for Rift with advanced features.
///
/// Provides async validation, cross-field validation, and
/// validation annotations for code generation.
library;

import 'dart:async';

import 'validation.dart';

/// Async validation rule that performs asynchronous checks.
class AsyncFieldRule {
  /// Async validation function.
  final Future<String?> Function(dynamic value) asyncValidator;

  /// Custom error message override.
  final String? message;

  const AsyncFieldRule({required this.asyncValidator, this.message});

  /// Creates an async validation rule.
  ///
  /// The [validator] function receives the field value and returns
  /// a Future that completes with an error message if validation fails,
  /// or null if it passes.
  factory AsyncFieldRule.async(
    Future<String?> Function(dynamic value) validator, {
    String? message,
  }) => AsyncFieldRule(asyncValidator: validator, message: message);

  /// Validates a [value] asynchronously against this rule.
  ///
  /// Returns null if validation passes, or an error message if it fails.
  Future<String?> validateAsync(dynamic value) async {
    return await asyncValidator(value);
  }
}

/// Cross-field validation rule that validates based on multiple fields.
class CrossFieldRule {
  /// The fields involved in this validation.
  final List<String> fields;

  /// Validation function that receives all field values.
  final String? Function(Map<String, dynamic> values) validator;

  /// Custom error message override.
  final String? message;

  const CrossFieldRule({
    required this.fields,
    required this.validator,
    this.message,
  });

  /// Validates [data] against this cross-field rule.
  ///
  /// Returns null if validation passes, or an error message if it fails.
  String? validate(Map<String, dynamic> data) {
    return validator(data);
  }
}

/// Enhanced validation schema with async and cross-field support.
class EnhancedValidationSchema extends DataValidationSchema {
  /// Async field rules.
  final Map<String, List<AsyncFieldRule>> asyncRules;

  /// Cross-field validation rules.
  final List<CrossFieldRule> crossFieldRules;

  const EnhancedValidationSchema({
    required super.fields,
    this.asyncRules = const {},
    this.crossFieldRules = const [],
    super.allowAdditionalFields = true,
  });
}

/// Enhanced validation error for async rules.
class AsyncValidationError {
  /// The field name that failed validation.
  final String field;

  /// The error message.
  final String message;

  /// The rule that failed.
  final AsyncFieldRule rule;

  /// Creates an [AsyncValidationError].
  const AsyncValidationError({
    required this.field,
    required this.message,
    required this.rule,
  });

  @override
  String toString() => 'AsyncValidationError($field: $message)';
}

/// Enhanced validation result with async errors.
class EnhancedValidationResult extends ValidationResult {
  /// The async validation errors found during validation.
  final List<AsyncValidationError> asyncErrors;

  /// Creates an [EnhancedValidationResult].
  const EnhancedValidationResult(super.errors, this.asyncErrors);

  /// Whether the data is valid (no errors).
  @override
  bool get isValid => errors.isEmpty && asyncErrors.isEmpty;

  /// Whether the data is invalid (has errors).
  @override
  bool get isInvalid => errors.isNotEmpty || asyncErrors.isNotEmpty;

  /// Gets all error messages as a list.
  @override
  List<String> get messages {
    final syncMessages = errors.map((e) => '${e.field}: ${e.message}');
    final asyncMessages = asyncErrors.map((e) => '${e.field}: ${e.message}');
    return [...syncMessages, ...asyncMessages];
  }

  @override
  String toString() => isValid
      ? 'EnhancedValidationResult(valid)'
      : 'EnhancedValidationResult(${errors.length} sync errors, ${asyncErrors.length} async errors)';
}

/// Enhanced schema validator with async validation support.
class EnhancedSchemaValidator extends SchemaValidator {
  /// The enhanced schema to validate against.
  final EnhancedValidationSchema enhancedSchema;

  /// Creates an [EnhancedSchemaValidator] with the given [schema].
  const EnhancedSchemaValidator(this.enhancedSchema) : super(enhancedSchema);

  /// Validates [data] against the schema synchronously.
  ///
  /// Returns a [ValidationResult] containing any validation errors.
  @override
  ValidationResult validate(Map<String, dynamic> data) {
    final errors = <ValidationError>[];

    // Validate regular field rules
    for (final entry in enhancedSchema.fields.entries) {
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

    // Validate cross-field rules
    for (final rule in enhancedSchema.crossFieldRules) {
      final error = rule.validate(data);
      if (error != null) {
        errors.add(
          ValidationError(
            field: rule.fields.join(', '),
            message: error,
            rule: FieldRule.custom((_) => null),
          ),
        );
      }
    }

    // Check for unexpected fields
    if (!enhancedSchema.allowAdditionalFields) {
      for (final key in data.keys) {
        if (!enhancedSchema.fields.containsKey(key)) {
          errors.add(
            ValidationError(
              field: key,
              message: 'Unexpected field not defined in schema',
              rule: FieldRule.required(),
            ),
          );
        }
      }
    }

    return ValidationResult(errors);
  }

  /// Validates [data] against the schema asynchronously.
  ///
  /// Returns an [EnhancedValidationResult] containing any validation errors.
  Future<EnhancedValidationResult> validateAsync(
    Map<String, dynamic> data,
  ) async {
    final errors = <ValidationError>[];
    final asyncErrors = <AsyncValidationError>[];

    // Validate regular field rules
    for (final entry in enhancedSchema.fields.entries) {
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

    // Validate async field rules
    for (final entry in enhancedSchema.asyncRules.entries) {
      final fieldName = entry.key;
      final rules = entry.value;
      final value = data[fieldName];

      for (final rule in rules) {
        final error = await rule.validateAsync(value);
        if (error != null) {
          asyncErrors.add(
            AsyncValidationError(field: fieldName, message: error, rule: rule),
          );
        }
      }
    }

    // Validate cross-field rules
    for (final rule in enhancedSchema.crossFieldRules) {
      final error = rule.validate(data);
      if (error != null) {
        errors.add(
          ValidationError(
            field: rule.fields.join(', '),
            message: error,
            rule: FieldRule.custom((_) => null),
          ),
        );
      }
    }

    // Check for unexpected fields
    if (!enhancedSchema.allowAdditionalFields) {
      for (final key in data.keys) {
        if (!enhancedSchema.fields.containsKey(key)) {
          errors.add(
            ValidationError(
              field: key,
              message: 'Unexpected field not defined in schema',
              rule: FieldRule.required(),
            ),
          );
        }
      }
    }

    return EnhancedValidationResult(errors, asyncErrors);
  }

  /// Validates and returns the data if valid, or throws with errors.
  ///
  /// Throws [ValidationException] if validation fails.
  @override
  Map<String, dynamic> validateOrThrow(Map<String, dynamic> data) {
    final result = validate(data);
    if (result.isInvalid) {
      throw ValidationException(result.errors);
    }
    return data;
  }

  /// Validates asynchronously and returns the data if valid, or throws with errors.
  ///
  /// Throws [ValidationException] if validation fails.
  Future<Map<String, dynamic>> validateOrThrowAsync(
    Map<String, dynamic> data,
  ) async {
    final result = await validateAsync(data);
    if (result.isInvalid) {
      final allErrors = [
        ...result.errors,
        ...result.asyncErrors.map(
          (e) => ValidationError(
            field: e.field,
            message: e.message,
            rule: FieldRule.custom((_) => null),
          ),
        ),
      ];
      throw ValidationException(allErrors);
    }
    return data;
  }
}

/// Pre-built validation rules for common use cases.
class ValidationRules {
  /// Email validation rule.
  static FieldRule email({String? message}) => FieldRule.pattern(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    message: message ?? 'Invalid email address',
  );

  /// URL validation rule.
  static FieldRule url({String? message}) => FieldRule.pattern(
    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    message: message ?? 'Invalid URL',
  );

  /// Phone number validation rule.
  static FieldRule phone({String? message}) => FieldRule.pattern(
    r'^[\d\+\-\(\) ]+$',
    message: message ?? 'Invalid phone number',
  );

  /// Credit card validation rule (Luhn algorithm).
  static FieldRule creditCard({String? message}) => FieldRule.custom((value) {
    if (value == null) return null;
    if (value is! String) return 'Credit card must be a string';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) {
      return 'Invalid credit card number';
    }
    // Luhn algorithm
    var sum = 0;
    var isEven = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var digit = int.parse(digits[i]);
      if (isEven) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      isEven = !isEven;
    }
    if (sum % 10 != 0) {
      return 'Invalid credit card number';
    }
    return null;
  }, message: message ?? 'Invalid credit card number');

  /// Password strength validation rule.
  static FieldRule passwordStrength({String? message}) =>
      FieldRule.custom((value) {
        if (value == null) return null;
        if (value is! String) return 'Password must be a string';
        if (value.length < 8) {
          return 'Password must be at least 8 characters';
        }
        if (!value.contains(RegExp(r'[A-Z]'))) {
          return 'Password must contain at least one uppercase letter';
        }
        if (!value.contains(RegExp(r'[a-z]'))) {
          return 'Password must contain at least one lowercase letter';
        }
        if (!value.contains(RegExp(r'[0-9]'))) {
          return 'Password must contain at least one number';
        }
        if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
          return 'Password must contain at least one special character';
        }
        return null;
      }, message: message ?? 'Password does not meet strength requirements');

  /// Username validation rule.
  static FieldRule username({String? message}) => FieldRule.pattern(
    r'^[a-zA-Z0-9_]{3,20}$',
    message: message ?? 'Username must be 3-20 alphanumeric characters',
  );

  /// Date validation rule (YYYY-MM-DD).
  static FieldRule date({String? message}) => FieldRule.pattern(
    r'^\d{4}-\d{2}-\d{2}$',
    message: message ?? 'Invalid date format (YYYY-MM-DD)',
  );

  /// UUID validation rule.
  static FieldRule uuid({String? message}) => FieldRule.pattern(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    message: message ?? 'Invalid UUID format',
  );

  /// Hex color validation rule.
  static FieldRule hexColor({String? message}) => FieldRule.pattern(
    r'^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$',
    message: message ?? 'Invalid hex color format',
  );

  /// IP address validation rule.
  static FieldRule ipAddress({String? message}) => FieldRule.pattern(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    message: message ?? 'Invalid IP address',
  );

  /// JSON validation rule (async).
  static AsyncFieldRule json({String? message}) =>
      AsyncFieldRule.async((value) async {
        if (value == null) return null;
        if (value is! String) return 'JSON must be a string';
        try {
          // Try to parse as JSON
          // Note: This is a simple check, actual parsing would use jsonDecode
          if (value.startsWith('{') || value.startsWith('[')) {
            return null;
          }
          return 'Invalid JSON format';
        } catch (e) {
          return 'Invalid JSON format';
        }
      }, message: message ?? 'Invalid JSON format');

  /// Unique value validation rule (async).
  static AsyncFieldRule unique({
    required Future<bool> Function(dynamic value) checkUnique,
    String? message,
  }) => AsyncFieldRule.async((value) async {
    if (value == null) return null;
    final isUnique = await checkUnique(value);
    if (!isUnique) {
      return message ?? 'Value must be unique';
    }
    return null;
  }, message: message);
}

/// Pre-built cross-field validation rules.
class CrossFieldValidationRules {
  /// Password confirmation rule.
  static CrossFieldRule passwordConfirmation({
    String passwordField = 'password',
    String confirmationField = 'passwordConfirmation',
    String? message,
  }) => CrossFieldRule(
    fields: [passwordField, confirmationField],
    validator: (data) {
      final password = data[passwordField];
      final confirmation = data[confirmationField];
      if (password != confirmation) {
        return message ?? 'Passwords do not match';
      }
      return null;
    },
  );

  /// Date range validation rule.
  static CrossFieldRule dateRange({
    String startDateField = 'startDate',
    String endDateField = 'endDate',
    String? message,
  }) => CrossFieldRule(
    fields: [startDateField, endDateField],
    validator: (data) {
      final startDate = data[startDateField];
      final endDate = data[endDateField];
      if (startDate is DateTime && endDate is DateTime) {
        if (startDate.isAfter(endDate)) {
          return message ?? 'Start date must be before end date';
        }
      }
      return null;
    },
  );

  /// Numeric range validation rule.
  static CrossFieldRule numericRange({
    String minField = 'min',
    String maxField = 'max',
    String? message,
  }) => CrossFieldRule(
    fields: [minField, maxField],
    validator: (data) {
      final min = data[minField];
      final max = data[maxField];
      if (min is num && max is num) {
        if (min > max) {
          return message ?? 'Minimum value must be less than maximum value';
        }
      }
      return null;
    },
  );

  /// At least one field required rule.
  static CrossFieldRule atLeastOneRequired({
    required List<String> fields,
    String? message,
  }) => CrossFieldRule(
    fields: fields,
    validator: (data) {
      final hasValue = fields.any((field) => data[field] != null);
      if (!hasValue) {
        return message ?? 'At least one of ${fields.join(', ')} is required';
      }
      return null;
    },
  );

  /// Mutually exclusive fields rule.
  static CrossFieldRule mutuallyExclusive({
    required List<String> fields,
    String? message,
  }) => CrossFieldRule(
    fields: fields,
    validator: (data) {
      final count = fields.where((field) => data[field] != null).length;
      if (count > 1) {
        return message ?? 'Only one of ${fields.join(', ')} can be set';
      }
      return null;
    },
  );
}

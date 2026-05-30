/// Data sanitization for preventing injection and malformed data.
///
/// Provides sanitization rules to clean input data before storage,
/// preventing XSS, injection, and other data quality issues.
///
/// Usage:
/// ```dart
/// final sanitizer = DataSanitizer();
/// sanitizer.addRule(SanitizationRule.trim);
/// sanitizer.addRule(SanitizationRule.stripHtml);
/// sanitizer.addRule(SanitizationRule.preventXss);
///
/// final result = sanitizer.sanitizeMap({
///   'name': '  <script>alert("xss")</script>Idris  ',
///   'email': '  idris@example.com  ',
/// });
/// print(result.data); // {name: Idris, email: idris@example.com}
/// ```
library;

/// Types of sanitization rules.
enum SanitizationRuleType {
  /// Trim leading and trailing whitespace.
  trim,

  /// Strip HTML tags from strings.
  stripHtml,

  /// Prevent XSS by escaping dangerous HTML characters.
  preventXss,

  /// Normalize whitespace (collapse multiple spaces).
  normalizeWhitespace,

  /// Convert to lowercase.
  toLowerCase,

  /// Convert to uppercase.
  toUpperCase,

  /// Remove null values from maps.
  removeNulls,

  /// Enforce maximum string length.
  maxLength,

  /// Only allow alphanumeric characters.
  alphanumericOnly,

  /// Custom sanitization function.
  custom,
}

/// A single sanitization rule.
class SanitizationRule {
  /// The type of this rule.
  final SanitizationRuleType type;

  /// Maximum length (for maxLength rule).
  final int? maxLengthValue;

  /// Custom sanitization function (for custom rule).
  final dynamic Function(dynamic value)? customSanitizer;

  /// Whether this rule applies to a specific field name.
  /// If null, applies to all string fields.
  final String? fieldName;

  /// Creates a [SanitizationRule].
  const SanitizationRule._({
    required this.type,
    this.maxLengthValue,
    this.customSanitizer,
    this.fieldName,
  });

  /// Trim leading and trailing whitespace.
  static const SanitizationRule trim = SanitizationRule._(
    type: SanitizationRuleType.trim,
  );

  /// Strip HTML tags from strings.
  static const SanitizationRule stripHtml = SanitizationRule._(
    type: SanitizationRuleType.stripHtml,
  );

  /// Prevent XSS by escaping dangerous characters.
  static const SanitizationRule preventXss = SanitizationRule._(
    type: SanitizationRuleType.preventXss,
  );

  /// Normalize whitespace (collapse multiple spaces into one).
  static const SanitizationRule normalizeWhitespace = SanitizationRule._(
    type: SanitizationRuleType.normalizeWhitespace,
  );

  /// Convert to lowercase.
  static const SanitizationRule toLowerCase = SanitizationRule._(
    type: SanitizationRuleType.toLowerCase,
  );

  /// Convert to uppercase.
  static const SanitizationRule toUpperCase = SanitizationRule._(
    type: SanitizationRuleType.toUpperCase,
  );

  /// Remove null values from maps.
  static const SanitizationRule removeNulls = SanitizationRule._(
    type: SanitizationRuleType.removeNulls,
  );

  /// Enforce a maximum string length.
  static SanitizationRule maxLength(int length) => SanitizationRule._(
    type: SanitizationRuleType.maxLength,
    maxLengthValue: length,
  );

  /// Only allow alphanumeric characters.
  static const SanitizationRule alphanumericOnly = SanitizationRule._(
    type: SanitizationRuleType.alphanumericOnly,
  );

  /// Custom sanitization rule.
  static SanitizationRule custom(dynamic Function(dynamic value) sanitizer) =>
      SanitizationRule._(
        type: SanitizationRuleType.custom,
        customSanitizer: sanitizer,
      );

  /// Rule that applies only to a specific field.
  static SanitizationRule forField(String fieldName, SanitizationRule rule) =>
      SanitizationRule._(
        type: rule.type,
        maxLengthValue: rule.maxLengthValue,
        customSanitizer: rule.customSanitizer,
        fieldName: fieldName,
      );

  /// Applies this rule to a value.
  dynamic apply(dynamic value) {
    if (value == null) return value;

    switch (type) {
      case SanitizationRuleType.trim:
        if (value is String) return value.trim();
        return value;

      case SanitizationRuleType.stripHtml:
        if (value is String) {
          return value.replaceAll(RegExp(r'<[^>]*>'), '');
        }
        return value;

      case SanitizationRuleType.preventXss:
        if (value is String) {
          return value
              .replaceAll('&', '&amp;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;')
              .replaceAll('"', '&quot;')
              .replaceAll("'", '&#x27;')
              .replaceAll('/', '&#x2F;');
        }
        return value;

      case SanitizationRuleType.normalizeWhitespace:
        if (value is String) {
          return value.replaceAll(RegExp(r'\s+'), ' ').trim();
        }
        return value;

      case SanitizationRuleType.toLowerCase:
        if (value is String) return value.toLowerCase();
        return value;

      case SanitizationRuleType.toUpperCase:
        if (value is String) return value.toUpperCase();
        return value;

      case SanitizationRuleType.removeNulls:
        return value;

      case SanitizationRuleType.maxLength:
        if (value is String && maxLengthValue != null) {
          return value.length > maxLengthValue!
              ? value.substring(0, maxLengthValue!)
              : value;
        }
        return value;

      case SanitizationRuleType.alphanumericOnly:
        if (value is String) {
          return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        }
        return value;

      case SanitizationRuleType.custom:
        return customSanitizer?.call(value) ?? value;
    }
  }
}

/// Result of sanitizing data.
class SanitizationResult {
  /// The sanitized data.
  final Map<String, dynamic> data;

  /// List of applied rules per field.
  final Map<String, List<SanitizationRuleType>> appliedRules;

  /// Whether any data was modified during sanitization.
  final bool wasModified;

  /// Creates a [SanitizationResult].
  const SanitizationResult({
    required this.data,
    required this.appliedRules,
    required this.wasModified,
  });

  @override
  String toString() =>
      'SanitizationResult(modified: $wasModified, rules: $appliedRules)';
}

/// Main class for sanitizing input data.
///
/// [DataSanitizer] applies a chain of sanitization rules to
/// clean data before storage. It supports both per-field and
/// global rules, and integrates with the Rift middleware system.
class DataSanitizer {
  /// The ordered list of sanitization rules.
  final List<SanitizationRule> _rules = [];

  /// Creates a [DataSanitizer].
  DataSanitizer();

  /// Adds a sanitization rule.
  void addRule(SanitizationRule rule) {
    _rules.add(rule);
  }

  /// Removes a sanitization rule.
  void removeRule(SanitizationRule rule) {
    _rules.remove(rule);
  }

  /// Clears all rules.
  void clearRules() {
    _rules.clear();
  }

  /// The number of registered rules.
  int get ruleCount => _rules.length;

  /// Sanitizes a single value.
  ///
  /// Applies all applicable rules to the value.
  dynamic sanitizeValue(dynamic value) {
    var result = value;
    for (final rule in _rules) {
      if (rule.fieldName != null) continue; // Skip field-specific rules
      result = rule.apply(result);
    }
    return result;
  }

  /// Sanitizes a map of data.
  ///
  /// Applies all applicable rules to each field value.
  /// Field-specific rules are only applied to their target field.
  SanitizationResult sanitizeMap(Map<String, dynamic> data) {
    var wasModified = false;
    final appliedRules = <String, List<SanitizationRuleType>>{};
    final result = <String, dynamic>{};

    // Check if removeNulls rule exists
    final hasRemoveNulls = _rules.any(
      (r) => r.type == SanitizationRuleType.removeNulls,
    );

    for (final entry in data.entries) {
      var value = entry.value;

      // Skip null values if removeNulls rule is active
      if (value == null && hasRemoveNulls) {
        wasModified = true;
        appliedRules[entry.key] = [SanitizationRuleType.removeNulls];
        continue;
      }

      final fieldRules = <SanitizationRuleType>[];

      // Apply global rules first
      for (final rule in _rules) {
        if (rule.fieldName != null) continue;
        final before = value;
        value = rule.apply(value);
        if (value != before) {
          fieldRules.add(rule.type);
          wasModified = true;
        }
      }

      // Apply field-specific rules
      for (final rule in _rules) {
        if (rule.fieldName != entry.key) continue;
        final before = value;
        value = rule.apply(value);
        if (value != before) {
          fieldRules.add(rule.type);
          wasModified = true;
        }
      }

      if (fieldRules.isNotEmpty) {
        appliedRules[entry.key] = fieldRules;
      }

      result[entry.key] = value;
    }

    return SanitizationResult(
      data: result,
      appliedRules: appliedRules,
      wasModified: wasModified,
    );
  }
}

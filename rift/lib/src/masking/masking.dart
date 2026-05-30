/// Data masking for sensitive information display.
///
/// The [DataMasker] provides strategies to mask sensitive data
/// such as credit card numbers, emails, phone numbers, and SSNs
/// for safe display in UIs or logs.
///
/// Usage:
/// ```dart
/// final masker = DataMasker();
/// print(masker.creditCard('4111111111111234')); // ****1234
/// print(masker.email('idris@gmail.com'));       // i***@gmail.com
/// print(masker.phone('+1-555-123-4567'));       // +1-555-***-4567
/// ```
library;

/// Strategies for masking data.
enum MaskingStrategy {
  /// Replace all characters with mask character (e.g., "****").
  full,

  /// Show some characters, mask the rest (e.g., "****1234").
  partial,

  /// Replace with a hash representation.
  hash,

  /// Replace with a redaction marker (e.g., "[REDACTED]").
  redact,
}

/// A function type for custom masking logic.
typedef CustomMaskingFunction = String Function(String input);

/// A rule defining how to mask a specific type of data.
class MaskingRule {
  /// The masking strategy to apply.
  final MaskingStrategy strategy;

  /// The character to use for masking (default: '*').
  final String maskChar;

  /// Number of characters to reveal at the start (for partial masking).
  final int revealStart;

  /// Number of characters to reveal at the end (for partial masking).
  final int revealEnd;

  /// Optional custom masking function, overrides strategy if provided.
  final CustomMaskingFunction? customMask;

  /// Creates a [MaskingRule].
  const MaskingRule({
    required this.strategy,
    this.maskChar = '*',
    this.revealStart = 0,
    this.revealEnd = 0,
    this.customMask,
  });

  /// Applies this rule to the given [input] string.
  String apply(String input) {
    if (customMask != null) return customMask!(input);

    switch (strategy) {
      case MaskingStrategy.full:
        return maskChar * input.length;
      case MaskingStrategy.partial:
        final start = input.substring(0, revealStart.clamp(0, input.length));
        final end = revealEnd > 0
            ? input.substring(
                (input.length - revealEnd).clamp(revealStart, input.length),
              )
            : '';
        final maskLength = input.length - revealStart - revealEnd;
        return '$start${maskChar * maskLength.clamp(0, input.length)}$end';
      case MaskingStrategy.hash:
        return _hashMask(input);
      case MaskingStrategy.redact:
        return '[REDACTED]';
    }
  }

  String _hashMask(String input) {
    var hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return 'hash_${hash.toRadixString(16).padLeft(8, '0')}';
  }
}

/// Main class for masking sensitive data.
///
/// Provides built-in maskers for common data types and supports
/// custom masking rules.
class DataMasker {
  /// Registered masking rules by name.
  final Map<String, MaskingRule> _rules = {};

  /// Custom maskers registered by name.
  final Map<String, CustomMaskingFunction> _customMaskers = {};

  /// Creates a [DataMasker] with optional custom rules.
  DataMasker({Map<String, MaskingRule>? customRules}) {
    if (customRules != null) {
      _rules.addAll(customRules);
    }
  }

  /// Masks a credit card number, showing only the last 4 digits.
  ///
  /// Example: `'4111111111111234'` → `'****1234'`
  String creditCard(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return maskChar * digits.length;
    return '${maskChar * (digits.length - 4)}${digits.substring(digits.length - 4)}';
  }

  /// Masks an email address, showing first character and domain.
  ///
  /// Example: `'idris@gmail.com'` → `'i***@gmail.com'`
  String email(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex < 1) return email;
    final localPart = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    final maskedLocal = '${localPart[0]}${maskChar * (localPart.length - 1)}';
    return '$maskedLocal$domain';
  }

  /// Masks a phone number, showing area code and last 4 digits.
  ///
  /// Example: `'+1-555-123-4567'` → `'+1-555-***-4567'`
  String phone(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return maskChar * phoneNumber.length;
    final lastFour = digits.substring(digits.length - 4);
    final areaCode = digits.substring(0, 3);
    return '($areaCode) ${maskChar * 3}-$lastFour';
  }

  /// Masks a Social Security Number, showing only the last 4 digits.
  ///
  /// Example: `'123-45-6789'` → `'***-**-6789'`
  String ssn(String ssn) {
    final digits = ssn.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return maskChar * ssn.length;
    return '${maskChar * 3}-${maskChar * 2}-${digits.substring(digits.length - 4)}';
  }

  /// Masks a personal name, showing only the first letter.
  ///
  /// Example: `'Idris Ghamid'` → `'I***** G*****'`
  String name(String fullName) {
    return fullName
        .split(' ')
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0]}${maskChar * (part.length - 1)}';
        })
        .join(' ');
  }

  /// The mask character used by built-in maskers.
  String get maskChar => '*';

  /// Registers a custom masking rule by [name].
  void registerRule(String name, MaskingRule rule) {
    _rules[name] = rule;
  }

  /// Registers a custom masking function by [name].
  void registerCustomMasker(String name, CustomMaskingFunction masker) {
    _customMaskers[name] = masker;
  }

  /// Applies a named masking rule to [input].
  ///
  /// Throws [ArgumentError] if no rule with [name] is found.
  String applyRule(String name, String input) {
    final customMasker = _customMaskers[name];
    if (customMasker != null) return customMasker(input);

    final rule = _rules[name];
    if (rule != null) return rule.apply(input);

    throw ArgumentError('No masking rule found for name: $name');
  }

  /// Masks all sensitive fields in a map using field name heuristics.
  ///
  /// Fields with names containing 'card', 'email', 'phone', 'ssn', or
  /// 'password' are automatically masked using the appropriate strategy.
  Map<String, dynamic> maskMap(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final keyLower = entry.key.toLowerCase();
      if (entry.value is! String) {
        result[entry.key] = entry.value;
        continue;
      }
      final value = entry.value as String;
      if (keyLower.contains('card') || keyLower.contains('credit')) {
        result[entry.key] = creditCard(value);
      } else if (keyLower.contains('email') || keyLower.contains('mail')) {
        result[entry.key] = email(value);
      } else if (keyLower.contains('phone') || keyLower.contains('tel')) {
        result[entry.key] = phone(value);
      } else if (keyLower.contains('ssn') || keyLower.contains('social')) {
        result[entry.key] = ssn(value);
      } else if (keyLower.contains('password') ||
          keyLower.contains('secret') ||
          keyLower.contains('token')) {
        result[entry.key] = maskChar * value.length;
      } else {
        result[entry.key] = value;
      }
    }
    return result;
  }

  /// Checks if a named rule exists.
  bool hasRule(String name) =>
      _rules.containsKey(name) || _customMaskers.containsKey(name);

  /// Removes a named rule.
  void removeRule(String name) {
    _rules.remove(name);
    _customMaskers.remove(name);
  }

  /// Lists all registered rule names.
  Iterable<String> get ruleNames => {..._rules.keys, ..._customMaskers.keys};
}

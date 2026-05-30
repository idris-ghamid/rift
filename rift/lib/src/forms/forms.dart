/// Reactive forms backed by Rift boxes.
///
/// Provides reactive form fields that auto-persist to Rift boxes.
/// Supports validation, dirty/clean tracking, and debounced auto-save.
///
/// Usage:
/// ```dart
/// final form = RiftForm(
///   box: userBox,
///   autoSave: true,
///   debounceDuration: Duration(milliseconds: 500),
/// );
///
/// final nameField = form.field<String>('name', validators: [
///   FieldValidator.required(),
///   FieldValidator.minLength(2),
/// ]);
///
/// nameField.value = 'Idris';
/// print(nameField.isDirty); // true
/// print(nameField.isValid);  // true
///
/// // Auto-save happens after debounce
/// await form.save();
/// ```
library;

import 'dart:async';

import 'package:rift/rift.dart';

/// Validation result for a form field.
class FieldValidationResult {
  /// Whether the field value is valid.
  final bool isValid;

  /// The list of error messages (empty if valid).
  final List<String> errors;

  /// Creates a [FieldValidationResult].
  const FieldValidationResult({required this.isValid, this.errors = const []});

  /// A valid result with no errors.
  static const FieldValidationResult valid = FieldValidationResult(
    isValid: true,
  );

  /// An invalid result with the given [errors].
  factory FieldValidationResult.invalid(List<String> errors) =>
      FieldValidationResult(isValid: false, errors: errors);

  @override
  String toString() => isValid
      ? 'FieldValidationResult(valid)'
      : 'FieldValidationResult($errors)';
}

/// A validator for a form field.
class FieldValidator<T> {
  /// The validation function.
  final FieldValidationResult Function(T? value) validate;

  /// Optional name for debugging.
  final String? name;

  /// Creates a [FieldValidator] with a custom [validate] function.
  const FieldValidator(this.validate, {this.name});

  /// Required field validator (value must not be null or empty).
  static FieldValidator<String> required({
    String message = 'This field is required',
  }) => FieldValidator<String>(
    (value) => (value == null || value.trim().isEmpty)
        ? FieldValidationResult.invalid([message])
        : FieldValidationResult.valid,
    name: 'required',
  );

  /// Minimum length validator for strings.
  static FieldValidator<String> minLength(int min, {String? message}) =>
      FieldValidator<String>((value) {
        if (value == null) return FieldValidationResult.valid;
        if (value.length < min) {
          return FieldValidationResult.invalid([
            message ?? 'Must be at least $min characters',
          ]);
        }
        return FieldValidationResult.valid;
      }, name: 'minLength');

  /// Maximum length validator for strings.
  static FieldValidator<String> maxLength(int max, {String? message}) =>
      FieldValidator<String>((value) {
        if (value == null) return FieldValidationResult.valid;
        if (value.length > max) {
          return FieldValidationResult.invalid([
            message ?? 'Must be at most $max characters',
          ]);
        }
        return FieldValidationResult.valid;
      }, name: 'maxLength');

  /// Pattern validator for strings.
  static FieldValidator<String> pattern(
    RegExp regex, {
    String message = 'Invalid format',
  }) => FieldValidator<String>((value) {
    if (value == null) return FieldValidationResult.valid;
    if (!regex.hasMatch(value)) {
      return FieldValidationResult.invalid([message]);
    }
    return FieldValidationResult.valid;
  }, name: 'pattern');

  /// Numeric range validator.
  static FieldValidator<num> range(num min, num max, {String? message}) =>
      FieldValidator<num>((value) {
        if (value == null) return FieldValidationResult.valid;
        if (value < min || value > max) {
          return FieldValidationResult.invalid([
            message ?? 'Must be between $min and $max',
          ]);
        }
        return FieldValidationResult.valid;
      }, name: 'range');

  /// Email format validator.
  static FieldValidator<String> email({
    String message = 'Invalid email format',
  }) => FieldValidator<String>((value) {
    if (value == null || value.isEmpty) return FieldValidationResult.valid;
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(value)) {
      return FieldValidationResult.invalid([message]);
    }
    return FieldValidationResult.valid;
  }, name: 'email');
}

/// A reactive form field bound to a box key.
///
/// [RiftFormField] tracks value changes, dirty state, and
/// validation. When the value changes, it can auto-persist
/// to the backing box.
class RiftFormField<T> {
  /// The key in the backing box.
  final String key;

  /// The list of validators for this field.
  final List<FieldValidator<T>> validators;

  /// The current value.
  T? _value;

  /// The initial value (for dirty tracking).
  T? _initialValue;

  /// Whether the field has been touched (interacted with).
  bool _touched = false;

  /// Stream controller for value changes.
  final StreamController<T?> _changeController = StreamController.broadcast();

  /// The last validation result.
  FieldValidationResult _validationResult = FieldValidationResult.valid;

  /// Creates a [RiftFormField].
  RiftFormField({
    required this.key,
    T? initialValue,
    this.validators = const [],
  }) : _value = initialValue,
       _initialValue = initialValue;

  /// The current value of the field.
  T? get value => _value;

  /// Sets the current value and marks the field as dirty.
  set value(T? newValue) {
    if (newValue == _value) return;
    _value = newValue;
    _touched = true;
    if (!_changeController.isClosed) {
      _changeController.add(newValue);
    }
    validate();
  }

  /// The initial value of the field.
  T? get initialValue => _initialValue;

  /// Whether the field value has changed from its initial value.
  bool get isDirty => _value != _initialValue;

  /// Whether the field value matches its initial value.
  bool get isClean => !isDirty;

  /// Whether the field has been interacted with.
  bool get isTouched => _touched;

  /// Marks the field as touched.
  void touch() => _touched = true;

  /// Resets the field to its initial value.
  void reset() {
    _value = _initialValue;
    _touched = false;
    _validationResult = FieldValidationResult.valid;
  }

  /// Marks the current value as the initial value (pristine).
  void markAsPristine() {
    _initialValue = _value;
    _touched = false;
  }

  /// Validates the field using its validators.
  FieldValidationResult validate() {
    final allErrors = <String>[];
    for (final validator in validators) {
      final result = validator.validate(_value);
      if (!result.isValid) {
        allErrors.addAll(result.errors);
      }
    }
    _validationResult = allErrors.isEmpty
        ? FieldValidationResult.valid
        : FieldValidationResult.invalid(allErrors);
    return _validationResult;
  }

  /// Whether the field value is currently valid.
  bool get isValid => _validationResult.isValid;

  /// Whether the field value is currently invalid.
  bool get isInvalid => !isValid;

  /// The current validation errors.
  List<String> get errors => _validationResult.errors;

  /// A stream of value changes.
  Stream<T?> get onChange => _changeController.stream;

  /// Disposes the form field.
  void dispose() {
    _changeController.close();
  }
}

/// Form state representing the overall state of a [RiftForm].
enum FormState {
  /// The form has not been modified.
  pristine,

  /// The form has been modified but not saved.
  dirty,

  /// The form is currently being saved.
  saving,

  /// The form has been saved successfully.
  saved,

  /// The form has validation errors.
  invalid,
}

/// A reactive form group with validation and auto-save.
///
/// [RiftForm] manages a collection of [RiftFormField] instances
/// and provides form-level validation, dirty tracking, and
/// auto-persist to a Rift box.
class RiftForm {
  /// The backing Rift box.
  final Box? box;

  /// Whether to auto-save when field values change.
  final bool autoSave;

  /// Debounce duration for auto-save.
  final Duration debounceDuration;

  /// The form fields.
  final Map<String, RiftFormField> _fields = {};

  /// The current form state.
  FormState _state = FormState.pristine;

  /// Debounce timer for auto-save.
  Timer? _debounceTimer;

  /// Stream controller for form state changes.
  final StreamController<FormState> _stateController =
      StreamController.broadcast();

  /// Creates a [RiftForm].
  RiftForm({
    this.box,
    this.autoSave = false,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  /// The current form state.
  FormState get state => _state;

  /// A stream of form state changes.
  Stream<FormState> get onStateChanged => _stateController.stream;

  /// Creates or gets a form field for [key].
  ///
  /// If the field doesn't exist, it's created with the given
  /// [validators] and optional [initialValue]. If the box
  /// contains a value for [key], it's used as the initial value.
  RiftFormField<T> field<T>({
    required String key,
    List<FieldValidator<T>> validators = const [],
    T? initialValue,
  }) {
    if (_fields.containsKey(key)) {
      return _fields[key] as RiftFormField<T>;
    }

    // Try to load initial value from box
    T? value = initialValue;
    if (box != null && box!.containsKey(key)) {
      value = box!.get(key) as T?;
    }

    final formField = RiftFormField<T>(
      key: key,
      initialValue: value,
      validators: validators,
    );

    _fields[key] = formField;

    // Listen for changes
    formField.onChange.listen((_) {
      _updateFormState();
      if (autoSave) {
        _scheduleAutoSave();
      }
    });

    return formField;
  }

  /// Gets a form field by [key].
  RiftFormField<T>? getField<T>(String key) {
    return _fields[key] as RiftFormField<T>?;
  }

  /// All field keys.
  Iterable<String> get fieldKeys => _fields.keys;

  /// The number of fields.
  int get fieldCount => _fields.length;

  /// Whether any field has been modified.
  bool get isDirty => _fields.values.any((f) => f.isDirty);

  /// Whether all fields are clean.
  bool get isClean => !isDirty;

  /// Whether all fields are valid.
  bool get isValid => _fields.values.every((f) => f.isValid);

  /// Whether any field is invalid.
  bool get isInvalid => !isValid;

  /// Validates all fields and returns whether the form is valid.
  bool validate() {
    var allValid = true;
    for (final field in _fields.values) {
      final result = field.validate();
      if (!result.isValid) allValid = false;
    }
    _updateFormState();
    return allValid;
  }

  /// Gets all validation errors grouped by field key.
  Map<String, List<String>> get allErrors {
    return Map.fromEntries(
      _fields.entries
          .where((e) => e.value.isInvalid)
          .map((e) => MapEntry(e.key, e.value.errors)),
    );
  }

  /// Saves all field values to the backing box.
  ///
  /// Only saves if the form is valid. Returns true if saved.
  Future<bool> save() async {
    if (!validate()) return false;
    if (box == null) return false;

    _setState(FormState.saving);

    try {
      for (final field in _fields.values) {
        if (field.isDirty) {
          await box!.put(field.key, field.value);
          field.markAsPristine();
        }
      }
      _setState(FormState.saved);
      return true;
    } catch (e) {
      _setState(FormState.dirty);
      return false;
    }
  }

  /// Resets all fields to their initial values.
  void reset() {
    for (final field in _fields.values) {
      field.reset();
    }
    _setState(FormState.pristine);
  }

  void _updateFormState() {
    if (isDirty) {
      _setState(isValid ? FormState.dirty : FormState.invalid);
    } else {
      _setState(FormState.pristine);
    }
  }

  void _setState(FormState newState) {
    if (_state == newState) return;
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  void _scheduleAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () async {
      await save();
    });
  }

  /// Disposes the form and all its fields.
  void dispose() {
    _debounceTimer?.cancel();
    _stateController.close();
    for (final field in _fields.values) {
      field.dispose();
    }
    _fields.clear();
  }
}

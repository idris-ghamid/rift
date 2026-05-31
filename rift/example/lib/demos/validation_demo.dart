import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class ValidationDemoPage extends StatelessWidget {
  const ValidationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Enhanced Validation',
      description:
          'Advanced validation with async rules, cross-field validation, and pre-built rules',
      codeExample:
          "// Pre-built rules\nfinal schema = DataValidationSchema(fields: {\n  'email': [ValidationRules.email()],\n  'age': [ValidationRule.required(), ValidationRule.min(0), ValidationRule.max(150)],\n  'password': [ValidationRules.passwordStrength()],\n});\n\n// Async validation\nfinal enhancedSchema = EnhancedValidationSchema(\n  asyncRules: {'email': [ValidationRules.unique(checkUnique: ...)]},\n);\n\n// Cross-field validation\nfinal crossFieldSchema = EnhancedValidationSchema(\n  crossFieldRules: [CrossFieldValidationRules.passwordConfirmation()],\n);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Enhanced Validation Demo ===\n');

        // 1. Pre-built validation rules
        buf.writeln('--- Pre-built Validation Rules ---');
        final preBuiltSchema = DataValidationSchema(
          fields: {
            'email': [
              ValidationRules.email(),
            ],
            'phone': [
              ValidationRules.phone(),
            ],
            'url': [
              ValidationRules.url(),
            ],
            'password': [
              ValidationRules.passwordStrength(),
            ],
            'username': [
              ValidationRules.username(),
            ],
            'uuid': [
              ValidationRules.uuid(),
            ],
            'hexColor': [
              ValidationRules.hexColor(),
            ],
            'ipAddress': [
              ValidationRules.ipAddress(),
            ],
          },
        );

        final preBuiltValidator = SchemaValidator(preBuiltSchema);

        // Test email validation
        final emailTest = {'email': 'test@example.com'};
        final emailResult = preBuiltValidator.validate(emailTest);
        buf.writeln('  Email "test@example.com": valid=${emailResult.isValid}');

        final invalidEmailTest = {'email': 'not-an-email'};
        final invalidEmailResult = preBuiltValidator.validate(invalidEmailTest);
        buf.writeln(
            '  Email "not-an-email": valid=${invalidEmailResult.isValid}');
        if (invalidEmailResult.isInvalid) {
          for (final e in invalidEmailResult.errors) {
            buf.writeln('    ❌ ${e.message}');
          }
        }

        // Test password strength
        final weakPassword = {'password': 'weak'};
        final weakResult = preBuiltValidator.validate(weakPassword);
        buf.writeln('  Password "weak": valid=${weakResult.isValid}');
        if (weakResult.isInvalid) {
          for (final e in weakResult.errors) {
            buf.writeln('    ❌ ${e.message}');
          }
        }

        final strongPassword = {'password': 'Str0ngP@ss!123'};
        final strongResult = preBuiltValidator.validate(strongPassword);
        buf.writeln(
            '  Password "Str0ngP@ss!123": valid=${strongResult.isValid}');

        // Test UUID validation
        final validUuid = {'uuid': '550e8400-e29b-41d4-a716-446655440000'};
        final uuidResult = preBuiltValidator.validate(validUuid);
        buf.writeln('  UUID: valid=${uuidResult.isValid}');

        // Test hex color
        final validColor = {'hexColor': '#FF5733'};
        final colorResult = preBuiltValidator.validate(validColor);
        buf.writeln('  Hex Color "#FF5733": valid=${colorResult.isValid}');

        // Test IP address
        final validIp = {'ipAddress': '192.168.1.1'};
        final ipResult = preBuiltValidator.validate(validIp);
        buf.writeln('  IP Address "192.168.1.1": valid=${ipResult.isValid}');

        // 2. Async validation
        buf.writeln('\n--- Async Validation ---');
        final enhancedSchema = EnhancedValidationSchema(
          fields: {
            'email': [FieldRule.required()],
            'username': [FieldRule.required()],
          },
          asyncRules: {
            'email': [
              ValidationRules.unique(
                checkUnique: (email) async {
                  // Simulate async check
                  await Future.delayed(Duration(milliseconds: 10));
                  return email != 'existing@example.com';
                },
              ),
            ],
            'username': [
              ValidationRules.unique(
                checkUnique: (username) async {
                  await Future.delayed(Duration(milliseconds: 10));
                  return username != 'taken_username';
                },
              ),
            ],
          },
        );

        final enhancedValidator = EnhancedSchemaValidator(enhancedSchema);

        final uniqueData = {
          'email': 'new@example.com',
          'username': 'new_user',
        };
        final uniqueResult = await enhancedValidator.validateAsync(uniqueData);
        buf.writeln('  Unique data: valid=${uniqueResult.isValid}');

        final duplicateData = {
          'email': 'existing@example.com',
          'username': 'taken_username',
        };
        final duplicateResult =
            await enhancedValidator.validateAsync(duplicateData);
        buf.writeln('  Duplicate data: valid=${duplicateResult.isValid}');
        if (duplicateResult.isInvalid) {
          for (final e in duplicateResult.asyncErrors) {
            buf.writeln('    ❌ ${e.field}: ${e.message}');
          }
        }

        // 3. Cross-field validation
        buf.writeln('\n--- Cross-Field Validation ---');
        final crossFieldSchema = EnhancedValidationSchema(
          fields: {
            'password': [FieldRule.required()],
            'passwordConfirmation': [FieldRule.required()],
            'startDate': [FieldRule.required()],
            'endDate': [FieldRule.required()],
            'min': [FieldRule.required()],
            'max': [FieldRule.required()],
          },
          crossFieldRules: [
            CrossFieldValidationRules.passwordConfirmation(),
            CrossFieldValidationRules.dateRange(),
            CrossFieldValidationRules.numericRange(),
            CrossFieldValidationRules.atLeastOneRequired(
              fields: ['email', 'phone'],
            ),
            CrossFieldValidationRules.mutuallyExclusive(
              fields: ['creditCard', 'paypal'],
            ),
          ],
        );

        final crossFieldValidator = EnhancedSchemaValidator(crossFieldSchema);

        // Password confirmation
        final passwordData = {
          'password': 'Secure123!',
          'passwordConfirmation': 'Secure123!',
        };
        final passwordResult = crossFieldValidator.validate(passwordData);
        buf.writeln('  Passwords match: valid=${passwordResult.isValid}');

        final mismatchData = {
          'password': 'Secure123!',
          'passwordConfirmation': 'Different123!',
        };
        final mismatchResult = crossFieldValidator.validate(mismatchData);
        buf.writeln('  Passwords mismatch: valid=${mismatchResult.isValid}');
        if (mismatchResult.isInvalid) {
          for (final e in mismatchResult.errors) {
            buf.writeln('    ❌ ${e.message}');
          }
        }

        // Date range
        final validDateData = {
          'startDate': DateTime(2024, 1, 1),
          'endDate': DateTime(2024, 12, 31),
        };
        final dateResult = crossFieldValidator.validate(validDateData);
        buf.writeln('  Valid date range: valid=${dateResult.isValid}');

        final invalidDateData = {
          'startDate': DateTime(2024, 12, 31),
          'endDate': DateTime(2024, 1, 1),
        };
        final invalidDateResult = crossFieldValidator.validate(invalidDateData);
        buf.writeln('  Invalid date range: valid=${invalidDateResult.isValid}');
        if (invalidDateResult.isInvalid) {
          for (final e in invalidDateResult.errors) {
            buf.writeln('    ❌ ${e.message}');
          }
        }

        // Numeric range
        final validNumericData = {'min': 0, 'max': 100};
        final numericResult = crossFieldValidator.validate(validNumericData);
        buf.writeln('  Valid numeric range: valid=${numericResult.isValid}');

        final invalidNumericData = {'min': 100, 'max': 0};
        final invalidNumericResult =
            crossFieldValidator.validate(invalidNumericData);
        buf.writeln(
            '  Invalid numeric range: valid=${invalidNumericResult.isValid}');
        if (invalidNumericResult.isInvalid) {
          for (final e in invalidNumericResult.errors) {
            buf.writeln('    ❌ ${e.message}');
          }
        }

        // At least one required
        final atLeastOneData = <String, dynamic>{'email': 'test@example.com'};
        final atLeastOneResult = crossFieldValidator.validate(atLeastOneData);
        buf.writeln(
            '  At least one field present: valid=${atLeastOneResult.isValid}');

        final noneData = <String, dynamic>{};
        final noneResult = crossFieldValidator.validate(noneData);
        buf.writeln('  No fields present: valid=${noneResult.isValid}');
        if (noneResult.isInvalid) {
          for (final e in noneResult.errors) {
            buf.writeln('    ❌ ${e.message}');
          }
        }

        // Mutually exclusive
        final exclusiveData = {'creditCard': '4111...'};
        final exclusiveResult = crossFieldValidator.validate(exclusiveData);
        buf.writeln('  Single field set: valid=${exclusiveResult.isValid}');

        final bothData = {'creditCard': '4111...', 'paypal': 'user@email.com'};
        final bothResult = crossFieldValidator.validate(bothData);
        buf.writeln('  Both fields set: valid=${bothResult.isValid}');
        if (bothResult.isInvalid) {
          for (final e in bothResult.errors) {
            buf.writeln('    ❌ ${e.message}');
          }
        }

        // 4. Combined sync + async + cross-field validation
        buf.writeln('\n--- Combined Validation ---');
        final combinedSchema = EnhancedValidationSchema(
          fields: {
            'email': [
              FieldRule.required(),
              ValidationRules.email(),
            ],
            'password': [
              FieldRule.required(),
              ValidationRules.passwordStrength(),
            ],
            'passwordConfirmation': [FieldRule.required()],
          },
          asyncRules: {
            'email': [
              ValidationRules.unique(
                checkUnique: (email) async {
                  await Future.delayed(Duration(milliseconds: 10));
                  return email != 'admin@example.com';
                },
              ),
            ],
          },
          crossFieldRules: [
            CrossFieldValidationRules.passwordConfirmation(),
          ],
        );

        final combinedValidator = EnhancedSchemaValidator(combinedSchema);

        final validCombined = {
          'email': 'user@example.com',
          'password': 'Str0ngP@ss!123',
          'passwordConfirmation': 'Str0ngP@ss!123',
        };
        final combinedResult =
            await combinedValidator.validateAsync(validCombined);
        buf.writeln('  Valid combined data: valid=${combinedResult.isValid}');

        final invalidCombined = {
          'email': 'admin@example.com', // Duplicate
          'password': 'weak', // Too weak
          'passwordConfirmation': 'different', // Mismatch
        };
        final invalidCombinedResult =
            await combinedValidator.validateAsync(invalidCombined);
        buf.writeln(
            '  Invalid combined data: valid=${invalidCombinedResult.isValid}');
        if (invalidCombinedResult.isInvalid) {
          buf.writeln('  Sync errors: ${invalidCombinedResult.errors.length}');
          for (final e in invalidCombinedResult.errors) {
            buf.writeln('    ❌ ${e.field}: ${e.message}');
          }
          buf.writeln(
              '  Async errors: ${invalidCombinedResult.asyncErrors.length}');
          for (final e in invalidCombinedResult.asyncErrors) {
            buf.writeln('    ❌ ${e.field}: ${e.message}');
          }
        }

        return buf.toString();
      },
    );
  }
}

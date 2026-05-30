import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class FormsDemoPage extends StatelessWidget {
  const FormsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Reactive Forms',
      description: 'Reactive forms with auto-save and validation',
      codeExample:
          "final form = RiftForm(box: box, autoSave: true);\nfinal name = form.field<String>(key: 'name',\n  validators: [FieldValidator.required()]);\nname.value = 'Idris';",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Reactive Forms Demo ===\n');

        // Open a backing box
        final box = await Rift.openBox<Map>('forms_demo');
        await box.clear();

        // Create form with auto-save
        final form = RiftForm(
          box: box,
          autoSave: true,
          debounceDuration: const Duration(milliseconds: 100),
        );

        // Define fields with validators
        final nameField = form.field<String>(
          key: 'name',
          validators: [
            FieldValidator.required(),
            FieldValidator.minLength(2),
          ],
        );
        final emailField = form.field<String>(
          key: 'email',
          validators: [
            FieldValidator.email(),
          ],
        );
        final ageField = form.field<String>(
          key: 'age',
          initialValue: '25',
        );

        buf.writeln('--- Form Fields ---');
        buf.writeln('  Field count: ${form.fieldCount}');
        buf.writeln('  Keys: ${form.fieldKeys.toList()}');

        // Set values
        buf.writeln('\n--- Set Values ---');
        nameField.value = 'Idris';
        emailField.value = 'invalid-email';
        buf.writeln(
            '  name: "${nameField.value}" (dirty: ${nameField.isDirty}, valid: ${nameField.isValid})');
        buf.writeln(
            '  email: "${emailField.value}" (dirty: ${emailField.isDirty}, valid: ${emailField.isValid})');
        buf.writeln(
            '  age: "${ageField.value}" (dirty: ${ageField.isDirty}, valid: ${ageField.isValid})');

        // Form state
        buf.writeln('\n--- Form State ---');
        buf.writeln('  State: ${form.state.name}');
        buf.writeln('  isDirty: ${form.isDirty}');
        buf.writeln('  isValid: ${form.isValid}');
        buf.writeln('  All errors: ${form.allErrors}');

        // Fix email
        buf.writeln('\n--- Fix Email ---');
        emailField.value = 'idris@example.com';
        buf.writeln(
            '  email: "${emailField.value}" (valid: ${emailField.isValid})');
        buf.writeln('  Form isValid: ${form.isValid}');

        // Wait for auto-save
        buf.writeln('\n--- Auto-save (debounced) ---');
        await Future.delayed(const Duration(milliseconds: 200));
        buf.writeln('  Form state: ${form.state.name}');
        buf.writeln('  Box "name": ${box.get('name')}');
        buf.writeln('  Box "email": ${box.get('email')}');

        // Reset
        buf.writeln('\n--- Reset Form ---');
        form.reset();
        buf.writeln(
            '  name: "${nameField.value}" (dirty: ${nameField.isDirty})');
        buf.writeln(
            '  email: "${emailField.value}" (dirty: ${emailField.isDirty})');
        buf.writeln('  Form state: ${form.state.name}');

        // Validation details
        buf.writeln('\n--- Validation Details ---');
        nameField.value = '';
        final result = nameField.validate();
        buf.writeln('  Empty name valid: ${result.isValid}');
        buf.writeln('  Errors: ${result.errors}');

        // Touched state
        buf.writeln('\n--- Touched State ---');
        buf.writeln('  name touched: ${nameField.isTouched}');
        buf.writeln('  age touched: ${ageField.isTouched}');

        form.dispose();
        await box.close();
        return buf.toString();
      },
    );
  }
}

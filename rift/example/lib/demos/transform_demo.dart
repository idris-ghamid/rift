import 'package:flutter/material.dart';
import 'package:rift/rift.dart';
import '../widgets/demo_page.dart';

class TransformDemoPage extends StatelessWidget {
  const TransformDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RiftDemoPage(
      title: 'Transform Pipeline',
      description: 'ETL-style data transform pipeline',
      codeExample:
          "final pipeline = TransformPipeline()\n  .add(RenameFieldTransform('old', 'new'))\n  .add(FilterFieldsTransform(['name', 'age']))\n  .add(MapValuesTransform('age', (v) => v + 1));\nfinal result = pipeline.applyWrite(data);",
      runDemo: () async {
        final buf = StringBuffer();
        buf.writeln('=== Transform Pipeline Demo ===\n');

        final input = {
          'oldName': 'Idris',
          'age': '25',
          'email': 'idris@example.com',
          'secret': 'hidden-value',
          'score': 95,
        };
        buf.writeln('--- Input Data ---');
        buf.writeln('  $input');

        // Build pipeline
        final pipeline = TransformPipeline()
          ..add(RenameFieldTransform('oldName', 'name'))
          ..add(FilterFieldsTransform(['name', 'age', 'email', 'score'],
              inclusive: true))
          ..add(
              MapValuesTransform('age', (v) => int.tryParse(v.toString()) ?? v))
          ..add(MapValuesTransform('score', (v) => (v as num) * 2));

        buf.writeln('\n--- Pipeline Steps ---');
        for (final t in pipeline.transforms) {
          buf.writeln('  ${t.name} (${t.phase.name})');
        }

        // Apply write transforms
        buf.writeln('\n--- After Write Transforms ---');
        final writeResult = pipeline.applyWrite(input);
        buf.writeln('  $writeResult');

        // Apply read transforms
        buf.writeln('\n--- After Read Transforms ---');
        final readResult = pipeline.applyRead(input);
        buf.writeln('  $readResult');

        // Individual transforms
        buf.writeln('\n--- Individual Transforms ---');

        // RenameFieldTransform
        final renameResult = RenameFieldTransform('email', 'mail')
            .apply({'email': 'a@b.c', 'name': 'X'});
        buf.writeln('  RenameField(email→mail): $renameResult');

        // FilterFieldsTransform (exclusive)
        final filterResult = FilterFieldsTransform(['secret'], inclusive: false)
            .apply({'name': 'X', 'secret': 'pwd', 'age': 25});
        buf.writeln('  FilterFields(exclude secret): $filterResult');

        // TypeConvertTransform
        final convertResult = TypeConvertTransform('age', 'int')
            .apply({'age': '25', 'name': 'X'});
        buf.writeln('  TypeConvert(age→int): $convertResult');

        // ComputedFieldTransform
        final computed = ComputedFieldTransform(
                'fullName', (data) => '${data["first"]} ${data["last"]}')
            .apply({'first': 'Idris', 'last': 'Ghamid', 'age': 25});
        buf.writeln('  ComputedField(fullName): $computed');

        // Phase-specific transforms
        buf.writeln('\n--- Phase-specific Transforms ---');
        final phasedPipeline = TransformPipeline()
          ..add(RenameFieldTransform('oldName', 'name',
              phase: TransformPhase.write))
          ..add(MapValuesTransform('score', (v) => v * 10,
              phase: TransformPhase.read));

        final original = {'oldName': 'Idris', 'score': 5};
        buf.writeln('  Original: $original');
        buf.writeln('  Write: ${phasedPipeline.applyWrite(original)}');
        buf.writeln('  Read: ${phasedPipeline.applyRead(original)}');

        return buf.toString();
      },
    );
  }
}

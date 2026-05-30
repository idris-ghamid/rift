// @dart=3.6
// ignore_for_file: type=lint
// build_runner >=2.4.16
import 'dart:io' as _io;
import 'package:build_runner/src/build_plan/builder_factories.dart'
    as _build_runner;
import 'package:build_runner/src/bootstrap/processes.dart' as _build_runner;
import 'package:json_serializable/builder.dart' as _i1;
import 'package:source_gen/builder.dart' as _i2;

final _builderFactories = _build_runner.BuilderFactories(
  {
    'json_serializable:json_serializable': [_i1.jsonSerializable],
    'source_gen:combining_builder': [_i2.combiningBuilder],
  },
  postProcessBuilderFactories: {
    'source_gen:part_cleanup': _i2.partCleanup,
  },
);
void main(List<String> args) async {
  _io.exitCode = await _build_runner.ChildProcess.run(
    args,
    _builderFactories,
  )!;
}

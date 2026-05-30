import 'dart:isolate';

import 'package:rift/src/isolate/handler/isolate_entry_point.dart';

void main(List<String> args, SendPort sendPort) {
  isolateEntryPoint(sendPort);
}

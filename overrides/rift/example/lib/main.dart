import 'package:rift/rift.dart';

void main() async {
  Rift.init('test');
  final box = await Rift.openBox('test');
  box.put('key', 'value');
  print(box.get('key'));
}


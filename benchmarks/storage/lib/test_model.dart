import 'package:rift/rift.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'test_model.g.dart';

@JsonSerializable()
@RiftType(typeId: 0)
@immutable
class TestModel {
  @RiftField(0)
  final int testModelFieldZero;

  @RiftField(1)
  final int testModelFieldOne;

  @RiftField(2)
  final int testModelFieldTwo;

  @RiftField(3)
  final int testModelFieldThree;

  @RiftField(4)
  final int testModelFieldFour;

  @RiftField(5)
  final int testModelFieldFive;

  @RiftField(6)
  final int testModelFieldSix;

  @RiftField(7)
  final int testModelFieldSeven;

  @RiftField(8)
  final int testModelFieldEight;

  @RiftField(9)
  final int testModelFieldNine;

  const TestModel({
    required this.testModelFieldZero,
    required this.testModelFieldOne,
    required this.testModelFieldTwo,
    required this.testModelFieldThree,
    required this.testModelFieldFour,
    required this.testModelFieldFive,
    required this.testModelFieldSix,
    required this.testModelFieldSeven,
    required this.testModelFieldEight,
    required this.testModelFieldNine,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) =>
      _$TestModelFromJson(json);

  Map<String, dynamic> toJson() => _$TestModelToJson(this);
}

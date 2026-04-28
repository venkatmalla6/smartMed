// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcq.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class McqQuestionAdapter extends TypeAdapter<McqQuestion> {
  @override
  final int typeId = 1;

  @override
  McqQuestion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return McqQuestion(
      question: fields[0] as String,
      options: (fields[1] as List).cast<String>(),
      answer: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, McqQuestion obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.options)
      ..writeByte(2)
      ..write(obj.answer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McqQuestionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

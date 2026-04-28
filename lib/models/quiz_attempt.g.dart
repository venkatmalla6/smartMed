// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_attempt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuizAttemptAdapter extends TypeAdapter<QuizAttempt> {
  @override
  final int typeId = 2;

  @override
  QuizAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuizAttempt(
      score: fields[0] as int,
      totalQuestions: fields[1] as int,
      date: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QuizAttempt obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.score)
      ..writeByte(1)
      ..write(obj.totalQuestions)
      ..writeByte(2)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuizAttemptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

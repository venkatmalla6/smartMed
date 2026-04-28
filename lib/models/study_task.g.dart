// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudyTaskAdapter extends TypeAdapter<StudyTask> {
  @override
  final int typeId = 4;

  @override
  StudyTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      scheduledTime: fields[3] as DateTime,
      isCompleted: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StudyTask obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.scheduledTime)
      ..writeByte(4)
      ..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

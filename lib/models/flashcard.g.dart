// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FlashcardAdapter extends TypeAdapter<Flashcard> {
  @override
  final int typeId = 6;

  @override
  Flashcard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Flashcard(
      id: fields[0] as String,
      deckId: fields[1] as String,
      front: fields[2] as String,
      back: fields[3] as String,
      topic: fields[4] as String,
      interval: fields[5] as int,
      easeFactor: fields[6] as double,
      repetitions: fields[7] as int,
      nextReview: fields[8] as DateTime?,
      createdAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Flashcard obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.deckId)
      ..writeByte(2)
      ..write(obj.front)
      ..writeByte(3)
      ..write(obj.back)
      ..writeByte(4)
      ..write(obj.topic)
      ..writeByte(5)
      ..write(obj.interval)
      ..writeByte(6)
      ..write(obj.easeFactor)
      ..writeByte(7)
      ..write(obj.repetitions)
      ..writeByte(8)
      ..write(obj.nextReview)
      ..writeByte(9)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashcardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

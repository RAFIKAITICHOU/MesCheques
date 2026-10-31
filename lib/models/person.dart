import 'package:uuid/uuid.dart';
import '../utils/text_normalizer.dart';

class Person {
  final int? id;
  final String uuid;
  final String name;
  final String nameNormalized;
  final String createdAt;

  Person({
    this.id,
    String? uuid,
    required this.name,
    String? nameNormalized,
    required this.createdAt,
  })  : uuid = uuid ?? const Uuid().v4(),
        nameNormalized = nameNormalized ?? TextNormalizer.normalize(name);

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'name': name.trim(),
      'name_normalized': nameNormalized,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int?,
      uuid: (map['uuid'] as String?) ?? const Uuid().v4(),
      name: map['name'] as String,
      nameNormalized: (map['name_normalized'] as String?) ??
          TextNormalizer.normalize(map['name'] as String),
      createdAt: map['created_at'] as String,
    );
  }

  Person copyWith({
    int? id,
    String? uuid,
    String? name,
    String? nameNormalized,
    String? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      nameNormalized: nameNormalized ?? this.nameNormalized,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Person &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nameNormalized == other.nameNormalized;

  @override
  int get hashCode => id.hashCode ^ nameNormalized.hashCode;

  @override
  String toString() => 'Person(id: $id, uuid: $uuid, name: $name, norm: $nameNormalized)';
}

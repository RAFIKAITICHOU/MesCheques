class Tombstone {
  final String uuid;
  final String entityType; // 'check', 'person'
  final DateTime deletedAt;

  Tombstone({
    required this.uuid,
    required this.entityType,
    required this.deletedAt,
  });

  Map<String, dynamic> toMap() => {
    'uuid': uuid,
    'entity_type': entityType,
    'deleted_at': deletedAt.toIso8601String(),
  };

  factory Tombstone.fromMap(Map<String, dynamic> map) => Tombstone(
    uuid: map['uuid'] as String,
    entityType: map['entity_type'] as String? ?? 'check',
    deletedAt: DateTime.parse(map['deleted_at'] as String),
  );
}

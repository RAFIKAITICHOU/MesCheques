import 'package:uuid/uuid.dart';

class CheckImage {
  final int? id;
  final String uuid;
  final int checkId;
  final String fileName;
  final String kind; // 'front', 'back', 'other'
  final int sortOrder;
  final int sizeBytes;
  final String sha256;
  final String createdAt;

  CheckImage({
    this.id,
    String? uuid,
    required this.checkId,
    required this.fileName,
    this.kind = 'front',
    this.sortOrder = 0,
    required this.sizeBytes,
    required this.sha256,
    required this.createdAt,
  }) : uuid = uuid ?? const Uuid().v4();

  bool get isFront => kind == 'front';
  bool get isBack => kind == 'back';
  bool get isOther => kind != 'front' && kind != 'back';

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'check_id': checkId,
      'file_name': fileName,
      'kind': kind,
      'sort_order': sortOrder,
      'size_bytes': sizeBytes,
      'sha256': sha256,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory CheckImage.fromMap(Map<String, dynamic> map) {
    return CheckImage(
      id: map['id'] as int?,
      uuid: (map['uuid'] as String?) ?? const Uuid().v4(),
      checkId: map['check_id'] as int,
      fileName: map['file_name'] as String,
      kind: (map['kind'] as String?) ?? 'front',
      sortOrder: (map['sort_order'] as int?) ?? 0,
      sizeBytes: (map['size_bytes'] as int?) ?? 0,
      sha256: map['sha256'] as String,
      createdAt: map['created_at'] as String,
    );
  }

  CheckImage copyWith({
    int? id,
    String? uuid,
    int? checkId,
    String? fileName,
    String? kind,
    int? sortOrder,
    int? sizeBytes,
    String? sha256,
    String? createdAt,
  }) {
    return CheckImage(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      checkId: checkId ?? this.checkId,
      fileName: fileName ?? this.fileName,
      kind: kind ?? this.kind,
      sortOrder: sortOrder ?? this.sortOrder,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      sha256: sha256 ?? this.sha256,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

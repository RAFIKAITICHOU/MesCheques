import 'package:uuid/uuid.dart';
import '../utils/text_normalizer.dart';

class Check {
  final int? id;
  final String uuid;
  final String checkNumber;
  final int amountCents;
  final String checkDate;
  final String receivedDate;
  final int giverId;
  final int? drawerId;
  final int? paidToId;
  final String? paidDate;
  final String? notes;
  final String? searchText;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  Check({
    this.id,
    String? uuid,
    required this.checkNumber,
    required this.amountCents,
    required this.checkDate,
    required this.receivedDate,
    required this.giverId,
    this.drawerId,
    this.paidToId,
    this.paidDate,
    this.notes,
    String? searchText,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  })  : uuid = uuid ?? const Uuid().v4(),
        searchText = searchText ??
            TextNormalizer.normalize('$checkNumber ${notes ?? ""}');

  bool get isInStock => paidToId == null;
  bool get isUsed => paidToId != null;
  bool get isDeleted => deletedAt != null;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'uuid': uuid,
      'check_number': checkNumber.trim(),
      'amount_cents': amountCents,
      'check_date': checkDate,
      'received_date': receivedDate,
      'giver_id': giverId,
      'drawer_id': drawerId,
      'paid_to_id': paidToId,
      'paid_date': paidDate,
      'notes': notes?.trim(),
      'search_text': searchText ?? TextNormalizer.normalize('$checkNumber ${notes ?? ""}'),
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  factory Check.fromMap(Map<String, dynamic> map) {
    return Check(
      id: map['id'] as int?,
      uuid: (map['uuid'] as String?) ?? const Uuid().v4(),
      checkNumber: map['check_number'] as String,
      amountCents: map['amount_cents'] as int,
      checkDate: map['check_date'] as String,
      receivedDate: map['received_date'] as String,
      giverId: map['giver_id'] as int,
      drawerId: map['drawer_id'] as int?,
      paidToId: map['paid_to_id'] as int?,
      paidDate: map['paid_date'] as String?,
      notes: map['notes'] as String?,
      searchText: map['search_text'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
    );
  }

  Check copyWith({
    int? id,
    String? uuid,
    String? checkNumber,
    int? amountCents,
    String? checkDate,
    String? receivedDate,
    int? giverId,
    int? Function()? drawerId,
    int? Function()? paidToId,
    String? Function()? paidDate,
    String? Function()? notes,
    String? searchText,
    String? createdAt,
    String? updatedAt,
    String? Function()? deletedAt,
  }) {
    return Check(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      checkNumber: checkNumber ?? this.checkNumber,
      amountCents: amountCents ?? this.amountCents,
      checkDate: checkDate ?? this.checkDate,
      receivedDate: receivedDate ?? this.receivedDate,
      giverId: giverId ?? this.giverId,
      drawerId: drawerId != null ? drawerId() : this.drawerId,
      paidToId: paidToId != null ? paidToId() : this.paidToId,
      paidDate: paidDate != null ? paidDate() : this.paidDate,
      notes: notes != null ? notes() : this.notes,
      searchText: searchText ?? this.searchText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt != null ? deletedAt() : this.deletedAt,
    );
  }
}

/// Joined representation for UI display with person names
class CheckWithNames {
  final Check check;
  final String giverName;
  final String? drawerName;
  final String? paidToName;
  final String giverNameNormalized;
  final String? drawerNameNormalized;
  final String? paidToNameNormalized;
  final int imageCount;
  final String? primaryImageFileName;

  CheckWithNames({
    required this.check,
    required this.giverName,
    this.drawerName,
    this.paidToName,
    String? giverNameNormalized,
    String? drawerNameNormalized,
    this.paidToNameNormalized,
    this.imageCount = 0,
    this.primaryImageFileName,
  })  : giverNameNormalized = giverNameNormalized ?? TextNormalizer.normalize(giverName),
        drawerNameNormalized = drawerNameNormalized ?? (drawerName != null ? TextNormalizer.normalize(drawerName) : null);

  int? get id => check.id;
  String get uuid => check.uuid;
  String get checkNumber => check.checkNumber;
  int get amountCents => check.amountCents;
  String get checkDate => check.checkDate;
  String get receivedDate => check.receivedDate;
  int get giverId => check.giverId;
  int? get drawerId => check.drawerId;
  int? get paidToId => check.paidToId;
  String? get paidDate => check.paidDate;
  String? get notes => check.notes;
  String? get searchText => check.searchText;
  String get createdAt => check.createdAt;
  String get updatedAt => check.updatedAt;
  String? get deletedAt => check.deletedAt;

  bool get isInStock => check.isInStock;
  bool get isUsed => check.isUsed;
  bool get isDeleted => check.isDeleted;

  /// True if drawer is specified and different from giver
  bool get isDrawerDifferent {
    if (drawerId != null && drawerId != giverId) return true;
    if (drawerName != null &&
        drawerName!.trim().isNotEmpty &&
        drawerNameNormalized != giverNameNormalized) {
      return true;
    }
    return false;
  }

  factory CheckWithNames.fromMap(Map<String, dynamic> map) {
    return CheckWithNames(
      check: Check.fromMap(map),
      giverName: (map['giver_name'] as String?) ?? 'Inconnu',
      drawerName: map['drawer_name'] as String?,
      paidToName: map['paid_to_name'] as String?,
      giverNameNormalized: map['giver_name_normalized'] as String?,
      drawerNameNormalized: map['drawer_name_normalized'] as String?,
      paidToNameNormalized: map['paid_to_name_normalized'] as String?,
      imageCount: (map['image_count'] as int?) ?? 0,
      primaryImageFileName: map['primary_image_file_name'] as String?,
    );
  }

  CheckWithNames copyWith({
    Check? check,
    String? giverName,
    String? drawerName,
    String? paidToName,
    String? giverNameNormalized,
    String? drawerNameNormalized,
    String? paidToNameNormalized,
    int? imageCount,
    String? primaryImageFileName,
  }) {
    return CheckWithNames(
      check: check ?? this.check,
      giverName: giverName ?? this.giverName,
      drawerName: drawerName ?? this.drawerName,
      paidToName: paidToName ?? this.paidToName,
      giverNameNormalized: giverNameNormalized ?? this.giverNameNormalized,
      drawerNameNormalized: drawerNameNormalized ?? this.drawerNameNormalized,
      paidToNameNormalized: paidToNameNormalized ?? this.paidToNameNormalized,
      imageCount: imageCount ?? this.imageCount,
      primaryImageFileName: primaryImageFileName ?? this.primaryImageFileName,
    );
  }
}

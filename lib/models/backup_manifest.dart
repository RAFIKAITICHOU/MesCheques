import 'dart:convert';

class BackupManifest {
  final String deviceId;
  final String deviceName;
  final String createdAt;
  final int dbVersion;
  final int backupVersion;
  final int checksCount;
  final int imagesCount;
  final List<String> imagesSha256;
  final String salt;
  final String checksum;

  BackupManifest({
    required this.deviceId,
    required this.deviceName,
    required this.createdAt,
    required this.dbVersion,
    required this.backupVersion,
    required this.checksCount,
    required this.imagesCount,
    required this.imagesSha256,
    required this.salt,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
    'device_id': deviceId,
    'device_name': deviceName,
    'created_at': createdAt,
    'db_version': dbVersion,
    'backup_version': backupVersion,
    'checks_count': checksCount,
    'images_count': imagesCount,
    'images_sha256': imagesSha256,
    'salt': salt,
    'checksum': checksum,
  };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
    deviceId: json['device_id'] as String? ?? '',
    deviceName: json['device_name'] as String? ?? '',
    createdAt: json['created_at'] as String? ?? '',
    dbVersion: (json['db_version'] as int?) ?? 5,
    backupVersion: (json['backup_version'] as int?) ?? 3,
    checksCount: (json['checks_count'] as int?) ?? 0,
    imagesCount: (json['images_count'] as int?) ?? 0,
    imagesSha256: (json['images_sha256'] as List?)?.map((e) => e.toString()).toList() ?? [],
    salt: json['salt'] as String? ?? '',
    checksum: json['checksum'] as String? ?? '',
  );

  String serialize() => jsonEncode(toJson());

  static BackupManifest deserialize(String jsonString) =>
      BackupManifest.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

import 'check.dart';

enum ConflictResolutionAction {
  keepIncoming, // Garder la version reçue (A)
  keepExisting, // Garder la version locale (B)
  keepBoth,     // Garder les deux (renommer le numéro reçu)
}

class CheckConflict {
  final Check incomingCheck;
  final String incomingGiverName;
  final String? incomingPaidToName;

  final Check existingCheck;
  final String existingGiverName;
  final String? existingPaidToName;

  ConflictResolutionAction? resolvedAction;

  CheckConflict({
    required this.incomingCheck,
    required this.incomingGiverName,
    this.incomingPaidToName,
    required this.existingCheck,
    required this.existingGiverName,
    this.existingPaidToName,
    this.resolvedAction,
  });

  String get checkNumber => existingCheck.checkNumber;
}

class MergeReport {
  final String? fileCreatedAt;
  final int newChecksCount;
  final int updatedChecksCount;
  final int identicalChecksCount;
  final int newPersonsCount;
  final int purgedPropagatedCount;
  final List<CheckConflict> conflicts;

  final int incomingChecksTotal;
  final int incomingAmountCents;
  final int currentChecksTotal;
  final int currentAmountCents;

  final int newImagesCount;
  final int incomingImagesSizeBytes;

  MergeReport({
    this.fileCreatedAt,
    required this.newChecksCount,
    required this.updatedChecksCount,
    required this.identicalChecksCount,
    required this.newPersonsCount,
    required this.purgedPropagatedCount,
    required this.conflicts,
    required this.incomingChecksTotal,
    required this.incomingAmountCents,
    required this.currentChecksTotal,
    required this.currentAmountCents,
    this.newImagesCount = 0,
    this.incomingImagesSizeBytes = 0,
  });

  String get formattedImagesVolume {
    if (incomingImagesSizeBytes < 1024) return '$incomingImagesSizeBytes B';
    if (incomingImagesSizeBytes < 1024 * 1024) {
      return '${(incomingImagesSizeBytes / 1024).toStringAsFixed(1)} Ko';
    }
    return '${(incomingImagesSizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  int get conflictsCount => conflicts.length;
  int get unresolvedCount => conflicts.where((c) => c.resolvedAction == null).length;
  bool get hasConflicts => conflicts.isNotEmpty;
  bool get isFullyResolved => conflicts.every((c) => c.resolvedAction != null);
}

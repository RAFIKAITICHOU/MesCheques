import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/check.dart';
import '../models/check_filter.dart';
import '../models/check_image.dart';
import '../repositories/check_repository.dart';
import '../services/image_service.dart';

class ChecksProvider extends ChangeNotifier {
  final CheckRepository _repository;

  ChecksProvider({CheckRepository? repository})
      : _repository = repository ?? CheckRepository();

  List<CheckWithNames> _checks = [];
  List<CheckWithNames> get checks => _checks;

  List<CheckWithNames> _trashChecks = [];
  List<CheckWithNames> get trashChecks => _trashChecks;

  CheckStats _stats = const CheckStats();
  CheckStats get stats => _stats;

  CheckFilter _filter = const CheckFilter();
  CheckFilter get filter => _filter;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _searchDebounce;

  /// Initial load
  Future<void> init() async {
    await refreshAll();
  }

  /// Reload checks, stats, and trash count
  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.query(_filter),
        _repository.getStats(),
        _repository.getTrashChecks(),
      ]);

      _checks = results[0] as List<CheckWithNames>;
      _stats = results[1] as CheckStats;
      _trashChecks = results[2] as List<CheckWithNames>;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des chèques : $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set search query with 300ms debounce
  void setSearchQuery(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      final trimmed = query.trim();
      _filter = _filter.copyWith(
        searchQuery: () => trimmed.isEmpty ? null : trimmed,
      );
      await refreshAll();
    });
  }

  /// Switch status filter (Tous / En stock / Utilisés)
  Future<void> setStatusFilter(CheckStatusFilter status) async {
    if (_filter.status == status) return;
    _filter = _filter.copyWith(status: status);
    await refreshAll();
  }

  /// Change sorting
  Future<void> setSortOption(CheckSortOption sortOption) async {
    if (_filter.sortOption == sortOption) return;
    _filter = _filter.copyWith(sortOption: sortOption);
    await refreshAll();
  }

  /// Apply advanced filter sheet
  Future<void> applyFilter(CheckFilter newFilter) async {
    _filter = newFilter;
    await refreshAll();
  }

  /// Reset all filters to default
  Future<void> resetFilters() async {
    _filter = const CheckFilter();
    await refreshAll();
  }

  /// Clear specific active filter
  Future<void> clearFilterGiver() async {
    _filter = _filter.copyWith(giverId: () => null);
    await refreshAll();
  }

  Future<void> clearFilterDrawer() async {
    _filter = _filter.copyWith(drawerId: () => null);
    await refreshAll();
  }

  Future<void> clearFilterImages() async {
    _filter = _filter.copyWith(imageFilter: CheckImageFilter.all);
    await refreshAll();
  }

  Future<void> clearFilterPaidTo() async {
    _filter = _filter.copyWith(paidToId: () => null);
    await refreshAll();
  }

  Future<void> clearFilterMinAmount() async {
    _filter = _filter.copyWith(minAmountCents: () => null);
    await refreshAll();
  }

  Future<void> clearFilterMaxAmount() async {
    _filter = _filter.copyWith(maxAmountCents: () => null);
    await refreshAll();
  }

  Future<void> clearFilterDateRange() async {
    _filter = _filter.copyWith(
      checkDateFrom: () => null,
      checkDateTo: () => null,
    );
    await refreshAll();
  }

  /// Create check
  Future<void> createCheck({
    required String checkNumber,
    required int amountCents,
    required String checkDate,
    required String receivedDate,
    required String giverName,
    String? drawerName,
    String? paidToName,
    String? paidDate,
    String? notes,
    List<ProcessedImageData>? images,
  }) async {
    await _repository.createCheck(
      checkNumber: checkNumber,
      amountCents: amountCents,
      checkDate: checkDate,
      receivedDate: receivedDate,
      giverName: giverName,
      drawerName: drawerName,
      paidToName: paidToName,
      paidDate: paidDate,
      notes: notes,
      images: images,
    );
    await refreshAll();
  }

  /// Update check
  Future<void> updateCheck({
    required int id,
    required String checkNumber,
    required int amountCents,
    required String checkDate,
    required String receivedDate,
    required String giverName,
    String? drawerName,
    String? paidToName,
    String? paidDate,
    String? notes,
    required String createdAt,
    List<ProcessedImageData>? newImages,
    List<int>? deleteImageIds,
    List<({int id, int sortOrder, String kind})>? updateImagesOrderKind,
  }) async {
    await _repository.updateCheck(
      id: id,
      checkNumber: checkNumber,
      amountCents: amountCents,
      checkDate: checkDate,
      receivedDate: receivedDate,
      giverName: giverName,
      drawerName: drawerName,
      paidToName: paidToName,
      paidDate: paidDate,
      notes: notes,
      createdAt: createdAt,
      newImages: newImages,
      deleteImageIds: deleteImageIds,
      updateImagesOrderKind: updateImagesOrderKind,
    );
    await refreshAll();
  }

  /// Get images for a check
  Future<List<CheckImage>> getCheckImages(int checkId) async {
    return await _repository.getCheckImages(checkId);
  }

  /// Delete an image
  Future<void> deleteCheckImage(int checkId, int imageId) async {
    await _repository.deleteCheckImage(checkId, imageId);
    await refreshAll();
  }

  /// Mark check as used
  Future<void> markAsUsed({
    required int id,
    required String paidToName,
    required String paidDate,
  }) async {
    await _repository.markAsUsed(
      id: id,
      paidToName: paidToName,
      paidDate: paidDate,
    );
    await refreshAll();
  }

  /// Cancel payment (back to stock)
  Future<void> cancelPayment(int id) async {
    await _repository.cancelPayment(id);
    await refreshAll();
  }

  /// Move check to trash
  Future<void> softDeleteCheck(int id) async {
    await _repository.softDelete(id);
    await refreshAll();
  }

  /// Restore check from trash
  Future<void> restoreCheck(int id) async {
    await _repository.restore(id);
    await refreshAll();
  }

  /// Hard delete check permanently
  Future<void> hardDeleteCheck(int id) async {
    await _repository.hardDelete(id);
    await refreshAll();
  }

  /// Empty trash completely
  Future<void> emptyTrash() async {
    await _repository.emptyTrash();
    await refreshAll();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

enum CheckStatusFilter {
  all,
  stock,
  used,
}

enum CheckImageFilter {
  all,
  withImage,
  withoutImage,
}

enum CheckSortOption {
  lifo,             // Derniers ajoutés (défaut)
  fifo,             // Plus anciens
  giverNameAsc,     // Nom émetteur A→Z
  giverNameDesc,    // Nom émetteur Z→A
  amountDesc,       // Montant décroissant
  amountAsc,        // Montant croissant
  checkDateDesc,    // Date chèque récente
  checkDateAsc,     // Date chèque ancienne
  receivedDateDesc, // Date réception récente
  receivedDateAsc,  // Date réception ancienne
  numberAsc,        // Numéro croissant
  numberDesc,       // Numéro décroissant
}

extension CheckSortOptionExtension on CheckSortOption {
  String get label {
    switch (this) {
      case CheckSortOption.lifo:
        return 'Derniers ajoutés (LIFO)';
      case CheckSortOption.fifo:
        return 'Plus anciens';
      case CheckSortOption.giverNameAsc:
        return 'Nom émetteur (A → Z)';
      case CheckSortOption.giverNameDesc:
        return 'Nom émetteur (Z → A)';
      case CheckSortOption.amountDesc:
        return 'Montant décroissant (↓)';
      case CheckSortOption.amountAsc:
        return 'Montant croissant (↑)';
      case CheckSortOption.checkDateDesc:
        return 'Date chèque (récente)';
      case CheckSortOption.checkDateAsc:
        return 'Date chèque (ancienne)';
      case CheckSortOption.receivedDateDesc:
        return 'Date réception (récente)';
      case CheckSortOption.receivedDateAsc:
        return 'Date réception (ancienne)';
      case CheckSortOption.numberAsc:
        return 'Numéro (croissant)';
      case CheckSortOption.numberDesc:
        return 'Numéro (décroissant)';
    }
  }

  String get sqlOrderBy {
    switch (this) {
      case CheckSortOption.lifo:
        return 'c.created_at DESC, c.id DESC';
      case CheckSortOption.fifo:
        return 'c.created_at ASC, c.id ASC';
      case CheckSortOption.giverNameAsc:
        return 'g.name_normalized ASC';
      case CheckSortOption.giverNameDesc:
        return 'g.name_normalized DESC';
      case CheckSortOption.amountDesc:
        return 'c.amount_cents DESC';
      case CheckSortOption.amountAsc:
        return 'c.amount_cents ASC';
      case CheckSortOption.checkDateDesc:
        return 'c.check_date DESC';
      case CheckSortOption.checkDateAsc:
        return 'c.check_date ASC';
      case CheckSortOption.receivedDateDesc:
        return 'c.received_date DESC';
      case CheckSortOption.receivedDateAsc:
        return 'c.received_date ASC';
      case CheckSortOption.numberAsc:
        return 'c.check_number ASC';
      case CheckSortOption.numberDesc:
        return 'c.check_number DESC';
    }
  }
}

class CheckFilter {
  final String? searchQuery;
  final CheckStatusFilter status;
  final int? giverId;
  final int? drawerId;
  final int? paidToId;
  final CheckImageFilter imageFilter;
  final int? minAmountCents;
  final int? maxAmountCents;
  final String? checkDateFrom;
  final String? checkDateTo;
  final String? receivedDateFrom;
  final String? receivedDateTo;
  final String? checkNumber;
  final String? notes;
  final CheckSortOption sortOption;

  const CheckFilter({
    this.searchQuery,
    this.status = CheckStatusFilter.all,
    this.giverId,
    this.drawerId,
    this.paidToId,
    this.imageFilter = CheckImageFilter.all,
    this.minAmountCents,
    this.maxAmountCents,
    this.checkDateFrom,
    this.checkDateTo,
    this.receivedDateFrom,
    this.receivedDateTo,
    this.checkNumber,
    this.notes,
    this.sortOption = CheckSortOption.lifo,
  });

  bool get hasAdvancedFilters =>
      giverId != null ||
      drawerId != null ||
      paidToId != null ||
      imageFilter != CheckImageFilter.all ||
      minAmountCents != null ||
      maxAmountCents != null ||
      checkDateFrom != null ||
      checkDateTo != null ||
      receivedDateFrom != null ||
      receivedDateTo != null ||
      (checkNumber != null && checkNumber!.trim().isNotEmpty) ||
      (notes != null && notes!.trim().isNotEmpty);

  int get activeFiltersCount {
    int count = 0;
    if (giverId != null) count++;
    if (drawerId != null) count++;
    if (paidToId != null) count++;
    if (imageFilter != CheckImageFilter.all) count++;
    if (minAmountCents != null) count++;
    if (maxAmountCents != null) count++;
    if (checkDateFrom != null || checkDateTo != null) count++;
    if (receivedDateFrom != null || receivedDateTo != null) count++;
    if (checkNumber != null && checkNumber!.trim().isNotEmpty) count++;
    if (notes != null && notes!.trim().isNotEmpty) count++;
    if (status != CheckStatusFilter.all) count++;
    return count;
  }

  CheckFilter copyWith({
    String? Function()? searchQuery,
    CheckStatusFilter? status,
    int? Function()? giverId,
    int? Function()? drawerId,
    int? Function()? paidToId,
    CheckImageFilter? imageFilter,
    int? Function()? minAmountCents,
    int? Function()? maxAmountCents,
    String? Function()? checkDateFrom,
    String? Function()? checkDateTo,
    String? Function()? receivedDateFrom,
    String? Function()? receivedDateTo,
    String? Function()? checkNumber,
    String? Function()? notes,
    CheckSortOption? sortOption,
  }) {
    return CheckFilter(
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
      status: status ?? this.status,
      giverId: giverId != null ? giverId() : this.giverId,
      drawerId: drawerId != null ? drawerId() : this.drawerId,
      paidToId: paidToId != null ? paidToId() : this.paidToId,
      imageFilter: imageFilter ?? this.imageFilter,
      minAmountCents: minAmountCents != null ? minAmountCents() : this.minAmountCents,
      maxAmountCents: maxAmountCents != null ? maxAmountCents() : this.maxAmountCents,
      checkDateFrom: checkDateFrom != null ? checkDateFrom() : this.checkDateFrom,
      checkDateTo: checkDateTo != null ? checkDateTo() : this.checkDateTo,
      receivedDateFrom: receivedDateFrom != null ? receivedDateFrom() : this.receivedDateFrom,
      receivedDateTo: receivedDateTo != null ? receivedDateTo() : this.receivedDateTo,
      checkNumber: checkNumber != null ? checkNumber() : this.checkNumber,
      notes: notes != null ? notes() : this.notes,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class CheckStats {
  final int totalCount;
  final int totalAmountCents;
  final int inStockCount;
  final int inStockAmountCents;
  final int usedCount;
  final int usedAmountCents;

  const CheckStats({
    this.totalCount = 0,
    this.totalAmountCents = 0,
    this.inStockCount = 0,
    this.inStockAmountCents = 0,
    this.usedCount = 0,
    this.usedAmountCents = 0,
  });
}

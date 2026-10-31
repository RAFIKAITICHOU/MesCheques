import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/check_filter.dart';
import '../models/person.dart';
import '../providers/locale_provider.dart';
import '../repositories/person_repository.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class FilterBottomSheet extends StatefulWidget {
  final CheckFilter currentFilter;
  final ValueChanged<CheckFilter> onApply;
  final VoidCallback onReset;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
    required this.onReset,
  });

  static Future<void> show(
    BuildContext context, {
    required CheckFilter currentFilter,
    required ValueChanged<CheckFilter> onApply,
    required VoidCallback onReset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => FilterBottomSheet(
        currentFilter: currentFilter,
        onApply: onApply,
        onReset: onReset,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final PersonRepository _personRepo = PersonRepository();
  List<Person> _allPersons = [];
  bool _loadingPersons = true;

  late CheckStatusFilter _status;
  CheckImageFilter _imageFilter = CheckImageFilter.all;
  int? _drawerId;
  int? _giverId;
  int? _paidToId;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _checkNumberController;
  late TextEditingController _notesController;
  String? _checkDateFrom;
  String? _checkDateTo;
  String? _receivedDateFrom;
  String? _receivedDateTo;

  @override
  void initState() {
    super.initState();
    final f = widget.currentFilter;
    _status = f.status;
    _imageFilter = f.imageFilter;
    _drawerId = f.drawerId;
    _giverId = f.giverId;
    _paidToId = f.paidToId;
    _minAmountController = TextEditingController(
      text: f.minAmountCents != null ? (f.minAmountCents! / 100.0).toStringAsFixed(2) : '',
    );
    _maxAmountController = TextEditingController(
      text: f.maxAmountCents != null ? (f.maxAmountCents! / 100.0).toStringAsFixed(2) : '',
    );
    _checkNumberController = TextEditingController(text: f.checkNumber ?? '');
    _notesController = TextEditingController(text: f.notes ?? '');
    _checkDateFrom = f.checkDateFrom;
    _checkDateTo = f.checkDateTo;
    _receivedDateFrom = f.receivedDateFrom;
    _receivedDateTo = f.receivedDateTo;

    _loadPersons();
  }

  Future<void> _loadPersons() async {
    final list = await _personRepo.getAll();
    if (mounted) {
      setState(() {
        _allPersons = list;
        _loadingPersons = false;
      });
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _checkNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required BuildContext context,
    required String? initialIso,
    required ValueChanged<String?> onPicked,
  }) async {
    final initialDate = Formatters.parseIsoDate(initialIso) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(Formatters.toIsoDate(picked));
    }
  }

  void _apply() {
    final minCents = Formatters.parseAmountToCents(_minAmountController.text);
    final maxCents = Formatters.parseAmountToCents(_maxAmountController.text);
    final chqNum = _checkNumberController.text.trim();
    final notes = _notesController.text.trim();

    final newFilter = widget.currentFilter.copyWith(
      status: _status,
      imageFilter: _imageFilter,
      drawerId: () => _drawerId,
      giverId: () => _giverId,
      paidToId: () => _paidToId,
      minAmountCents: () => minCents,
      maxAmountCents: () => maxCents,
      checkDateFrom: () => _checkDateFrom,
      checkDateTo: () => _checkDateTo,
      receivedDateFrom: () => _receivedDateFrom,
      receivedDateTo: () => _receivedDateTo,
      checkNumber: () => chqNum.isNotEmpty ? chqNum : null,
      notes: () => notes.isNotEmpty ? notes : null,
    );

    widget.onApply(newFilter);
    Navigator.pop(context);
  }

  void _reset() {
    widget.onReset();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final currencySymbol = isArabic ? 'د.م.' : 'DH';
    final localeCode = isArabic ? 'ar' : 'fr';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.filterSearch ?? 'Filtres de recherche',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Status Filter Segment
                  Text(
                    l10n?.statusLabel ?? 'Statut du chèque',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<CheckStatusFilter>(
                    segments: [
                      ButtonSegment(
                        value: CheckStatusFilter.all,
                        label: Text(l10n?.all ?? 'Tous'),
                        icon: const Icon(Icons.all_inclusive, size: 16),
                      ),
                      ButtonSegment(
                        value: CheckStatusFilter.stock,
                        label: Text(l10n?.inStock ?? 'En stock'),
                        icon: const Icon(Icons.inventory_2_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: CheckStatusFilter.used,
                        label: Text(l10n?.used ?? 'Utilisé'),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                      ),
                    ],
                    selected: {_status},
                    onSelectionChanged: (Set<CheckStatusFilter> newSelection) {
                      setState(() {
                        _status = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Images Filter
                  Text(
                    l10n?.imagesFilterLabel ?? 'Images',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<CheckImageFilter>(
                    segments: [
                      ButtonSegment(
                        value: CheckImageFilter.all,
                        label: Text(l10n?.allImages ?? 'Tous'),
                        icon: const Icon(Icons.photo_library_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: CheckImageFilter.withImage,
                        label: Text(l10n?.withImage ?? 'Avec image'),
                        icon: const Icon(Icons.image_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: CheckImageFilter.withoutImage,
                        label: Text(l10n?.withoutImage ?? 'Sans image'),
                        icon: const Icon(Icons.hide_image_outlined, size: 16),
                      ),
                    ],
                    selected: {_imageFilter},
                    onSelectionChanged: (Set<CheckImageFilter> newSelection) {
                      setState(() {
                        _imageFilter = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Drawer Filter Dropdown
                  Text(
                    l10n?.drawer ?? 'Titulaire du chèque',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    initialValue: _drawerId,
                    decoration: InputDecoration(
                      hintText: _loadingPersons ? '...' : (l10n?.allDrawers ?? 'Tous les titulaires'),
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n?.allDrawers ?? 'Tous les titulaires'),
                      ),
                      ..._allPersons.map(
                        (p) => DropdownMenuItem<int?>(
                          value: p.id,
                          child: Text(p.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _drawerId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Giver Filter Dropdown
                  Text(
                    l10n?.givenBy ?? 'Donné par',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    initialValue: _giverId,
                    decoration: InputDecoration(
                      hintText: _loadingPersons ? '...' : (l10n?.allGivers ?? 'Tous les émetteurs'),
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n?.allGivers ?? 'Tous les émetteurs'),
                      ),
                      ..._allPersons.map(
                        (p) => DropdownMenuItem<int?>(
                          value: p.id,
                          child: Text(p.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _giverId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Paid To Filter Dropdown
                  Text(
                    l10n?.givenTo ?? 'Donné à',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    initialValue: _paidToId,
                    decoration: InputDecoration(
                      hintText: _loadingPersons ? '...' : (l10n?.allReceivers ?? 'Tous les bénéficiaires'),
                      prefixIcon: const Icon(Icons.person_pin_outlined, size: 20),
                    ),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(l10n?.allReceivers ?? 'Tous les bénéficiaires'),
                      ),
                      ..._allPersons.map(
                        (p) => DropdownMenuItem<int?>(
                          value: p.id,
                          child: Text(p.name),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _paidToId = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Amounts range
                  Text(
                    '${l10n?.amount ?? "Montant"} ($currencySymbol)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n?.min ?? 'Min',
                            hintText: '0',
                            suffixText: currencySymbol,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxAmountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: l10n?.max ?? 'Max',
                            hintText: '10000',
                            suffixText: currencySymbol,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date du chèque range
                  Text(
                    l10n?.checkDate ?? 'Date du chèque',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateChip(
                          label: l10n?.from ?? 'Du',
                          isoDate: _checkDateFrom,
                          localeCode: localeCode,
                          onTap: () => _pickDate(
                            context: context,
                            initialIso: _checkDateFrom,
                            onPicked: (iso) => setState(() => _checkDateFrom = iso),
                          ),
                          onClear: () => setState(() => _checkDateFrom = null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateChip(
                          label: l10n?.to ?? 'Au',
                          isoDate: _checkDateTo,
                          localeCode: localeCode,
                          onTap: () => _pickDate(
                            context: context,
                            initialIso: _checkDateTo,
                            onPicked: (iso) => setState(() => _checkDateTo = iso),
                          ),
                          onClear: () => setState(() => _checkDateTo = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date de réception range
                  Text(
                    l10n?.receivedDate ?? 'Date de réception',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateChip(
                          label: l10n?.from ?? 'Du',
                          isoDate: _receivedDateFrom,
                          localeCode: localeCode,
                          onTap: () => _pickDate(
                            context: context,
                            initialIso: _receivedDateFrom,
                            onPicked: (iso) => setState(() => _receivedDateFrom = iso),
                          ),
                          onClear: () => setState(() => _receivedDateFrom = null),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateChip(
                          label: l10n?.to ?? 'Au',
                          isoDate: _receivedDateTo,
                          localeCode: localeCode,
                          onTap: () => _pickDate(
                            context: context,
                            initialIso: _receivedDateTo,
                            onPicked: (iso) => setState(() => _receivedDateTo = iso),
                          ),
                          onClear: () => setState(() => _receivedDateTo = null),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Check number and notes filter
                  TextFormField(
                    controller: _checkNumberController,
                    decoration: InputDecoration(
                      labelText: l10n?.checkNumber ?? 'Numéro de chèque',
                      hintText: l10n?.checkNumberExample ?? 'ex: CHQ-00125',
                      prefixIcon: const Icon(Icons.tag, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: l10n?.notes ?? 'Remarques',
                      hintText: l10n?.notesFilterHint ?? 'ex: matériel, avance...',
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: Text(l10n?.reset ?? 'Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apply,
                      child: Text(l10n?.apply ?? 'Appliquer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateChip({
    required String label,
    required String? isoDate,
    required String localeCode,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    final hasDate = isoDate != null && isoDate.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasDate ? AppColors.primary : AppColors.border,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: hasDate ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasDate ? Formatters.formatDate(isoDate, locale: localeCode) : label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
                  color: hasDate ? AppColors.textPrimary : AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasDate)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.cancel, size: 16, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}

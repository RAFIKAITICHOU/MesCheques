import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/check.dart';
import '../providers/checks_provider.dart';
import '../providers/locale_provider.dart';
import '../repositories/check_repository.dart';
import '../services/image_service.dart';
import '../utils/bidi_helper.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/drawer_field.dart';
import '../widgets/image_picker_row.dart';
import '../widgets/person_autocomplete.dart';

class EditCheckScreen extends StatefulWidget {
  final CheckWithNames check;

  const EditCheckScreen({
    super.key,
    required this.check,
  });

  @override
  State<EditCheckScreen> createState() => _EditCheckScreenState();
}

class _EditCheckScreenState extends State<EditCheckScreen> {
  final _formKey = GlobalKey<FormState>();
  final CheckRepository _checkRepo = CheckRepository();

  List<FormImageItem> _images = [];
  final Set<int> _initialImageIds = {};
  bool _loadingImages = true;

  late String _giverName;
  String? _drawerName;
  late bool _sameAsGiver;

  late TextEditingController _amountController;
  late TextEditingController _checkNumberController;
  late TextEditingController _notesController;

  late DateTime _checkDate;
  late DateTime _receivedDate;

  late bool _isPaymentSectionOpen;
  late String _paidToName;
  DateTime? _paidDate;

  bool _isSubmitting = false;
  String? _duplicateNumberError;

  @override
  void initState() {
    super.initState();
    final c = widget.check;
    _giverName = c.giverName;
    _drawerName = c.drawerName;
    _sameAsGiver = c.drawerId == c.giverId || (c.drawerId == null && c.drawerName == null);

    _amountController = TextEditingController(
      text: (c.amountCents / 100.0).toStringAsFixed(2),
    );
    _checkNumberController = TextEditingController(text: c.checkNumber);
    _notesController = TextEditingController(text: c.notes ?? '');

    _checkDate = Formatters.parseIsoDate(c.checkDate) ?? DateTime.now();
    _receivedDate = Formatters.parseIsoDate(c.receivedDate) ?? DateTime.now();

    _isPaymentSectionOpen = c.isUsed;
    _paidToName = c.paidToName ?? '';
    _paidDate = c.paidDate != null ? Formatters.parseIsoDate(c.paidDate) : null;

    _loadExistingImages();
  }

  Future<void> _loadExistingImages() async {
    if (widget.check.id == null) return;
    try {
      final imgs = await _checkRepo.getCheckImages(widget.check.id!);
      final loadedItems = <FormImageItem>[];
      for (final img in imgs) {
        if (img.id != null) _initialImageIds.add(img.id!);
        try {
          final thumb = await ImageService.instance.loadThumbnailBytes(img.fileName);
          loadedItems.add(FormImageItem.fromCheckImage(img, thumb));
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _images = loadedItems;
          _loadingImages = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingImages = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _checkNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required BuildContext context,
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final localeProvider = context.read<LocaleProvider>();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: localeProvider.locale,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _duplicateNumberError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_giverName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.giverRequired)),
      );
      return;
    }

    final hasPaidTo = _isPaymentSectionOpen && _paidToName.trim().isNotEmpty;
    if (_isPaymentSectionOpen) {
      if (hasPaidTo && _paidDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentDateRequired)),
        );
        return;
      }
      if (!hasPaidTo && _paidDate != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentReceiverRequired)),
        );
        return;
      }
      if (hasPaidTo && _paidDate != null && _paidDate!.isBefore(_receivedDate)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.paymentDateBeforeReception)),
        );
        return;
      }
    }

    final checkNumber = _checkNumberController.text.trim();
    final amountCents = Formatters.parseAmountToCents(_amountController.text);
    if (amountCents == null || amountCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidAmountShort)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final provider = context.read<ChecksProvider>();
      final isTaken = await _checkRepo.isCheckNumberTaken(checkNumber, excludeId: widget.check.id);
      if (!mounted) return;
      if (isTaken) {
        setState(() {
          _duplicateNumberError = l10n.duplicateNumberErrorOther;
          _isSubmitting = false;
        });
        return;
      }

      // Process new images
      final newProcessed = <ProcessedImageData>[];
      for (final img in _images) {
        if (img.isNew && img.rawBytes != null) {
          final saved = await ImageService.instance.processAndSaveNewImage(
            rawBytes: img.rawBytes!,
            kind: img.kind,
            sortOrder: img.sortOrder,
          );
          newProcessed.add(saved);
        }
      }

      // Identify deleted images
      final currentIds = _images.where((i) => i.id != null).map((i) => i.id!).toSet();
      final deleteIds = _initialImageIds.difference(currentIds).toList();

      // Existing images with updated order/kind
      final updateOrderKind = <({int id, int sortOrder, String kind})>[];
      for (int i = 0; i < _images.length; i++) {
        final img = _images[i];
        if (img.id != null) {
          updateOrderKind.add((id: img.id!, sortOrder: i, kind: img.kind));
        }
      }

      final resolvedDrawerName = _sameAsGiver
          ? _giverName.trim()
          : (_drawerName?.trim().isNotEmpty == true ? _drawerName!.trim() : null);

      await provider.updateCheck(
        id: widget.check.id!,
        checkNumber: checkNumber,
        amountCents: amountCents,
        checkDate: Formatters.toIsoDate(_checkDate),
        receivedDate: Formatters.toIsoDate(_receivedDate),
        giverName: _giverName.trim(),
        drawerName: resolvedDrawerName,
        paidToName: hasPaidTo ? _paidToName.trim() : null,
        paidDate: hasPaidTo && _paidDate != null ? Formatters.toIsoDate(_paidDate!) : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: widget.check.createdAt,
        newImages: newProcessed,
        deleteImageIds: deleteIds,
        updateImagesOrderKind: updateOrderKind,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.checkUpdated)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.updateError(e.toString()))),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editCheck),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // IMAGES SECTION
              if (_loadingImages)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else ...[
                ImagePickerRow(
                  images: _images,
                  onImagesChanged: (list) {
                    setState(() => _images = list);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // SECTION TITULAIRE DU CHÈQUE
              _buildSectionHeader(
                title: l10n.drawer,
                icon: Icons.account_balance_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              DrawerField(
                giverName: _giverName,
                initialDrawerName: _drawerName,
                initialSameAsGiver: _sameAsGiver,
                onChanged: (name, same) {
                  setState(() {
                    _drawerName = name;
                    _sameAsGiver = same;
                  });
                },
              ),
              const SizedBox(height: 20),

              // SECTION RÉCEPTION
              _buildSectionHeader(
                title: l10n.receptionSection,
                icon: Icons.input_rounded,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),

              // Giver Person Autocomplete
              PersonAutocomplete(
                label: l10n.givenBy,
                hint: l10n.giverHint,
                initialValue: _giverName,
                isRequired: true,
                onSelected: (val) {
                  setState(() => _giverName = val);
                },
                validator: (val) => Validators.validateRequired(
                  val,
                  l10n.giverLabel,
                  customError: l10n.requiredField(l10n.giverLabel),
                ),
              ),
              const SizedBox(height: 14),

              // Amount
              TextFormField(
                controller: _amountController,
                textDirection: TextDirection.ltr,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${l10n.amount} *',
                  hintText: l10n.amountExample,
                  suffixText: isArabic ? 'د.م.' : 'DH',
                  prefixIcon: const Icon(Icons.attach_money, size: 20, color: AppColors.textSecondary),
                ),
                validator: (val) => Validators.validateAmount(
                  val,
                  requiredError: l10n.requiredField(l10n.amount),
                  invalidError: l10n.invalidAmount,
                ),
              ),
              const SizedBox(height: 14),

              // Check Number (always LTR)
              TextFormField(
                controller: _checkNumberController,
                textDirection: TextDirection.ltr,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: '${l10n.checkNumber} *',
                  hintText: l10n.checkNumberExample,
                  errorText: _duplicateNumberError,
                  prefixIcon: const Icon(Icons.tag, size: 20, color: AppColors.textSecondary),
                ),
                validator: (val) => Validators.validateRequired(
                  val,
                  l10n.checkNumber,
                  customError: l10n.requiredField(l10n.checkNumber),
                ),
              ),
              const SizedBox(height: 14),

              // Check Date & Received Date Row
              Row(
                children: [
                  // Check Date
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _pickDate(
                        context: context,
                        initialDate: _checkDate,
                        onPicked: (d) => setState(() => _checkDate = d),
                      ),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '${l10n.checkDate} *',
                          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                        ),
                        child: Text(
                          Formatters.formatDate(Formatters.toIsoDate(_checkDate), isArabic: isArabic),
                          style: const TextStyle(fontSize: 14.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Received Date
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _pickDate(
                        context: context,
                        initialDate: _receivedDate,
                        onPicked: (d) => setState(() => _receivedDate = d),
                      ),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '${l10n.receivedDate} *',
                          prefixIcon: const Icon(Icons.event_available_outlined, size: 18),
                        ),
                        child: Text(
                          Formatters.formatDate(Formatters.toIsoDate(_receivedDate), isArabic: isArabic),
                          style: const TextStyle(fontSize: 14.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                textDirection: BidiHelper.detectDirection(
                  _notesController.text,
                  defaultDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
                decoration: InputDecoration(
                  labelText: l10n.notesOptional,
                  hintText: l10n.notesHint,
                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 20, color: AppColors.textSecondary),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),

              // SECTION PAIEMENT
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        l10n.paymentSectionOptional,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        _isPaymentSectionOpen ? l10n.checkDirectlyUsed : l10n.checkLeftInStock,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isPaymentSectionOpen ? AppColors.used : AppColors.textSecondary,
                          fontWeight: _isPaymentSectionOpen ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      activeTrackColor: AppColors.used,
                      value: _isPaymentSectionOpen,
                      onChanged: (val) {
                        setState(() {
                          _isPaymentSectionOpen = val;
                          if (val && _paidDate == null) {
                            _paidDate = DateTime.now();
                          }
                        });
                      },
                    ),
                    if (_isPaymentSectionOpen) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Paid To Person Autocomplete
                            PersonAutocomplete(
                              label: l10n.givenTo,
                              hint: l10n.receiverHint,
                              initialValue: _paidToName,
                              prefixIcon: Icons.person_pin_outlined,
                              isRequired: true,
                              onSelected: (val) {
                                setState(() => _paidToName = val);
                              },
                            ),
                            const SizedBox(height: 14),

                            // Payment Date
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _pickDate(
                                context: context,
                                initialDate: _paidDate ?? DateTime.now(),
                                onPicked: (d) => setState(() => _paidDate = d),
                              ),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: '${l10n.paymentDate} *',
                                  prefixIcon: const Icon(Icons.event_outlined, size: 20),
                                ),
                                child: Text(
                                  _paidDate != null
                                      ? Formatters.formatDate(Formatters.toIsoDate(_paidDate!), isArabic: isArabic)
                                      : l10n.chooseDate,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: _paidDate != null ? AppColors.textPrimary : AppColors.textHint,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // SUBMIT BUTTON
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.saveChanges),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

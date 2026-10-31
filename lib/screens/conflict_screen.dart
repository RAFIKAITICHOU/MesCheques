import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/merge_report.dart';
import '../providers/locale_provider.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class ConflictScreen extends StatefulWidget {
  final List<CheckConflict> conflicts;

  const ConflictScreen({
    super.key,
    required this.conflicts,
  });

  @override
  State<ConflictScreen> createState() => _ConflictScreenState();
}

class _ConflictScreenState extends State<ConflictScreen> {
  late Map<String, ConflictResolutionAction> _resolutions;

  @override
  void initState() {
    super.initState();
    _resolutions = {
      for (final c in widget.conflicts)
        c.incomingCheck.uuid: c.resolvedAction ?? ConflictResolutionAction.keepIncoming,
    };
  }

  void _submit() {
    for (final c in widget.conflicts) {
      c.resolvedAction = _resolutions[c.incomingCheck.uuid];
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.conflictsTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.dangerBg.withValues(alpha: 0.6),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.conflictsToResolve(widget.conflicts.length),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: widget.conflicts.length,
                itemBuilder: (context, index) {
                  final conflict = widget.conflicts[index];
                  final uuid = conflict.incomingCheck.uuid;
                  final currentAction = _resolutions[uuid] ?? ConflictResolutionAction.keepIncoming;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.danger, width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.dangerBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  conflict.checkNumber,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.conflictCardTitle(conflict.checkNumber),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.conflictCardDesc,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),

                          // Comparison table / cards
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Incoming Version A
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.incomingVersion,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Formatters.formatAmount(conflict.incomingCheck.amountCents, isArabic: isArabic),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${l10n.givenBy}: ${conflict.incomingGiverName}', style: const TextStyle(fontSize: 11)),
                                      if (conflict.incomingPaidToName != null)
                                        Text('${l10n.givenTo}: ${conflict.incomingPaidToName}', style: const TextStyle(fontSize: 11, color: AppColors.used)),
                                      const SizedBox(height: 2),
                                      Text(
                                        Formatters.formatDate(conflict.incomingCheck.checkDate, isArabic: isArabic),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Existing Version B
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.existingVersion,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        Formatters.formatAmount(conflict.existingCheck.amountCents, isArabic: isArabic),
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${l10n.givenBy}: ${conflict.existingGiverName}', style: const TextStyle(fontSize: 11)),
                                      if (conflict.existingPaidToName != null)
                                        Text('${l10n.givenTo}: ${conflict.existingPaidToName}', style: const TextStyle(fontSize: 11, color: AppColors.used)),
                                      const SizedBox(height: 2),
                                      Text(
                                        Formatters.formatDate(conflict.existingCheck.checkDate, isArabic: isArabic),
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 6),

                          // Choice options
                          RadioGroup<ConflictResolutionAction>(
                            groupValue: currentAction,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _resolutions[uuid] = val);
                              }
                            },
                            child: Column(
                              children: [
                                RadioListTile<ConflictResolutionAction>(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(l10n.keepIncomingOption, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  value: ConflictResolutionAction.keepIncoming,
                                  activeColor: AppColors.primary,
                                ),
                                RadioListTile<ConflictResolutionAction>(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(l10n.keepExistingOption, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  value: ConflictResolutionAction.keepExisting,
                                  activeColor: AppColors.primary,
                                ),
                                RadioListTile<ConflictResolutionAction>(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(l10n.keepBothOption, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  value: ConflictResolutionAction.keepBoth,
                                  activeColor: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(
                  l10n.validateConflicts,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

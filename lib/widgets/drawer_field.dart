import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import 'person_autocomplete.dart';

class DrawerField extends StatefulWidget {
  final String giverName;
  final String? initialDrawerName;
  final bool initialSameAsGiver;
  final void Function(String? drawerName, bool sameAsGiver) onChanged;

  const DrawerField({
    super.key,
    required this.giverName,
    this.initialDrawerName,
    this.initialSameAsGiver = true,
    required this.onChanged,
  });

  @override
  State<DrawerField> createState() => _DrawerFieldState();
}

class _DrawerFieldState extends State<DrawerField> {
  late bool _sameAsGiver;
  String? _customDrawerName;

  @override
  void initState() {
    super.initState();
    _sameAsGiver = widget.initialSameAsGiver;
    _customDrawerName = widget.initialDrawerName;
  }

  @override
  void didUpdateWidget(covariant DrawerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDrawerName != widget.initialDrawerName) {
      _customDrawerName = widget.initialDrawerName;
    }
    if (oldWidget.initialSameAsGiver != widget.initialSameAsGiver) {
      _sameAsGiver = widget.initialSameAsGiver;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentDisplayValue = _sameAsGiver ? widget.giverName : (_customDrawerName ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAutocomplete(
          label: l10n.drawer,
          hint: l10n.drawerHint,
          initialValue: currentDisplayValue,
          enabled: !_sameAsGiver,
          prefixIcon: Icons.account_balance_outlined,
          onSelected: (val) {
            _customDrawerName = val.trim();
            widget.onChanged(_customDrawerName, false);
          },
        ),
        const SizedBox(height: 4),
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _sameAsGiver = !_sameAsGiver;
            });
            final resolvedName = _sameAsGiver ? widget.giverName : _customDrawerName;
            widget.onChanged(resolvedName, _sameAsGiver);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _sameAsGiver,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      setState(() {
                        _sameAsGiver = val ?? false;
                      });
                      final resolvedName = _sameAsGiver ? widget.giverName : _customDrawerName;
                      widget.onChanged(resolvedName, _sameAsGiver);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.sameAsGiver,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

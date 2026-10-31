import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../repositories/person_repository.dart';
import '../utils/bidi_helper.dart';
import '../utils/constants.dart';

class PersonAutocomplete extends StatefulWidget {
  final String label;
  final String hint;
  final String? initialValue;
  final ValueChanged<String> onSelected;
  final String? Function(String?)? validator;
  final bool isRequired;
  final IconData prefixIcon;
  final bool enabled;

  const PersonAutocomplete({
    super.key,
    required this.label,
    required this.hint,
    this.initialValue,
    required this.onSelected,
    this.validator,
    this.isRequired = false,
    this.prefixIcon = Icons.person_outline,
    this.enabled = true,
  });

  @override
  State<PersonAutocomplete> createState() => _PersonAutocompleteState();
}

class _PersonAutocompleteState extends State<PersonAutocomplete> {
  final PersonRepository _repo = PersonRepository();
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void didUpdateWidget(covariant PersonAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && widget.initialValue != _controller.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.initialValue != _controller.text) {
          _controller.text = widget.initialValue ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleProvider>().isArabic;
    final addPrefix = isArabic ? '+ إضافة "' : '+ Ajouter "';

    return RawAutocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        final query = textEditingValue.text.trim();
        final matches = await _repo.search(query, limit: 6);
        final names = matches.map((p) => p.name).toList();

        if (query.isNotEmpty) {
          final exactMatch = names.any(
            (n) => n.trim().toLowerCase() == query.toLowerCase(),
          );
          if (!exactMatch) {
            names.add('$addPrefix$query"');
          }
        }
        return names;
      },
      onSelected: (String selection) {
        String finalName = selection;
        if (selection.startsWith(addPrefix) && selection.endsWith('"')) {
          finalName = selection.substring(addPrefix.length, selection.length - 1);
        } else if (selection.startsWith('+ Ajouter "') && selection.endsWith('"')) {
          finalName = selection.substring(11, selection.length - 1);
        }
        _controller.text = finalName;
        widget.onSelected(finalName);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        final direction = BidiHelper.detectDirection(
          textEditingController.text,
          defaultDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        );

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          enabled: widget.enabled,
          textDirection: direction,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: widget.isRequired ? '${widget.label} *' : widget.label,
            hintText: widget.hint,
            fillColor: widget.enabled ? Colors.white : AppColors.background,
            prefixIcon: Icon(widget.prefixIcon, size: 20, color: AppColors.textSecondary),
            suffixIcon: (widget.enabled && textEditingController.text.isNotEmpty)
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      textEditingController.clear();
                      widget.onSelected('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          validator: widget.validator,
          onChanged: (value) {
            widget.onSelected(value.trim());
            setState(() {});
          },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: AlignmentDirectional.topStart,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  final isAddOption = option.startsWith('+');
                  final optDirection = BidiHelper.detectDirection(
                    option,
                    defaultDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  );

                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            isAddOption ? Icons.person_add_alt_1 : Icons.person,
                            size: 18,
                            color: isAddOption ? AppColors.primary : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              textDirection: optDirection,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isAddOption ? FontWeight.w600 : FontWeight.w500,
                                color: isAddOption ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

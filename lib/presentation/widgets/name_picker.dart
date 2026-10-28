import 'package:flutter/material.dart';

/// Pick a name that exists in OBS (scene, source, input...). When OBS is not
/// connected there is nothing to list, so it falls back to typing.
class NamePickerField extends StatelessWidget {
  const NamePickerField({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.icon,
    this.helper,
    super.key,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onChanged;
  final IconData? icon;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return TextFormField(
        key: ValueKey('text-$label'),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
        onChanged: (v) => onChanged(v.trim()),
      );
    }
    // Keep a value that no longer exists in OBS visible, so the user sees it.
    final items = {...options, if (value?.isNotEmpty ?? false) value!};
    return DropdownButtonFormField<String>(
      key: ValueKey('drop-$label-$value-${options.length}'),
      initialValue: value?.isEmpty ?? true ? null : value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      items: [
        for (final item in items)
          DropdownMenuItem(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

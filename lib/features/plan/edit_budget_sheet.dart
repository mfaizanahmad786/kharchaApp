import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/icon_color_picker.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

class EditBudgetSheet extends ConsumerStatefulWidget {
  const EditBudgetSheet({super.key, this.existing});

  final Budget? existing;

  static Future<void> show(BuildContext context, {Budget? existing}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditBudgetSheet(existing: existing),
      );

  @override
  ConsumerState<EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends ConsumerState<EditBudgetSheet> {
  late final TextEditingController _name;
  late final TextEditingController _limit;
  late String _icon;
  late int _color;
  late bool _alerts;
  late double _threshold;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _name = TextEditingController(text: b?.name ?? '');
    _limit = TextEditingController(
        text: b == null ? '' : (b.limit / 100).toStringAsFixed(0));
    _icon = b?.iconName ?? 'wallet';
    _color = b?.colorValue ?? AppColors.purple.toARGB32();
    _alerts = b?.alertsEnabled ?? true;
    _threshold = b?.alertThreshold ?? 0.8;
    _categoryId = b?.categoryId;
  }

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final limit = Money.parse(_limit.text) ?? 0;
    if (name.isEmpty || limit <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Give the budget a name and a limit above zero.'),
        ));
      return;
    }

    final actions = ref.read(actionsProvider);
    final existing = widget.existing;
    await actions.upsertBudget(Budget(
      id: existing?.id ?? actions.repo.newId(),
      name: name,
      iconName: _icon,
      colorValue: _color,
      limit: limit,
      categoryId: _categoryId,
      alertsEnabled: _alerts,
      alertThreshold: _threshold,
      sortOrder: existing?.sortOrder ?? 99,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final b = widget.existing;
    if (b == null) return;
    await ref.read(actionsProvider).deleteBudget(b.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref.watch(categoriesProvider(TxType.expense)).value ?? const <Category>[];

    return EditorSheetShell(
      title: widget.existing == null ? 'New Budget' : 'Edit Budget',
      accent: Color(_color),
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      saveLabel: widget.existing == null ? 'Create budget' : 'Save changes',
      children: [
        EditorField(label: 'Name', controller: _name, hint: 'Groceries'),
        const SizedBox(height: 18),
        EditorField(
          label: 'Monthly limit',
          controller: _limit,
          hint: '0',
          prefix: '$kCurrencySymbol ',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 18),
        const _Label('Applies to'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _CategoryChip(
              label: 'All spending',
              icon: Icons.all_inclusive_rounded,
              color: AppColors.purple,
              selected: _categoryId == null,
              onTap: () => setState(() => _categoryId = null),
            ),
            for (final c in categories)
              _CategoryChip(
                label: c.name,
                icon: c.icon,
                color: c.color,
                selected: _categoryId == c.id,
                onTap: () => setState(() => _categoryId = c.id),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 10, 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _alerts,
                activeTrackColor: Color(_color),
                onChanged: (v) => setState(() => _alerts = v),
                title: const Text(
                  'Warn me before I hit the limit',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              if (_alerts) ...[
                Row(
                  children: [
                    const Text(
                      'Warn at',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    Expanded(
                      child: Slider.adaptive(
                        value: _threshold,
                        min: 0.5,
                        max: 0.95,
                        divisions: 9,
                        activeColor: Color(_color),
                        label: '${(_threshold * 100).round()}%',
                        onChanged: (v) => setState(() => _threshold = v),
                      ),
                    ),
                    Text(
                      '${(_threshold * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _Label('Icon'),
        const SizedBox(height: 8),
        IconPickerRow(
          selected: _icon,
          color: Color(_color),
          onSelect: (v) => setState(() => _icon = v),
        ),
        const SizedBox(height: 18),
        const _Label('Colour'),
        const SizedBox(height: 8),
        ColorPickerRow(
          selected: _color,
          onSelect: (v) => setState(() => _color = v),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
      );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/icon_color_picker.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

class EditGoalSheet extends ConsumerStatefulWidget {
  const EditGoalSheet({super.key, this.existing});

  final Goal? existing;

  static Future<void> show(BuildContext context, {Goal? existing}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditGoalSheet(existing: existing),
      );

  @override
  ConsumerState<EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends ConsumerState<EditGoalSheet> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _saved;
  late String _icon;
  late int _color;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _name = TextEditingController(text: g?.name ?? '');
    _target = TextEditingController(
        text: g == null ? '' : (g.target / 100).toStringAsFixed(0));
    _saved = TextEditingController(
        text: g == null ? '0' : (g.saved / 100).toStringAsFixed(0));
    _icon = g?.iconName ?? 'savings';
    _color = g?.colorValue ?? AppColors.purple.toARGB32();
    _deadline = g?.deadline;
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime(now.year + 1, now.month),
      firstDate: now,
      lastDate: DateTime(now.year + 30),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Color(_color)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final target = Money.parse(_target.text) ?? 0;
    final saved = Money.parse(_saved.text) ?? 0;

    if (name.isEmpty || target <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Give the goal a name and a target above zero.'),
        ));
      return;
    }

    final actions = ref.read(actionsProvider);
    final existing = widget.existing;
    final goal = Goal(
      id: existing?.id ?? actions.repo.newId(),
      name: name,
      iconName: _icon,
      colorValue: _color,
      target: target,
      saved: saved,
      createdAt: existing?.createdAt ?? DateTime.now(),
      deadline: _deadline,
    );
    await actions.upsertGoal(goal);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final g = widget.existing;
    if (g == null) return;
    await ref.read(actionsProvider).deleteGoal(g.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return EditorSheetShell(
      title: widget.existing == null ? 'New Goal' : 'Edit Goal',
      accent: Color(_color),
      onSave: _save,
      onDelete: widget.existing == null ? null : _delete,
      saveLabel: widget.existing == null ? 'Create goal' : 'Save changes',
      children: [
        EditorField(label: 'Name', controller: _name, hint: 'House by the Sea'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: EditorField(
                label: 'Target',
                controller: _target,
                hint: '0',
                prefix: '$kCurrencySymbol ',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: EditorField(
                label: 'Already saved',
                controller: _saved,
                hint: '0',
                prefix: '$kCurrencySymbol ',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Deadline',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickDeadline,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
                color: AppColors.surface,
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, size: 19, color: AppColors.inkSoft),
                  const SizedBox(width: 10),
                  Text(
                    _deadline == null ? 'No deadline' : AppDate.shortDay(_deadline!),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.inkFaint),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Icon',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        IconPickerRow(
          selected: _icon,
          color: Color(_color),
          onSelect: (v) => setState(() => _icon = v),
        ),
        const SizedBox(height: 18),
        const Text(
          'Colour',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 8),
        ColorPickerRow(
          selected: _color,
          onSelect: (v) => setState(() => _color = v),
        ),
      ],
    );
  }
}

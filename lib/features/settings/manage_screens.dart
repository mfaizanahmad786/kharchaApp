import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/amount_text.dart';
import '../../core/widgets/glyph_tile.dart';
import '../../core/widgets/icon_color_picker.dart';
import '../../core/widgets/pills.dart';
import '../../core/widgets/soft_card.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';

/// Add, rename, recolour and delete categories.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const CategoriesScreen()));

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  TxType _type = TxType.expense;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider(_type)).value ?? const <Category>[];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Categories'),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.ink),
            onPressed: () => _edit(null),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: SegmentedToggle(
              labels: const ['Expense', 'Income'],
              index: _type.isExpense ? 0 : 1,
              height: 46,
              onChanged: (i) =>
                  setState(() => _type = i == 0 ? TxType.expense : TxType.income),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = categories[i];
                return SoftCard(
                  radius: 18,
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                  shadows: AppColors.softShadow,
                  onTap: () => _edit(c),
                  child: Row(
                    children: [
                      GlyphTile(icon: c.icon, color: c.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.inkFaint),
                        onPressed: () => _delete(c),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(Category c) async {
    final removed = await ref.read(actionsProvider).deleteCategory(c.id);
    if (!mounted) return;
    if (!removed) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('${c.name} still has transactions, so it was kept.'),
        ));
    }
  }

  Future<void> _edit(Category? existing) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _CategoryEditor(existing: existing, type: _type),
      );
}

class _CategoryEditor extends ConsumerStatefulWidget {
  const _CategoryEditor({required this.existing, required this.type});

  final Category? existing;
  final TxType type;

  @override
  ConsumerState<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends ConsumerState<_CategoryEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late String _icon = widget.existing?.iconName ?? 'other';
  late int _color = widget.existing?.colorValue ?? AppColors.purple.toARGB32();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final actions = ref.read(actionsProvider);
    await actions.upsertCategory(Category(
      id: widget.existing?.id ?? actions.repo.newId(),
      name: name,
      iconName: _icon,
      colorValue: _color,
      type: widget.existing?.type ?? widget.type,
      sortOrder: widget.existing?.sortOrder ?? 99,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return EditorSheetShell(
      title: widget.existing == null ? 'New Category' : 'Edit Category',
      accent: Color(_color),
      onSave: _save,
      children: [
        EditorField(label: 'Name', controller: _name, hint: 'Groceries'),
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

/// Add, rename and remove accounts, and set their opening balance.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const AccountsScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Accounts'),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.ink),
            onPressed: () => _edit(context, null),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: accounts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final a = accounts[i];
          return SoftCard(
            radius: 18,
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            shadows: AppColors.softShadow,
            onTap: () => _edit(context, a),
            child: Row(
              children: [
                GlyphTile(icon: a.icon, color: a.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text(
                            'Opening ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkFaint,
                            ),
                          ),
                          AmountText(
                            a.openingBalance,
                            showDecimals: false,
                            color: AppColors.inkFaint,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.inkFaint),
                  onPressed: accounts.length <= 1
                      ? null
                      : () => ref.read(actionsProvider).deleteAccount(a.id),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, Account? existing) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _AccountEditor(existing: existing),
      );
}

class _AccountEditor extends ConsumerStatefulWidget {
  const _AccountEditor({required this.existing});

  final Account? existing;

  @override
  ConsumerState<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<_AccountEditor> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _opening = TextEditingController(
    text: widget.existing == null
        ? '0'
        : (widget.existing!.openingBalance / 100).toStringAsFixed(0),
  );
  late String _icon = widget.existing?.iconName ?? 'wallet';
  late int _color = widget.existing?.colorValue ?? AppColors.purple.toARGB32();

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final actions = ref.read(actionsProvider);
    await actions.upsertAccount(Account(
      id: widget.existing?.id ?? actions.repo.newId(),
      name: name,
      iconName: _icon,
      colorValue: _color,
      openingBalance: Money.parse(_opening.text) ?? 0,
      sortOrder: widget.existing?.sortOrder ?? 99,
    ));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return EditorSheetShell(
      title: widget.existing == null ? 'New Account' : 'Edit Account',
      accent: Color(_color),
      onSave: _save,
      children: [
        EditorField(label: 'Name', controller: _name, hint: 'Cash'),
        const SizedBox(height: 18),
        EditorField(
          label: 'Opening balance',
          controller: _opening,
          hint: '0',
          prefix: '$kCurrencySymbol ',
          keyboardType: TextInputType.number,
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

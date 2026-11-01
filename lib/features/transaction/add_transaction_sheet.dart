import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/glyph_tile.dart';
import '../../core/widgets/pills.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import 'widgets/amount_keypad.dart';
import '../../core/theme/app_palette.dart';

/// Add, or edit, a single transaction. Opened by the purple + in the nav bar.
class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key, this.existing});

  final Txn? existing;

  static Future<bool?> show(BuildContext context, {Txn? existing}) =>
      showModalBottomSheet<bool>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AddTransactionSheet(existing: existing),
      );

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TxType _type;
  late DateTime _date;
  late String _input;
  late final TextEditingController _note;

  String? _categoryId;
  String? _accountId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? TxType.expense;
    _date = e?.date ?? DateTime.now();
    _categoryId = e?.categoryId;
    _accountId = e?.accountId;
    _note = TextEditingController(text: e?.note ?? '');
    _input = e == null
        ? '0'
        : (e.amount % 100 == 0
              ? (e.amount ~/ 100).toString()
              : (e.amount / 100).toStringAsFixed(2));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _paisa => Money.parse(_input) ?? 0;

  /// entering-data.md asks for dynamic validation. The amount is the only
  /// field a person can leave unusable: category and account are preselected.
  bool get _canSave => _paisa > 0 && !_saving;

  bool get _dirty => _paisa > 0 || _note.text.trim().isNotEmpty;
  bool get _isEdit => widget.existing != null;

  void _digit(String d) {
    setState(() {
      if (_input == '0') {
        _input = d;
      } else {
        final dot = _input.indexOf('.');
        // Never allow more than two decimal places.
        if (dot != -1 && _input.length - dot > 2) return;
        if (_input.replaceAll('.', '').length >= 11) return;
        _input += d;
      }
    });
  }

  void _decimal() {
    if (_input.contains('.')) return;
    setState(() => _input += '.');
  }

  void _backspace() {
    setState(() {
      _input = _input.length <= 1
          ? '0'
          : _input.substring(0, _input.length - 1);
      if (_input.endsWith('.')) _input = _input.substring(0, _input.length - 1);
      if (_input.isEmpty) _input = '0';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: true,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.brand),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  /// modality.md: a modal needs an obvious way out — but not one that throws
  /// away what someone just typed without asking.
  Future<bool> _confirmDiscard() async {
    if (!_dirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this transaction?'),
        content: const Text('What you have entered will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep editing',
              style: TextStyle(color: ctx.palette.inkSoft),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Discard',
              style: TextStyle(color: ctx.palette.expense),
            ),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _close() async {
    if (await _confirmDiscard() && mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final amount = _paisa;
    if (amount <= 0) {
      _complain('Enter an amount greater than zero.');
      return;
    }
    if (_categoryId == null) {
      _complain('Pick a category.');
      return;
    }
    if (_accountId == null) {
      _complain('Pick an account.');
      return;
    }

    setState(() => _saving = true);
    final actions = ref.read(actionsProvider);
    final note = _note.text.trim();

    if (_isEdit) {
      await actions.updateTransaction(
        widget.existing!.copyWith(
          amount: amount,
          type: _type,
          categoryId: _categoryId,
          accountId: _accountId,
          date: _date,
          note: note,
        ),
      );
    } else {
      await actions.addTransaction(
        amount: amount,
        type: _type,
        categoryId: _categoryId!,
        accountId: _accountId!,
        date: _date,
        note: note,
      );
    }

    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
  }

  void _complain(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final categories = ref.watch(categoriesProvider(_type)).value ?? const [];
    final accounts = ref.watch(accountsProvider).value ?? const [];

    // Default the pickers once the data arrives.
    if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }
    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }

    final accent = _type.isIncome ? p.income : AppColors.brand;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmDiscard() && mounted) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: p.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
                child: Row(
                  children: [
                    Text(
                      _isEdit ? 'Edit Transaction' : 'Add Transaction',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _close,
                      tooltip: 'Close',
                      icon: const Icon(Icons.close_rounded),
                      color: p.inkSoft,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SegmentedToggle(
                        labels: const ['Out', 'In'],
                        index: _type.isExpense ? 0 : 1,
                        onChanged: (i) => setState(() {
                          _type = i == 0 ? TxType.expense : TxType.income;
                          _categoryId = null;
                        }),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: _AmountDisplay(input: _input, accent: accent),
                      ),
                      const SizedBox(height: 22),
                      const _Label('Category'),
                      const SizedBox(height: 10),
                      _CategoryPicker(
                        categories: categories,
                        selectedId: _categoryId,
                        onSelect: (id) => setState(() => _categoryId = id),
                      ),
                      const SizedBox(height: 18),
                      const _Label('Account'),
                      const SizedBox(height: 10),
                      _AccountPicker(
                        accounts: accounts,
                        selectedId: _accountId,
                        onSelect: (id) => setState(() => _accountId = id),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _FieldShell(
                              label: 'Date',
                              onTap: _pickDate,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 15,
                                    color: p.inkSoft,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppDate.shortDay(_date),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FieldShell(
                              label: 'Note',
                              child: TextField(
                                controller: _note,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: 'Optional',
                                  contentPadding: EdgeInsets.zero,
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: p.inkFaint,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AmountKeypad(
                        onDigit: _digit,
                        onDecimal: _decimal,
                        onBackspace: _backspace,
                        onClear: () => setState(() => _input = '0'),
                      ),
                    ],
                  ),
                ),
              ),

              // Pinned footer: the save action must never scroll out of reach.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _canSave ? _save : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      disabledBackgroundColor: accent.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Save changes' : 'Add transaction',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  const _AmountDisplay({required this.input, required this.accent});

  final String input;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dot = input.indexOf('.');
    final whole = dot == -1 ? input : input.substring(0, dot);
    final frac = dot == -1 ? '' : input.substring(dot);
    final grouped = Money.groupDigits(whole);

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 4),
            child: Text(
              kCurrencySymbol,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                // At 70% alpha this measured 2.38:1 against a 3:1
                // requirement; at full strength it is 3.40:1.
                color: accent,
              ),
            ),
          ),
          Text(
            grouped,
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.6,
              height: 1.1,
            ),
          ),
          if (frac.isNotEmpty)
            Text(
              frac,
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.6,
                height: 1.1,
                color: p.ink.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = categories[i];
          final selected = c.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(c.id),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  // One accent for the selection and one neutral for
                  // everything else: fourteen category hues at once made the
                  // row read as decoration rather than as a choice.
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brand : p.track,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      c.icon,
                      size: 23,
                      color: selected ? Colors.white : p.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? p.ink : p.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AccountPicker extends StatelessWidget {
  const _AccountPicker({
    required this.accounts,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Account> accounts;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        for (final a in accounts) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelect(a.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 10,
                ),
                // Selection lifts the card instead of outlining it. In the
                // dark appearance a drop shadow does nothing, so the lift is
                // carried by lightness there, and the label's weight backs
                // both up so the state never rests on depth alone.
                decoration: BoxDecoration(
                  color: a.id == selectedId && p.isDark
                      ? p.surfaceMuted
                      : p.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: a.id == selectedId && p.isDark
                        ? p.borderSoft
                        : p.border,
                  ),
                  boxShadow: a.id == selectedId && !p.isDark
                      ? const [
                          BoxShadow(
                            color: Color(0x1F101828),
                            blurRadius: 14,
                            offset: Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlyphTile(
                      icon: a.icon,
                      color: a.id == selectedId ? AppColors.brand : p.inkSoft,
                      size: 26,
                      radius: 8,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: a.id == selectedId
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: a.id == selectedId ? p.ink : p.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (a != accounts.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.label, required this.child, this.onTap});

  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: p.softShadow,
            color: p.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.inkFaint,
                ),
              ),
              const SizedBox(height: 5),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: context.palette.inkSoft,
    ),
  );
}

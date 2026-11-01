import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/security_controller.dart';
import 'lock_screen.dart';
import 'pin_pad.dart';
import '../../core/theme/app_palette.dart';

enum _Stage { current, choose, confirm }

/// Sets a new PIN, or changes an existing one (which asks for the old PIN first).
class PinSetupSheet extends ConsumerStatefulWidget {
  const PinSetupSheet({super.key, required this.requireCurrent});

  final bool requireCurrent;

  static Future<bool?> show(
    BuildContext context, {
    required bool requireCurrent,
  }) => showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PinSetupSheet(requireCurrent: requireCurrent),
  );

  @override
  ConsumerState<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends ConsumerState<PinSetupSheet> {
  late _Stage _stage = widget.requireCurrent ? _Stage.current : _Stage.choose;
  String _entry = '';
  String _first = '';
  String? _error;

  String get _title => switch (_stage) {
    _Stage.current => 'Enter your current PIN',
    _Stage.choose => 'Choose a $kPinLength-digit PIN',
    _Stage.confirm => 'Confirm your PIN',
  };

  Future<void> _onDigit(String d) async {
    if (_entry.length >= kPinLength) return;
    setState(() {
      _entry += d;
      _error = null;
    });
    if (_entry.length == kPinLength) await _advance();
  }

  Future<void> _advance() async {
    final controller = ref.read(securityProvider.notifier);

    switch (_stage) {
      case _Stage.current:
        final ok = await controller.verifyPin(_entry);
        if (!mounted) return;
        setState(() {
          _entry = '';
          if (ok) {
            _stage = _Stage.choose;
          } else {
            _error = 'That PIN is not right.';
            HapticFeedback.heavyImpact();
          }
        });

      case _Stage.choose:
        setState(() {
          _first = _entry;
          _entry = '';
          _stage = _Stage.confirm;
        });

      case _Stage.confirm:
        if (_entry == _first) {
          await controller.setPin(_entry);
          if (!mounted) return;
          HapticFeedback.mediumImpact();
          Navigator.of(context).pop(true);
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _entry = '';
            _first = '';
            _stage = _Stage.choose;
            _error = 'Those did not match. Try again.';
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.scaffold,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                    color: p.inkSoft,
                  ),
                ],
              ),
            ),
            Text(_title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              child: Text(
                _error ?? 'Used every time Kharcha opens.',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _error == null ? p.inkSoft : p.expense,
                ),
              ),
            ),
            const SizedBox(height: 24),
            PinDots(
              length: kPinLength,
              filled: _entry.length,
              error: _error != null,
            ),
            const SizedBox(height: 26),
            PinPad(
              onDigit: _onDigit,
              onBackspace: () => setState(() {
                if (_entry.isNotEmpty) {
                  _entry = _entry.substring(0, _entry.length - 1);
                }
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

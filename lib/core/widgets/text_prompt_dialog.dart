import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// A one-field dialog that owns its own controller.
///
/// Creating a `TextEditingController` beside `showDialog` and disposing it as
/// soon as the future resolves is a trap: the route is still playing its exit
/// animation, the `TextField` rebuilds once more, and it throws
/// "A TextEditingController was used after being disposed". Holding the
/// controller in this widget's State ties its lifetime to the dialog itself.
class TextPromptDialog extends StatefulWidget {
  const TextPromptDialog({
    super.key,
    required this.title,
    this.initialText = '',
    this.hintText,
    this.prefixText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.confirmLabel = 'Save',
  });

  final String title;
  final String initialText;
  final String? hintText;
  final String? prefixText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String confirmLabel;

  /// Resolves to the trimmed text, or null if the person backed out.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    String initialText = '',
    String? hintText,
    String? prefixText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String confirmLabel = 'Save',
  }) {
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => TextPromptDialog(
        title: title,
        initialText: initialText,
        hintText: hintText,
        prefixText: prefixText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        confirmLabel: confirmLabel,
      ),
    );
  }

  @override
  State<TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_controller.text.trim());

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixText: widget.prefixText,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: p.inkSoft)),
        ),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

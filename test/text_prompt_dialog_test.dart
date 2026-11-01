import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kharcha/core/theme/app_theme.dart';
import 'package:kharcha/core/widgets/text_prompt_dialog.dart';

import 'test_fonts.dart';

/// Regression cover for a crash in the goal "Add money" and Settings "Your
/// name" dialogs: both built a TextEditingController beside showDialog and
/// disposed it the moment the future resolved. The route was still playing
/// its exit animation, the TextField rebuilt once more, and it threw
/// "A TextEditingController was used after being disposed" — intermittently,
/// because it depended on where the animation had got to.
void main() {
  setUpAll(loadAppFonts);

  Future<String?> openAndTap(WidgetTester tester, String buttonLabel) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await TextPromptDialog.show(
                    context,
                    title: 'Add to House by the Sea',
                    hintText: '0',
                    confirmLabel: 'Add',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), ' 250 ');
    await tester.pump();
    await tester.tap(find.text(buttonLabel));

    // Pumping all the way through the exit transition is the point: the old
    // code threw here, not at the moment of the tap.
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('survives the dialog exit animation and returns the text', (
    tester,
  ) async {
    final value = await openAndTap(tester, 'Add');
    expect(value, '250', reason: 'the result should come back trimmed');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling returns null and throws nothing', (tester) async {
    final value = await openAndTap(tester, 'Cancel');
    expect(value, isNull);
    expect(tester.takeException(), isNull);
  });
}

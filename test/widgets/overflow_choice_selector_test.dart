import 'package:beltech/core/widgets/overflow_choice_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: SizedBox(width: 320, child: child)));

  testWidgets('renders chips when options fit on one line', (tester) async {
    await tester.pumpWidget(wrap(
      OverflowChoiceSelector<String>(
        options: const ['A', 'B', 'C'],
        selected: 'B',
        labelFor: (o) => o,
        onChanged: (_) {},
      ),
    ));

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down_rounded), findsNothing);
  });

  testWidgets('shows dropdown when options overflow one line', (tester) async {
    const many = [
      'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 'Eta', 'Theta',
      'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 'Xi', 'Omicron', 'Pi', 'Rho',
      'Sigma', 'Tau', 'Upsilon', 'Phi', 'Chi', 'Psi', 'Omega',
    ];
    await tester.pumpWidget(wrap(
      OverflowChoiceSelector<String>(
        options: many,
        selected: 'Zeta',
        labelFor: (o) => o,
        onChanged: (_) {},
      ),
    ));

    // Overflow → dropdown trigger with the selected value + chevron.
    expect(find.text('Zeta'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);

    // Open the menu and verify the selected item is check-marked.
    await tester.tap(find.byIcon(Icons.arrow_drop_down_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('selecting from the dropdown invokes onChanged', (tester) async {
    const many = [
      'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 'Eta', 'Theta',
      'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 'Xi', 'Omicron', 'Pi', 'Rho',
      'Sigma', 'Tau', 'Upsilon', 'Phi', 'Chi', 'Psi', 'Omega',
    ];
    String? picked;
    await tester.pumpWidget(wrap(
      OverflowChoiceSelector<String>(
        options: many,
        selected: null,
        labelFor: (o) => o,
        onChanged: (o) => picked = o,
        hint: 'Pick one',
      ),
    ));

    await tester.tap(find.byIcon(Icons.arrow_drop_down_rounded));
    await tester.pumpAndSettle();
    // The 24-item menu overflows the screen — scroll the popup to Omega.
    await tester.scrollUntilVisible(
      find.text('Omega').last,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Omega').last);
    await tester.pumpAndSettle();

    expect(picked, 'Omega');
  });
}

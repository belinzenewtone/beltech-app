import 'package:beltech/features/assistant/presentation/widgets/assistant_action_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('AssistantSendButton exposes accessibility labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(AssistantSendButton(loading: false, onTap: () {})),
    );
    await tester.pump();

    expect(find.byTooltip('Send message'), findsOneWidget);
    expect(find.bySemanticsLabel('Send message'), findsOneWidget);
  });

  testWidgets('AssistantSendButton loading state updates label', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(AssistantSendButton(loading: true, onTap: () {})),
    );
    await tester.pump();

    expect(find.byTooltip('Sending message'), findsOneWidget);
    expect(find.bySemanticsLabel('Sending message'), findsOneWidget);
  });

  testWidgets('AssistantPillButton exposes tooltip text', (tester) async {
    await tester.pumpWidget(
      wrap(
        AssistantPillButton(
          icon: Icons.chat_outlined,
          label: 'New chat',
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('New chat'), findsOneWidget);
  });
}

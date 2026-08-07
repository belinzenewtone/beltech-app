import 'package:beltech/core/widgets/tool_shortcut_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tool hub grid height matches content (no dead space)',
      (tester) async {
    // Six shortcuts like the Profile Tool Hub.
    const shortcuts = [
      ToolShortcut(
        label: 'A', icon: Icons.add, color: Colors.red, routeName: 'x'),
      ToolShortcut(
        label: 'B', icon: Icons.add, color: Colors.red, routeName: 'x'),
      ToolShortcut(
        label: 'C', icon: Icons.add, color: Colors.red, routeName: 'x'),
      ToolShortcut(
        label: 'D', icon: Icons.add, color: Colors.red, routeName: 'x'),
      ToolShortcut(
        label: 'E', icon: Icons.add, color: Colors.red, routeName: 'x'),
      ToolShortcut(
        label: 'F', icon: Icons.add, color: Colors.red, routeName: 'x'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    color: Colors.grey,
                    padding: const EdgeInsets.all(12),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('TOOL HUB'),
                        SizedBox(height: 10),
                        ToolShortcutGrid(
                          shortcuts: shortcuts,
                          childAspectRatio: 1.5,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final gridSize = tester.getSize(find.byType(ToolShortcutGrid));
    final cardSize = tester.getSize(find.byType(Container).first);

    // Print diagnostics for the actual measured heights.
    debugPrint('grid height: ${gridSize.height}');
    debugPrint('card height: ${cardSize.height}');

    // Grid is 3 columns × 2 rows. mainAxisExtent = max(77, tileW/1.5).
    // With width 360-24=336: tileW=(336-20)/3=105.3; aspectH=70.2 → extent 77.
    // Expected grid height = 2*77 + 10 = 164.
    expect(gridSize.height, closeTo(164, 1));
  });
}

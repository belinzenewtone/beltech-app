import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_security_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrapLightTheme(Widget child) {
  return MaterialApp(
    theme: ThemeData.light(),
    home: Scaffold(body: child),
  );
}

void main() {
  group('Style token regressions', () {
    testWidgets('AppButton primary uses shared accent in light mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapLightTheme(
          AppButton(
            label: 'Save',
            onPressed: () {},
            variant: AppButtonVariant.primary,
          ),
        ),
      );

      final filledButton = tester.widget<FilledButton>(
        find.byType(FilledButton),
      );
      final backgroundColor = filledButton.style?.backgroundColor?.resolve(
        <WidgetState>{},
      );

      expect(backgroundColor, AppColors.accent);
    });

    testWidgets('Profile security InkWell radii follow app card radius', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapLightTheme(
          const ProfileSecuritySection(
            onChangePassword: _noop,
            onSignOut: _noop,
            signingOut: false,
          ),
        ),
      );

      final inkwells = tester.widgetList<InkWell>(find.byType(InkWell));
      const radius = Radius.circular(AppRadius.xl);

      expect(
        inkwells.any(
          (inkWell) =>
              inkWell.borderRadius == const BorderRadius.vertical(top: radius),
        ),
        isTrue,
      );
      expect(
        inkwells.any(
          (inkWell) =>
              inkWell.borderRadius ==
              const BorderRadius.vertical(bottom: radius),
        ),
        isTrue,
      );
    });
  });
}

void _noop() {}

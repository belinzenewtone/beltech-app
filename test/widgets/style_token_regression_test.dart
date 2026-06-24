import 'package:beltech/core/theme/app_colors.dart';
import 'package:beltech/core/theme/app_radius.dart';
import 'package:beltech/core/theme/glass_styles.dart';
import 'package:beltech/core/widgets/app_button.dart';
import 'package:beltech/features/profile/domain/entities/user_profile.dart';
import 'package:beltech/features/profile/presentation/widgets/profile_content_section.dart';
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

    test('GlassStyles card radius matches app radius token', () {
      expect(GlassStyles.borderRadius, AppRadius.xl);
    });

    testWidgets('Profile security InkWell radii follow glass card radius', (
      tester,
    ) async {
      const profile = UserProfile(
        name: 'Test User',
        email: 'test@example.com',
        phone: '+123456789',
        memberSinceLabel: 'Jan 2024',
        verified: true,
      );

      await tester.pumpWidget(
        _wrapLightTheme(
          const ProfileContentSection(
            profile: profile,
            onEdit: _noop,
            onOpenSettings: _noop,
            onChangePassword: _noop,
            onAvatarCameraTap: _noop,
            showSignOut: true,
            signingOut: false,
            onSignOut: _noop,
          ),
        ),
      );

      final inkwells = tester.widgetList<InkWell>(find.byType(InkWell));
      const radius = Radius.circular(GlassStyles.borderRadius);

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

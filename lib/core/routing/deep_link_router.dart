import 'package:beltech/core/navigation/shell_providers.dart';

/// Maps notification payload route strings to [ShellTab] values.
///
/// Notification payloads use simple, slash-prefixed route strings
/// (e.g. `'/tasks'`). This class converts them to the correct [ShellTab]
/// without requiring access to go_router or a [BuildContext].
///
/// Usage:
/// ```dart
/// final tab = DeepLinkRouter.tabForRoute(payload);
/// if (tab != null) {
///   ref.read(shellTabIndexProvider.notifier).state = tab.index;
/// }
/// ```
abstract final class DeepLinkRouter {
  static const _routes = <String, ShellTab>{
    '/': ShellTab.home,
    '/home': ShellTab.home,
    '/finance': ShellTab.finance,
    '/calendar': ShellTab.calendar,
    '/assistant': ShellTab.assistant,
    '/profile': ShellTab.profile,
  };

  /// Returns the [ShellTab] that corresponds to [route], or `null` if the
  /// route string is unrecognised.
  static ShellTab? tabForRoute(String route) => _routes[route];
}

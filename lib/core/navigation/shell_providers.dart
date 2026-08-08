import 'package:flutter_riverpod/legacy.dart';

/// Single source of truth for shell tab positions.
/// Home, Finance, More (3 tabs).
enum ShellTab {
  home, // 0
  finance, // 1
  more, // 2
}

final shellTabIndexProvider = StateProvider<int>((_) => ShellTab.home.index);

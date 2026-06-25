import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single source of truth for shell tab positions.
/// Matches Kotlin app: Home, Finance, Calendar, AI, Profile.
enum ShellTab {
  home, // 0
  finance, // 1
  calendar, // 2
  assistant, // 3
  profile, // 4
}

final shellTabIndexProvider = StateProvider<int>((_) => ShellTab.home.index);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CodeTheme { github, atomOneDark, monokai, vs2015, nightOwl }

const _kCodeThemeKey = 'code_theme_key';

class CodeThemeNotifier extends StateNotifier<CodeTheme> {
  CodeThemeNotifier() : super(CodeTheme.github) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kCodeThemeKey);
    if (saved != null) {
      try {
        state = CodeTheme.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => CodeTheme.github,
        );
      } catch (_) {
        state = CodeTheme.github;
      }
    }
  }

  /// Sets a new theme and persists it.
  Future<void> setCodeTheme(CodeTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCodeThemeKey, theme.name);
  }
}

final codeThemeProvider = StateNotifierProvider<CodeThemeNotifier, CodeTheme>(
  (ref) => CodeThemeNotifier(),
);

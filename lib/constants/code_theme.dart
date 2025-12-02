import 'package:chat_box/providers/codetheme_provider.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/night-owl.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

final codeThemes = {
  CodeTheme.atomOneDark: atomOneDarkTheme,
  CodeTheme.monokai: monokaiSublimeTheme,
  CodeTheme.vs2015: vs2015Theme,
  CodeTheme.nightOwl: nightOwlTheme,
};

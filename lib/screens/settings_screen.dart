import 'package:chat_box/constants/code_theme.dart';
import 'package:chat_box/providers/codetheme_provider.dart';
import 'package:chat_box/providers/theme_provider.dart';
import 'package:chat_box/providers/user_provider.dart';
import 'package:chat_box/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _sampleCode = '''
void main() {
  print('Hello, World!');
}
''';

  void _logout() async {
    await AuthService().logout();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = ref.watch(themeModeProvider.notifier);
    final codeNotifier = ref.watch(codeThemeProvider.notifier);
    final currentCode = ref.watch(codeThemeProvider);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          elevation: 0,
          centerTitle: true,

          title: Text(
            'Settings',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Profile Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundImage:
                        user.userMetadata?['avatar_url'] != null
                            ? NetworkImage(user.userMetadata!['avatar_url'])
                            : null,
                    backgroundColor: theme.dividerColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.userMetadata?['full_name'] ?? 'User Name',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.userMetadata?['email'] ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Appearance Section
          Text('Appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildThemeOptions(
            theme,
            themeNotifier,
            themeNotifier.currentThemeMode,
          ),
          const SizedBox(height: 32),
          // Code Theme Section
          Text('Code Theme', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _buildCodeThemes(theme, codeNotifier, currentCode),
          const SizedBox(height: 64),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            elevation: 4,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: theme.cardTheme.color,
            foregroundColor: theme.colorScheme.primaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptions(
    ThemeData theme,
    ThemeModeNotifier notifier,
    ThemeMode current,
  ) {
    final options = [
      _ThemeOption(
        icon: Icons.phone_android,
        label: 'System',
        mode: ThemeMode.system,
      ),
      _ThemeOption(icon: Icons.dark_mode, label: 'Dark', mode: ThemeMode.dark),
      _ThemeOption(
        icon: Icons.light_mode,
        label: 'Light',
        mode: ThemeMode.light,
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          options.map((opt) {
            final selected = current == opt.mode;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? theme.colorScheme.primaryContainer
                          : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? theme.primaryColor : theme.dividerColor,
                  ),
                  boxShadow:
                      selected
                          ? [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ]
                          : [],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => notifier.setTheme(opt.mode.toAppTheme()),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          opt.icon,
                          size: 28,
                          color:
                              selected ? Colors.white : theme.iconTheme.color,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          opt.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                selected
                                    ? Colors.white
                                    : theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildCodeThemes(
    ThemeData theme,
    CodeThemeNotifier notifier,
    CodeTheme current,
  ) {
    return GridView.builder(
      itemCount: codeThemes.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final entry = codeThemes.entries.elementAt(index);
        final key = entry.key;
        final thm = entry.value;
        final label = key.name.replaceAll('_', ' ');
        final selected = current == key;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected
                      ? theme.colorScheme.primaryContainer
                      : theme.secondaryHeaderColor,
              width: 2,
            ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ]
                    : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => notifier.setCodeTheme(key),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: HighlightView(
                        language: 'dart',
                        _sampleCode,
                        theme: thm,
                        padding: const EdgeInsets.all(8),
                        textStyle: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Roboto Mono',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Extensions and Option classes
class _ThemeOption {
  final IconData icon;
  final String label;
  final ThemeMode mode;
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.mode,
  });
}

extension on ThemeMode {
  AppThemeMode toAppTheme() {
    switch (this) {
      case ThemeMode.dark:
        return AppThemeMode.dark;
      case ThemeMode.light:
        return AppThemeMode.light;
      default:
        return AppThemeMode.system;
    }
  }
}

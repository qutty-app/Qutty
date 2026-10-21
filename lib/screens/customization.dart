import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dynamic_color/dynamic_color.dart';

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/settings_ui.dart';

class CustomizationScreen extends StatelessWidget {
  const CustomizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsCustomization)),
      body: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          final supportsSystemAccent =
              lightDynamic != null || darkDynamic != null;
          return ListenableBuilder(
            listenable: manager,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: l10n.themeLabel,
                  children: [
                    SettingsTile(
                      leading: const Icon(Icons.brightness_6_outlined),
                      title: l10n.themeLabel,
                      subtitle: _themeLabel(manager.themePreference, l10n),
                      onTap: () => _showThemePicker(context),
                    ),
                  ],
                ),
                SettingsSection(
                  title: l10n.accentColorLabel,
                  children: [
                    SettingsTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: l10n.accentColorLabel,
                      subtitle: _accentLabel(manager.accentPreference, l10n),
                      onTap: () => _showAccentPicker(
                        context,
                        supportsSystemAccent: supportsSystemAccent,
                      ),
                    ),
                  ],
                ),
                SettingsSection(
                  title: l10n.settingsFont,
                  children: [
                    SettingsTile(
                      leading: const Icon(Icons.text_fields),
                      title: l10n.settingsFont,
                      // The picked font's own name when there is one. This is
                      // a font name rather than a label, so it is shown as it
                      // is and not translated.
                      subtitle: manager.usesSystemFont
                          ? l10n.fontSystemDefault
                          : manager.fontLabel ?? l10n.fontSystemDefault,
                      onTap: () => context.push('/settings/font'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showThemePicker(BuildContext context) async {
    final selected = await showDialog<ThemePreference>(
      context: context,
      builder: (context) => _PreferenceDialog<ThemePreference>(
        title: context.l10n.themeLabel,
        selected: AppManager.instance.themePreference,
        options: {
          ThemePreference.system: context.l10n.themeSystem,
          ThemePreference.dark: context.l10n.themeDark,
          ThemePreference.light: context.l10n.themeLight,
        },
      ),
    );
    if (selected != null) {
      await AppManager.instance.setThemePreference(selected);
    }
  }

  Future<void> _showAccentPicker(
    BuildContext context, {
    required bool supportsSystemAccent,
  }) async {
    final l10n = context.l10n;
    final options = <AccentPreference, String>{
      AccentPreference.quttyBlue: l10n.accentQuttyBlue,
      if (supportsSystemAccent) AccentPreference.system: l10n.themeSystem,
      AccentPreference.custom: l10n.accentCustom,
    };
    final selected = await showDialog<AccentPreference>(
      context: context,
      builder: (context) => _PreferenceDialog<AccentPreference>(
        title: l10n.accentColorLabel,
        selected: AppManager.instance.accentPreference,
        options: options,
      ),
    );
    if (selected == null || !context.mounted) return;
    if (selected != AccentPreference.custom) {
      await AppManager.instance.setAccentPreference(selected);
      return;
    }
    final color = await _showCustomColorDialog(context);
    if (color != null) {
      await AppManager.instance.setCustomAccentColor(color);
    }
  }

  Future<int?> _showCustomColorDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: AppManager.instance.customAccentColor
          .toRadixString(16)
          .padLeft(8, '0')
          .substring(2),
    );
    final l10n = context.l10n;
    return showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.customAccentColor),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 6,
          decoration: InputDecoration(
            labelText: l10n.hexColor,
            prefixText: '#',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim(), radix: 16);
              if (value != null && controller.text.trim().length == 6) {
                Navigator.pop(dialogContext, 0xff000000 | value);
              }
            },
            child: Text(l10n.commonApply),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemePreference preference, AppLocalizations l10n) =>
      switch (preference) {
        ThemePreference.system => l10n.themeSystem,
        ThemePreference.dark => l10n.themeDark,
        ThemePreference.light => l10n.themeLight,
      };

  String _accentLabel(AccentPreference preference, AppLocalizations l10n) =>
      switch (preference) {
        AccentPreference.quttyBlue => l10n.accentQuttyBlue,
        AccentPreference.system => l10n.themeSystem,
        AccentPreference.custom => l10n.accentCustom,
      };
}

class _PreferenceDialog<T> extends StatelessWidget {
  final String title;
  final T selected;
  final Map<T, String> options;

  const _PreferenceDialog({
    required this.title,
    required this.selected,
    required this.options,
  });

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in options.entries)
          ListTile(
            title: Text(entry.value),
            trailing: entry.key == selected
                ? Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () => Navigator.pop(context, entry.key),
          ),
      ],
    ),
  );
}

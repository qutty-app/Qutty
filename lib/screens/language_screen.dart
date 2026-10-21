import 'package:flutter/material.dart';

import 'package:qutty/api/app_manager.dart';
import 'package:qutty/l10n/l10n.dart';
import 'package:qutty/widgets/settings_ui.dart';

/// Radio values are non-nullable, so "follow the device" gets a sentinel that
/// no language code can collide with.
const _systemValue = '';

/// Picks the language the app renders in.
///
/// The list is built from [AppLocalizations.supportedLocales] rather than a
/// hand-maintained array, so dropping a translation into `lib/l10n` and
/// re-running `flutter gen-l10n` is all it takes for a language to appear here.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = AppManager.instance;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageTitle)),
      body: ListenableBuilder(
        listenable: manager,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            SettingsSection(
              title: l10n.languageSubtitle,
              children: [
                RadioGroup<String>(
                  groupValue: manager.locale?.languageCode ?? _systemValue,
                  onChanged: (value) => manager.setLocale(
                    value == null || value == _systemValue
                        ? null
                        : Locale(value),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        value: _systemValue,
                        title: Text(l10n.languageSystemDefault),
                      ),
                      for (final locale in AppLocalizations.supportedLocales)
                        RadioListTile<String>(
                          value: locale.languageCode,
                          // Each name is written in its own language, because a
                          // reader who cannot read the current UI is the exact
                          // person who needs to find their language here.
                          title: Text(languageName(locale)),
                          secondary: Text(
                            locale.languageCode.toUpperCase(),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

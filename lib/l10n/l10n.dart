import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Localized strings for code that has no [BuildContext].
///
/// The API client and the notification stack both build user-visible text long
/// after the widget that started the request is gone, so they cannot call
/// [AppLocalizations.of]. [L10nScope] keeps this in sync with whatever locale
/// the widget tree resolved, and it falls back to the template language so
/// there is always something to show.
class L10n {
  L10n._();

  static AppLocalizations _current = lookupAppLocalizations(const Locale('en'));

  /// The strings for the locale currently in effect.
  static AppLocalizations get current => _current;

  static void update(AppLocalizations value) => _current = value;
}

/// Shortest spelling for localized strings at a call site: `context.l10n.foo`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Picks the strings for [locale] without a widget tree.
///
/// [L10nScope] cannot do this job in a headless isolate -- a background
/// notification service has no [Localizations] ancestor to observe -- so the
/// channel descriptions it posts are resolved straight from the stored
/// preference here. A null [locale] means "follow the device", so the caller
/// passes the platform locale in that case.
///
/// Returns the template language rather than throwing for an unknown locale,
/// matching what the widget tree does.
AppLocalizations resolveL10n(Locale? locale) {
  try {
    return lookupAppLocalizations(locale ?? const Locale('en'));
  } on FlutterError {
    return lookupAppLocalizations(const Locale('en'));
  }
}

/// Publishes the active [AppLocalizations] to [L10n].
///
/// Mount this below [Localizations] -- that is, as the [MaterialApp.builder]
/// child -- so it observes the same locale the rest of the tree does.
class L10nScope extends StatefulWidget {
  final Widget child;

  const L10nScope({super.key, required this.child});

  @override
  State<L10nScope> createState() => _L10nScopeState();
}

class _L10nScopeState extends State<L10nScope> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    L10n.update(AppLocalizations.of(context));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The display name of a supported locale, written in that locale.
///
/// The generated localizations expose no language names, and a picker that
/// shows "de" to a user who cannot read it is useless, so the names are carried
/// here instead. Each is written the way a speaker of that language would
/// normally name their own language.
const Map<String, String> languageNames = <String, String>{
  'en': 'English',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'ru': 'Русский',
  'uk': 'Українська',
};

/// The endonym of [locale], falling back to the raw language code.
String languageName(Locale locale) =>
    languageNames[locale.languageCode] ?? locale.languageCode;

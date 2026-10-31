// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Qutty';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonSaveChanges => 'Änderungen speichern';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonCopy => 'Kopieren';

  @override
  String get commonApply => 'Anwenden';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonRemove => 'Entfernen';

  @override
  String get commonRevoke => 'Widerrufen';

  @override
  String get commonContinue => 'Fortfahren';

  @override
  String get commonDismiss => 'Ausblenden';

  @override
  String get commonTryAgain => 'Erneut versuchen';

  @override
  String get commonOpen => 'Öffnen';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Wird gespeichert…';

  @override
  String get commonNotAvailable => 'N/V';

  @override
  String get commonLoading => 'wird geladen';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonName => 'Name';

  @override
  String get commonHandle => 'Handle';

  @override
  String get commonDescription => 'Beschreibung';

  @override
  String get commonSettings => 'Einstellungen';

  @override
  String get username => 'Benutzername';

  @override
  String get password => 'Passwort';

  @override
  String get optionalEmail => 'E-Mail (optional)';

  @override
  String get usernamePasswordRequired =>
      'Benutzername und Passwort sind erforderlich.';

  @override
  String get loginCreateAccountTitle => 'Erstelle dein Konto';

  @override
  String get loginWelcomeBackTitle => 'Willkommen zurück';

  @override
  String get loginJoinConversation => 'Mach mit bei der Unterhaltung.';

  @override
  String get loginSignInConversations =>
      'Melde dich bei deinen Unterhaltungen an.';

  @override
  String get createAccount => 'Konto erstellen';

  @override
  String get signIn => 'Anmelden';

  @override
  String get alreadyHaveAccount => 'Schon ein Konto? Anmelden';

  @override
  String get newToQutty => 'Neu bei Qutty? Konto erstellen';

  @override
  String couldNotConnect(Object error) {
    return 'Verbindung zu Qutty fehlgeschlagen: $error';
  }

  @override
  String get quttyApiServiceDebugging => 'Qutty-ApiService-Debugging';

  @override
  String get developerOptions => 'Optionen für Entwickler';

  @override
  String get apiUrl => 'API-URL';

  @override
  String get jwtToken => 'JWT-Token';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get loginByToken => 'Mit Token anmelden';

  @override
  String get enterJwtToken => 'Gib einen JWT-Token ein.';

  @override
  String get couldNotValidateToken =>
      'Der Token konnte nicht überprüft werden.';

  @override
  String get selectChat => 'Chat auswählen';

  @override
  String get home => 'Start';

  @override
  String get pageNotFound => 'Seite nicht gefunden';

  @override
  String get pageNotFoundDescription =>
      'Das bedeutet, dass irgendwie eine ungültige Seite geöffnet wurde.';

  @override
  String get chatsSearchHint => 'Chats, Kanäle, Nutzer suchen';

  @override
  String get chatsProfileTooltip => 'Profil';

  @override
  String get chatsNewChannel => 'Neuer Kanal';

  @override
  String get chatsNewChat => 'Neuer Chat';

  @override
  String get chatsEmptyTitle => 'Noch keine Unterhaltungen';

  @override
  String get chatsEmptySubtitle => 'Erstelle einen Chat, um loszulegen.';

  @override
  String get chatsNoMatches => 'Keine Treffer gefunden';

  @override
  String get chatsPreviewAndJoin => 'Ansehen und beitreten';

  @override
  String get chatsMessageUser => 'Nachricht senden';

  @override
  String get chatBackToChats => 'Zurück zu den Chats';

  @override
  String get chatConversation => 'Unterhaltung';

  @override
  String get chatStartCall => 'Anruf starten';

  @override
  String get chatEndCall => 'Anruf beenden';

  @override
  String chatIncomingCall(String name) {
    return '$name ruft an';
  }

  @override
  String get chatOpenCall => 'Anruf öffnen';

  @override
  String get chatDismissCall => 'Anruf schließen';

  @override
  String get chatJoinCall => 'Anruf beitreten';

  @override
  String get chatLeaveCall => 'Anruf verlassen';

  @override
  String get chatMinimizeCall => 'Anruf minimieren';

  @override
  String get chatConnectingCall => 'Verbindung wird hergestellt…';

  @override
  String get chatCalling => 'Rufe an…';

  @override
  String get chatEnableWebcam => 'Kamera einschalten';

  @override
  String get chatDisableWebcam => 'Kamera ausschalten';

  @override
  String get chatEnableScreenShare => 'Bildschirm teilen';

  @override
  String get chatDisableScreenShare => 'Teilen beenden';

  @override
  String get chatEnableSpeaker => 'Lautsprecher ein';

  @override
  String get chatDisableSpeaker => 'Lautsprecher aus';

  @override
  String get chatMuteMicrophone => 'Mikrofon stummschalten';

  @override
  String get chatUnmuteMicrophone => 'Mikrofon einschalten';

  @override
  String get chatInCall => 'Im Anruf';

  @override
  String get chatCallsUnsupported => 'Der Server unterstützt keine Anrufe';

  @override
  String get chatUnableToOpenAttachment =>
      'Anhang konnte nicht geöffnet werden';

  @override
  String get chatUnableToOpenLink => 'Link konnte nicht geöffnet werden';

  @override
  String get chatJoined => 'Chat beigetreten';

  @override
  String get chatNoJoinLink => 'Dieser Chat hat keinen Beitrittslink';

  @override
  String get chatSendFirstMessage => 'Sende deine erste Nachricht';

  @override
  String get chatNoWritePermission =>
      'Keine Berechtigung zum Schreiben von Nachrichten';

  @override
  String get chatJoin => 'Chat beitreten';

  @override
  String get chatAttachFile => 'Datei anhängen';

  @override
  String get chatEmojiSelectButton => 'Emojis, GIFs und Sticker auswählen';

  @override
  String get mediaPickerStickerTab => 'Sticker';

  @override
  String get mediaPickerEmojiTab => 'Emoji';

  @override
  String get mediaPickerGifTab => 'GIF';

  @override
  String get mediaPickerGifSearchHint => 'GIFs suchen';

  @override
  String get mediaPickerGifFavorite => 'In Favoriten speichern';

  @override
  String get mediaPickerGifUnfavorite => 'Aus Favoriten entfernen';

  @override
  String get mediaPickerGifClearSearch => 'Suche löschen';

  @override
  String get mediaPickerGifNoFavorites =>
      'Noch keine GIFs gespeichert. Suche eines und drücke lange, um es zu speichern.';

  @override
  String get mediaPickerGifEmpty => 'Keine GIFs gefunden';

  @override
  String get mediaPickerGifLoadFailed => 'GIFs konnten nicht geladen werden';

  @override
  String get mediaPickerGifPoweredBy => 'GIFs von Klipy';

  @override
  String get mediaPickerGifSend => 'GIF senden';

  @override
  String get mediaPickerEmojiLoadFailed =>
      'Emoji konnten nicht geladen werden.';

  @override
  String get mediaPickerGroupSmileysEmotion => 'Smileys & Emotionen';

  @override
  String get mediaPickerGroupPeopleBody => 'Menschen & Körper';

  @override
  String get mediaPickerGroupAnimalsNature => 'Tiere & Natur';

  @override
  String get mediaPickerGroupFoodDrink => 'Essen & Trinken';

  @override
  String get mediaPickerGroupTravelPlaces => 'Reisen & Orte';

  @override
  String get mediaPickerGroupActivities => 'Aktivitäten';

  @override
  String get mediaPickerGroupObjects => 'Objekte';

  @override
  String get mediaPickerGroupSymbols => 'Symbole';

  @override
  String get mediaPickerGroupFlags => 'Flaggen';

  @override
  String get mediaPickerSkinTone => 'Hautton';

  @override
  String get mediaPickerSkinToneDefault => 'Standard';

  @override
  String get mediaPickerSkinToneLight => 'Hell';

  @override
  String get mediaPickerSkinToneMediumLight => 'Mittelhell';

  @override
  String get mediaPickerSkinToneMedium => 'Mittel';

  @override
  String get mediaPickerSkinToneMediumDark => 'Mitteldunkel';

  @override
  String get mediaPickerSkinToneDark => 'Dunkel';

  @override
  String get chatWriteMessage => 'Nachricht schreiben';

  @override
  String get chatSend => 'Senden';

  @override
  String chatMessageId(int id) {
    return 'Nachrichten-ID: $id';
  }

  @override
  String get chatMessageRead => 'Gelesen';

  @override
  String get chatMessageSent => 'Gesendet';

  @override
  String chatReadBy(int count) {
    return 'Von $count gelesen';
  }

  @override
  String chatSelectionCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get chatSelectionStop => 'Auswahl beenden';

  @override
  String get chatMenuReply => 'Antworten';

  @override
  String get chatReplyUnavailable => 'Originalnachricht';

  @override
  String get chatMenuForward => 'Weiterleiten';

  @override
  String get chatMenuSelect => 'Auswählen';

  @override
  String get chatMenuMore => 'Mehr';

  @override
  String get chatMessageCopied => 'Nachricht kopiert';

  @override
  String get chatActionUnavailable => 'Noch nicht verfügbar';

  @override
  String get chatForwardTitle => 'Weiterleiten an';

  @override
  String get chatForwardSearch => 'Chats durchsuchen';

  @override
  String get chatForwardNoChats => 'Keine Chats zum Weiterleiten';

  @override
  String get chatForwarded => 'Weitergeleitet';

  @override
  String chatForwardedFrom(String author) {
    return 'Weitergeleitet von $author';
  }

  @override
  String get chatForwardedOpen => 'Original öffnen';

  @override
  String chatForwardedTo(String chat) {
    return 'Weitergeleitet an $chat';
  }

  @override
  String get settingsChats => 'Chats';

  @override
  String get settingsReadCount => 'Gelesen-Zahl statt Haken anzeigen';

  @override
  String get settingsReadCountSubtitle =>
      'In Direktchats die Anzahl der Leser statt eines Hakens anzeigen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsCustomization => 'Anpassung';

  @override
  String get settingsCustomizationSubtitle => 'Design und Akzentfarbe';

  @override
  String get settingsConnectivity => 'Verbindung';

  @override
  String get settingsNotifications => 'Benachrichtigungen';

  @override
  String get settingsAccount => 'Konto';

  @override
  String get settingsAccounts => 'Konten';

  @override
  String get settingsAccountDefaultLabel => 'Konto';

  @override
  String get settingsAccountSafety => 'Kontosicherheit';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsEditProfile => 'Profil bearbeiten';

  @override
  String get settingsChangePassword => 'Passwort ändern';

  @override
  String get settingsChangePasswordSubtitle =>
      'Aktualisiere das Passwort deines Kontos';

  @override
  String get settingsChangeEmail => 'E-Mail ändern';

  @override
  String get settingsNoEmailOnFile => 'Keine E-Mail hinterlegt';

  @override
  String get settingsActiveSessions => 'Aktive Sitzungen';

  @override
  String get settingsActiveSessionsSubtitle =>
      'Verwalte Geräte, die in deinem Konto angemeldet sind';

  @override
  String get settingsRemoveAccount => 'Konto entfernen';

  @override
  String get settingsAddAccount => 'Konto hinzufügen';

  @override
  String get settingsAddAccountSubtitle =>
      'Bei einem anderen Server oder Konto anmelden';

  @override
  String get settingsDeleteAccount => 'Konto löschen';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Löscht dein Qutty-Konto dauerhaft';

  @override
  String get settingsVersionPlaceholder => 'Placeholder#424738';

  @override
  String get settingsLogOut => 'Abmelden';

  @override
  String get settingsPasswordUpdated => 'Passwort aktualisiert';

  @override
  String get settingsEmailUpdated => 'E-Mail aktualisiert';

  @override
  String get settingsLogOutTitle => 'Abmelden?';

  @override
  String get settingsLogOutBody =>
      'Zum erneuten Anmelden musst du dein Passwort noch einmal eingeben.';

  @override
  String get settingsDeleteAccountTitle => 'Konto löschen?';

  @override
  String get settingsDeleteAccountBody =>
      'Gib deinen Benutzernamen und dein Passwort ein, um dein Konto und alle Daten dauerhaft zu löschen.';

  @override
  String get settingsEditProfileTooltip => 'Profil bearbeiten';

  @override
  String get settingsCalls => 'Anrufe';

  @override
  String get settingsCallWebcam => 'Webcam';

  @override
  String get settingsCallWebcamSubtitle =>
      'Anrufe mit aktivierter Webcam starten';

  @override
  String get settingsCallCamera => 'Kamera';

  @override
  String get settingsCallCameraFront => 'Front';

  @override
  String get settingsCallCameraBack => 'Hinten';

  @override
  String get settingsCallLoudspeaker => 'Lautsprecher';

  @override
  String get settingsCallLoudspeakerSubtitle =>
      'Anruf laut über den Lautsprecher wiedergeben';

  @override
  String get settingsCallMic => 'Mikrofon';

  @override
  String get settingsCallMicSubtitle =>
      'Anrufe mit aktiviertem Mikrofon starten';

  @override
  String get settingsCallScreenShare => 'Screencast';

  @override
  String get settingsCallScreenShareSubtitle =>
      'Bildschirm während Anrufen teilen erlauben';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioInput => 'Mikrofon';

  @override
  String get settingsAudioOutput => 'Lautsprecher';

  @override
  String get settingsAudioCamera => 'Kamera';

  @override
  String get settingsAudioSystemDefault => 'Systemstandard';

  @override
  String get settingsAudioNoDevices => 'Keine Geräte gefunden';

  @override
  String get settingsAudioNoiseReduction => 'Rauschunterdrückung';

  @override
  String get settingsAudioNoiseReductionSubtitle =>
      'Hintergrundgeräusche während Anrufen unterdrücken';

  @override
  String get settingsAudioMicVolume => 'Mikrofonlautstärke';

  @override
  String get settingsAudioSpeakerVolume => 'Lautsprecherlautstärke';

  @override
  String get cacheTitle => 'Offline cache';

  @override
  String get cacheTitleSubtitle =>
      'Keep conversations and media on this device';

  @override
  String get cacheOfflineSection => 'Offline';

  @override
  String get cacheStorageSection => 'Storage';

  @override
  String get cacheContentsSection => 'Contents';

  @override
  String get cacheClearSection => 'Clear cache';

  @override
  String get cacheMessagesLabel => 'Messages';

  @override
  String get cacheProfilesLabel => 'People';

  @override
  String get cacheMediaToggle => 'Cache media';

  @override
  String get cacheMediaToggleSubtitle =>
      'Keep pictures and attachments on the device';

  @override
  String get cacheChatsToggle => 'Cache conversations';

  @override
  String get cacheChatsToggleSubtitle =>
      'Keep conversations, messages and profiles on the device';

  @override
  String get cacheMediaLabel => 'Media';

  @override
  String get cacheChatsLabel => 'Conversations';

  @override
  String get cacheTotalLabel => 'Total';

  @override
  String cacheMediaFiles(int count) {
    return '$count files';
  }

  @override
  String cacheChatCount(int count) {
    return '$count conversations';
  }

  @override
  String cacheMessageCount(int count) {
    return '$count messages';
  }

  @override
  String cacheProfileCount(int count) {
    return '$count profiles';
  }

  @override
  String get cacheLimitLabel => 'Media limit';

  @override
  String get cacheLimitSubtitle =>
      'How much space media may take on this device';

  @override
  String get cacheClearMedia => 'Clear media cache';

  @override
  String get cacheClearChats => 'Clear conversation cache';

  @override
  String get cacheClearAll => 'Clear all cache';

  @override
  String get cacheClearMediaTitle => 'Clear media cache?';

  @override
  String get cacheClearMediaBody =>
      'Pictures and attachments on this device will be downloaded again when they are needed.';

  @override
  String get cacheClearChatsTitle => 'Clear conversation cache?';

  @override
  String get cacheClearChatsBody =>
      'Saved conversations, messages and profiles will be removed from this device.';

  @override
  String get cacheClearAllTitle => 'Clear all cache?';

  @override
  String get cacheClearAllBody =>
      'Everything Qutty keeps on this device for offline use will be removed.';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get chatOfflineMessages => 'Showing saved messages — you are offline';

  @override
  String get screenSharePickTitle => 'Wähle aus, was geteilt werden soll';

  @override
  String get screenSharePickScreens => 'Bildschirme';

  @override
  String get screenSharePickWindows => 'Fenster';

  @override
  String get screenSharePickEmpty => 'Keine Bildschirme oder Fenster gefunden';

  @override
  String get screenSharePickError =>
      'Bildschirme und Fenster konnten nicht geladen werden';

  @override
  String get screenSharePickRetry => 'Erneut versuchen';

  @override
  String get notificationsToggle => 'Nachrichtenbenachrichtigungen';

  @override
  String get notificationsOffForDevice => 'Für dieses Gerät deaktiviert';

  @override
  String get notificationsOpenWithBackground =>
      'Benachrichtigungen, wenn die App geöffnet oder im Hintergrund ist';

  @override
  String get notificationsOpenOnly =>
      'Benachrichtigungen, wenn die App geöffnet ist';

  @override
  String get notificationsOpenBackgroundConnection =>
      'Benachrichtigungen, wenn die App geöffnet ist (Hintergrundverbindung)';

  @override
  String get notificationsPermissionHint =>
      'Erlaube Qutty in den Systemeinstellungen Benachrichtigungen, um Alerts im Hintergrund zu erhalten.';

  @override
  String get connectionStatus => 'Verbindungsstatus';

  @override
  String get connectionLiveWebsocket => 'Status der Live-Websocket';

  @override
  String get connectionReconnect => 'Neu verbinden';

  @override
  String get connectionConnected => 'Verbunden';

  @override
  String get connectionConnecting => 'Verbindung wird hergestellt…';

  @override
  String get connectionDisconnected => 'Getrennt';

  @override
  String sessionsRevokeTitle(String name) {
    return 'Sitzung von $name widerrufen?';
  }

  @override
  String get sessionsRevokeBody =>
      'Andere Geräte, die diese Sitzung nutzen, werden abgemeldet.';

  @override
  String get sessionsRevoked => 'Sitzung widerrufen';

  @override
  String get sessionsLoadFailed => 'Sitzungen konnten nicht geladen werden';

  @override
  String get sessionsNone => 'Keine aktiven Sitzungen';

  @override
  String get sessionsThisDevice => 'Dieses Gerät';

  @override
  String sessionsLastActive(String time) {
    return 'Zuletzt aktiv $time';
  }

  @override
  String get sessionsCurrentBadge => 'Aktuell';

  @override
  String get timeJustNow => 'gerade eben';

  @override
  String timeMinutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String timeHoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String timeDaysAgo(int count) {
    return 'vor $count T.';
  }

  @override
  String get languageTitle => 'Sprache';

  @override
  String get languageSubtitle => 'App-Sprache';

  @override
  String get languageSystemDefault => 'Systemstandard';

  @override
  String get themeLabel => 'Design';

  @override
  String get accentColorLabel => 'Akzentfarbe';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get accentQuttyBlue => 'Qutty-Blau';

  @override
  String get accentCustom => 'Benutzerdefiniert';

  @override
  String get customAccentColor => 'Benutzerdefinierte Akzentfarbe';

  @override
  String get hexColor => 'Hex-Farbe';

  @override
  String get roleOwner => 'Eigentümer';

  @override
  String get roleAdmin => 'Administrator';

  @override
  String get roleRestricted => 'Eingeschränkt';

  @override
  String get roleMember => 'Mitglied';

  @override
  String get accountNewEmail => 'Neue E-Mail';

  @override
  String get accountCurrentPassword => 'Aktuelles Passwort';

  @override
  String get accountConfirmPassword => 'Passwort bestätigen';

  @override
  String get accountNewPassword => 'Neues Passwort';

  @override
  String get chatSettingsTitle => 'Chat-Einstellungen';

  @override
  String get chatSettingsLeaveTitle => 'Chat verlassen?';

  @override
  String get chatSettingsLeaveBody =>
      'Du verlierst den Zugang zu diesem Chat, sofern dich nicht ein Administrator erneut einlädt.';

  @override
  String get chatSettingsLeave => 'Verlassen';

  @override
  String chatSettingsDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get chatSettingsDeleteBody =>
      'Alle Nachrichten und Mitglieder werden dauerhaft entfernt. Das lässt sich nicht rückgängig machen.';

  @override
  String get chatSettingsLoadFailed =>
      'Einstellungen konnten nicht geladen werden';

  @override
  String get chatSettingsProfileSection => 'Profil';

  @override
  String get chatSettingsEditProfileSubtitle =>
      'Name, Handle, Beschreibung und Bild';

  @override
  String get chatSettingsCreateInvite => 'Einladungslink erstellen';

  @override
  String get chatSettingsCreateInviteSubtitle =>
      'Erstelle eine teilbare Einladung';

  @override
  String get chatSettingsPermissions => 'Berechtigungen';

  @override
  String get chatSettingsMembers => 'Mitglieder';

  @override
  String get chatSettingsMembersSubtitle => 'Teilnehmer ansehen und verwalten';

  @override
  String get chatSettingsAccessControl => 'Zugriffskontrolle';

  @override
  String get chatSettingsAccessControlSubtitle =>
      'Standardberechtigungen für Mitglieder';

  @override
  String get chatSettingsDirectMessage => 'Direktnachricht';

  @override
  String get chatSettingsOpenContactProfile => 'Profil des Kontakts öffnen';

  @override
  String get chatSettingsDangerZone => 'Gefahrenzone';

  @override
  String get chatSettingsLeaveTile => 'Chat verlassen';

  @override
  String get chatSettingsDeleteTile => 'Chat löschen';

  @override
  String get chatSettingsDeleteTileSubtitle =>
      'Nur der Ersteller kann diesen Chat löschen';

  @override
  String get chatSettingsInviteTitle => 'Einladungslink';

  @override
  String get chatSettingsInviteBody =>
      'Teile diesen Link mit Personen, die du einladen möchtest. Er wurde in die Zwischenablage kopiert.';

  @override
  String get chatSettingsInviteCopied => 'Einladungslink kopiert';

  @override
  String get aclDefaultPermissions => 'Standardberechtigungen für Mitglieder';

  @override
  String get aclDescription =>
      'Diese Berechtigungen gelten für normale Mitglieder. Administratoren haben immer Verwaltungszugriff.';

  @override
  String get aclSavePermissions => 'Berechtigungen speichern';

  @override
  String get aclEditMessages => 'Nachrichten bearbeiten';

  @override
  String get aclEditMessagesDescription =>
      'Erlaubt Mitgliedern, Nachrichten zu bearbeiten.';

  @override
  String get permissionWriteMessages => 'Nachrichten senden';

  @override
  String get permissionWriteMessagesDescription =>
      'Erlaubt Mitgliedern, neue Nachrichten zu senden.';

  @override
  String get permissionDeleteOthersMessages => 'Nachrichten anderer löschen';

  @override
  String get permissionDeleteOthersMessagesDescription =>
      'Erlaubt Mitgliedern, Nachrichten anderer Personen zu entfernen.';

  @override
  String get permissionEditOthersMessages => 'Nachrichten anderer bearbeiten';

  @override
  String get permissionEditOthersMessagesDescription =>
      'Erlaubt Mitgliedern, Nachrichten anderer Personen zu bearbeiten.';

  @override
  String get permissionRestrictUsers => 'Mitglieder verwalten';

  @override
  String get permissionRestrictUsersDescription =>
      'Erlaubt Mitgliedern, andere Mitglieder zu entfernen oder einzuschränken.';

  @override
  String get permissionEditProfile => 'Chat-Profil bearbeiten';

  @override
  String get permissionEditProfileDescription =>
      'Erlaubt Mitgliedern, Namen und Beschreibung des Chats zu aktualisieren.';

  @override
  String get permissionAddAdmins => 'Administratoren verwalten';

  @override
  String get permissionAddAdminsDescription =>
      'Erlaubt Mitgliedern, andere Mitglieder zu befördern.';

  @override
  String get membersTitle => 'Mitglieder';

  @override
  String get membersLoadFailed => 'Mitglieder konnten nicht geladen werden';

  @override
  String get membersYou => 'Du';

  @override
  String get membersMore => 'Mehr';

  @override
  String get membersViewProfile => 'Profil ansehen';

  @override
  String membersGiveChat(String name) {
    return '$name an diesen Nutzer übergeben';
  }

  @override
  String get membersManagePermissions => 'Berechtigungen verwalten';

  @override
  String get membersRemoveFromChat => 'Aus Chat entfernen';

  @override
  String membersRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get membersRemoveBody =>
      'Diese Person verliert sofort den Zugang zu diesem Chat.';

  @override
  String membersOwnershipGiven(String name) {
    return 'Chat-Eigentum an $name übergeben';
  }

  @override
  String get membersTransferTitle => 'Angaben zum Zielnutzer';

  @override
  String get membersTransferAttention => 'ACHTUNG!';

  @override
  String membersTransferUsername(String username) {
    return 'BENUTZERNAME: $username';
  }

  @override
  String membersTransferAcknowledge(String chat, String username) {
    return 'Mir ist bewusst, dass ich die Eigentümerschaft von $chat verliere und $username $chat erhält.';
  }

  @override
  String get membersEnterPassword => 'Gib dein Passwort ein';

  @override
  String membersGiveConfirm(String chat, String username) {
    return '$chat an $username übergeben';
  }

  @override
  String get membersOwnerLocked =>
      'Der Chat-Eigentümer kann nicht geändert werden.';

  @override
  String get createChatNewChannel => 'Neuer Kanal';

  @override
  String get createChatNewChat => 'Neuer Chat';

  @override
  String get createChatClose => 'Schließen';

  @override
  String get createChatCreateChannel => 'Kanal erstellen';

  @override
  String get createChatCreateChat => 'Chat erstellen';

  @override
  String get createChatChooseAvatar => 'Avatar auswählen';

  @override
  String get createChatDisplayName => 'Anzeigename';

  @override
  String get createChatUsernameOptional => 'Benutzername (optional)';

  @override
  String get createChatUsernameOptionalHelper =>
      'Du kannst das leer lassen und später ergänzen.';

  @override
  String get createChatNameRequired => 'Der Anzeigename ist erforderlich.';

  @override
  String get joinPreviewTitle => 'Chat beitreten';

  @override
  String get joinPreviewInvalidLink => 'Ungültiger Beitrittslink';

  @override
  String get joinPreviewJoining => 'Beitritt läuft…';

  @override
  String get joinPreviewJoin => 'Beitreten';

  @override
  String get editProfileChangeAvatar => 'Avatar ändern';

  @override
  String get editProfileRemoveAvatar => 'Avatar entfernen';

  @override
  String get editProfileBio => 'Über mich';

  @override
  String get editProfileNameEmpty => 'Der Anzeigename darf nicht leer sein';

  @override
  String get editProfileHandleReserved =>
      'Das Handle darf nicht _ sein, dieses Handle ist zum Zurücksetzen reserviert';

  @override
  String get editChatChannelSettings => 'Kanaleinstellungen';

  @override
  String get editChatTapForPicture => 'Tippen, um das Chatbild zu ändern';

  @override
  String get editChatUpload => 'Hochladen';

  @override
  String get editChatReplace => 'Ersetzen';

  @override
  String get editChatHandleHelper =>
      'Wird verwendet, um den Chat über @handle zu teilen';

  @override
  String get profileUnableToOpen => 'Konnte nicht geöffnet werden';

  @override
  String profileError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get profileNotFound => 'Profil nicht gefunden';

  @override
  String profileChatId(int id) {
    return 'Chat-ID: $id';
  }

  @override
  String profileUserId(int id) {
    return 'Nutzer-ID: $id';
  }

  @override
  String profileTabMedia(int count) {
    return 'Medien ($count)';
  }

  @override
  String profileTabGifs(int count) {
    return 'GIFs ($count)';
  }

  @override
  String profileTabLinks(int count) {
    return 'Links ($count)';
  }

  @override
  String profileTabFiles(int count) {
    return 'Dateien ($count)';
  }

  @override
  String get profileNoMedia => 'Noch keine Medien';

  @override
  String get profileNoGifs => 'Noch keine GIFs';

  @override
  String get profileNoLinks => 'Noch keine Links';

  @override
  String get profileNoFiles => 'Noch keine Dateien';

  @override
  String get aboutTerms => 'Nutzungsbedingungen und Datenschutzerklärung';

  @override
  String get aboutLicenses => 'Open-Source-Lizenzen';

  @override
  String aboutBuild(String build) {
    return 'Build: $build';
  }

  @override
  String aboutCopyright(String version) {
    return 'Qutty - RdProjects 2026 © Alle Rechte vorbehalten\nVersion: $version';
  }

  @override
  String get debugTitle => 'Quttycaka';

  @override
  String get debugWarning =>
      'Diese Einstellungen dienen nur Entwicklungs- und Debug-Zwecken. \nÄnderungen können zu unerwartetem Verhalten führen.\nFahre nur fort, wenn du weißt, was du tust.\n - QuttyTeam bei RdProjects';

  @override
  String get debugSubtitle =>
      'Entwicklungs-/Debug-Einstellungen, auch Quttycaka genannt';

  @override
  String get debugApiEndpoint => 'API-Endpunkt';

  @override
  String get debugDeveloperInfo => 'Entwicklerinfo';

  @override
  String get debugDeveloperInfoSubtitle =>
      'IDs von Profilen und Nachrichten anzeigen';

  @override
  String get debugFallbackSelectorCast => 'FallBackSelectorCast';

  @override
  String get debugFallbackSelectorCastSubtitle =>
      'Immer die App-eigene Bildschirmauswahl statt der Systemauswahl verwenden';

  @override
  String get debugKeepWebsocketAlive => 'Websocket im Hintergrund aktiv halten';

  @override
  String get debugKeepWebsocketAliveSubtitle =>
      'Websocket im Hintergrund verbunden halten';

  @override
  String get debugBackgroundAllowTitle => 'Hintergrund ohne Grenzen erlauben?';

  @override
  String get debugBackgroundAllowMessage =>
      'Dies erlaubt der App, das Websocket im Hintergrund offen zu halten. Beim Android wird um Erlaubnis gefragt, im Hintergrund ohne Grenzen zu laufen. Fortfahren?';

  @override
  String get debugForceGroupCall => 'Gruppen-Call-Layout erzwingen';

  @override
  String get debugForceGroupCallSubtitle =>
      'Gruppen-Call-Layout auch in Direktgesprächen verwenden';

  @override
  String get debugJumpTo => 'Springen zu';

  @override
  String get debugJumpToSubtitle => 'Eine Seite über URL oder Route öffnen';

  @override
  String get debugJumpToTitle => 'Zur Seite springen';

  @override
  String get debugPageUrlOrRoute => 'Seiten-URL oder Route';

  @override
  String get debugBaseUrl => 'Basis-URL';

  @override
  String get debugApiEndpointUpdated => 'API-Endpunkt aktualisiert';

  @override
  String get debugTransport => 'Benachrichtigungskanal';

  @override
  String get debugTransportNotSelected => 'Nicht ausgewählt';

  @override
  String get debugTransportUnavailable => 'In diesem Build nicht verfügbar';

  @override
  String debugTransportNowUsing(String label) {
    return 'Benachrichtigungen nutzen jetzt $label';
  }

  @override
  String get transportApns => 'Apple Push Notification Service';

  @override
  String get transportFcm => 'Firebase Cloud Messaging';

  @override
  String get transportWebsocket => 'Hintergrundverbindung zu deinem Server';

  @override
  String get errorShowDetails => 'Details zum API-Fehler anzeigen';

  @override
  String errorHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get notificationChannelMessages => 'Nachrichten';

  @override
  String get notificationChannelDescription =>
      'Neue Nachrichten und Benachrichtigungen';

  @override
  String get notificationSentAttachment => 'Hat einen Anhang gesendet';

  @override
  String get notificationNewMessage => 'Neue Nachricht';

  @override
  String get unnamedChat => 'Chat ohne Namen';

  @override
  String get unnamedSession => 'Sitzung ohne Namen';

  @override
  String get tokenMissing => 'Token fehlt';

  @override
  String get avatarFormatError =>
      'Der Avatar muss ein JPEG-, JPG- oder PNG-Bild sein';

  @override
  String get unableToReadImage => 'Bild konnte nicht gelesen werden';

  @override
  String get avatarUploadFailed => 'Avatar-Upload fehlgeschlagen';

  @override
  String get unableToReadFile => 'Datei konnte nicht gelesen werden';

  @override
  String get fileUploadFailed => 'Datei-Upload fehlgeschlagen';

  @override
  String get requestFailed => 'Anfrage fehlgeschlagen';

  @override
  String get settingsFont => 'Schriftart';

  @override
  String get fontSystemDefault => 'Systemstandard';

  @override
  String get fontDownload => 'Herunterladen';

  @override
  String get fontDownloading => 'Wird heruntergeladen…';

  @override
  String get fontChooseFromFile => 'Aus Datei wählen';

  @override
  String get fontDownloadFailed =>
      'Schriftart konnte nicht heruntergeladen werden';

  @override
  String get fontFileUnreadable => 'Diese Datei ist keine Schriftart';

  @override
  String get fontSample =>
      'Franz jagt im komplett verwahrlosten Taxi quer durch Bayern';

  @override
  String get fontSubtitle => 'App-Schriftart';

  @override
  String get fontNotLoaded => 'Schriftart nicht geladen';

  @override
  String get fontDelete => 'Löschen';

  @override
  String get fontSource => 'Quelle';

  @override
  String fontDownloadTitle(String font) {
    return '$font herunterladen?';
  }

  @override
  String fontDownloadBody(String url) {
    return 'Die Schriftart wird von $url geladen und auf diesem Gerät gespeichert.';
  }

  @override
  String fontDeleteTitle(String font) {
    return '$font löschen?';
  }

  @override
  String fontDeleteBody(String url) {
    return 'Sie wird von diesem Gerät entfernt. Du kannst sie wieder von $url herunterladen.';
  }

  @override
  String fontDownloadingLabel(String font) {
    return '$font wird heruntergeladen…';
  }

  @override
  String get fontDeleteFailed => 'Schriftart konnte nicht gelöscht werden';

  @override
  String get fontSourceFailed => 'Link konnte nicht geöffnet werden';

  @override
  String get developerPortal => 'Entwicklerportal';

  @override
  String get developerPortalSubtitle => 'Werkzeuge für Qutty-Entwickler';

  @override
  String get botsPortalTitle => 'Bots';

  @override
  String get botsTitle => 'Bots';

  @override
  String get botsSubtitle => 'Erstelle und verwalte eigene Bots';

  @override
  String get botsCreate => 'Neuer Bot';

  @override
  String get botsCreateAction => 'Bot erstellen';

  @override
  String get botsNoBots => 'Noch keine Bots. Erstelle einen, um zu starten.';

  @override
  String get botsLoadFailed => 'Bots konnten nicht geladen werden';

  @override
  String get botsCreateFailed => 'Konnte es nicht erstellen';

  @override
  String get botsUpdated => 'Bot aktualisiert';

  @override
  String get botsDeleted => 'Gelöscht';

  @override
  String get botsCreated => 'Bot erstellt';

  @override
  String get botsDeleteTitle => 'Bot löschen?';

  @override
  String botsDeleteBody(String name) {
    return 'Bot \"$name\" löschen? Der Bot und sein Token verschwinden damit.';
  }

  @override
  String get botsResetTokenTooltip => 'Token zurücksetzen';

  @override
  String get botsResetTokenTitle => 'Token des Bots zurücksetzen?';

  @override
  String get botsResetTokenBody =>
      'Das aktuelle Token funktioniert sofort nicht mehr. Das neue Token wird nur einmal angezeigt, kopiere es also jetzt.';

  @override
  String get botsResetTokenAction => 'Token zurücksetzen';

  @override
  String get botsTokenTitle => 'Bot-Token';

  @override
  String get botsTokenCopy => 'Kopieren';

  @override
  String get botsTokenCopied => 'Kopiert';

  @override
  String get botsTokenMissing => 'Token fehlt';

  @override
  String get botsActionFailed => 'Etwas ist mit dem Bot schiefgelaufen';

  @override
  String get ugcTitle => 'Sticker und Emojis';

  @override
  String get ugcSubtitle => 'Erstelle und verwalte eigene Sticker und Emojis';

  @override
  String get ugcPortalTitle => 'Sticker und Emojis';

  @override
  String get ugcCreatePack => 'Neues Paket';

  @override
  String get ugcCreatePackAction => 'Paket erstellen';

  @override
  String get ugcPackNameRequired => 'Packname ist erforderlich.';

  @override
  String get ugcNameRequired => 'Ein Name ist erforderlich.';

  @override
  String get ugcItemImageRequired => 'Wähle zuerst ein Bild aus.';

  @override
  String get ugcChooseImage => 'Bild auswählen';

  @override
  String get ugcPackName => 'Paketname';

  @override
  String get ugcAddItem => 'Element hinzufügen';

  @override
  String get ugcItemsTitle => 'Elemente';

  @override
  String get ugcFavoritesTitle => 'Favoriten';

  @override
  String get ugcNoPacks =>
      'Noch keine Pakete. Erstelle eines, um Sticker und Emojis hinzuzufügen.';

  @override
  String get ugcNoItems => 'Dieses Paket hat noch keine Elemente.';

  @override
  String get ugcNoFavorites => 'Noch keine Favoriten.';

  @override
  String get ugcDeletePackTitle => 'Paket löschen?';

  @override
  String ugcDeletePackBody(String name) {
    return '„$name“ und alle Elemente löschen?';
  }

  @override
  String get ugcDeleteItemTitle => 'Element löschen?';

  @override
  String ugcDeleteItemBody(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get ugcCreated => 'Erstellt';

  @override
  String get ugcDeleted => 'Gelöscht';

  @override
  String get ugcCreateFailed => 'Konnte nicht erstellt werden';

  @override
  String get ugcPickerAll => 'Alle';

  @override
  String get ugcPickerFavorites => 'Favoriten';

  @override
  String get ugcPickerEmpty =>
      'Noch keine Sticker. Erstelle sie im Entwicklerportal.';

  @override
  String get ugcPickerNoPacks =>
      'Noch keine gespeicherten Packs. Speichere ein Pack, um seine Sticker hier zu sehen.';

  @override
  String get ugcPickerLoadFailed => 'Sticker konnten nicht geladen werden';

  @override
  String get ugcPickerManage => 'Im Entwicklerportal verwalten';

  @override
  String get ugcPickerSaved => 'Zu Favoriten hinzugefügt';

  @override
  String get ugcPickerRemoved => 'Aus Favoriten entfernt';

  @override
  String get ugcStickerInsert => 'Einfügen';

  @override
  String get ugcSavePack => 'Pack speichern';

  @override
  String get ugcUnsavePack => 'Gespeichertes Pack entfernen';

  @override
  String get ugcSharePack => 'Pack teilen';

  @override
  String get ugcLinkCopied => 'Link kopiert';

  @override
  String get ugcPackTitle => 'Sticker-Pack';

  @override
  String get ugcPackUnavailable => 'Dieses Sticker-Pack ist nicht verfügbar.';

  @override
  String get ugcStickerPreview => 'Sticker';

  @override
  String get debugPushServer => 'Push server';

  @override
  String get debugPushProvider => 'Push provider';

  @override
  String get debugPushRegistrationStatus => 'Push registration status';

  @override
  String get debugPushNotRegistered => 'Not registered';

  @override
  String debugPushRegisteredId(String id) {
    return 'Registered (id: $id)';
  }

  @override
  String get debugUnregisterPush => 'Unregister push';

  @override
  String get debugUnregisterPushSubtitle => 'Manually unregister this device';

  @override
  String get debugPushUnregistered => 'Push unregistered';
}

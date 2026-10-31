// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appName => 'Qutty';

  @override
  String get commonCancel => 'Скасувати';

  @override
  String get commonSave => 'Зберегти';

  @override
  String get commonSaveChanges => 'Зберегти зміни';

  @override
  String get commonClose => 'Закрити';

  @override
  String get commonCopy => 'Копіювати';

  @override
  String get commonApply => 'Застосувати';

  @override
  String get commonDelete => 'Видалити';

  @override
  String get commonRemove => 'Прибрати';

  @override
  String get commonRevoke => 'Відкликати';

  @override
  String get commonContinue => 'Продовжити';

  @override
  String get commonDismiss => 'Сховати';

  @override
  String get commonTryAgain => 'Повторити';

  @override
  String get commonOpen => 'Відкрити';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Збереження…';

  @override
  String get commonNotAvailable => 'Н/Д';

  @override
  String get commonLoading => 'завантаження';

  @override
  String get commonDetails => 'Подробиці';

  @override
  String get commonName => 'Назва';

  @override
  String get commonHandle => 'Нікнейм';

  @override
  String get commonDescription => 'Опис';

  @override
  String get commonSettings => 'Налаштування';

  @override
  String get username => 'Ім\'я користувача';

  @override
  String get password => 'Пароль';

  @override
  String get optionalEmail => 'Ел. пошта (необов\'язково)';

  @override
  String get usernamePasswordRequired =>
      'Ім\'я користувача та пароль обов\'язкові.';

  @override
  String get loginCreateAccountTitle => 'Створіть обліковий запис';

  @override
  String get loginWelcomeBackTitle => 'З поверненням';

  @override
  String get loginJoinConversation => 'Приєднуйтеся до бесіди.';

  @override
  String get loginSignInConversations => 'Увійдіть у свої бесіди.';

  @override
  String get createAccount => 'Створити обліковий запис';

  @override
  String get signIn => 'Увійти';

  @override
  String get alreadyHaveAccount => 'Вже маєте обліковий запис? Увійти';

  @override
  String get newToQutty => 'Вперше в Qutty? Створіть обліковий запис';

  @override
  String couldNotConnect(Object error) {
    return 'Не вдалося підключитися до Qutty: $error';
  }

  @override
  String get quttyApiServiceDebugging => 'Налагодження ApiService у Qutty';

  @override
  String get developerOptions => 'Налаштування розробника';

  @override
  String get apiUrl => 'URL API';

  @override
  String get jwtToken => 'JWT-токен';

  @override
  String get cancel => 'Скасувати';

  @override
  String get loginByToken => 'Увійти за токеном';

  @override
  String get enterJwtToken => 'Введіть JWT-токен.';

  @override
  String get couldNotValidateToken => 'Не вдалося перевірити токен.';

  @override
  String get selectChat => 'Виберіть чат';

  @override
  String get home => 'Головна';

  @override
  String get pageNotFound => 'Сторінку не знайдено';

  @override
  String get pageNotFoundDescription =>
      'Це означає, що помилково було відкрито недійсну сторінку.';

  @override
  String get chatsSearchHint => 'Пошук чатів, каналів, користувачів';

  @override
  String get chatsProfileTooltip => 'Профіль';

  @override
  String get chatsNewChannel => 'Новий канал';

  @override
  String get chatsNewChat => 'Новий чат';

  @override
  String get chatsEmptyTitle => 'Бесід ще немає';

  @override
  String get chatsEmptySubtitle => 'Створіть чат, щоб почати.';

  @override
  String get chatsNoMatches => 'Нічого не знайдено';

  @override
  String get chatsPreviewAndJoin => 'Переглянути й приєднатися';

  @override
  String get chatsMessageUser => 'Написати повідомлення';

  @override
  String get chatBackToChats => 'Назад до чатів';

  @override
  String get chatConversation => 'Бесіда';

  @override
  String get chatStartCall => 'Почати дзвінок';

  @override
  String get chatEndCall => 'Завершити дзвінок';

  @override
  String chatIncomingCall(String name) {
    return '$name телефонує';
  }

  @override
  String get chatOpenCall => 'Відкрити дзвінок';

  @override
  String get chatDismissCall => 'Відхилити дзвінок';

  @override
  String get chatJoinCall => 'Приєднатися до дзвінка';

  @override
  String get chatLeaveCall => 'Вийти з дзвінка';

  @override
  String get chatMinimizeCall => 'Згорнути дзвінок';

  @override
  String get chatConnectingCall => 'Підключення…';

  @override
  String get chatCalling => 'Виклик…';

  @override
  String get chatEnableWebcam => 'Увімкнути камеру';

  @override
  String get chatDisableWebcam => 'Вимкнути камеру';

  @override
  String get chatEnableScreenShare => 'Поділитися екраном';

  @override
  String get chatDisableScreenShare => 'Зупинити показ';

  @override
  String get chatEnableSpeaker => 'Динамік увімкнено';

  @override
  String get chatDisableSpeaker => 'Динамік вимкнено';

  @override
  String get chatMuteMicrophone => 'Вимкнути мікрофон';

  @override
  String get chatUnmuteMicrophone => 'Увімкнути мікрофон';

  @override
  String get chatInCall => 'Дзвінок активний';

  @override
  String get chatCallsUnsupported => 'Сервер не підтримує дзвінки';

  @override
  String get chatUnableToOpenAttachment => 'Не вдалося відкрити вкладення';

  @override
  String get chatUnableToOpenLink => 'Не вдалося відкрити посилання';

  @override
  String get chatJoined => 'Ви приєдналися до чату';

  @override
  String get chatNoJoinLink => 'У цього чату немає посилання для приєднання';

  @override
  String get chatSendFirstMessage => 'Надішліть перше повідомлення';

  @override
  String get chatNoWritePermission => 'Немає прав на надсилання повідомлень';

  @override
  String get chatJoin => 'Приєднатися до чату';

  @override
  String get chatAttachFile => 'Прикріпити файл';

  @override
  String get chatEmojiSelectButton => 'Вибрати емодзі, GIF і стікери';

  @override
  String get mediaPickerStickerTab => 'Стікер';

  @override
  String get mediaPickerEmojiTab => 'Емодзі';

  @override
  String get mediaPickerGifTab => 'GIF';

  @override
  String get mediaPickerGifSearchHint => 'Пошук GIF';

  @override
  String get mediaPickerGifFavorite => 'Зберегти в обране';

  @override
  String get mediaPickerGifUnfavorite => 'Видалити з обраного';

  @override
  String get mediaPickerGifClearSearch => 'Очистити пошук';

  @override
  String get mediaPickerGifNoFavorites =>
      'Збережених GIF ще немає. Знайдіть і натисніть, щоб зберегти.';

  @override
  String get mediaPickerGifEmpty => 'GIF не знайдено';

  @override
  String get mediaPickerGifLoadFailed => 'Не вдалося завантажити GIF';

  @override
  String get mediaPickerGifPoweredBy => 'GIF від Klipy';

  @override
  String get mediaPickerGifSend => 'Надіслати GIF';

  @override
  String get mediaPickerEmojiLoadFailed => 'Не вдалося завантажити емодзі.';

  @override
  String get mediaPickerGroupSmileysEmotion => 'Смайли та емоції';

  @override
  String get mediaPickerGroupPeopleBody => 'Люди й частини тіла';

  @override
  String get mediaPickerGroupAnimalsNature => 'Тварини й природа';

  @override
  String get mediaPickerGroupFoodDrink => 'Їжа та напиї';

  @override
  String get mediaPickerGroupTravelPlaces => 'Подорожі й місця';

  @override
  String get mediaPickerGroupActivities => 'Активності';

  @override
  String get mediaPickerGroupObjects => 'Об\'єкти';

  @override
  String get mediaPickerGroupSymbols => 'Символи';

  @override
  String get mediaPickerGroupFlags => 'Прапори';

  @override
  String get mediaPickerSkinTone => 'Відтінок шкіри';

  @override
  String get mediaPickerSkinToneDefault => 'Типово';

  @override
  String get mediaPickerSkinToneLight => 'Світлий';

  @override
  String get mediaPickerSkinToneMediumLight => 'Помірно світлий';

  @override
  String get mediaPickerSkinToneMedium => 'Середній';

  @override
  String get mediaPickerSkinToneMediumDark => 'Помірно темний';

  @override
  String get mediaPickerSkinToneDark => 'Темний';

  @override
  String get chatWriteMessage => 'Написати повідомлення';

  @override
  String get chatSend => 'Надіслати';

  @override
  String chatMessageId(int id) {
    return 'ID повідомлення: $id';
  }

  @override
  String get chatMessageRead => 'Прочитано';

  @override
  String get chatMessageSent => 'Надіслано';

  @override
  String chatReadBy(int count) {
    return 'Прочитано: $count';
  }

  @override
  String chatSelectionCount(int count) {
    return 'Вибрано: $count';
  }

  @override
  String get chatSelectionStop => 'Припинити вибір';

  @override
  String get chatMenuReply => 'Відповісти';

  @override
  String get chatReplyUnavailable => 'Початкове повідомлення';

  @override
  String get chatMenuForward => 'Переслати';

  @override
  String get chatMenuSelect => 'Вибрати';

  @override
  String get chatMenuMore => 'Ще';

  @override
  String get chatMessageCopied => 'Повідомлення скопійовано';

  @override
  String get chatActionUnavailable => 'Ще недоступно';

  @override
  String get chatForwardTitle => 'Переслати в';

  @override
  String get chatForwardSearch => 'Пошук чатів';

  @override
  String get chatForwardNoChats => 'Немає чатів для пересилання';

  @override
  String get chatForwarded => 'Переслано';

  @override
  String chatForwardedFrom(String author) {
    return 'Переслано від $author';
  }

  @override
  String get chatForwardedOpen => 'Відкрити оригінал';

  @override
  String chatForwardedTo(String chat) {
    return 'Переслано в $chat';
  }

  @override
  String get settingsChats => 'Чати';

  @override
  String get settingsReadCount =>
      'Показувати кількість прочитаних замість галочок';

  @override
  String get settingsReadCountSubtitle =>
      'У приватних чатах показувати, скільки людей прочитали повідомлення, замість галочки';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get settingsCustomization => 'Оформлення';

  @override
  String get settingsCustomizationSubtitle => 'Тема та акцентний колір';

  @override
  String get settingsConnectivity => 'Підключення';

  @override
  String get settingsNotifications => 'Сповіщення';

  @override
  String get settingsAccount => 'Обліковий запис';

  @override
  String get settingsAccounts => 'Облікові записи';

  @override
  String get settingsAccountDefaultLabel => 'Обліковий запис';

  @override
  String get settingsAccountSafety => 'Безпека облікового запису';

  @override
  String get settingsAbout => 'Про застосунок';

  @override
  String get settingsEditProfile => 'Змінити профіль';

  @override
  String get settingsChangePassword => 'Змінити пароль';

  @override
  String get settingsChangePasswordSubtitle =>
      'Оновіть пароль від облікового запису';

  @override
  String get settingsChangeEmail => 'Змінити ел. пошту';

  @override
  String get settingsNoEmailOnFile => 'Ел. пошту не вказано';

  @override
  String get settingsActiveSessions => 'Активні сеанси';

  @override
  String get settingsActiveSessionsSubtitle =>
      'Керуйте пристроями, які виконали вхід до облікового запису';

  @override
  String get settingsRemoveAccount => 'Прибрати обліковий запис';

  @override
  String get settingsAddAccount => 'Додати обліковий запис';

  @override
  String get settingsAddAccountSubtitle =>
      'Увійдіть на інший сервер або в інший обліковий запис';

  @override
  String get settingsDeleteAccount => 'Видалити обліковий запис';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Назавжди видалить ваш обліковий запис Qutty';

  @override
  String get settingsVersionPlaceholder => 'Placeholder#424738';

  @override
  String get settingsLogOut => 'Вийти';

  @override
  String get settingsPasswordUpdated => 'Пароль оновлено';

  @override
  String get settingsEmailUpdated => 'Ел. пошту оновлено';

  @override
  String get settingsLogOutTitle => 'Вийти?';

  @override
  String get settingsLogOutBody =>
      'Щоб увійти знову, доведеться ще раз ввести пароль.';

  @override
  String get settingsDeleteAccountTitle => 'Видалити обліковий запис?';

  @override
  String get settingsDeleteAccountBody =>
      'Введіть ім\'я користувача та пароль, щоб назавжди видалити обліковий запис і всі дані.';

  @override
  String get settingsEditProfileTooltip => 'Змінити профіль';

  @override
  String get settingsCalls => 'Дзвінки';

  @override
  String get settingsCallWebcam => 'Веб-камера';

  @override
  String get settingsCallWebcamSubtitle =>
      'Починати дзвінки з увімкненою камерою';

  @override
  String get settingsCallCamera => 'Камера';

  @override
  String get settingsCallCameraFront => 'Фронтальна';

  @override
  String get settingsCallCameraBack => 'Задня';

  @override
  String get settingsCallLoudspeaker => 'Гучний зв\'язок';

  @override
  String get settingsCallLoudspeakerSubtitle =>
      'Відтворювати звук дзвінка через динамік';

  @override
  String get settingsCallMic => 'Мікрофон';

  @override
  String get settingsCallMicSubtitle =>
      'Починати дзвінки з увімкненим мікрофоном';

  @override
  String get settingsCallScreenShare => 'Скринкаст';

  @override
  String get settingsCallScreenShareSubtitle =>
      'Дозволити демонстрацію екрана під час дзвінків';

  @override
  String get settingsAudio => 'Звук';

  @override
  String get settingsAudioInput => 'Мікрофон';

  @override
  String get settingsAudioOutput => 'Динаміки';

  @override
  String get settingsAudioCamera => 'Камера';

  @override
  String get settingsAudioSystemDefault => 'Системний за замовчуванням';

  @override
  String get settingsAudioNoDevices => 'Пристрої не знайдено';

  @override
  String get settingsAudioNoiseReduction => 'Шумозаглушення';

  @override
  String get settingsAudioNoiseReductionSubtitle =>
      'Пригнічувати фоновий шум під час дзвінків';

  @override
  String get settingsAudioMicVolume => 'Гучність мікрофона';

  @override
  String get settingsAudioSpeakerVolume => 'Гучність динаміків';

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
  String get screenSharePickTitle => 'Виберіть, чим поділитися';

  @override
  String get screenSharePickScreens => 'Екрани';

  @override
  String get screenSharePickWindows => 'Вікна';

  @override
  String get screenSharePickEmpty => 'Екрани та вікна не знайдено';

  @override
  String get screenSharePickError => 'Не вдалося завантажити екрани та вікна';

  @override
  String get screenSharePickRetry => 'Спробувати знову';

  @override
  String get notificationsToggle => 'Сповіщення про повідомлення';

  @override
  String get notificationsOffForDevice => 'Вимкнено на цьому пристрої';

  @override
  String get notificationsOpenWithBackground =>
      'Сигнали, поки застосунок відкритий і у фоні';

  @override
  String get notificationsOpenOnly => 'Сигнали, поки застосунок відкритий';

  @override
  String get notificationsOpenBackgroundConnection =>
      'Сигнали, поки застосунок відкритий (фонове підключення)';

  @override
  String get notificationsPermissionHint =>
      'Дозвольте сповіщення Qutty в системних налаштуваннях, щоб отримувати сигнали у фоні.';

  @override
  String get connectionStatus => 'Стан підключення';

  @override
  String get connectionLiveWebsocket => 'Стан активного вебсокета';

  @override
  String get connectionReconnect => 'Перепідключити';

  @override
  String get connectionConnected => 'Підключено';

  @override
  String get connectionConnecting => 'Підключення…';

  @override
  String get connectionDisconnected => 'Від\'єднано';

  @override
  String sessionsRevokeTitle(String name) {
    return 'Відкликати сеанс $name?';
  }

  @override
  String get sessionsRevokeBody =>
      'Інші пристрої, які використовують цей сеанс, буде від\'єднано.';

  @override
  String get sessionsRevoked => 'Сеанс відкликано';

  @override
  String get sessionsLoadFailed => 'Не вдалося завантажити сеанси';

  @override
  String get sessionsNone => 'Немає активних сеансів';

  @override
  String get sessionsThisDevice => 'Цей пристрій';

  @override
  String sessionsLastActive(String time) {
    return 'Активність $time';
  }

  @override
  String get sessionsCurrentBadge => 'Поточний';

  @override
  String get timeJustNow => 'щойно';

  @override
  String timeMinutesAgo(int count) {
    return '$count хв тому';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count год тому';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count дн тому';
  }

  @override
  String get languageTitle => 'Мова';

  @override
  String get languageSubtitle => 'Мова застосунку';

  @override
  String get languageSystemDefault => 'Як у системі';

  @override
  String get themeLabel => 'Тема';

  @override
  String get accentColorLabel => 'Акцентний колір';

  @override
  String get themeSystem => 'Системна';

  @override
  String get themeDark => 'Темна';

  @override
  String get themeLight => 'Світла';

  @override
  String get accentQuttyBlue => 'Синій Qutty';

  @override
  String get accentCustom => 'Власний';

  @override
  String get customAccentColor => 'Власний акцентний колір';

  @override
  String get hexColor => 'HEX-кольор';

  @override
  String get roleOwner => 'Власник';

  @override
  String get roleAdmin => 'Адміністратор';

  @override
  String get roleRestricted => 'Обмежений';

  @override
  String get roleMember => 'Учасник';

  @override
  String get accountNewEmail => 'Нова ел. пошта';

  @override
  String get accountCurrentPassword => 'Поточний пароль';

  @override
  String get accountConfirmPassword => 'Підтвердьте пароль';

  @override
  String get accountNewPassword => 'Новий пароль';

  @override
  String get chatSettingsTitle => 'Налаштування чату';

  @override
  String get chatSettingsLeaveTitle => 'Покинути чат?';

  @override
  String get chatSettingsLeaveBody =>
      'Ви втратите доступ до цього чату, доки вас знову не запросить адміністратор.';

  @override
  String get chatSettingsLeave => 'Покинути';

  @override
  String chatSettingsDeleteTitle(String name) {
    return 'Видалити $name?';
  }

  @override
  String get chatSettingsDeleteBody =>
      'Усі повідомлення та учасники буде видалено назавжди. Це не можна скасувати.';

  @override
  String get chatSettingsLoadFailed => 'Не вдалося завантажити налаштування';

  @override
  String get chatSettingsProfileSection => 'Профіль';

  @override
  String get chatSettingsEditProfileSubtitle =>
      'Назва, нікнейм, опис і зображення';

  @override
  String get chatSettingsCreateInvite => 'Створити посилання-запрошення';

  @override
  String get chatSettingsCreateInviteSubtitle =>
      'Створіть запрошення, яким можна поділитися';

  @override
  String get chatSettingsPermissions => 'Права доступу';

  @override
  String get chatSettingsMembers => 'Учасники';

  @override
  String get chatSettingsMembersSubtitle => 'Перегляд і керування учасниками';

  @override
  String get chatSettingsAccessControl => 'Контроль доступу';

  @override
  String get chatSettingsAccessControlSubtitle =>
      'Права учасників за замовчуванням';

  @override
  String get chatSettingsDirectMessage => 'Особисте повідомлення';

  @override
  String get chatSettingsOpenContactProfile => 'Відкрити профіль контакту';

  @override
  String get chatSettingsDangerZone => 'Небезпечна зона';

  @override
  String get chatSettingsLeaveTile => 'Покинути чат';

  @override
  String get chatSettingsDeleteTile => 'Видалити чат';

  @override
  String get chatSettingsDeleteTileSubtitle =>
      'Видалити цей чат може лише його творець';

  @override
  String get chatSettingsInviteTitle => 'Посилання-запрошення';

  @override
  String get chatSettingsInviteBody =>
      'Поділіться цим посиланням із тими, кого хочете запросити. Його скопійовано в буфер обміну.';

  @override
  String get chatSettingsInviteCopied => 'Посилання-запрошення скопійовано';

  @override
  String get aclDefaultPermissions => 'Права учасників за замовчуванням';

  @override
  String get aclDescription =>
      'Ці права діють для звичайних учасників. Адміністратори завжди мають доступ до керування.';

  @override
  String get aclSavePermissions => 'Зберегти права';

  @override
  String get aclEditMessages => 'Редагувати повідомлення';

  @override
  String get aclEditMessagesDescription =>
      'Дозволяє учасникам редагувати повідомлення.';

  @override
  String get permissionWriteMessages => 'Надсилати повідомлення';

  @override
  String get permissionWriteMessagesDescription =>
      'Дозволяє учасникам надсилати нові повідомлення.';

  @override
  String get permissionDeleteOthersMessages => 'Видаляти чужі повідомлення';

  @override
  String get permissionDeleteOthersMessagesDescription =>
      'Дозволяє учасникам видаляти повідомлення інших людей.';

  @override
  String get permissionEditOthersMessages => 'Редагувати чужі повідомлення';

  @override
  String get permissionEditOthersMessagesDescription =>
      'Дозволяє учасникам редагувати повідомлення інших людей.';

  @override
  String get permissionRestrictUsers => 'Керувати учасниками';

  @override
  String get permissionRestrictUsersDescription =>
      'Дозволяє учасникам прибирати або обмежувати інших учасників.';

  @override
  String get permissionEditProfile => 'Редагувати профіль чату';

  @override
  String get permissionEditProfileDescription =>
      'Дозволяє учасникам змінювати назву та опис чату.';

  @override
  String get permissionAddAdmins => 'Керувати адміністраторами';

  @override
  String get permissionAddAdminsDescription =>
      'Дозволяє учасникам підвищувати інших учасників.';

  @override
  String get membersTitle => 'Учасники';

  @override
  String get membersLoadFailed => 'Не вдалося завантажити учасників';

  @override
  String get membersYou => 'Ви';

  @override
  String get membersMore => 'Ще';

  @override
  String get membersViewProfile => 'Переглянути профіль';

  @override
  String membersGiveChat(String name) {
    return 'Передати $name цьому користувачеві';
  }

  @override
  String get membersManagePermissions => 'Керувати правами';

  @override
  String get membersRemoveFromChat => 'Прибрати з чату';

  @override
  String membersRemoveTitle(String name) {
    return 'Прибрати $name?';
  }

  @override
  String get membersRemoveBody => 'Ця людина одразу втратить доступ до чату.';

  @override
  String membersOwnershipGiven(String name) {
    return 'Власність чатом передано користувачеві $name';
  }

  @override
  String get membersTransferTitle => 'Дані майбутнього власника';

  @override
  String get membersTransferAttention => 'УВАГА!';

  @override
  String membersTransferUsername(String username) {
    return 'ІМ\'Я КОРИСТУВАЧА: $username';
  }

  @override
  String membersTransferAcknowledge(String chat, String username) {
    return 'Я розумію, що втрачу власність $chat, а $username отримає $chat.';
  }

  @override
  String get membersEnterPassword => 'Введіть пароль';

  @override
  String membersGiveConfirm(String chat, String username) {
    return 'Передати $chat користувачеві $username';
  }

  @override
  String get membersOwnerLocked => 'Власника чату не можна змінити.';

  @override
  String get createChatNewChannel => 'Новий канал';

  @override
  String get createChatNewChat => 'Новий чат';

  @override
  String get createChatClose => 'Закрити';

  @override
  String get createChatCreateChannel => 'Створити канал';

  @override
  String get createChatCreateChat => 'Створити чат';

  @override
  String get createChatChooseAvatar => 'Вибрати аватар';

  @override
  String get createChatDisplayName => 'Відображуване ім\'я';

  @override
  String get createChatUsernameOptional => 'Ім\'я користувача (необов\'язково)';

  @override
  String get createChatUsernameOptionalHelper =>
      'Можна залишити порожнім і додати пізніше.';

  @override
  String get createChatNameRequired => 'Відображуване ім\'я обов\'язкове.';

  @override
  String get joinPreviewTitle => 'Приєднатися до чату';

  @override
  String get joinPreviewInvalidLink => 'Некоректне посилання-запрошення';

  @override
  String get joinPreviewJoining => 'Підключення…';

  @override
  String get joinPreviewJoin => 'Приєднатися';

  @override
  String get editProfileChangeAvatar => 'Змінити аватар';

  @override
  String get editProfileRemoveAvatar => 'Прибрати аватар';

  @override
  String get editProfileBio => 'Про себе';

  @override
  String get editProfileNameEmpty =>
      'Відображуване ім\'я не може бути порожнім';

  @override
  String get editProfileHandleReserved =>
      'Нікнейм не може бути _, цей нікнейм зарезервовано для скидання нікнейма';

  @override
  String get editChatChannelSettings => 'Налаштування каналу';

  @override
  String get editChatTapForPicture => 'Натисніть, щоб змінити зображення чату';

  @override
  String get editChatUpload => 'Завантажити';

  @override
  String get editChatReplace => 'Замінити';

  @override
  String get editChatHandleHelper =>
      'Використовується, щоб поділитися чатом як @нікнейм';

  @override
  String get profileUnableToOpen => 'Не вдалося відкрити';

  @override
  String profileError(String error) {
    return 'Помилка: $error';
  }

  @override
  String get profileNotFound => 'Профіль не знайдено';

  @override
  String profileChatId(int id) {
    return 'ID чату: $id';
  }

  @override
  String profileUserId(int id) {
    return 'ID користувача: $id';
  }

  @override
  String profileTabMedia(int count) {
    return 'Медіа ($count)';
  }

  @override
  String profileTabGifs(int count) {
    return 'Гіфки ($count)';
  }

  @override
  String profileTabLinks(int count) {
    return 'Посилання ($count)';
  }

  @override
  String profileTabFiles(int count) {
    return 'Файли ($count)';
  }

  @override
  String get profileNoMedia => 'Медіа ще немає';

  @override
  String get profileNoGifs => 'Гіфок ще немає';

  @override
  String get profileNoLinks => 'Посилань ще немає';

  @override
  String get profileNoFiles => 'Файлів ще немає';

  @override
  String get aboutTerms => 'Умови використання та політика конфіденційності';

  @override
  String get aboutLicenses => 'Ліцензії відкритого коду';

  @override
  String aboutBuild(String build) {
    return 'Збірка: $build';
  }

  @override
  String aboutCopyright(String version) {
    return 'Qutty - RdProjects 2026 © Усі права захищено\nВерсія: $version';
  }

  @override
  String get debugTitle => 'Quttycaka';

  @override
  String get debugWarning =>
      'Ці налаштування потрібні лише для розробки та налагодження. \nЇхня зміна може призвести до непередбачуваної поведінки.\nПродовжуйте, лише якщо точно знаєте, що робите.\n - QuttyTeam у RdProjects';

  @override
  String get debugSubtitle =>
      'Налаштування розробки/налагодження, він же Quttycaka';

  @override
  String get debugApiEndpoint => 'Адреса API';

  @override
  String get debugDeveloperInfo => 'Дані для розробника';

  @override
  String get debugDeveloperInfoSubtitle =>
      'Показувати ID профілів і повідомлень';

  @override
  String get debugFallbackSelectorCast => 'FallBackSelectorCast';

  @override
  String get debugFallbackSelectorCastSubtitle =>
      'Завжди використовувати власний вибір екрана застосунку замість системного';

  @override
  String get debugKeepWebsocketAlive =>
      'Підтримувати WebSocket у фоновому режимі';

  @override
  String get debugKeepWebsocketAliveSubtitle =>
      'Підтримувати WebSocket підключеним у фоновому режимі';

  @override
  String get debugBackgroundAllowTitle => 'Дозволити фон без обмежень?';

  @override
  String get debugBackgroundAllowMessage =>
      'Це дозволяє застосунку тримати WebSocket відкритим, поки він не на передньому плані. У Android це запитує дозвіл на роботу в фоновому режимі без обмежень. Продовжити?';

  @override
  String get debugForceGroupCall => 'Примусовий макет групового дзвінка';

  @override
  String get debugForceGroupCallSubtitle =>
      'Використовувати макет групового дзвінка навіть в особистих дзвінках';

  @override
  String get debugJumpTo => 'Перейти';

  @override
  String get debugJumpToSubtitle => 'Відкрити сторінку за URL або маршрутом';

  @override
  String get debugJumpToTitle => 'Перейти до сторінки';

  @override
  String get debugPageUrlOrRoute => 'URL або маршрут сторінки';

  @override
  String get debugBaseUrl => 'Базовий URL';

  @override
  String get debugApiEndpointUpdated => 'Адресу API оновлено';

  @override
  String get debugTransport => 'Канал доставки сповіщень';

  @override
  String get debugTransportNotSelected => 'Не вибрано';

  @override
  String get debugTransportUnavailable => 'Недоступно в цій збірці';

  @override
  String debugTransportNowUsing(String label) {
    return 'Сповіщення тепер надсилаються через $label';
  }

  @override
  String get transportApns => 'Служба push-сповіщень Apple';

  @override
  String get transportFcm => 'Firebase Cloud Messaging';

  @override
  String get transportWebsocket => 'Фонове підключення до вашого сервера';

  @override
  String get errorShowDetails => 'Показати подробиці помилки API';

  @override
  String errorHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get notificationChannelMessages => 'Повідомлення';

  @override
  String get notificationChannelDescription => 'Нові повідомлення та сигнали';

  @override
  String get notificationSentAttachment => 'Надіслав вкладення';

  @override
  String get notificationNewMessage => 'Нове повідомлення';

  @override
  String get unnamedChat => 'Чат без назви';

  @override
  String get unnamedSession => 'Сеанс без назви';

  @override
  String get tokenMissing => 'Відсутній токен';

  @override
  String get avatarFormatError =>
      'Аватар має бути зображенням JPEG, JPG або PNG';

  @override
  String get unableToReadImage => 'Не вдалося прочитати зображення';

  @override
  String get avatarUploadFailed => 'Не вдалося завантажити аватар';

  @override
  String get unableToReadFile => 'Не вдалося прочитати файл';

  @override
  String get fileUploadFailed => 'Не вдалося завантажити файл';

  @override
  String get requestFailed => 'Запит не виконано';

  @override
  String get settingsFont => 'Шрифт';

  @override
  String get fontSystemDefault => 'Системний шрифт';

  @override
  String get fontDownload => 'Завантажити';

  @override
  String get fontDownloading => 'Завантаження…';

  @override
  String get fontChooseFromFile => 'Вибрати файл';

  @override
  String get fontDownloadFailed => 'Не вдалося завантажити шрифт';

  @override
  String get fontFileUnreadable => 'Це не файл шрифту';

  @override
  String get fontSample =>
      'Чуєш їх доцю га? Кумедна ж ти, прощайся без ґольфів!';

  @override
  String get fontSubtitle => 'Шрифт застосунку';

  @override
  String get fontNotLoaded => 'Шрифт не завантажено';

  @override
  String get fontDelete => 'Видалити';

  @override
  String get fontSource => 'Джерело';

  @override
  String fontDownloadTitle(String font) {
    return 'Завантажити $font?';
  }

  @override
  String fontDownloadBody(String url) {
    return 'Шрифт завантажується з $url і зберігається на цьому пристрої.';
  }

  @override
  String fontDeleteTitle(String font) {
    return 'Видалити $font?';
  }

  @override
  String fontDeleteBody(String url) {
    return 'Він буде видалено з цього пристрою. Його можна знову завантажити з $url.';
  }

  @override
  String fontDownloadingLabel(String font) {
    return 'Завантаження $font…';
  }

  @override
  String get fontDeleteFailed => 'Не вдалося видалити шрифт';

  @override
  String get fontSourceFailed => 'Не вдалося відкрити посилання';

  @override
  String get developerPortal => 'Портал розробника';

  @override
  String get developerPortalSubtitle => 'Інструменти для розробників Qutty';

  @override
  String get botsPortalTitle => 'Боти';

  @override
  String get botsTitle => 'Боти';

  @override
  String get botsSubtitle => 'Створюйте та керуйте своими ботами';

  @override
  String get botsCreate => 'Новий бот';

  @override
  String get botsCreateAction => 'Створити бота';

  @override
  String get botsNoBots => 'Поки немає ботів. Створіть першого, щоб почати.';

  @override
  String get botsLoadFailed => 'Не вдалося завантажити ботів';

  @override
  String get botsCreateFailed => 'Не вдалося створити';

  @override
  String get botsUpdated => 'Бот оновлено';

  @override
  String get botsDeleted => 'Бот видалено';

  @override
  String get botsCreated => 'Бот створено';

  @override
  String get botsDeleteTitle => 'Видалити бота?';

  @override
  String botsDeleteBody(String name) {
    return 'Видалити бота \"$name\"? Бот і його токен зникнуть.';
  }

  @override
  String get botsResetTokenTooltip => 'Скинути токен';

  @override
  String get botsResetTokenTitle => 'Скинути токен бота?';

  @override
  String get botsResetTokenBody =>
      'Поточний токен негайно перестане працювати. Новий токен показується один раз, тому скопіюйте його зараз.';

  @override
  String get botsResetTokenAction => 'Скинути токен';

  @override
  String get botsTokenTitle => 'Токен бота';

  @override
  String get botsTokenCopy => 'Копіювати';

  @override
  String get botsTokenCopied => 'Скопійовано';

  @override
  String get botsTokenMissing => 'Токен відсутній';

  @override
  String get botsActionFailed => 'Щось пішло не так з ботом';

  @override
  String get ugcTitle => 'Стикери та емодзі';

  @override
  String get ugcSubtitle => 'Створюйте власні стікери та емодзі й керуйте ними';

  @override
  String get ugcPortalTitle => 'Стикери та емодзі';

  @override
  String get ugcCreatePack => 'Новий набір';

  @override
  String get ugcCreatePackAction => 'Створити набір';

  @override
  String get ugcPackNameRequired => 'Назва набору обов\'язкова.';

  @override
  String get ugcNameRequired => 'Ім\'я обов\'язкове.';

  @override
  String get ugcItemImageRequired => 'Спочатку виберіть зображення.';

  @override
  String get ugcChooseImage => 'Вибрати зображення';

  @override
  String get ugcPackName => 'Назва набору';

  @override
  String get ugcAddItem => 'Додати елемент';

  @override
  String get ugcItemsTitle => 'Елементи';

  @override
  String get ugcFavoritesTitle => 'Обране';

  @override
  String get ugcNoPacks =>
      'Наборів ще немає. Створіть набір, щоб додавати стікери та емодзі.';

  @override
  String get ugcNoItems => 'У цьому наборі ще немає елементів.';

  @override
  String get ugcNoFavorites => 'В обраному ще нічого немає.';

  @override
  String get ugcDeletePackTitle => 'Видалити набір?';

  @override
  String ugcDeletePackBody(String name) {
    return 'Видалити «$name» та всі його елементи?';
  }

  @override
  String get ugcDeleteItemTitle => 'Видалити елемент?';

  @override
  String ugcDeleteItemBody(String name) {
    return 'Видалити «$name»?';
  }

  @override
  String get ugcCreated => 'Створено';

  @override
  String get ugcDeleted => 'Видалено';

  @override
  String get ugcCreateFailed => 'Не вдалося створити';

  @override
  String get ugcPickerAll => 'Усі';

  @override
  String get ugcPickerFavorites => 'Обране';

  @override
  String get ugcPickerEmpty =>
      'Стікерів ще немає. Створіть їх у Порталі розробника.';

  @override
  String get ugcPickerNoPacks =>
      'Збережених паків ще немає. Збережіть пак, щоб побачити його стікери тут.';

  @override
  String get ugcPickerLoadFailed => 'Не вдалося завантажити стікери';

  @override
  String get ugcPickerManage => 'Керувати в Порталі розробника';

  @override
  String get ugcPickerSaved => 'Додано в обране';

  @override
  String get ugcPickerRemoved => 'Видалено з обраного';

  @override
  String get ugcStickerInsert => 'Вставити';

  @override
  String get ugcSavePack => 'Зберегти пак';

  @override
  String get ugcUnsavePack => 'Видалити збережений пак';

  @override
  String get ugcSharePack => 'Поділитися паком';

  @override
  String get ugcLinkCopied => 'Посилання скопійовано';

  @override
  String get ugcPackTitle => 'Набір стікерів';

  @override
  String get ugcPackUnavailable => 'Цей набір стікерів недоступний.';

  @override
  String get ugcStickerPreview => 'Стікер';

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

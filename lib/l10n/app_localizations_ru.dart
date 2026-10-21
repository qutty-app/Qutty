// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Qutty';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonSaveChanges => 'Сохранить изменения';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonApply => 'Применить';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonRemove => 'Убрать';

  @override
  String get commonRevoke => 'Отозвать';

  @override
  String get commonContinue => 'Продолжить';

  @override
  String get commonDismiss => 'Скрыть';

  @override
  String get commonTryAgain => 'Повторить';

  @override
  String get commonOpen => 'Открыть';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonSaving => 'Сохранение…';

  @override
  String get commonNotAvailable => 'Н/Д';

  @override
  String get commonLoading => 'загрузка';

  @override
  String get commonDetails => 'Подробности';

  @override
  String get commonName => 'Название';

  @override
  String get commonHandle => 'Никнейм';

  @override
  String get commonDescription => 'Описание';

  @override
  String get commonSettings => 'Настройки';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get optionalEmail => 'Эл. почта (необязательно)';

  @override
  String get usernamePasswordRequired =>
      'Имя пользователя и пароль обязательны.';

  @override
  String get loginCreateAccountTitle => 'Создайте аккаунт';

  @override
  String get loginWelcomeBackTitle => 'С возвращением';

  @override
  String get loginJoinConversation => 'Присоединяйтесь к беседе.';

  @override
  String get loginSignInConversations => 'Войдите в свои беседы.';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get signIn => 'Войти';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get newToQutty => 'Впервые в Qutty? Создайте аккаунт';

  @override
  String couldNotConnect(Object error) {
    return 'Не удалось подключиться к Qutty: $error';
  }

  @override
  String get quttyApiServiceDebugging => 'Отладка ApiService в Qutty';

  @override
  String get developerOptions => 'Настройки разработчика';

  @override
  String get apiUrl => 'URL API';

  @override
  String get jwtToken => 'JWT-токен';

  @override
  String get cancel => 'Отмена';

  @override
  String get loginByToken => 'Войти по токену';

  @override
  String get enterJwtToken => 'Введите JWT-токен.';

  @override
  String get couldNotValidateToken => 'Не удалось проверить токен.';

  @override
  String get selectChat => 'Выберите чат';

  @override
  String get home => 'Главная';

  @override
  String get pageNotFound => 'Страница не найдена';

  @override
  String get pageNotFoundDescription =>
      'Это означает, что по ошибке была открыта недопустимая страница.';

  @override
  String get chatsSearchHint => 'Поиск чатов, каналов, пользователей';

  @override
  String get chatsProfileTooltip => 'Профиль';

  @override
  String get chatsNewChannel => 'Новый канал';

  @override
  String get chatsNewChat => 'Новый чат';

  @override
  String get chatsEmptyTitle => 'Пока нет бесед';

  @override
  String get chatsEmptySubtitle => 'Создайте чат, чтобы начать.';

  @override
  String get chatsNoMatches => 'Ничего не найдено';

  @override
  String get chatsPreviewAndJoin => 'Посмотреть и присоединиться';

  @override
  String get chatsMessageUser => 'Написать сообщение';

  @override
  String get chatBackToChats => 'Назад к чатам';

  @override
  String get chatConversation => 'Беседа';

  @override
  String get chatStartCall => 'Начать звонок';

  @override
  String get chatEndCall => 'Завершить звонок';

  @override
  String chatIncomingCall(String name) {
    return '$name звонит';
  }

  @override
  String get chatOpenCall => 'Открыть звонок';

  @override
  String get chatDismissCall => 'Отклонить звонок';

  @override
  String get chatJoinCall => 'Присоединиться к звонку';

  @override
  String get chatLeaveCall => 'Покинуть звонок';

  @override
  String get chatMinimizeCall => 'Свернуть звонок';

  @override
  String get chatConnectingCall => 'Подключение…';

  @override
  String get chatCalling => 'Звоним…';

  @override
  String get chatEnableWebcam => 'Включить камеру';

  @override
  String get chatDisableWebcam => 'Выключить камеру';

  @override
  String get chatEnableScreenShare => 'Поделиться экраном';

  @override
  String get chatDisableScreenShare => 'Остановить показ';

  @override
  String get chatEnableSpeaker => 'Динамик включён';

  @override
  String get chatDisableSpeaker => 'Динамик выключен';

  @override
  String get chatMuteMicrophone => 'Выключить микрофон';

  @override
  String get chatUnmuteMicrophone => 'Включить микрофон';

  @override
  String get chatInCall => 'Звонок активен';

  @override
  String get chatCallsUnsupported => 'Сервер не поддерживает звонки';

  @override
  String get chatUnableToOpenAttachment => 'Не удалось открыть вложение';

  @override
  String get chatUnableToOpenLink => 'Не удалось открыть ссылку';

  @override
  String get chatJoined => 'Вы присоединились к чату';

  @override
  String get chatNoJoinLink => 'У этого чата нет ссылки для присоединения';

  @override
  String get chatSendFirstMessage => 'Отправьте первое сообщение';

  @override
  String get chatNoWritePermission => 'Нет прав на отправку сообщений';

  @override
  String get chatJoin => 'Присоединиться к чату';

  @override
  String get chatAttachFile => 'Прикрепить файл';

  @override
  String get chatEmojiSelectButton => 'Выбрать эмодзи, GIF и стикеры';

  @override
  String get mediaPickerStickerTab => 'Стикер';

  @override
  String get mediaPickerEmojiTab => 'Эмодзи';

  @override
  String get mediaPickerGifTab => 'GIF';

  @override
  String get mediaPickerGifSearchHint => 'Поиск GIF';

  @override
  String get mediaPickerGifFavorite => 'Сохранить в избранное';

  @override
  String get mediaPickerGifUnfavorite => 'Убрать из избранного';

  @override
  String get mediaPickerGifClearSearch => 'Очистить поиск';

  @override
  String get mediaPickerGifNoFavorites =>
      'Сохранённых GIF пока нет. Найдите и нажмите, чтобы сохранить.';

  @override
  String get mediaPickerGifEmpty => 'GIF не найдены';

  @override
  String get mediaPickerGifLoadFailed => 'Не удалось загрузить GIF';

  @override
  String get mediaPickerGifPoweredBy => 'GIF от Klipy';

  @override
  String get mediaPickerGifSend => 'Отправить GIF';

  @override
  String get mediaPickerEmojiLoadFailed => 'Не удалось загрузить эмодзи.';

  @override
  String get mediaPickerGroupSmileysEmotion => 'Смайлы и эмоции';

  @override
  String get mediaPickerGroupPeopleBody => 'Люди и части тела';

  @override
  String get mediaPickerGroupAnimalsNature => 'Животные и природа';

  @override
  String get mediaPickerGroupFoodDrink => 'Еда и напитки';

  @override
  String get mediaPickerGroupTravelPlaces => 'Путешествия и места';

  @override
  String get mediaPickerGroupActivities => 'Активности';

  @override
  String get mediaPickerGroupObjects => 'Объекты';

  @override
  String get mediaPickerGroupSymbols => 'Символы';

  @override
  String get mediaPickerGroupFlags => 'Флаги';

  @override
  String get mediaPickerSkinTone => 'Тон кожи';

  @override
  String get mediaPickerSkinToneDefault => 'По умолчанию';

  @override
  String get mediaPickerSkinToneLight => 'Светлый';

  @override
  String get mediaPickerSkinToneMediumLight => 'Умеренно светлый';

  @override
  String get mediaPickerSkinToneMedium => 'Средний';

  @override
  String get mediaPickerSkinToneMediumDark => 'Умеренно тёмный';

  @override
  String get mediaPickerSkinToneDark => 'Тёмный';

  @override
  String get chatWriteMessage => 'Написать сообщение';

  @override
  String get chatSend => 'Отправить';

  @override
  String chatMessageId(int id) {
    return 'ID сообщения: $id';
  }

  @override
  String get chatMessageRead => 'Прочитано';

  @override
  String get chatMessageSent => 'Отправлено';

  @override
  String chatReadBy(int count) {
    return 'Прочитано: $count';
  }

  @override
  String chatSelectionCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get chatSelectionStop => 'Прекратить выбор';

  @override
  String get chatMenuReply => 'Ответить';

  @override
  String get chatReplyUnavailable => 'Исходное сообщение';

  @override
  String get chatMenuForward => 'Переслать';

  @override
  String get chatMenuSelect => 'Выбрать';

  @override
  String get chatMenuMore => 'Ещё';

  @override
  String get chatMessageCopied => 'Сообщение скопировано';

  @override
  String get chatActionUnavailable => 'Пока недоступно';

  @override
  String get chatForwardTitle => 'Переслать в';

  @override
  String get chatForwardSearch => 'Поиск чатов';

  @override
  String get chatForwardNoChats => 'Нет чатов для пересылки';

  @override
  String get chatForwarded => 'Переслано';

  @override
  String chatForwardedFrom(String author) {
    return 'Переслано от $author';
  }

  @override
  String get chatForwardedOpen => 'Открыть оригинал';

  @override
  String chatForwardedTo(String chat) {
    return 'Переслано в $chat';
  }

  @override
  String get settingsChats => 'Чаты';

  @override
  String get settingsReadCount => 'Показывать число прочитавших вместо галочек';

  @override
  String get settingsReadCountSubtitle =>
      'В личных чатах показывать, сколько человек прочитали сообщение, вместо галочки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsCustomization => 'Оформление';

  @override
  String get settingsCustomizationSubtitle => 'Тема и акцентный цвет';

  @override
  String get settingsConnectivity => 'Подключение';

  @override
  String get settingsNotifications => 'Уведомления';

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsAccounts => 'Аккаунты';

  @override
  String get settingsAccountDefaultLabel => 'Аккаунт';

  @override
  String get settingsAccountSafety => 'Безопасность аккаунта';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String get settingsEditProfile => 'Изменить профиль';

  @override
  String get settingsChangePassword => 'Сменить пароль';

  @override
  String get settingsChangePasswordSubtitle => 'Обновите пароль от аккаунта';

  @override
  String get settingsChangeEmail => 'Сменить эл. почту';

  @override
  String get settingsNoEmailOnFile => 'Эл. почта не указана';

  @override
  String get settingsActiveSessions => 'Активные сеансы';

  @override
  String get settingsActiveSessionsSubtitle =>
      'Управляйте устройствами, выполнившими вход в аккаунт';

  @override
  String get settingsRemoveAccount => 'Убрать аккаунт';

  @override
  String get settingsAddAccount => 'Добавить аккаунт';

  @override
  String get settingsAddAccountSubtitle =>
      'Войдите на другой сервер или в другой аккаунт';

  @override
  String get settingsDeleteAccount => 'Удалить аккаунт';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Навсегда удалит ваш аккаунт Qutty';

  @override
  String get settingsVersionPlaceholder => 'Placeholder#424738';

  @override
  String get settingsLogOut => 'Выйти';

  @override
  String get settingsPasswordUpdated => 'Пароль обновлён';

  @override
  String get settingsEmailUpdated => 'Эл. почта обновлена';

  @override
  String get settingsLogOutTitle => 'Выйти?';

  @override
  String get settingsLogOutBody =>
      'Чтобы войти снова, нужно будет заново ввести пароль.';

  @override
  String get settingsDeleteAccountTitle => 'Удалить аккаунт?';

  @override
  String get settingsDeleteAccountBody =>
      'Введите имя пользователя и пароль, чтобы навсегда удалить аккаунт и все данные.';

  @override
  String get settingsEditProfileTooltip => 'Изменить профиль';

  @override
  String get settingsCalls => 'Звонки';

  @override
  String get settingsCallWebcam => 'Веб-камера';

  @override
  String get settingsCallWebcamSubtitle =>
      'Начинать звонки со включённой камерой';

  @override
  String get settingsCallCamera => 'Камера';

  @override
  String get settingsCallCameraFront => 'Фронтальная';

  @override
  String get settingsCallCameraBack => 'Задняя';

  @override
  String get settingsCallLoudspeaker => 'Громкая связь';

  @override
  String get settingsCallLoudspeakerSubtitle =>
      'Воспроизводить звук звонка через динамик';

  @override
  String get settingsCallMic => 'Микрофон';

  @override
  String get settingsCallMicSubtitle =>
      'Начинать звонки со включённым микрофоном';

  @override
  String get settingsCallScreenShare => 'Скрейнкаст';

  @override
  String get settingsCallScreenShareSubtitle =>
      'Разрешить демонстрацию экрана во время звонков';

  @override
  String get settingsAudio => 'Звук';

  @override
  String get settingsAudioInput => 'Микрофон';

  @override
  String get settingsAudioOutput => 'Динамики';

  @override
  String get settingsAudioCamera => 'Камера';

  @override
  String get settingsAudioSystemDefault => 'Системное по умолчанию';

  @override
  String get settingsAudioNoDevices => 'Устройства не найдены';

  @override
  String get settingsAudioNoiseReduction => 'Шумоподавление';

  @override
  String get settingsAudioNoiseReductionSubtitle =>
      'Подавлять фоновый шум во время звонков';

  @override
  String get settingsAudioMicVolume => 'Громкость микрофона';

  @override
  String get settingsAudioSpeakerVolume => 'Громкость динамиков';

  @override
  String get screenSharePickTitle => 'Выберите, чем поделиться';

  @override
  String get screenSharePickScreens => 'Экраны';

  @override
  String get screenSharePickWindows => 'Окна';

  @override
  String get screenSharePickEmpty => 'Экраны и окна не найдены';

  @override
  String get screenSharePickError => 'Не удалось загрузить экраны и окна';

  @override
  String get screenSharePickRetry => 'Повторить';

  @override
  String get notificationsToggle => 'Уведомления о сообщениях';

  @override
  String get notificationsOffForDevice => 'Отключены на этом устройстве';

  @override
  String get notificationsOpenWithBackground =>
      'Оповещения, пока приложение открыто и в фоне';

  @override
  String get notificationsOpenOnly => 'Оповещения, пока приложение открыто';

  @override
  String get notificationsOpenBackgroundConnection =>
      'Оповещения, пока приложение открыто (фоновое подключение)';

  @override
  String get notificationsPermissionHint =>
      'Разрешите уведомления Qutty в системных настройках, чтобы получать оповещения в фоне.';

  @override
  String get connectionStatus => 'Состояние подключения';

  @override
  String get connectionLiveWebsocket => 'Состояние активного вебсокета';

  @override
  String get connectionReconnect => 'Переподключиться';

  @override
  String get connectionConnected => 'Подключено';

  @override
  String get connectionConnecting => 'Подключение…';

  @override
  String get connectionDisconnected => 'Отключено';

  @override
  String sessionsRevokeTitle(String name) {
    return 'Отозвать сеанс $name?';
  }

  @override
  String get sessionsRevokeBody =>
      'Другие устройства, использующие этот сеанс, будут отключены.';

  @override
  String get sessionsRevoked => 'Сеанс отозван';

  @override
  String get sessionsLoadFailed => 'Не удалось загрузить сеансы';

  @override
  String get sessionsNone => 'Нет активных сеансов';

  @override
  String get sessionsThisDevice => 'Это устройство';

  @override
  String sessionsLastActive(String time) {
    return 'Активность $time';
  }

  @override
  String get sessionsCurrentBadge => 'Текущий';

  @override
  String get timeJustNow => 'только что';

  @override
  String timeMinutesAgo(int count) {
    return '$count мин назад';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count дн назад';
  }

  @override
  String get languageTitle => 'Язык';

  @override
  String get languageSubtitle => 'Язык приложения';

  @override
  String get languageSystemDefault => 'Как в системе';

  @override
  String get themeLabel => 'Тема';

  @override
  String get accentColorLabel => 'Акцентный цвет';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get accentQuttyBlue => 'Синий Qutty';

  @override
  String get accentCustom => 'Свой';

  @override
  String get customAccentColor => 'Свой акцентный цвет';

  @override
  String get hexColor => 'HEX-код цвета';

  @override
  String get roleOwner => 'Владелец';

  @override
  String get roleAdmin => 'Администратор';

  @override
  String get roleRestricted => 'Ограниченный';

  @override
  String get roleMember => 'Участник';

  @override
  String get accountNewEmail => 'Новая эл. почта';

  @override
  String get accountCurrentPassword => 'Текущий пароль';

  @override
  String get accountConfirmPassword => 'Подтвердите пароль';

  @override
  String get accountNewPassword => 'Новый пароль';

  @override
  String get chatSettingsTitle => 'Настройки чата';

  @override
  String get chatSettingsLeaveTitle => 'Покинуть чат?';

  @override
  String get chatSettingsLeaveBody =>
      'Вы потеряете доступ к этому чату, пока вас снова не пригласит администратор.';

  @override
  String get chatSettingsLeave => 'Покинуть';

  @override
  String chatSettingsDeleteTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String get chatSettingsDeleteBody =>
      'Все сообщения и участники будут удалены навсегда. Отменить это нельзя.';

  @override
  String get chatSettingsLoadFailed => 'Не удалось загрузить настройки';

  @override
  String get chatSettingsProfileSection => 'Профиль';

  @override
  String get chatSettingsEditProfileSubtitle =>
      'Название, никнейм, описание и картинка';

  @override
  String get chatSettingsCreateInvite => 'Создать ссылку-приглашение';

  @override
  String get chatSettingsCreateInviteSubtitle =>
      'Создайте приглашение, которым можно поделиться';

  @override
  String get chatSettingsPermissions => 'Права доступа';

  @override
  String get chatSettingsMembers => 'Участники';

  @override
  String get chatSettingsMembersSubtitle => 'Просмотр и управление участниками';

  @override
  String get chatSettingsAccessControl => 'Контроль доступа';

  @override
  String get chatSettingsAccessControlSubtitle =>
      'Права участников по умолчанию';

  @override
  String get chatSettingsDirectMessage => 'Личное сообщение';

  @override
  String get chatSettingsOpenContactProfile => 'Открыть профиль контакта';

  @override
  String get chatSettingsDangerZone => 'Опасная зона';

  @override
  String get chatSettingsLeaveTile => 'Покинуть чат';

  @override
  String get chatSettingsDeleteTile => 'Удалить чат';

  @override
  String get chatSettingsDeleteTileSubtitle =>
      'Удалить этот чат может только создатель';

  @override
  String get chatSettingsInviteTitle => 'Ссылка-приглашение';

  @override
  String get chatSettingsInviteBody =>
      'Поделитесь этой ссылкой с теми, кого хотите пригласить. Она скопирована в буфер обмена.';

  @override
  String get chatSettingsInviteCopied => 'Ссылка-приглашение скопирована';

  @override
  String get aclDefaultPermissions => 'Права участников по умолчанию';

  @override
  String get aclDescription =>
      'Эти права действуют для обычных участников. У администраторов всегда есть доступ к управлению.';

  @override
  String get aclSavePermissions => 'Сохранить права';

  @override
  String get aclEditMessages => 'Редактировать сообщения';

  @override
  String get aclEditMessagesDescription =>
      'Разрешает участникам редактировать сообщения.';

  @override
  String get permissionWriteMessages => 'Отправлять сообщения';

  @override
  String get permissionWriteMessagesDescription =>
      'Разрешает участникам отправлять новые сообщения.';

  @override
  String get permissionDeleteOthersMessages => 'Удалять чужие сообщения';

  @override
  String get permissionDeleteOthersMessagesDescription =>
      'Разрешает участникам удалять сообщения других людей.';

  @override
  String get permissionEditOthersMessages => 'Редактировать чужие сообщения';

  @override
  String get permissionEditOthersMessagesDescription =>
      'Разрешает участникам редактировать сообщения других людей.';

  @override
  String get permissionRestrictUsers => 'Управлять участниками';

  @override
  String get permissionRestrictUsersDescription =>
      'Разрешает участникам убирать или ограничивать других участников.';

  @override
  String get permissionEditProfile => 'Редактировать профиль чата';

  @override
  String get permissionEditProfileDescription =>
      'Разрешает участникам менять название и описание чата.';

  @override
  String get permissionAddAdmins => 'Управлять администраторами';

  @override
  String get permissionAddAdminsDescription =>
      'Разрешает участникам повышать других участников.';

  @override
  String get membersTitle => 'Участники';

  @override
  String get membersLoadFailed => 'Не удалось загрузить участников';

  @override
  String get membersYou => 'Вы';

  @override
  String get membersMore => 'Ещё';

  @override
  String get membersViewProfile => 'Открыть профиль';

  @override
  String membersGiveChat(String name) {
    return 'Передать $name этому пользователю';
  }

  @override
  String get membersManagePermissions => 'Управлять правами';

  @override
  String get membersRemoveFromChat => 'Убрать из чата';

  @override
  String membersRemoveTitle(String name) {
    return 'Убрать $name?';
  }

  @override
  String get membersRemoveBody => 'Этот человек сразу потеряет доступ к чату.';

  @override
  String membersOwnershipGiven(String name) {
    return 'Владение чатом передано пользователю $name';
  }

  @override
  String get membersTransferTitle => 'Данные будущего владельца';

  @override
  String get membersTransferAttention => 'ВНИМАНИЕ!';

  @override
  String membersTransferUsername(String username) {
    return 'ИМЯ ПОЛЬЗОВАТЕЛЯ: $username';
  }

  @override
  String membersTransferAcknowledge(String chat, String username) {
    return 'Я понимаю, что потеряю владение $chat, а $username получит $chat.';
  }

  @override
  String get membersEnterPassword => 'Введите пароль';

  @override
  String membersGiveConfirm(String chat, String username) {
    return 'Передать $chat пользователю $username';
  }

  @override
  String get membersOwnerLocked => 'Владельца чата нельзя изменить.';

  @override
  String get createChatNewChannel => 'Новый канал';

  @override
  String get createChatNewChat => 'Новый чат';

  @override
  String get createChatClose => 'Закрыть';

  @override
  String get createChatCreateChannel => 'Создать канал';

  @override
  String get createChatCreateChat => 'Создать чат';

  @override
  String get createChatChooseAvatar => 'Выбрать аватар';

  @override
  String get createChatDisplayName => 'Отображаемое имя';

  @override
  String get createChatUsernameOptional => 'Имя пользователя (необязательно)';

  @override
  String get createChatUsernameOptionalHelper =>
      'Можно оставить пустым и добавить позже.';

  @override
  String get createChatNameRequired => 'Отображаемое имя обязательно.';

  @override
  String get joinPreviewTitle => 'Присоединиться к чату';

  @override
  String get joinPreviewInvalidLink => 'Некорректная ссылка-приглашение';

  @override
  String get joinPreviewJoining => 'Подключение…';

  @override
  String get joinPreviewJoin => 'Присоединиться';

  @override
  String get editProfileChangeAvatar => 'Сменить аватар';

  @override
  String get editProfileRemoveAvatar => 'Убрать аватар';

  @override
  String get editProfileBio => 'О себе';

  @override
  String get editProfileNameEmpty => 'Отображаемое имя не может быть пустым';

  @override
  String get editProfileHandleReserved =>
      'Никнейм не может быть _, этот никнейм зарезервирован для сброса никнейма';

  @override
  String get editChatChannelSettings => 'Настройки канала';

  @override
  String get editChatTapForPicture => 'Нажмите, чтобы сменить картинку чата';

  @override
  String get editChatUpload => 'Загрузить';

  @override
  String get editChatReplace => 'Заменить';

  @override
  String get editChatHandleHelper =>
      'Используется, чтобы поделиться чатом как @никнейм';

  @override
  String get profileUnableToOpen => 'Не удалось открыть';

  @override
  String profileError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get profileNotFound => 'Профиль не найден';

  @override
  String profileChatId(int id) {
    return 'ID чата: $id';
  }

  @override
  String profileUserId(int id) {
    return 'ID пользователя: $id';
  }

  @override
  String profileTabMedia(int count) {
    return 'Медиа ($count)';
  }

  @override
  String profileTabGifs(int count) {
    return 'Гифки ($count)';
  }

  @override
  String profileTabLinks(int count) {
    return 'Ссылки ($count)';
  }

  @override
  String profileTabFiles(int count) {
    return 'Файлы ($count)';
  }

  @override
  String get profileNoMedia => 'Медиа пока нет';

  @override
  String get profileNoGifs => 'Гифок пока нет';

  @override
  String get profileNoLinks => 'Ссылок пока нет';

  @override
  String get profileNoFiles => 'Файлов пока нет';

  @override
  String get aboutTerms =>
      'Условия использования и политика конфиденциальности';

  @override
  String get aboutLicenses => 'Лицензии открытого кода';

  @override
  String aboutBuild(String build) {
    return 'Сборка: $build';
  }

  @override
  String aboutCopyright(String version) {
    return 'Qutty - RdProjects 2026 © Все права защищены\nВерсия: $version';
  }

  @override
  String get debugTitle => 'Quttycaka';

  @override
  String get debugWarning =>
      'Эти настройки нужны только для разработки и отладки. \nИх изменение может привести к непредсказуемому поведению.\nПродолжайте, только если точно знаете, что делаете.\n - QuttyTeam в RdProjects';

  @override
  String get debugSubtitle => 'Настройки разработки/отладки, он же Quttycaka';

  @override
  String get debugApiEndpoint => 'Адрес API';

  @override
  String get debugDeveloperInfo => 'Данные для разработчика';

  @override
  String get debugDeveloperInfoSubtitle => 'Показывать ID профилей и сообщений';

  @override
  String get debugFallbackSelectorCast => 'FallBackSelectorCast';

  @override
  String get debugFallbackSelectorCastSubtitle =>
      'Всегда использовать собственный выбор экрана приложения вместо системного';

  @override
  String get debugForceGroupCall => 'Принудительный макет группового звонка';

  @override
  String get debugForceGroupCallSubtitle =>
      'Использовать макет группового звонка даже в личных звонках';

  @override
  String get debugJumpTo => 'Перейти';

  @override
  String get debugJumpToSubtitle => 'Открыть страницу по URL или маршруту';

  @override
  String get debugJumpToTitle => 'Перейти к странице';

  @override
  String get debugPageUrlOrRoute => 'URL или маршрут страницы';

  @override
  String get debugBaseUrl => 'Базовый URL';

  @override
  String get debugApiEndpointUpdated => 'Адрес API обновлён';

  @override
  String get debugTransport => 'Канал доставки уведомлений';

  @override
  String get debugTransportNotSelected => 'Не выбран';

  @override
  String get debugTransportUnavailable => 'Недоступно в этой сборке';

  @override
  String debugTransportNowUsing(String label) {
    return 'Уведомления теперь отправляются через $label';
  }

  @override
  String get transportApns => 'Служба push-уведомлений Apple';

  @override
  String get transportFcm => 'Firebase Cloud Messaging';

  @override
  String get transportWebsocket => 'Фоновое подключение к вашему серверу';

  @override
  String get errorShowDetails => 'Показать подробности ошибки API';

  @override
  String errorHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get notificationChannelMessages => 'Сообщения';

  @override
  String get notificationChannelDescription => 'Новые сообщения и оповещения';

  @override
  String get notificationSentAttachment => 'Отправил вложение';

  @override
  String get notificationNewMessage => 'Новое сообщение';

  @override
  String get unnamedChat => 'Чат без названия';

  @override
  String get unnamedSession => 'Сеанс без названия';

  @override
  String get tokenMissing => 'Отсутствует токен';

  @override
  String get avatarFormatError =>
      'Аватар должен быть изображением JPEG, JPG или PNG';

  @override
  String get unableToReadImage => 'Не удалось прочитать изображение';

  @override
  String get avatarUploadFailed => 'Не удалось загрузить аватар';

  @override
  String get unableToReadFile => 'Не удалось прочитать файл';

  @override
  String get fileUploadFailed => 'Не удалось загрузить файл';

  @override
  String get requestFailed => 'Запрос не выполнен';

  @override
  String get settingsFont => 'Шрифт';

  @override
  String get fontSystemDefault => 'Системный шрифт';

  @override
  String get fontDownload => 'Скачать';

  @override
  String get fontDownloading => 'Скачивание…';

  @override
  String get fontChooseFromFile => 'Выбрать файл';

  @override
  String get fontDownloadFailed => 'Не удалось скачать шрифт';

  @override
  String get fontFileUnreadable => 'Это не файл шрифта';

  @override
  String get fontSample =>
      'Съешь же ещё этих мягких французских булок да выпей чаю';

  @override
  String get fontSubtitle => 'Шрифт приложения';

  @override
  String get fontNotLoaded => 'Шрифт не загружен';

  @override
  String get fontDelete => 'Удалить';

  @override
  String get fontSource => 'Источник';

  @override
  String fontDownloadTitle(String font) {
    return 'Скачать $font?';
  }

  @override
  String fontDownloadBody(String url) {
    return 'Шрифт загружается с $url и сохраняется на этом устройстве.';
  }

  @override
  String fontDeleteTitle(String font) {
    return 'Удалить $font?';
  }

  @override
  String fontDeleteBody(String url) {
    return 'Он будет удалён с этого устройства. Его можно снова скачать с $url.';
  }

  @override
  String fontDownloadingLabel(String font) {
    return 'Скачивание $font…';
  }

  @override
  String get fontDeleteFailed => 'Не удалось удалить шрифт';

  @override
  String get fontSourceFailed => 'Не удалось открыть ссылку';

  @override
  String get developerPortal => 'Портал разработчика';

  @override
  String get developerPortalSubtitle => 'Инструменты для разработчиков Qutty';

  @override
  String get ugcTitle => 'Стикеры и эмодзи';

  @override
  String get ugcSubtitle => 'Создавайте свои стикеры и эмодзи и управляйте ими';

  @override
  String get ugcPortalTitle => 'Стикеры и эмодзи';

  @override
  String get ugcCreatePack => 'Новый набор';

  @override
  String get ugcCreatePackAction => 'Создать набор';

  @override
  String get ugcPackNameRequired => 'Имя набора обязательно.';

  @override
  String get ugcNameRequired => 'Имя обязательно.';

  @override
  String get ugcItemImageRequired => 'Сначала выберите изображение.';

  @override
  String get ugcChooseImage => 'Выбрать изображение';

  @override
  String get ugcPackName => 'Название набора';

  @override
  String get ugcAddItem => 'Добавить элемент';

  @override
  String get ugcItemsTitle => 'Элементы';

  @override
  String get ugcFavoritesTitle => 'Избранное';

  @override
  String get ugcNoPacks =>
      'Наборов пока нет. Создайте набор, чтобы добавлять стикеры и эмодзи.';

  @override
  String get ugcNoItems => 'В этом наборе пока нет элементов.';

  @override
  String get ugcNoFavorites => 'В избранном пока ничего нет.';

  @override
  String get ugcDeletePackTitle => 'Удалить набор?';

  @override
  String ugcDeletePackBody(String name) {
    return 'Удалить «$name» и все его элементы?';
  }

  @override
  String get ugcDeleteItemTitle => 'Удалить элемент?';

  @override
  String ugcDeleteItemBody(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get ugcCreated => 'Создано';

  @override
  String get ugcDeleted => 'Удалено';

  @override
  String get ugcCreateFailed => 'Не удалось создать';

  @override
  String get ugcPickerAll => 'Все';

  @override
  String get ugcPickerFavorites => 'Избранное';

  @override
  String get ugcPickerEmpty =>
      'Стикеров пока нет. Создайте их в Портале разработчика.';

  @override
  String get ugcPickerNoPacks =>
      'Сохранённых паков пока нет. Сохраните пак, чтобы увидеть его стикеры здесь.';

  @override
  String get ugcPickerLoadFailed => 'Не удалось загрузить стикеры';

  @override
  String get ugcPickerManage => 'Управление в Портале разработчика';

  @override
  String get ugcPickerSaved => 'Добавлено в избранное';

  @override
  String get ugcPickerRemoved => 'Удалено из избранного';

  @override
  String get ugcStickerInsert => 'Вставить';

  @override
  String get ugcSavePack => 'Сохранить пак';

  @override
  String get ugcUnsavePack => 'Убрать сохранённый пак';

  @override
  String get ugcSharePack => 'Поделиться паком';

  @override
  String get ugcLinkCopied => 'Ссылка скопирована';

  @override
  String get ugcPackTitle => 'Набор стикеров';

  @override
  String get ugcPackUnavailable => 'Этот набор стикеров недоступен.';

  @override
  String get ugcStickerPreview => 'Стикер';
}

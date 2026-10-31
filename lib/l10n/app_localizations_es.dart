// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Qutty';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonSave => 'Guardar';

  @override
  String get commonSaveChanges => 'Guardar cambios';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get commonRevoke => 'Revocar';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonDismiss => 'Descartar';

  @override
  String get commonTryAgain => 'Reintentar';

  @override
  String get commonOpen => 'Abrir';

  @override
  String get commonOk => 'Aceptar';

  @override
  String get commonSaving => 'Guardando…';

  @override
  String get commonNotAvailable => 'N/D';

  @override
  String get commonLoading => 'cargando';

  @override
  String get commonDetails => 'Detalles';

  @override
  String get commonName => 'Nombre';

  @override
  String get commonHandle => 'Alias';

  @override
  String get commonDescription => 'Descripción';

  @override
  String get commonSettings => 'Ajustes';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get password => 'Contraseña';

  @override
  String get optionalEmail => 'Correo electrónico (opcional)';

  @override
  String get usernamePasswordRequired =>
      'El nombre de usuario y la contraseña son obligatorios.';

  @override
  String get loginCreateAccountTitle => 'Crea tu cuenta';

  @override
  String get loginWelcomeBackTitle => 'Te damos la bienvenida de nuevo';

  @override
  String get loginJoinConversation => 'Únete a la conversación.';

  @override
  String get loginSignInConversations => 'Inicia sesión en tus conversaciones.';

  @override
  String get createAccount => 'Crear cuenta';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get alreadyHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get newToQutty => '¿Nuevo en Qutty? Crea una cuenta';

  @override
  String couldNotConnect(Object error) {
    return 'No se pudo conectar con Qutty: $error';
  }

  @override
  String get quttyApiServiceDebugging => 'Depuración del ApiService de Qutty';

  @override
  String get developerOptions => 'Opciones para desarrolladores';

  @override
  String get apiUrl => 'URL de la API';

  @override
  String get jwtToken => 'Token JWT';

  @override
  String get cancel => 'Cancelar';

  @override
  String get loginByToken => 'Iniciar sesión con token';

  @override
  String get enterJwtToken => 'Introduce un token JWT.';

  @override
  String get couldNotValidateToken => 'No se pudo validar el token.';

  @override
  String get selectChat => 'Selecciona un chat';

  @override
  String get home => 'Inicio';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get pageNotFoundDescription =>
      'Esto indica que se ha abierto una página no válida por algún error.';

  @override
  String get chatsSearchHint => 'Buscar chats, canales, usuarios';

  @override
  String get chatsProfileTooltip => 'Perfil';

  @override
  String get chatsNewChannel => 'Nuevo canal';

  @override
  String get chatsNewChat => 'Nuevo chat';

  @override
  String get chatsEmptyTitle => 'Todavía no hay conversaciones';

  @override
  String get chatsEmptySubtitle => 'Crea un chat para empezar.';

  @override
  String get chatsNoMatches => 'No se han encontrado coincidencias';

  @override
  String get chatsPreviewAndJoin => 'Ver y unirse';

  @override
  String get chatsMessageUser => 'Enviar mensaje';

  @override
  String get chatBackToChats => 'Volver a los chats';

  @override
  String get chatConversation => 'Conversación';

  @override
  String get chatStartCall => 'Iniciar llamada';

  @override
  String get chatEndCall => 'Finalizar llamada';

  @override
  String chatIncomingCall(String name) {
    return '$name está llamando';
  }

  @override
  String get chatOpenCall => 'Abrir llamada';

  @override
  String get chatDismissCall => 'Descartar llamada';

  @override
  String get chatJoinCall => 'Unirse a la llamada';

  @override
  String get chatLeaveCall => 'Salir de la llamada';

  @override
  String get chatMinimizeCall => 'Minimizar llamada';

  @override
  String get chatConnectingCall => 'Conectando…';

  @override
  String get chatCalling => 'Llamando…';

  @override
  String get chatEnableWebcam => 'Activar cámara';

  @override
  String get chatDisableWebcam => 'Desactivar cámara';

  @override
  String get chatEnableScreenShare => 'Compartir pantalla';

  @override
  String get chatDisableScreenShare => 'Dejar de compartir';

  @override
  String get chatEnableSpeaker => 'Altavoz activado';

  @override
  String get chatDisableSpeaker => 'Altavoz desactivado';

  @override
  String get chatMuteMicrophone => 'Silenciar micrófono';

  @override
  String get chatUnmuteMicrophone => 'Activar micrófono';

  @override
  String get chatInCall => 'En llamada';

  @override
  String get chatCallsUnsupported => 'El servidor no admite llamadas';

  @override
  String get chatUnableToOpenAttachment =>
      'No se pudo abrir el archivo adjunto';

  @override
  String get chatUnableToOpenLink => 'No se pudo abrir el enlace';

  @override
  String get chatJoined => 'Te has unido al chat';

  @override
  String get chatNoJoinLink => 'Este chat no tiene enlace de invitación';

  @override
  String get chatSendFirstMessage => 'Envía tu primer mensaje';

  @override
  String get chatNoWritePermission =>
      'No tienes permiso para escribir mensajes';

  @override
  String get chatJoin => 'Unirse al chat';

  @override
  String get chatAttachFile => 'Adjuntar archivo';

  @override
  String get chatEmojiSelectButton => 'Elegir emojis, GIF y pegatinas';

  @override
  String get mediaPickerStickerTab => 'Sticker';

  @override
  String get mediaPickerEmojiTab => 'Emoji';

  @override
  String get mediaPickerGifTab => 'GIF';

  @override
  String get mediaPickerGifSearchHint => 'Buscar GIFs';

  @override
  String get mediaPickerGifFavorite => 'Guardar en favoritos';

  @override
  String get mediaPickerGifUnfavorite => 'Quitar de favoritos';

  @override
  String get mediaPickerGifClearSearch => 'Borrar búsqueda';

  @override
  String get mediaPickerGifNoFavorites =>
      'Aún no hay GIF guardados. Busca uno y mantén pulsado para guardarlo.';

  @override
  String get mediaPickerGifEmpty => 'No se encontraron GIFs';

  @override
  String get mediaPickerGifLoadFailed => 'No se pudieron cargar los GIFs';

  @override
  String get mediaPickerGifPoweredBy => 'GIFs de Klipy';

  @override
  String get mediaPickerGifSend => 'Enviar GIF';

  @override
  String get mediaPickerEmojiLoadFailed => 'No se pudieron cargar los emojis.';

  @override
  String get mediaPickerGroupSmileysEmotion => 'Emoticonos y sentimientos';

  @override
  String get mediaPickerGroupPeopleBody => 'Personas y cuerpos';

  @override
  String get mediaPickerGroupAnimalsNature => 'Animales y naturaleza';

  @override
  String get mediaPickerGroupFoodDrink => 'Comida y bebida';

  @override
  String get mediaPickerGroupTravelPlaces => 'Viajes y lugares';

  @override
  String get mediaPickerGroupActivities => 'Actividades';

  @override
  String get mediaPickerGroupObjects => 'Objetos';

  @override
  String get mediaPickerGroupSymbols => 'Símbolos';

  @override
  String get mediaPickerGroupFlags => 'Banderas';

  @override
  String get mediaPickerSkinTone => 'Tono de piel';

  @override
  String get mediaPickerSkinToneDefault => 'Predeterminado';

  @override
  String get mediaPickerSkinToneLight => 'Claro';

  @override
  String get mediaPickerSkinToneMediumLight => 'Medio claro';

  @override
  String get mediaPickerSkinToneMedium => 'Medio';

  @override
  String get mediaPickerSkinToneMediumDark => 'Medio oscuro';

  @override
  String get mediaPickerSkinToneDark => 'Oscuro';

  @override
  String get chatWriteMessage => 'Escribe un mensaje';

  @override
  String get chatSend => 'Enviar';

  @override
  String chatMessageId(int id) {
    return 'ID del mensaje: $id';
  }

  @override
  String get chatMessageRead => 'Leído';

  @override
  String get chatMessageSent => 'Enviado';

  @override
  String chatReadBy(int count) {
    return 'Leído por $count';
  }

  @override
  String chatSelectionCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get chatSelectionStop => 'Dejar de seleccionar';

  @override
  String get chatMenuReply => 'Responder';

  @override
  String get chatReplyUnavailable => 'Mensaje original';

  @override
  String get chatMenuForward => 'Reenviar';

  @override
  String get chatMenuSelect => 'Seleccionar';

  @override
  String get chatMenuMore => 'Más';

  @override
  String get chatMessageCopied => 'Mensaje copiado';

  @override
  String get chatActionUnavailable => 'Aún no disponible';

  @override
  String get chatForwardTitle => 'Reenviar a';

  @override
  String get chatForwardSearch => 'Buscar chats';

  @override
  String get chatForwardNoChats => 'No hay chats a los que reenviar';

  @override
  String get chatForwarded => 'Reenviado';

  @override
  String chatForwardedFrom(String author) {
    return 'Reenviado de $author';
  }

  @override
  String get chatForwardedOpen => 'Abrir original';

  @override
  String chatForwardedTo(String chat) {
    return 'Reenviado a $chat';
  }

  @override
  String get settingsChats => 'Chats';

  @override
  String get settingsReadCount =>
      'Mostrar el número de lecturas en vez de marcas';

  @override
  String get settingsReadCountSubtitle =>
      'En los chats directos, mostrar cuántas personas han leído cada mensaje en vez de una marca';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsCustomization => 'Personalización';

  @override
  String get settingsCustomizationSubtitle => 'Tema y color de acento';

  @override
  String get settingsConnectivity => 'Conectividad';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsAccount => 'Cuenta';

  @override
  String get settingsAccounts => 'Cuentas';

  @override
  String get settingsAccountDefaultLabel => 'Cuenta';

  @override
  String get settingsAccountSafety => 'Seguridad de la cuenta';

  @override
  String get settingsAbout => 'Acerca de';

  @override
  String get settingsEditProfile => 'Editar perfil';

  @override
  String get settingsChangePassword => 'Cambiar contraseña';

  @override
  String get settingsChangePasswordSubtitle =>
      'Actualiza la contraseña de tu cuenta';

  @override
  String get settingsChangeEmail => 'Cambiar correo electrónico';

  @override
  String get settingsNoEmailOnFile => 'No hay correo electrónico guardado';

  @override
  String get settingsActiveSessions => 'Sesiones activas';

  @override
  String get settingsActiveSessionsSubtitle =>
      'Gestiona los dispositivos con sesión iniciada en tu cuenta';

  @override
  String get settingsRemoveAccount => 'Quitar cuenta';

  @override
  String get settingsAddAccount => 'Añadir cuenta';

  @override
  String get settingsAddAccountSubtitle =>
      'Inicia sesión en otro servidor o cuenta';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Elimina permanentemente tu cuenta de Qutty';

  @override
  String get settingsVersionPlaceholder => 'Placeholder#424738';

  @override
  String get settingsLogOut => 'Cerrar sesión';

  @override
  String get settingsPasswordUpdated => 'Contraseña actualizada';

  @override
  String get settingsEmailUpdated => 'Correo electrónico actualizado';

  @override
  String get settingsLogOutTitle => '¿Cerrar sesión?';

  @override
  String get settingsLogOutBody =>
      'Tendrás que introducir tu contraseña otra vez para volver a iniciar sesión.';

  @override
  String get settingsDeleteAccountTitle => '¿Eliminar la cuenta?';

  @override
  String get settingsDeleteAccountBody =>
      'Introduce tu nombre de usuario y contraseña para eliminar permanentemente tu cuenta y todos tus datos.';

  @override
  String get settingsEditProfileTooltip => 'Editar perfil';

  @override
  String get settingsCalls => 'Llamadas';

  @override
  String get settingsCallWebcam => 'Webcam';

  @override
  String get settingsCallWebcamSubtitle =>
      'Empezar llamadas con la cámara encendida';

  @override
  String get settingsCallCamera => 'Cámara';

  @override
  String get settingsCallCameraFront => 'Frontal';

  @override
  String get settingsCallCameraBack => 'Trasera';

  @override
  String get settingsCallLoudspeaker => 'Altavoz';

  @override
  String get settingsCallLoudspeakerSubtitle =>
      'Reproducir el audio de la llamada por el altavoz';

  @override
  String get settingsCallMic => 'Micrófono';

  @override
  String get settingsCallMicSubtitle =>
      'Empezar llamadas con el micrófono encendido';

  @override
  String get settingsCallScreenShare => 'Screencast';

  @override
  String get settingsCallScreenShareSubtitle =>
      'Permitir compartir la pantalla durante las llamadas';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioInput => 'Micrófono';

  @override
  String get settingsAudioOutput => 'Altavoces';

  @override
  String get settingsAudioCamera => 'Cámara';

  @override
  String get settingsAudioSystemDefault => 'Predeterminado del sistema';

  @override
  String get settingsAudioNoDevices => 'No se encontraron dispositivos';

  @override
  String get settingsAudioNoiseReduction => 'Reducción de ruido';

  @override
  String get settingsAudioNoiseReductionSubtitle =>
      'Suprime el ruido de fondo durante las llamadas';

  @override
  String get settingsAudioMicVolume => 'Volumen del micrófono';

  @override
  String get settingsAudioSpeakerVolume => 'Volumen de los altavoces';

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
  String get screenSharePickTitle => 'Elige qué compartir';

  @override
  String get screenSharePickScreens => 'Pantallas';

  @override
  String get screenSharePickWindows => 'Ventanas';

  @override
  String get screenSharePickEmpty => 'No se encontraron pantallas ni ventanas';

  @override
  String get screenSharePickError =>
      'No se pudieron cargar las pantallas y ventanas';

  @override
  String get screenSharePickRetry => 'Reintentar';

  @override
  String get notificationsToggle => 'Notificaciones de mensajes';

  @override
  String get notificationsOffForDevice => 'Desactivadas en este dispositivo';

  @override
  String get notificationsOpenWithBackground =>
      'Alertas con la app abierta y en segundo plano';

  @override
  String get notificationsOpenOnly => 'Alertas con la app abierta';

  @override
  String get notificationsOpenBackgroundConnection =>
      'Alertas con la app abierta (conexión en segundo plano)';

  @override
  String get notificationsPermissionHint =>
      'Permite las notificaciones de Qutty en los ajustes del sistema para recibir alertas en segundo plano.';

  @override
  String get connectionStatus => 'Estado de la conexión';

  @override
  String get connectionLiveWebsocket => 'Estado del websocket en vivo';

  @override
  String get connectionReconnect => 'Reconectar';

  @override
  String get connectionConnected => 'Conectado';

  @override
  String get connectionConnecting => 'Conectando…';

  @override
  String get connectionDisconnected => 'Desconectado';

  @override
  String sessionsRevokeTitle(String name) {
    return '¿Revocar la sesión de $name?';
  }

  @override
  String get sessionsRevokeBody =>
      'Se cerrará la sesión de los demás dispositivos que usen esta sesión.';

  @override
  String get sessionsRevoked => 'Sesión revocada';

  @override
  String get sessionsLoadFailed => 'No se pudieron cargar las sesiones';

  @override
  String get sessionsNone => 'No hay sesiones activas';

  @override
  String get sessionsThisDevice => 'Este dispositivo';

  @override
  String sessionsLastActive(String time) {
    return 'Última actividad $time';
  }

  @override
  String get sessionsCurrentBadge => 'Actual';

  @override
  String get timeJustNow => 'ahora mismo';

  @override
  String timeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSubtitle => 'Idioma de la app';

  @override
  String get languageSystemDefault => 'Predeterminado del sistema';

  @override
  String get themeLabel => 'Tema';

  @override
  String get accentColorLabel => 'Color de acento';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeLight => 'Blanco';

  @override
  String get accentQuttyBlue => 'Azul Qutty';

  @override
  String get accentCustom => 'Personalizado';

  @override
  String get customAccentColor => 'Color de acento personalizado';

  @override
  String get hexColor => 'Color hexadecimal';

  @override
  String get roleOwner => 'Propietario';

  @override
  String get roleAdmin => 'Administrador';

  @override
  String get roleRestricted => 'Restringido';

  @override
  String get roleMember => 'Miembro';

  @override
  String get accountNewEmail => 'Nuevo correo electrónico';

  @override
  String get accountCurrentPassword => 'Contraseña actual';

  @override
  String get accountConfirmPassword => 'Confirmar contraseña';

  @override
  String get accountNewPassword => 'Nueva contraseña';

  @override
  String get chatSettingsTitle => 'Ajustes del chat';

  @override
  String get chatSettingsLeaveTitle => '¿Salir del chat?';

  @override
  String get chatSettingsLeaveBody =>
      'Perderás el acceso a este chat salvo que un administrador te invite de nuevo.';

  @override
  String get chatSettingsLeave => 'Salir';

  @override
  String chatSettingsDeleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String get chatSettingsDeleteBody =>
      'Todos los mensajes y miembros se eliminarán permanentemente. Esto no se puede deshacer.';

  @override
  String get chatSettingsLoadFailed => 'No se pudieron cargar los ajustes';

  @override
  String get chatSettingsProfileSection => 'Perfil';

  @override
  String get chatSettingsEditProfileSubtitle =>
      'Nombre, alias, descripción e imagen';

  @override
  String get chatSettingsCreateInvite => 'Crear enlace de invitación';

  @override
  String get chatSettingsCreateInviteSubtitle =>
      'Genera una invitación para compartir';

  @override
  String get chatSettingsPermissions => 'Permisos';

  @override
  String get chatSettingsMembers => 'Miembros';

  @override
  String get chatSettingsMembersSubtitle =>
      'Consulta y gestiona los participantes';

  @override
  String get chatSettingsAccessControl => 'Control de acceso';

  @override
  String get chatSettingsAccessControlSubtitle =>
      'Permisos predeterminados de los miembros';

  @override
  String get chatSettingsDirectMessage => 'Mensaje directo';

  @override
  String get chatSettingsOpenContactProfile => 'Abrir el perfil del contacto';

  @override
  String get chatSettingsDangerZone => 'Zona de peligro';

  @override
  String get chatSettingsLeaveTile => 'Salir del chat';

  @override
  String get chatSettingsDeleteTile => 'Eliminar chat';

  @override
  String get chatSettingsDeleteTileSubtitle =>
      'Solo el creador puede eliminar este chat';

  @override
  String get chatSettingsInviteTitle => 'Enlace de invitación';

  @override
  String get chatSettingsInviteBody =>
      'Comparte este enlace con quien quieras invitar. Se ha copiado al portapapeles.';

  @override
  String get chatSettingsInviteCopied => 'Enlace de invitación copiado';

  @override
  String get aclDefaultPermissions =>
      'Permisos predeterminados de los miembros';

  @override
  String get aclDescription =>
      'Estos permisos se aplican a los miembros normales. Los administradores siempre tienen acceso de gestión.';

  @override
  String get aclSavePermissions => 'Guardar permisos';

  @override
  String get aclEditMessages => 'Editar mensajes';

  @override
  String get aclEditMessagesDescription =>
      'Permite que los miembros editen mensajes.';

  @override
  String get permissionWriteMessages => 'Enviar mensajes';

  @override
  String get permissionWriteMessagesDescription =>
      'Permite que los miembros envíen mensajes nuevos.';

  @override
  String get permissionDeleteOthersMessages => 'Eliminar mensajes ajenos';

  @override
  String get permissionDeleteOthersMessagesDescription =>
      'Permite que los miembros eliminen mensajes de otras personas.';

  @override
  String get permissionEditOthersMessages => 'Editar mensajes ajenos';

  @override
  String get permissionEditOthersMessagesDescription =>
      'Permite que los miembros editen mensajes de otras personas.';

  @override
  String get permissionRestrictUsers => 'Gestionar miembros';

  @override
  String get permissionRestrictUsersDescription =>
      'Permite que los miembros quiten o restrinjan a otros miembros.';

  @override
  String get permissionEditProfile => 'Editar el perfil del chat';

  @override
  String get permissionEditProfileDescription =>
      'Permite que los miembros actualicen el nombre y la descripción del chat.';

  @override
  String get permissionAddAdmins => 'Gestionar administradores';

  @override
  String get permissionAddAdminsDescription =>
      'Permite que los miembros promocionen a otros miembros.';

  @override
  String get membersTitle => 'Miembros';

  @override
  String get membersLoadFailed => 'No se pudieron cargar los miembros';

  @override
  String get membersYou => 'Tú';

  @override
  String get membersMore => 'Más';

  @override
  String get membersViewProfile => 'Ver perfil';

  @override
  String membersGiveChat(String name) {
    return 'Dar $name a este usuario';
  }

  @override
  String get membersManagePermissions => 'Gestionar permisos';

  @override
  String get membersRemoveFromChat => 'Quitar del chat';

  @override
  String membersRemoveTitle(String name) {
    return '¿Quitar a $name?';
  }

  @override
  String get membersRemoveBody => 'Perderá el acceso a este chat de inmediato.';

  @override
  String membersOwnershipGiven(String name) {
    return 'La propiedad del chat se ha dado a $name';
  }

  @override
  String get membersTransferTitle => 'Datos del usuario destinatario';

  @override
  String get membersTransferAttention => '¡ATENCIÓN!';

  @override
  String membersTransferUsername(String username) {
    return 'NOMBRE DE USUARIO: $username';
  }

  @override
  String membersTransferAcknowledge(String chat, String username) {
    return 'Reconozco que perderé la propiedad de $chat y $username recibirá $chat.';
  }

  @override
  String get membersEnterPassword => 'Introduce tu contraseña';

  @override
  String membersGiveConfirm(String chat, String username) {
    return 'Dar $chat a $username';
  }

  @override
  String get membersOwnerLocked =>
      'El propietario del chat no se puede modificar.';

  @override
  String get createChatNewChannel => 'Nuevo canal';

  @override
  String get createChatNewChat => 'Nuevo chat';

  @override
  String get createChatClose => 'Cerrar';

  @override
  String get createChatCreateChannel => 'Crear canal';

  @override
  String get createChatCreateChat => 'Crear chat';

  @override
  String get createChatChooseAvatar => 'Elegir avatar';

  @override
  String get createChatDisplayName => 'Nombre visible';

  @override
  String get createChatUsernameOptional => 'Nombre de usuario (opcional)';

  @override
  String get createChatUsernameOptionalHelper =>
      'Puedes dejarlo vacío y añadirlo más tarde.';

  @override
  String get createChatNameRequired => 'El nombre visible es obligatorio.';

  @override
  String get joinPreviewTitle => 'Unirse al chat';

  @override
  String get joinPreviewInvalidLink => 'Enlace de invitación no válido';

  @override
  String get joinPreviewJoining => 'Uniéndose…';

  @override
  String get joinPreviewJoin => 'Unirse';

  @override
  String get editProfileChangeAvatar => 'Cambiar avatar';

  @override
  String get editProfileRemoveAvatar => 'Quitar avatar';

  @override
  String get editProfileBio => 'Biografía';

  @override
  String get editProfileNameEmpty => 'El nombre visible no puede estar vacío';

  @override
  String get editProfileHandleReserved =>
      'El alias no puede ser _, este alias está reservado para restablecer el alias';

  @override
  String get editChatChannelSettings => 'Ajustes del canal';

  @override
  String get editChatTapForPicture => 'Toca para cambiar la imagen del chat';

  @override
  String get editChatUpload => 'Subir';

  @override
  String get editChatReplace => 'Reemplazar';

  @override
  String get editChatHandleHelper =>
      'Se usa para compartir el chat como @alias';

  @override
  String get profileUnableToOpen => 'No se pudo abrir';

  @override
  String profileError(String error) {
    return 'Error: $error';
  }

  @override
  String get profileNotFound => 'Perfil no encontrado';

  @override
  String profileChatId(int id) {
    return 'ID del chat: $id';
  }

  @override
  String profileUserId(int id) {
    return 'ID de usuario: $id';
  }

  @override
  String profileTabMedia(int count) {
    return 'Medios ($count)';
  }

  @override
  String profileTabGifs(int count) {
    return 'GIF ($count)';
  }

  @override
  String profileTabLinks(int count) {
    return 'Enlaces ($count)';
  }

  @override
  String profileTabFiles(int count) {
    return 'Archivos ($count)';
  }

  @override
  String get profileNoMedia => 'Todavía no hay medios';

  @override
  String get profileNoGifs => 'Todavía no hay GIF';

  @override
  String get profileNoLinks => 'Todavía no hay enlaces';

  @override
  String get profileNoFiles => 'Todavía no hay archivos';

  @override
  String get aboutTerms => 'Términos del servicio y política de privacidad';

  @override
  String get aboutLicenses => 'Licencias de código abierto';

  @override
  String aboutBuild(String build) {
    return 'Compilación: $build';
  }

  @override
  String aboutCopyright(String version) {
    return 'Qutty - RdProjects 2026 © Todos los derechos reservados\nVersión: $version';
  }

  @override
  String get debugTitle => 'Quttycaka';

  @override
  String get debugWarning =>
      'Estos ajustes son solo para desarrollo y depuración. \nCambiarlos puede provocar comportamientos inesperados.\nContinúa solo si sabes lo que haces.\n - QuttyTeam en RdProjects';

  @override
  String get debugSubtitle => 'Ajustes de desarrollo/depuración, aka Quttycaka';

  @override
  String get debugApiEndpoint => 'Endpoint de la API';

  @override
  String get debugDeveloperInfo => 'Información para desarrolladores';

  @override
  String get debugDeveloperInfoSubtitle =>
      'Mostrar los ID de perfiles y mensajes';

  @override
  String get debugFallbackSelectorCast => 'FallBackSelectorCast';

  @override
  String get debugFallbackSelectorCastSubtitle =>
      'Usar siempre el selector de pantalla de la app en lugar del del sistema';

  @override
  String get debugKeepWebsocketAlive =>
      'Mantener activo el websocket en segundo plano';

  @override
  String get debugKeepWebsocketAliveSubtitle =>
      'Mantener el websocket conectado mientras la app está en segundo plano';

  @override
  String get debugBackgroundAllowTitle => '¿Permitir fondo sin límites?';

  @override
  String get debugBackgroundAllowMessage =>
      'Esto permite que la app mantenga el websocket abierto mientras no está en primer plano. En Android pide permiso para ejecutarse en el fondo sin límites. ¿Continuar?';

  @override
  String get debugForceGroupCall => 'Forzar diseño de llamada grupal';

  @override
  String get debugForceGroupCallSubtitle =>
      'Usar el diseño de llamada grupal incluso en llamadas directas';

  @override
  String get debugJumpTo => 'Ir a';

  @override
  String get debugJumpToSubtitle => 'Abre una página por URL o ruta';

  @override
  String get debugJumpToTitle => 'Ir a la página';

  @override
  String get debugPageUrlOrRoute => 'URL o ruta de la página';

  @override
  String get debugBaseUrl => 'URL base';

  @override
  String get debugApiEndpointUpdated => 'Endpoint de la API actualizado';

  @override
  String get debugTransport => 'Transporte de notificaciones';

  @override
  String get debugTransportNotSelected => 'Sin seleccionar';

  @override
  String get debugTransportUnavailable => 'No disponible en esta versión';

  @override
  String debugTransportNowUsing(String label) {
    return 'Las notificaciones usan ahora $label';
  }

  @override
  String get transportApns => 'Servicio de notificaciones push de Apple';

  @override
  String get transportFcm => 'Firebase Cloud Messaging';

  @override
  String get transportWebsocket => 'Conexión en segundo plano con tu servidor';

  @override
  String get errorShowDetails => 'Mostrar detalles del error de la API';

  @override
  String errorHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get notificationChannelMessages => 'Mensajes';

  @override
  String get notificationChannelDescription => 'Mensajes y alertas nuevos';

  @override
  String get notificationSentAttachment => 'Envió un archivo adjunto';

  @override
  String get notificationNewMessage => 'Mensaje nuevo';

  @override
  String get unnamedChat => 'Chat sin nombre';

  @override
  String get unnamedSession => 'Sesión sin nombre';

  @override
  String get tokenMissing => 'Falta el token';

  @override
  String get avatarFormatError =>
      'El avatar debe ser una imagen JPEG, JPG o PNG';

  @override
  String get unableToReadImage => 'No se pudo leer la imagen';

  @override
  String get avatarUploadFailed => 'Falló la subida del avatar';

  @override
  String get unableToReadFile => 'No se pudo leer el archivo';

  @override
  String get fileUploadFailed => 'Falló la subida del archivo';

  @override
  String get requestFailed => 'La solicitud ha fallado';

  @override
  String get settingsFont => 'Fuente';

  @override
  String get fontSystemDefault => 'Predeterminada del sistema';

  @override
  String get fontDownload => 'Descargar';

  @override
  String get fontDownloading => 'Descargando…';

  @override
  String get fontChooseFromFile => 'Elegir desde archivo';

  @override
  String get fontDownloadFailed => 'No se pudo descargar la fuente';

  @override
  String get fontFileUnreadable => 'Ese archivo no es una fuente';

  @override
  String get fontSample =>
      'El veloz murciélago hindú comía feliz cardillo y kiwi';

  @override
  String get fontSubtitle => 'Tipografía de la app';

  @override
  String get fontNotLoaded => 'Fuente no cargada';

  @override
  String get fontDelete => 'Eliminar';

  @override
  String get fontSource => 'Fuente';

  @override
  String fontDownloadTitle(String font) {
    return '¿Descargar $font?';
  }

  @override
  String fontDownloadBody(String url) {
    return 'La fuente se obtiene de $url y se guarda en este dispositivo.';
  }

  @override
  String fontDeleteTitle(String font) {
    return '¿Eliminar $font?';
  }

  @override
  String fontDeleteBody(String url) {
    return 'Se elimina de este dispositivo. Puedes volver a descargarla de $url.';
  }

  @override
  String fontDownloadingLabel(String font) {
    return 'Descargando $font…';
  }

  @override
  String get fontDeleteFailed => 'No se pudo eliminar la fuente';

  @override
  String get fontSourceFailed => 'No se pudo abrir el enlace';

  @override
  String get developerPortal => 'Portal para desarrolladores';

  @override
  String get developerPortalSubtitle =>
      'Herramientas para desarrolladores de Qutty';

  @override
  String get botsPortalTitle => 'Bots';

  @override
  String get botsTitle => 'Bots';

  @override
  String get botsSubtitle => 'Crea y gestiona tus propios bots';

  @override
  String get botsCreate => 'Nuevo bot';

  @override
  String get botsCreateAction => 'Crear bot';

  @override
  String get botsNoBots => 'Aún no hay bots. Crea uno para empezar.';

  @override
  String get botsLoadFailed => 'No se pudieron cargar los bots';

  @override
  String get botsCreateFailed => 'No se pudo crear';

  @override
  String get botsUpdated => 'Bot actualizado';

  @override
  String get botsDeleted => 'Bot eliminado';

  @override
  String get botsCreated => 'Bot creado';

  @override
  String get botsDeleteTitle => '¿Eliminar bot?';

  @override
  String botsDeleteBody(String name) {
    return 'Eliminar \"$name\"? El bot y su token desaparecerán.';
  }

  @override
  String get botsResetTokenTooltip => 'Restablecer token';

  @override
  String get botsResetTokenTitle => '¿Restablecer el token del bot?';

  @override
  String get botsResetTokenBody =>
      'El token actual dejará de funcionar de inmediato. El nuevo token se muestra una sola vez, así que cópialo ahora.';

  @override
  String get botsResetTokenAction => 'Restablecer token';

  @override
  String get botsTokenTitle => 'Token del bot';

  @override
  String get botsTokenCopy => 'Copiar';

  @override
  String get botsTokenCopied => 'Copiado';

  @override
  String get botsTokenMissing => 'Token no encontrado';

  @override
  String get botsActionFailed => 'Algo salió mal con el bot';

  @override
  String get ugcTitle => 'Stickers y emojis';

  @override
  String get ugcSubtitle => 'Crea y gestiona tus propios stickers y emojis';

  @override
  String get ugcPortalTitle => 'Stickers y emojis';

  @override
  String get ugcCreatePack => 'Nuevo paquete';

  @override
  String get ugcCreatePackAction => 'Crear paquete';

  @override
  String get ugcPackNameRequired => 'El nombre del paquete es obligatorio.';

  @override
  String get ugcNameRequired => 'El nombre es obligatorio.';

  @override
  String get ugcItemImageRequired => 'Elige una imagen primero.';

  @override
  String get ugcChooseImage => 'Elegir imagen';

  @override
  String get ugcPackName => 'Nombre del paquete';

  @override
  String get ugcAddItem => 'Añadir elemento';

  @override
  String get ugcItemsTitle => 'Elementos';

  @override
  String get ugcFavoritesTitle => 'Favoritos';

  @override
  String get ugcNoPacks =>
      'Aún no hay paquetes. Crea uno para añadir stickers y emojis.';

  @override
  String get ugcNoItems => 'Este paquete aún no tiene elementos.';

  @override
  String get ugcNoFavorites => 'Aún no hay favoritos.';

  @override
  String get ugcDeletePackTitle => '¿Eliminar paquete?';

  @override
  String ugcDeletePackBody(String name) {
    return '¿Eliminar «$name» y todos sus elementos?';
  }

  @override
  String get ugcDeleteItemTitle => '¿Eliminar elemento?';

  @override
  String ugcDeleteItemBody(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get ugcCreated => 'Creado';

  @override
  String get ugcDeleted => 'Eliminado';

  @override
  String get ugcCreateFailed => 'No se pudo crear';

  @override
  String get ugcPickerAll => 'Todos';

  @override
  String get ugcPickerFavorites => 'Favoritos';

  @override
  String get ugcPickerEmpty =>
      'Aún no hay stickers. Créalos en el Portal para desarrolladores.';

  @override
  String get ugcPickerNoPacks =>
      'Aún no hay paquetes guardados. Guarda un paquete para ver sus stickers aquí.';

  @override
  String get ugcPickerLoadFailed => 'No se pudieron cargar los stickers';

  @override
  String get ugcPickerManage => 'Gestionar en el Portal para desarrolladores';

  @override
  String get ugcPickerSaved => 'Guardado en favoritos';

  @override
  String get ugcPickerRemoved => 'Eliminado de favoritos';

  @override
  String get ugcStickerInsert => 'Insertar';

  @override
  String get ugcSavePack => 'Guardar paquete';

  @override
  String get ugcUnsavePack => 'Quitar paquete guardado';

  @override
  String get ugcSharePack => 'Compartir paquete';

  @override
  String get ugcLinkCopied => 'Enlace copiado';

  @override
  String get ugcPackTitle => 'Paquete de stickers';

  @override
  String get ugcPackUnavailable =>
      'Este paquete de stickers no está disponible.';

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

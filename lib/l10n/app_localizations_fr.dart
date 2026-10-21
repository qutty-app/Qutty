// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Qutty';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSaveChanges => 'Enregistrer les modifications';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonApply => 'Appliquer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get commonRevoke => 'Révoquer';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonDismiss => 'Ignorer';

  @override
  String get commonTryAgain => 'Réessayer';

  @override
  String get commonOpen => 'Ouvrir';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Enregistrement…';

  @override
  String get commonNotAvailable => 'N/D';

  @override
  String get commonLoading => 'chargement';

  @override
  String get commonDetails => 'Détails';

  @override
  String get commonName => 'Nom';

  @override
  String get commonHandle => 'Identifiant';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonSettings => 'Paramètres';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get optionalEmail => 'E-mail (facultatif)';

  @override
  String get usernamePasswordRequired =>
      'Le nom d\'utilisateur et le mot de passe sont obligatoires.';

  @override
  String get loginCreateAccountTitle => 'Créez votre compte';

  @override
  String get loginWelcomeBackTitle => 'Bon retour';

  @override
  String get loginJoinConversation => 'Rejoignez la conversation.';

  @override
  String get loginSignInConversations => 'Connectez-vous à vos conversations.';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get signIn => 'Se connecter';

  @override
  String get alreadyHaveAccount => 'Vous avez déjà un compte ? Se connecter';

  @override
  String get newToQutty => 'Nouveau sur Qutty ? Créez un compte';

  @override
  String couldNotConnect(Object error) {
    return 'Impossible de se connecter à Qutty : $error';
  }

  @override
  String get quttyApiServiceDebugging => 'Débogage de l\'ApiService Qutty';

  @override
  String get developerOptions => 'Options pour les développeurs';

  @override
  String get apiUrl => 'URL de l\'API';

  @override
  String get jwtToken => 'Jeton JWT';

  @override
  String get cancel => 'Annuler';

  @override
  String get loginByToken => 'Se connecter avec un jeton';

  @override
  String get enterJwtToken => 'Saisissez un jeton JWT.';

  @override
  String get couldNotValidateToken => 'Impossible de valider le jeton.';

  @override
  String get selectChat => 'Sélectionnez une discussion';

  @override
  String get home => 'Accueil';

  @override
  String get pageNotFound => 'Page introuvable';

  @override
  String get pageNotFoundDescription =>
      'Cela indique qu\'une page invalide a été ouverte par erreur.';

  @override
  String get chatsSearchHint =>
      'Rechercher des discussions, canaux, utilisateurs';

  @override
  String get chatsProfileTooltip => 'Profil';

  @override
  String get chatsNewChannel => 'Nouveau canal';

  @override
  String get chatsNewChat => 'Nouvelle discussion';

  @override
  String get chatsEmptyTitle => 'Aucune conversation pour l\'instant';

  @override
  String get chatsEmptySubtitle => 'Créez une discussion pour commencer.';

  @override
  String get chatsNoMatches => 'Aucun résultat';

  @override
  String get chatsPreviewAndJoin => 'Aperçu et rejoindre';

  @override
  String get chatsMessageUser => 'Envoyer un message';

  @override
  String get chatBackToChats => 'Retour aux discussions';

  @override
  String get chatConversation => 'Conversation';

  @override
  String get chatStartCall => 'Démarrer l\'appel';

  @override
  String get chatEndCall => 'Terminer l\'appel';

  @override
  String chatIncomingCall(String name) {
    return '$name vous appelle';
  }

  @override
  String get chatOpenCall => 'Ouvrir l\'appel';

  @override
  String get chatDismissCall => 'Ignorer l\'appel';

  @override
  String get chatJoinCall => 'Rejoindre l\'appel';

  @override
  String get chatLeaveCall => 'Quitter l\'appel';

  @override
  String get chatMinimizeCall => 'Réduire l\'appel';

  @override
  String get chatConnectingCall => 'Connexion…';

  @override
  String get chatCalling => 'Appel…';

  @override
  String get chatEnableWebcam => 'Activer la caméra';

  @override
  String get chatDisableWebcam => 'Désactiver la caméra';

  @override
  String get chatEnableScreenShare => 'Partager l\'écran';

  @override
  String get chatDisableScreenShare => 'Arrêter le partage';

  @override
  String get chatEnableSpeaker => 'Haut-parleur activé';

  @override
  String get chatDisableSpeaker => 'Haut-parleur désactivé';

  @override
  String get chatMuteMicrophone => 'Couper le microphone';

  @override
  String get chatUnmuteMicrophone => 'Activer le microphone';

  @override
  String get chatInCall => 'En appel';

  @override
  String get chatCallsUnsupported =>
      'Le serveur ne prend pas en charge les appels';

  @override
  String get chatUnableToOpenAttachment =>
      'Impossible d\'ouvrir la pièce jointe';

  @override
  String get chatUnableToOpenLink => 'Impossible d\'ouvrir le lien';

  @override
  String get chatJoined => 'Discussion rejoint';

  @override
  String get chatNoJoinLink =>
      'Cette discussion n\'a pas de lien d\'invitation';

  @override
  String get chatSendFirstMessage => 'Envoyez votre premier message';

  @override
  String get chatNoWritePermission =>
      'Aucune autorisation d\'écrire des messages';

  @override
  String get chatJoin => 'Rejoindre la discussion';

  @override
  String get chatAttachFile => 'Joindre un fichier';

  @override
  String get chatEmojiSelectButton => 'Choisir des emojis, GIF et stickers';

  @override
  String get mediaPickerStickerTab => 'Sticker';

  @override
  String get mediaPickerEmojiTab => 'Emoji';

  @override
  String get mediaPickerGifTab => 'GIF';

  @override
  String get mediaPickerGifSearchHint => 'Rechercher des GIFs';

  @override
  String get mediaPickerGifFavorite => 'Ajouter aux favoris';

  @override
  String get mediaPickerGifUnfavorite => 'Retirer des favoris';

  @override
  String get mediaPickerGifClearSearch => 'Effacer la recherche';

  @override
  String get mediaPickerGifNoFavorites =>
      'Aucun GIF enregistré. Cherchez-en un et appuyez longuement pour l\'enregistrer.';

  @override
  String get mediaPickerGifEmpty => 'Aucun GIF trouvé';

  @override
  String get mediaPickerGifLoadFailed => 'Impossible de charger les GIFs';

  @override
  String get mediaPickerGifPoweredBy => 'GIFs par Klipy';

  @override
  String get mediaPickerGifSend => 'Envoyer le GIF';

  @override
  String get mediaPickerEmojiLoadFailed => 'Impossible de charger les emojis.';

  @override
  String get mediaPickerGroupSmileysEmotion => 'Émoticônes';

  @override
  String get mediaPickerGroupPeopleBody => 'Personnes et corps';

  @override
  String get mediaPickerGroupAnimalsNature => 'Animaux et nature';

  @override
  String get mediaPickerGroupFoodDrink => 'Nourriture et boissons';

  @override
  String get mediaPickerGroupTravelPlaces => 'Voyages et lieux';

  @override
  String get mediaPickerGroupActivities => 'Activités';

  @override
  String get mediaPickerGroupObjects => 'Objets';

  @override
  String get mediaPickerGroupSymbols => 'Symboles';

  @override
  String get mediaPickerGroupFlags => 'Drapeaux';

  @override
  String get mediaPickerSkinTone => 'Teinte de peau';

  @override
  String get mediaPickerSkinToneDefault => 'Par défaut';

  @override
  String get mediaPickerSkinToneLight => 'Clair';

  @override
  String get mediaPickerSkinToneMediumLight => 'Moyennement clair';

  @override
  String get mediaPickerSkinToneMedium => 'Moyen';

  @override
  String get mediaPickerSkinToneMediumDark => 'Moyennement foncé';

  @override
  String get mediaPickerSkinToneDark => 'Foncé';

  @override
  String get chatWriteMessage => 'Écrire un message';

  @override
  String get chatSend => 'Envoyer';

  @override
  String chatMessageId(int id) {
    return 'ID du message : $id';
  }

  @override
  String get chatMessageRead => 'Lu';

  @override
  String get chatMessageSent => 'Envoyé';

  @override
  String chatReadBy(int count) {
    return 'Lu par $count';
  }

  @override
  String chatSelectionCount(int count) {
    return '$count sélectionnés';
  }

  @override
  String get chatSelectionStop => 'Arrêter la sélection';

  @override
  String get chatMenuReply => 'Répondre';

  @override
  String get chatReplyUnavailable => 'Message d\'origine';

  @override
  String get chatMenuForward => 'Transférer';

  @override
  String get chatMenuSelect => 'Sélectionner';

  @override
  String get chatMenuMore => 'Plus';

  @override
  String get chatMessageCopied => 'Message copié';

  @override
  String get chatActionUnavailable => 'Pas encore disponible';

  @override
  String get chatForwardTitle => 'Transférer vers';

  @override
  String get chatForwardSearch => 'Rechercher des discussions';

  @override
  String get chatForwardNoChats => 'Aucune discussion vers laquelle transférer';

  @override
  String get chatForwarded => 'Transféré';

  @override
  String chatForwardedFrom(String author) {
    return 'Transféré de $author';
  }

  @override
  String get chatForwardedOpen => 'Ouvrir l\'original';

  @override
  String chatForwardedTo(String chat) {
    return 'Transféré à $chat';
  }

  @override
  String get settingsChats => 'Discussions';

  @override
  String get settingsReadCount =>
      'Afficher le nombre de lectures au lieu des coches';

  @override
  String get settingsReadCountSubtitle =>
      'Dans les discussions directes, afficher combien de personnes ont lu chaque message au lieu d\'une coche';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsCustomization => 'Personnalisation';

  @override
  String get settingsCustomizationSubtitle => 'Thème et couleur d\'accent';

  @override
  String get settingsConnectivity => 'Connectivité';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsAccounts => 'Comptes';

  @override
  String get settingsAccountDefaultLabel => 'Compte';

  @override
  String get settingsAccountSafety => 'Sécurité du compte';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsEditProfile => 'Modifier le profil';

  @override
  String get settingsChangePassword => 'Changer le mot de passe';

  @override
  String get settingsChangePasswordSubtitle =>
      'Mettez à jour le mot de passe de votre compte';

  @override
  String get settingsChangeEmail => 'Changer d\'e-mail';

  @override
  String get settingsNoEmailOnFile => 'Aucun e-mail enregistré';

  @override
  String get settingsActiveSessions => 'Sessions actives';

  @override
  String get settingsActiveSessionsSubtitle =>
      'Gérez les appareils connectés à votre compte';

  @override
  String get settingsRemoveAccount => 'Retirer le compte';

  @override
  String get settingsAddAccount => 'Ajouter un compte';

  @override
  String get settingsAddAccountSubtitle =>
      'Connectez-vous à un autre serveur ou compte';

  @override
  String get settingsDeleteAccount => 'Supprimer le compte';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Supprime définitivement votre compte Qutty';

  @override
  String get settingsVersionPlaceholder => 'Placeholder#424738';

  @override
  String get settingsLogOut => 'Se déconnecter';

  @override
  String get settingsPasswordUpdated => 'Mot de passe mis à jour';

  @override
  String get settingsEmailUpdated => 'E-mail mis à jour';

  @override
  String get settingsLogOutTitle => 'Se déconnecter ?';

  @override
  String get settingsLogOutBody =>
      'Vous devrez saisir à nouveau votre mot de passe pour vous reconnecter.';

  @override
  String get settingsDeleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get settingsDeleteAccountBody =>
      'Saisissez votre nom d\'utilisateur et votre mot de passe pour supprimer définitivement votre compte et toutes vos données.';

  @override
  String get settingsEditProfileTooltip => 'Modifier le profil';

  @override
  String get settingsCalls => 'Appels';

  @override
  String get settingsCallWebcam => 'Webcam';

  @override
  String get settingsCallWebcamSubtitle => 'Démarrer les appels webcam allumée';

  @override
  String get settingsCallCamera => 'Caméra';

  @override
  String get settingsCallCameraFront => 'Face avant';

  @override
  String get settingsCallCameraBack => 'Face arrière';

  @override
  String get settingsCallLoudspeaker => 'Haut-parleur';

  @override
  String get settingsCallLoudspeakerSubtitle =>
      'Écouter l\'appel via le haut-parleur';

  @override
  String get settingsCallMic => 'Microphone';

  @override
  String get settingsCallMicSubtitle => 'Démarrer les appels micro ouvert';

  @override
  String get settingsCallScreenShare => 'Screencast';

  @override
  String get settingsCallScreenShareSubtitle =>
      'Autoriser le partage d\'écran pendant les appels';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioInput => 'Microphone';

  @override
  String get settingsAudioOutput => 'Haut-parleurs';

  @override
  String get settingsAudioCamera => 'Caméra';

  @override
  String get settingsAudioSystemDefault => 'Par défaut du système';

  @override
  String get settingsAudioNoDevices => 'Aucun appareil trouvé';

  @override
  String get settingsAudioNoiseReduction => 'Réduction du bruit';

  @override
  String get settingsAudioNoiseReductionSubtitle =>
      'Supprime le bruit de fond pendant les appels';

  @override
  String get settingsAudioMicVolume => 'Volume du microphone';

  @override
  String get settingsAudioSpeakerVolume => 'Volume des haut-parleurs';

  @override
  String get screenSharePickTitle => 'Choisissez ce que vous voulez partager';

  @override
  String get screenSharePickScreens => 'Écrans';

  @override
  String get screenSharePickWindows => 'Fenêtres';

  @override
  String get screenSharePickEmpty => 'Aucun écran ni fenêtre trouvé';

  @override
  String get screenSharePickError =>
      'Impossible de charger les écrans et fenêtres';

  @override
  String get screenSharePickRetry => 'Réessayer';

  @override
  String get notificationsToggle => 'Notifications de messages';

  @override
  String get notificationsOffForDevice => 'Désactivées pour cet appareil';

  @override
  String get notificationsOpenWithBackground =>
      'Alertes lorsque l\'application est ouverte et en arrière-plan';

  @override
  String get notificationsOpenOnly =>
      'Alertes lorsque l\'application est ouverte';

  @override
  String get notificationsOpenBackgroundConnection =>
      'Alertes lorsque l\'application est ouverte (connexion en arrière-plan)';

  @override
  String get notificationsPermissionHint =>
      'Autorisez les notifications de Qutty dans les réglages système pour recevoir des alertes en arrière-plan.';

  @override
  String get connectionStatus => 'État de la connexion';

  @override
  String get connectionLiveWebsocket => 'État du websocket en direct';

  @override
  String get connectionReconnect => 'Se reconnecter';

  @override
  String get connectionConnected => 'Connecté';

  @override
  String get connectionConnecting => 'Connexion…';

  @override
  String get connectionDisconnected => 'Déconnecté';

  @override
  String sessionsRevokeTitle(String name) {
    return 'Révoquer la session de $name ?';
  }

  @override
  String get sessionsRevokeBody =>
      'Les autres appareils utilisant cette session seront déconnectés.';

  @override
  String get sessionsRevoked => 'Session révoquée';

  @override
  String get sessionsLoadFailed => 'Impossible de charger les sessions';

  @override
  String get sessionsNone => 'Aucune session active';

  @override
  String get sessionsThisDevice => 'Cet appareil';

  @override
  String sessionsLastActive(String time) {
    return 'Actif $time';
  }

  @override
  String get sessionsCurrentBadge => 'Actuelle';

  @override
  String get timeJustNow => 'à l\'instant';

  @override
  String timeMinutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'il y a $count j';
  }

  @override
  String get languageTitle => 'Langue';

  @override
  String get languageSubtitle => 'Langue de l\'application';

  @override
  String get languageSystemDefault => 'Réglage du système';

  @override
  String get themeLabel => 'Thème';

  @override
  String get accentColorLabel => 'Couleur d\'accent';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeDark => 'Sombre';

  @override
  String get themeLight => 'Blanc';

  @override
  String get accentQuttyBlue => 'Bleu Qutty';

  @override
  String get accentCustom => 'Personnalisée';

  @override
  String get customAccentColor => 'Couleur d\'accent personnalisée';

  @override
  String get hexColor => 'Couleur hexadécimale';

  @override
  String get roleOwner => 'Propriétaire';

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get roleRestricted => 'Restreint';

  @override
  String get roleMember => 'Membre';

  @override
  String get accountNewEmail => 'Nouvel e-mail';

  @override
  String get accountCurrentPassword => 'Mot de passe actuel';

  @override
  String get accountConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get accountNewPassword => 'Nouveau mot de passe';

  @override
  String get chatSettingsTitle => 'Paramètres de la discussion';

  @override
  String get chatSettingsLeaveTitle => 'Quitter la discussion ?';

  @override
  String get chatSettingsLeaveBody =>
      'Vous perdrez l\'accès à cette discussion, sauf si un administrateur vous invite à nouveau.';

  @override
  String get chatSettingsLeave => 'Quitter';

  @override
  String chatSettingsDeleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String get chatSettingsDeleteBody =>
      'Tous les messages et membres seront définitivement supprimés. Cette action est irréversible.';

  @override
  String get chatSettingsLoadFailed => 'Impossible de charger les paramètres';

  @override
  String get chatSettingsProfileSection => 'Profil';

  @override
  String get chatSettingsEditProfileSubtitle =>
      'Nom, identifiant, description et image';

  @override
  String get chatSettingsCreateInvite => 'Créer un lien d\'invitation';

  @override
  String get chatSettingsCreateInviteSubtitle =>
      'Générez une invitation à partager';

  @override
  String get chatSettingsPermissions => 'Autorisations';

  @override
  String get chatSettingsMembers => 'Membres';

  @override
  String get chatSettingsMembersSubtitle =>
      'Consulter et gérer les participants';

  @override
  String get chatSettingsAccessControl => 'Contrôle d\'accès';

  @override
  String get chatSettingsAccessControlSubtitle =>
      'Autorisations par défaut des membres';

  @override
  String get chatSettingsDirectMessage => 'Message direct';

  @override
  String get chatSettingsOpenContactProfile => 'Ouvrir le profil du contact';

  @override
  String get chatSettingsDangerZone => 'Zone de danger';

  @override
  String get chatSettingsLeaveTile => 'Quitter la discussion';

  @override
  String get chatSettingsDeleteTile => 'Supprimer la discussion';

  @override
  String get chatSettingsDeleteTileSubtitle =>
      'Seul le créateur peut supprimer cette discussion';

  @override
  String get chatSettingsInviteTitle => 'Lien d\'invitation';

  @override
  String get chatSettingsInviteBody =>
      'Partagez ce lien avec les personnes que vous souhaitez inviter. Il a été copié dans votre presse-papiers.';

  @override
  String get chatSettingsInviteCopied => 'Lien d\'invitation copié';

  @override
  String get aclDefaultPermissions => 'Autorisations par défaut des membres';

  @override
  String get aclDescription =>
      'Ces autorisations s\'appliquent aux membres ordinaires. Les administrateurs disposent toujours d\'un accès de gestion.';

  @override
  String get aclSavePermissions => 'Enregistrer les autorisations';

  @override
  String get aclEditMessages => 'Modifier les messages';

  @override
  String get aclEditMessagesDescription =>
      'Permet aux membres de modifier les messages.';

  @override
  String get permissionWriteMessages => 'Envoyer des messages';

  @override
  String get permissionWriteMessagesDescription =>
      'Permet aux membres d\'envoyer de nouveaux messages.';

  @override
  String get permissionDeleteOthersMessages =>
      'Supprimer les messages des autres';

  @override
  String get permissionDeleteOthersMessagesDescription =>
      'Permet aux membres de supprimer les messages des autres.';

  @override
  String get permissionEditOthersMessages => 'Modifier les messages des autres';

  @override
  String get permissionEditOthersMessagesDescription =>
      'Permet aux membres de modifier les messages des autres.';

  @override
  String get permissionRestrictUsers => 'Gérer les membres';

  @override
  String get permissionRestrictUsersDescription =>
      'Permet aux membres de retirer ou de restreindre d\'autres membres.';

  @override
  String get permissionEditProfile => 'Modifier le profil de la discussion';

  @override
  String get permissionEditProfileDescription =>
      'Permet aux membres de mettre à jour le nom et la description de la discussion.';

  @override
  String get permissionAddAdmins => 'Gérer les administrateurs';

  @override
  String get permissionAddAdminsDescription =>
      'Permet aux membres de promouvoir d\'autres membres.';

  @override
  String get membersTitle => 'Membres';

  @override
  String get membersLoadFailed => 'Impossible de charger les membres';

  @override
  String get membersYou => 'Vous';

  @override
  String get membersMore => 'Plus';

  @override
  String get membersViewProfile => 'Voir le profil';

  @override
  String membersGiveChat(String name) {
    return 'Confier $name à cet utilisateur';
  }

  @override
  String get membersManagePermissions => 'Gérer les autorisations';

  @override
  String get membersRemoveFromChat => 'Retirer de la discussion';

  @override
  String membersRemoveTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get membersRemoveBody =>
      'Cette personne perdra immédiatement l\'accès à cette discussion.';

  @override
  String membersOwnershipGiven(String name) {
    return 'La propriété de la discussion a été confiée à $name';
  }

  @override
  String get membersTransferTitle => 'Informations sur l\'utilisateur cible';

  @override
  String get membersTransferAttention => 'ATTENTION !';

  @override
  String membersTransferUsername(String username) {
    return 'NOM D\'UTILISATEUR : $username';
  }

  @override
  String membersTransferAcknowledge(String chat, String username) {
    return 'Je reconnais que je vais perdre la propriété de $chat et que $username recevra $chat.';
  }

  @override
  String get membersEnterPassword => 'Saisissez votre mot de passe';

  @override
  String membersGiveConfirm(String chat, String username) {
    return 'Confier $chat à $username';
  }

  @override
  String get membersOwnerLocked =>
      'Le propriétaire de la discussion ne peut pas être modifié.';

  @override
  String get createChatNewChannel => 'Nouveau canal';

  @override
  String get createChatNewChat => 'Nouvelle discussion';

  @override
  String get createChatClose => 'Fermer';

  @override
  String get createChatCreateChannel => 'Créer un canal';

  @override
  String get createChatCreateChat => 'Créer une discussion';

  @override
  String get createChatChooseAvatar => 'Choisir un avatar';

  @override
  String get createChatDisplayName => 'Nom affiché';

  @override
  String get createChatUsernameOptional => 'Nom d\'utilisateur (facultatif)';

  @override
  String get createChatUsernameOptionalHelper =>
      'Vous pouvez laisser ce champ vide et l\'ajouter plus tard.';

  @override
  String get createChatNameRequired => 'Le nom affiché est obligatoire.';

  @override
  String get joinPreviewTitle => 'Rejoindre la discussion';

  @override
  String get joinPreviewInvalidLink => 'Lien d\'invitation invalide';

  @override
  String get joinPreviewJoining => 'Connexion…';

  @override
  String get joinPreviewJoin => 'Rejoindre';

  @override
  String get editProfileChangeAvatar => 'Changer d\'avatar';

  @override
  String get editProfileRemoveAvatar => 'Retirer l\'avatar';

  @override
  String get editProfileBio => 'Biographie';

  @override
  String get editProfileNameEmpty => 'Le nom affiché ne peut pas être vide';

  @override
  String get editProfileHandleReserved =>
      'L\'identifiant ne peut pas être _, cet identifiant est réservé à la réinitialisation';

  @override
  String get editChatChannelSettings => 'Paramètres du canal';

  @override
  String get editChatTapForPicture =>
      'Appuyez pour changer l\'image de la discussion';

  @override
  String get editChatUpload => 'Téléverser';

  @override
  String get editChatReplace => 'Remplacer';

  @override
  String get editChatHandleHelper =>
      'Sert à partager la discussion via @identifiant';

  @override
  String get profileUnableToOpen => 'Impossible d\'ouvrir';

  @override
  String profileError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get profileNotFound => 'Profil introuvable';

  @override
  String profileChatId(int id) {
    return 'ID de discussion : $id';
  }

  @override
  String profileUserId(int id) {
    return 'ID d\'utilisateur : $id';
  }

  @override
  String profileTabMedia(int count) {
    return 'Médias ($count)';
  }

  @override
  String profileTabGifs(int count) {
    return 'GIF ($count)';
  }

  @override
  String profileTabLinks(int count) {
    return 'Liens ($count)';
  }

  @override
  String profileTabFiles(int count) {
    return 'Fichiers ($count)';
  }

  @override
  String get profileNoMedia => 'Aucun média pour l\'instant';

  @override
  String get profileNoGifs => 'Aucun GIF pour l\'instant';

  @override
  String get profileNoLinks => 'Aucun lien pour l\'instant';

  @override
  String get profileNoFiles => 'Aucun fichier pour l\'instant';

  @override
  String get aboutTerms =>
      'Conditions d\'utilisation et politique de confidentialité';

  @override
  String get aboutLicenses => 'Licences open source';

  @override
  String aboutBuild(String build) {
    return 'Build : $build';
  }

  @override
  String aboutCopyright(String version) {
    return 'Qutty - RdProjects 2026 © Tous droits réservés\nVersion : $version';
  }

  @override
  String get debugTitle => 'Quttycaka';

  @override
  String get debugWarning =>
      'Ces paramètres servent uniquement au développement et au débogage. \nLes modifier peut provoquer un comportement inattendu.\nContinuez seulement si vous savez ce que vous faites.\n - QuttyTeam chez RdProjects';

  @override
  String get debugSubtitle =>
      'Paramètres de développement/débogage, aka Quttycaka';

  @override
  String get debugApiEndpoint => 'Point de terminaison de l\'API';

  @override
  String get debugDeveloperInfo => 'Infos développeur';

  @override
  String get debugDeveloperInfoSubtitle =>
      'Afficher les ID des profils et des messages';

  @override
  String get debugFallbackSelectorCast => 'FallBackSelectorCast';

  @override
  String get debugFallbackSelectorCastSubtitle =>
      'Toujours utiliser le sélecteur d\'écran de l\'app au lieu de celui du système';

  @override
  String get debugForceGroupCall => 'Forcer la disposition d\'appel de groupe';

  @override
  String get debugForceGroupCallSubtitle =>
      'Utiliser la disposition d\'appel de groupe même dans les appels directs';

  @override
  String get debugJumpTo => 'Aller à';

  @override
  String get debugJumpToSubtitle => 'Ouvrir une page par URL ou par route';

  @override
  String get debugJumpToTitle => 'Aller à la page';

  @override
  String get debugPageUrlOrRoute => 'URL ou route de la page';

  @override
  String get debugBaseUrl => 'URL de base';

  @override
  String get debugApiEndpointUpdated =>
      'Point de terminaison de l\'API mis à jour';

  @override
  String get debugTransport => 'Canal de notification';

  @override
  String get debugTransportNotSelected => 'Non sélectionné';

  @override
  String get debugTransportUnavailable => 'Indisponible dans cette version';

  @override
  String debugTransportNowUsing(String label) {
    return 'Les notifications utilisent maintenant $label';
  }

  @override
  String get transportApns => 'Service de notification push Apple';

  @override
  String get transportFcm => 'Firebase Cloud Messaging';

  @override
  String get transportWebsocket => 'Connexion en arrière-plan à votre serveur';

  @override
  String get errorShowDetails => 'Afficher les détails de l\'erreur d\'API';

  @override
  String errorHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get notificationChannelMessages => 'Messages';

  @override
  String get notificationChannelDescription => 'Nouveaux messages et alertes';

  @override
  String get notificationSentAttachment => 'A envoyé une pièce jointe';

  @override
  String get notificationNewMessage => 'Nouveau message';

  @override
  String get unnamedChat => 'Discussion sans nom';

  @override
  String get unnamedSession => 'Session sans nom';

  @override
  String get tokenMissing => 'Jeton manquant';

  @override
  String get avatarFormatError =>
      'L\'avatar doit être une image JPEG, JPG ou PNG';

  @override
  String get unableToReadImage => 'Impossible de lire l\'image';

  @override
  String get avatarUploadFailed => 'Échec du téléversement de l\'avatar';

  @override
  String get unableToReadFile => 'Impossible de lire le fichier';

  @override
  String get fileUploadFailed => 'Échec du téléversement du fichier';

  @override
  String get requestFailed => 'Échec de la requête';

  @override
  String get settingsFont => 'Police';

  @override
  String get fontSystemDefault => 'Police système';

  @override
  String get fontDownload => 'Télécharger';

  @override
  String get fontDownloading => 'Téléchargement…';

  @override
  String get fontChooseFromFile => 'Choisir un fichier';

  @override
  String get fontDownloadFailed => 'Impossible de télécharger cette police';

  @override
  String get fontFileUnreadable => 'Ce fichier n\'est pas une police';

  @override
  String get fontSample => 'Portez ce vieux whisky au juge blond qui fume';

  @override
  String get fontSubtitle => 'Police de l\'application';

  @override
  String get fontNotLoaded => 'Police non chargée';

  @override
  String get fontDelete => 'Supprimer';

  @override
  String get fontSource => 'Source';

  @override
  String fontDownloadTitle(String font) {
    return 'Télécharger $font ?';
  }

  @override
  String fontDownloadBody(String url) {
    return 'La police est récupérée depuis $url et stockée sur cet appareil.';
  }

  @override
  String fontDeleteTitle(String font) {
    return 'Supprimer $font ?';
  }

  @override
  String fontDeleteBody(String url) {
    return 'Elle est supprimée de cet appareil. Vous pouvez la retélécharger depuis $url.';
  }

  @override
  String fontDownloadingLabel(String font) {
    return 'Téléchargement de $font…';
  }

  @override
  String get fontDeleteFailed => 'Impossible de supprimer cette police';

  @override
  String get fontSourceFailed => 'Impossible d\'ouvrir ce lien';

  @override
  String get developerPortal => 'Portail développeur';

  @override
  String get developerPortalSubtitle => 'Outils pour les développeurs de Qutty';

  @override
  String get ugcTitle => 'Stickers et emojis';

  @override
  String get ugcSubtitle => 'Créez et gérez vos propres stickers et emojis';

  @override
  String get ugcPortalTitle => 'Stickers et emojis';

  @override
  String get ugcCreatePack => 'Nouveau pack';

  @override
  String get ugcCreatePackAction => 'Créer un pack';

  @override
  String get ugcPackNameRequired => 'Le nom du pack est obligatoire.';

  @override
  String get ugcNameRequired => 'Un nom est obligatoire.';

  @override
  String get ugcItemImageRequired => 'Choisissez d\'abord une image.';

  @override
  String get ugcChooseImage => 'Choisir une image';

  @override
  String get ugcPackName => 'Nom du pack';

  @override
  String get ugcAddItem => 'Ajouter un élément';

  @override
  String get ugcItemsTitle => 'Éléments';

  @override
  String get ugcFavoritesTitle => 'Favoris';

  @override
  String get ugcNoPacks =>
      'Aucun pack pour l\'instant. Créez-en un pour ajouter des stickers et des emojis.';

  @override
  String get ugcNoItems => 'Ce pack n\'a encore aucun élément.';

  @override
  String get ugcNoFavorites => 'Aucun favori pour l\'instant.';

  @override
  String get ugcDeletePackTitle => 'Supprimer le pack ?';

  @override
  String ugcDeletePackBody(String name) {
    return 'Supprimer « $name » et tous ses éléments ?';
  }

  @override
  String get ugcDeleteItemTitle => 'Supprimer l\'élément ?';

  @override
  String ugcDeleteItemBody(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get ugcCreated => 'Créé';

  @override
  String get ugcDeleted => 'Supprimé';

  @override
  String get ugcCreateFailed => 'Impossible de le créer';

  @override
  String get ugcPickerAll => 'Tous';

  @override
  String get ugcPickerFavorites => 'Favoris';

  @override
  String get ugcPickerEmpty =>
      'Aucun sticker pour l\'instant. Créez-en dans le Portail développeur.';

  @override
  String get ugcPickerNoPacks =>
      'Aucun pack enregistré pour le moment. Enregistrez un pack pour voir ses stickers ici.';

  @override
  String get ugcPickerLoadFailed => 'Impossible de charger les stickers';

  @override
  String get ugcPickerManage => 'Gérer dans le Portail développeur';

  @override
  String get ugcPickerSaved => 'Ajouté aux favoris';

  @override
  String get ugcPickerRemoved => 'Retiré des favoris';

  @override
  String get ugcStickerInsert => 'Insérer';

  @override
  String get ugcSavePack => 'Enregistrer le pack';

  @override
  String get ugcUnsavePack => 'Retirer le pack enregistré';

  @override
  String get ugcSharePack => 'Partager le pack';

  @override
  String get ugcLinkCopied => 'Lien copié';

  @override
  String get ugcPackTitle => 'Pack de stickers';

  @override
  String get ugcPackUnavailable => 'Ce pack de stickers n\'est pas disponible.';

  @override
  String get ugcStickerPreview => 'Sticker';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Qutty';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonSaveChanges => 'Save changes';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonRevoke => 'Revoke';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonOpen => 'Open';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonNotAvailable => 'N/A';

  @override
  String get commonLoading => 'loading';

  @override
  String get commonDetails => 'Details';

  @override
  String get commonName => 'Name';

  @override
  String get commonHandle => 'Handle';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonSettings => 'Settings';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get optionalEmail => 'Email (optional)';

  @override
  String get usernamePasswordRequired => 'Username and password are required.';

  @override
  String get loginCreateAccountTitle => 'Create your account';

  @override
  String get loginWelcomeBackTitle => 'Welcome back';

  @override
  String get loginJoinConversation => 'Join the conversation.';

  @override
  String get loginSignInConversations => 'Sign in to your conversations.';

  @override
  String get createAccount => 'Create account';

  @override
  String get signIn => 'Sign in';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get newToQutty => 'New to Qutty? Create an account';

  @override
  String couldNotConnect(Object error) {
    return 'Could not connect to Qutty: $error';
  }

  @override
  String get quttyApiServiceDebugging => 'Qutty ApiService Debugging';

  @override
  String get developerOptions => 'Options for developers';

  @override
  String get apiUrl => 'API URL';

  @override
  String get jwtToken => 'JWT token';

  @override
  String get cancel => 'Cancel';

  @override
  String get loginByToken => 'Login by token';

  @override
  String get enterJwtToken => 'Enter a JWT token.';

  @override
  String get couldNotValidateToken => 'Could not validate the token.';

  @override
  String get selectChat => 'Select a chat';

  @override
  String get home => 'Home';

  @override
  String get pageNotFound => 'Page Not Found';

  @override
  String get pageNotFoundDescription =>
      'This indicates that an invalid page was somehow opened.';

  @override
  String get chatsSearchHint => 'Search chats, channels, users';

  @override
  String get chatsProfileTooltip => 'Profile';

  @override
  String get chatsNewChannel => 'New Channel';

  @override
  String get chatsNewChat => 'New Chat';

  @override
  String get chatsEmptyTitle => 'No conversations yet';

  @override
  String get chatsEmptySubtitle => 'Create a chat to get started.';

  @override
  String get chatsNoMatches => 'No matches found';

  @override
  String get chatsPreviewAndJoin => 'Preview and join';

  @override
  String get chatsMessageUser => 'Message user';

  @override
  String get chatBackToChats => 'Back to chats';

  @override
  String get chatConversation => 'Conversation';

  @override
  String get chatStartCall => 'Start call';

  @override
  String get chatEndCall => 'End call';

  @override
  String chatIncomingCall(String name) {
    return '$name is calling';
  }

  @override
  String get chatOpenCall => 'Open call';

  @override
  String get chatDismissCall => 'Dismiss call';

  @override
  String get chatJoinCall => 'Join call';

  @override
  String get chatLeaveCall => 'Leave call';

  @override
  String get chatMinimizeCall => 'Minimize call';

  @override
  String get chatConnectingCall => 'Connecting…';

  @override
  String get chatCalling => 'Calling…';

  @override
  String get chatEnableWebcam => 'Camera on';

  @override
  String get chatDisableWebcam => 'Camera off';

  @override
  String get chatEnableScreenShare => 'Share screen';

  @override
  String get chatDisableScreenShare => 'Stop sharing';

  @override
  String get chatEnableSpeaker => 'Speaker on';

  @override
  String get chatDisableSpeaker => 'Speaker off';

  @override
  String get chatMuteMicrophone => 'Mute microphone';

  @override
  String get chatUnmuteMicrophone => 'Unmute microphone';

  @override
  String get chatInCall => 'In call';

  @override
  String get chatCallsUnsupported => 'Server doesnt support calls';

  @override
  String get chatUnableToOpenAttachment => 'Unable to open attachment';

  @override
  String get chatUnableToOpenLink => 'Unable to open link';

  @override
  String get chatJoined => 'Joined chat';

  @override
  String get chatNoJoinLink => 'This chat does not have a join link';

  @override
  String get chatSendFirstMessage => 'Send your first message';

  @override
  String get chatNoWritePermission => 'No permissions to write messages';

  @override
  String get chatJoin => 'Join chat';

  @override
  String get chatAttachFile => 'Attach file';

  @override
  String get chatEmojiSelectButton => 'Choose emojis, gifs and stickers';

  @override
  String get mediaPickerStickerTab => 'Sticker';

  @override
  String get mediaPickerEmojiTab => 'Emoji';

  @override
  String get mediaPickerGifTab => 'GIF';

  @override
  String get mediaPickerGifSearchHint => 'Search GIFs';

  @override
  String get mediaPickerGifFavorite => 'Save to favorites';

  @override
  String get mediaPickerGifUnfavorite => 'Remove from favorites';

  @override
  String get mediaPickerGifClearSearch => 'Clear search';

  @override
  String get mediaPickerGifNoFavorites =>
      'No saved GIFs yet. Search to find one, then long-press to save it.';

  @override
  String get mediaPickerGifEmpty => 'No GIFs found';

  @override
  String get mediaPickerGifLoadFailed => 'Couldn\'t load GIFs';

  @override
  String get mediaPickerGifPoweredBy => 'GIFs by Klipy';

  @override
  String get mediaPickerGifSend => 'Send GIF';

  @override
  String get mediaPickerEmojiLoadFailed => 'Emoji could not be loaded.';

  @override
  String get mediaPickerGroupSmileysEmotion => 'Smileys & Emotion';

  @override
  String get mediaPickerGroupPeopleBody => 'People & Body';

  @override
  String get mediaPickerGroupAnimalsNature => 'Animals & Nature';

  @override
  String get mediaPickerGroupFoodDrink => 'Food & Drink';

  @override
  String get mediaPickerGroupTravelPlaces => 'Travel & Places';

  @override
  String get mediaPickerGroupActivities => 'Activities';

  @override
  String get mediaPickerGroupObjects => 'Objects';

  @override
  String get mediaPickerGroupSymbols => 'Symbols';

  @override
  String get mediaPickerGroupFlags => 'Flags';

  @override
  String get mediaPickerSkinTone => 'Skin tone';

  @override
  String get mediaPickerSkinToneDefault => 'Default';

  @override
  String get mediaPickerSkinToneLight => 'Light';

  @override
  String get mediaPickerSkinToneMediumLight => 'Medium-light';

  @override
  String get mediaPickerSkinToneMedium => 'Medium';

  @override
  String get mediaPickerSkinToneMediumDark => 'Medium-dark';

  @override
  String get mediaPickerSkinToneDark => 'Dark';

  @override
  String get chatWriteMessage => 'Write a message';

  @override
  String get chatSend => 'Send';

  @override
  String chatMessageId(int id) {
    return 'Message ID: $id';
  }

  @override
  String get chatMessageRead => 'Read';

  @override
  String get chatMessageSent => 'Sent';

  @override
  String chatReadBy(int count) {
    return 'Read by $count';
  }

  @override
  String chatSelectionCount(int count) {
    return '$count selected';
  }

  @override
  String get chatSelectionStop => 'Stop selecting';

  @override
  String get chatMenuReply => 'Reply';

  @override
  String get chatReplyUnavailable => 'Original message';

  @override
  String get chatMenuForward => 'Forward';

  @override
  String get chatMenuSelect => 'Select';

  @override
  String get chatMenuMore => 'More';

  @override
  String get chatMessageCopied => 'Message copied';

  @override
  String get chatActionUnavailable => 'Not available yet';

  @override
  String get chatForwardTitle => 'Forward to';

  @override
  String get chatForwardSearch => 'Search chats';

  @override
  String get chatForwardNoChats => 'No chats to forward to';

  @override
  String get chatForwarded => 'Forwarded';

  @override
  String chatForwardedFrom(String author) {
    return 'Forwarded from $author';
  }

  @override
  String get chatForwardedOpen => 'Open original';

  @override
  String chatForwardedTo(String chat) {
    return 'Forwarded to $chat';
  }

  @override
  String get settingsChats => 'Chats';

  @override
  String get settingsReadCount => 'Show read count instead of ticks';

  @override
  String get settingsReadCountSubtitle =>
      'In direct chats, show how many people have read each message instead of a check mark';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsCustomization => 'Customization';

  @override
  String get settingsCustomizationSubtitle => 'Theme and accent color';

  @override
  String get settingsConnectivity => 'Connectivity';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsAccounts => 'Accounts';

  @override
  String get settingsAccountDefaultLabel => 'Account';

  @override
  String get settingsAccountSafety => 'Account safety';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsEditProfile => 'Edit profile';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsChangePasswordSubtitle => 'Update your account password';

  @override
  String get settingsChangeEmail => 'Change email';

  @override
  String get settingsNoEmailOnFile => 'No email on file';

  @override
  String get settingsActiveSessions => 'Active sessions';

  @override
  String get settingsActiveSessionsSubtitle =>
      'Manage devices signed in to your account';

  @override
  String get settingsRemoveAccount => 'Remove account';

  @override
  String get settingsAddAccount => 'Add account';

  @override
  String get settingsAddAccountSubtitle =>
      'Sign in to another server or account';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountSubtitle =>
      'Permanently delete your Qutty account';

  @override
  String get settingsVersionPlaceholder => 'Placeholder#424738';

  @override
  String get settingsLogOut => 'Log out';

  @override
  String get settingsPasswordUpdated => 'Password updated';

  @override
  String get settingsEmailUpdated => 'Email updated';

  @override
  String get settingsLogOutTitle => 'Log out?';

  @override
  String get settingsLogOutBody =>
      'You will need to enter your password again to sign back in.';

  @override
  String get settingsDeleteAccountTitle => 'Delete account?';

  @override
  String get settingsDeleteAccountBody =>
      'Type your username and password to permanently delete your account and all data.';

  @override
  String get settingsEditProfileTooltip => 'Edit profile';

  @override
  String get settingsCalls => 'Calls';

  @override
  String get settingsCallWebcam => 'Webcam';

  @override
  String get settingsCallWebcamSubtitle => 'Start calls with the webcam on';

  @override
  String get settingsCallCamera => 'Camera';

  @override
  String get settingsCallCameraFront => 'Front';

  @override
  String get settingsCallCameraBack => 'Back';

  @override
  String get settingsCallLoudspeaker => 'Loudspeaker';

  @override
  String get settingsCallLoudspeakerSubtitle =>
      'Play call audio through the speaker';

  @override
  String get settingsCallMic => 'Microphone';

  @override
  String get settingsCallMicSubtitle => 'Start calls with the microphone on';

  @override
  String get settingsCallScreenShare => 'Screencast';

  @override
  String get settingsCallScreenShareSubtitle =>
      'Allow sharing your screen during calls';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioInput => 'Microphone';

  @override
  String get settingsAudioOutput => 'Speakers';

  @override
  String get settingsAudioCamera => 'Camera';

  @override
  String get settingsAudioSystemDefault => 'System default';

  @override
  String get settingsAudioNoDevices => 'No devices found';

  @override
  String get settingsAudioNoiseReduction => 'Noise reduction';

  @override
  String get settingsAudioNoiseReductionSubtitle =>
      'Suppress background noise during calls';

  @override
  String get settingsAudioMicVolume => 'Microphone volume';

  @override
  String get settingsAudioSpeakerVolume => 'Speaker volume';

  @override
  String get screenSharePickTitle => 'Choose what to share';

  @override
  String get screenSharePickScreens => 'Screens';

  @override
  String get screenSharePickWindows => 'Windows';

  @override
  String get screenSharePickEmpty => 'No screens or windows found';

  @override
  String get screenSharePickError => 'Couldn\'t load screens and windows';

  @override
  String get screenSharePickRetry => 'Try again';

  @override
  String get notificationsToggle => 'Message notifications';

  @override
  String get notificationsOffForDevice => 'Off for this device';

  @override
  String get notificationsOpenWithBackground =>
      'Alerts while the app is open and in the background';

  @override
  String get notificationsOpenOnly => 'Alerts while the app is open';

  @override
  String get notificationsOpenBackgroundConnection =>
      'Alerts while the app is open (background connection)';

  @override
  String get notificationsPermissionHint =>
      'Allow notifications for Qutty in system settings to receive alerts in the background.';

  @override
  String get connectionStatus => 'Connection status';

  @override
  String get connectionLiveWebsocket => 'Live websocket status';

  @override
  String get connectionReconnect => 'Reconnect';

  @override
  String get connectionConnected => 'Connected';

  @override
  String get connectionConnecting => 'Connecting…';

  @override
  String get connectionDisconnected => 'Disconnected';

  @override
  String sessionsRevokeTitle(String name) {
    return 'Revoke $name?';
  }

  @override
  String get sessionsRevokeBody =>
      'Other devices using this session will be signed out.';

  @override
  String get sessionsRevoked => 'Session revoked';

  @override
  String get sessionsLoadFailed => 'Unable to load sessions';

  @override
  String get sessionsNone => 'No active sessions';

  @override
  String get sessionsThisDevice => 'This device';

  @override
  String sessionsLastActive(String time) {
    return 'Last active $time';
  }

  @override
  String get sessionsCurrentBadge => 'Current';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSubtitle => 'App language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get themeLabel => 'Theme';

  @override
  String get accentColorLabel => 'Accent color';

  @override
  String get themeSystem => 'System';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'White';

  @override
  String get accentQuttyBlue => 'Qutty Blue';

  @override
  String get accentCustom => 'Custom';

  @override
  String get customAccentColor => 'Custom accent color';

  @override
  String get hexColor => 'Hex color';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleRestricted => 'Restricted';

  @override
  String get roleMember => 'Member';

  @override
  String get accountNewEmail => 'New email';

  @override
  String get accountCurrentPassword => 'Current password';

  @override
  String get accountConfirmPassword => 'Confirm password';

  @override
  String get accountNewPassword => 'New password';

  @override
  String get chatSettingsTitle => 'Chat settings';

  @override
  String get chatSettingsLeaveTitle => 'Leave chat?';

  @override
  String get chatSettingsLeaveBody =>
      'You will lose access to this chat unless an admin invites you again.';

  @override
  String get chatSettingsLeave => 'Leave';

  @override
  String chatSettingsDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get chatSettingsDeleteBody =>
      'All messages and members will be permanently removed. This cannot be undone.';

  @override
  String get chatSettingsLoadFailed => 'Could not load settings';

  @override
  String get chatSettingsProfileSection => 'Profile';

  @override
  String get chatSettingsEditProfileSubtitle =>
      'Name, handle, description and picture';

  @override
  String get chatSettingsCreateInvite => 'Create invite link';

  @override
  String get chatSettingsCreateInviteSubtitle => 'Generate a shareable invite';

  @override
  String get chatSettingsPermissions => 'Permissions';

  @override
  String get chatSettingsMembers => 'Members';

  @override
  String get chatSettingsMembersSubtitle => 'View and manage participants';

  @override
  String get chatSettingsAccessControl => 'Access control';

  @override
  String get chatSettingsAccessControlSubtitle =>
      'Default permissions for members';

  @override
  String get chatSettingsDirectMessage => 'Direct message';

  @override
  String get chatSettingsOpenContactProfile => 'Open contact profile';

  @override
  String get chatSettingsDangerZone => 'Danger zone';

  @override
  String get chatSettingsLeaveTile => 'Leave chat';

  @override
  String get chatSettingsDeleteTile => 'Delete chat';

  @override
  String get chatSettingsDeleteTileSubtitle =>
      'Only the creator can delete this chat';

  @override
  String get chatSettingsInviteTitle => 'Invite link';

  @override
  String get chatSettingsInviteBody =>
      'Share this link with people you want to invite. It has been copied to your clipboard.';

  @override
  String get chatSettingsInviteCopied => 'Invite link copied';

  @override
  String get aclDefaultPermissions => 'Default member permissions';

  @override
  String get aclDescription =>
      'These permissions apply to regular members. Administrators always have management access.';

  @override
  String get aclSavePermissions => 'Save permissions';

  @override
  String get aclEditMessages => 'Edit messages';

  @override
  String get aclEditMessagesDescription => 'Allow members to edit messages.';

  @override
  String get permissionWriteMessages => 'Send messages';

  @override
  String get permissionWriteMessagesDescription =>
      'Allow members to send new messages.';

  @override
  String get permissionDeleteOthersMessages => 'Delete other messages';

  @override
  String get permissionDeleteOthersMessagesDescription =>
      'Allow members to remove messages from other people.';

  @override
  String get permissionEditOthersMessages => 'Edit other messages';

  @override
  String get permissionEditOthersMessagesDescription =>
      'Allow members to edit messages from other people.';

  @override
  String get permissionRestrictUsers => 'Manage members';

  @override
  String get permissionRestrictUsersDescription =>
      'Allow members to remove or restrict other members.';

  @override
  String get permissionEditProfile => 'Edit chat profile';

  @override
  String get permissionEditProfileDescription =>
      'Allow members to update the chat name and description.';

  @override
  String get permissionAddAdmins => 'Manage administrators';

  @override
  String get permissionAddAdminsDescription =>
      'Allow members to promote other members.';

  @override
  String get membersTitle => 'Members';

  @override
  String get membersLoadFailed => 'Could not load members';

  @override
  String get membersYou => 'You';

  @override
  String get membersMore => 'More';

  @override
  String get membersViewProfile => 'View profile';

  @override
  String membersGiveChat(String name) {
    return 'Give $name to this user';
  }

  @override
  String get membersManagePermissions => 'Manage permissions';

  @override
  String get membersRemoveFromChat => 'Remove from chat';

  @override
  String membersRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get membersRemoveBody =>
      'They will lose access to this chat immediately.';

  @override
  String membersOwnershipGiven(String name) {
    return 'Chat ownership given to $name';
  }

  @override
  String get membersTransferTitle => 'Target User Info';

  @override
  String get membersTransferAttention => '!ATTENTION!';

  @override
  String membersTransferUsername(String username) {
    return 'USERNAME: $username';
  }

  @override
  String membersTransferAcknowledge(String chat, String username) {
    return 'I acknowledge that I will lose ownership of $chat, and $username will get $chat.';
  }

  @override
  String get membersEnterPassword => 'Enter your password';

  @override
  String membersGiveConfirm(String chat, String username) {
    return 'Give $chat to $username';
  }

  @override
  String get membersOwnerLocked => 'The chat owner cannot be modified.';

  @override
  String get createChatNewChannel => 'New channel';

  @override
  String get createChatNewChat => 'New chat';

  @override
  String get createChatClose => 'Close';

  @override
  String get createChatCreateChannel => 'Create channel';

  @override
  String get createChatCreateChat => 'Create chat';

  @override
  String get createChatChooseAvatar => 'Choose avatar';

  @override
  String get createChatDisplayName => 'Display name';

  @override
  String get createChatUsernameOptional => 'Username (optional)';

  @override
  String get createChatUsernameOptionalHelper =>
      'You can leave this empty and add one later.';

  @override
  String get createChatNameRequired => 'Display name is required.';

  @override
  String get joinPreviewTitle => 'Join chat';

  @override
  String get joinPreviewInvalidLink => 'Invalid join link';

  @override
  String get joinPreviewJoining => 'Joining...';

  @override
  String get joinPreviewJoin => 'Join';

  @override
  String get editProfileChangeAvatar => 'Change avatar';

  @override
  String get editProfileRemoveAvatar => 'Remove avatar';

  @override
  String get editProfileBio => 'Bio';

  @override
  String get editProfileNameEmpty => 'Display name cannot be empty';

  @override
  String get editProfileHandleReserved =>
      'Handle cannot be _, this exact handle reserved to reset handle';

  @override
  String get editChatChannelSettings => 'Channel settings';

  @override
  String get editChatTapForPicture => 'Tap to change the chat picture';

  @override
  String get editChatUpload => 'Upload';

  @override
  String get editChatReplace => 'Replace';

  @override
  String get editChatHandleHelper => 'Used to share the chat via @handle';

  @override
  String get profileUnableToOpen => 'Unable to open';

  @override
  String profileError(String error) {
    return 'Error: $error';
  }

  @override
  String get profileNotFound => 'Profile not found';

  @override
  String profileChatId(int id) {
    return 'Chat ID: $id';
  }

  @override
  String profileUserId(int id) {
    return 'User ID: $id';
  }

  @override
  String profileTabMedia(int count) {
    return 'Media ($count)';
  }

  @override
  String profileTabGifs(int count) {
    return 'Gifs ($count)';
  }

  @override
  String profileTabLinks(int count) {
    return 'Links ($count)';
  }

  @override
  String profileTabFiles(int count) {
    return 'Files ($count)';
  }

  @override
  String get profileNoMedia => 'No media yet';

  @override
  String get profileNoGifs => 'No gifs yet';

  @override
  String get profileNoLinks => 'No links yet';

  @override
  String get profileNoFiles => 'No files yet';

  @override
  String get aboutTerms => 'Terms of Service & Privacy Policy';

  @override
  String get aboutLicenses => 'Open Source Licenses';

  @override
  String aboutBuild(String build) {
    return 'Build: $build';
  }

  @override
  String aboutCopyright(String version) {
    return 'Qutty - RdProjects 2026 © All rights reserved\nVersion: $version';
  }

  @override
  String get debugTitle => 'Quttycaka';

  @override
  String get debugWarning =>
      'These settings are for development/debug purposes only. \nChanging them may cause unexpected behavior.\nContinue if you know what you are doing.\n - QuttyTeam at RdProjects';

  @override
  String get debugSubtitle => 'Deveelopment/Debug settings a.k.a Quttycaka';

  @override
  String get debugApiEndpoint => 'API endpoint';

  @override
  String get debugDeveloperInfo => 'Developer Info';

  @override
  String get debugDeveloperInfoSubtitle => 'Show IDs for profiles and messages';

  @override
  String get debugFallbackSelectorCast => 'FallBackSelectorCast';

  @override
  String get debugFallbackSelectorCastSubtitle =>
      'Always use the app\'s own screen picker instead of the system one';

  @override
  String get debugForceGroupCall => 'Force group call layout';

  @override
  String get debugForceGroupCallSubtitle =>
      'Use the group call layout even in direct calls';

  @override
  String get debugJumpTo => 'Jump to';

  @override
  String get debugJumpToSubtitle => 'Open a page by URL or route path';

  @override
  String get debugJumpToTitle => 'Jump to page';

  @override
  String get debugPageUrlOrRoute => 'Page URL or route';

  @override
  String get debugBaseUrl => 'Base URL';

  @override
  String get debugApiEndpointUpdated => 'API endpoint updated';

  @override
  String get debugTransport => 'Notification transport';

  @override
  String get debugTransportNotSelected => 'Not selected';

  @override
  String get debugTransportUnavailable => 'Not available in this build';

  @override
  String debugTransportNowUsing(String label) {
    return 'Notifications now use $label';
  }

  @override
  String get transportApns => 'Apple Push Notification service';

  @override
  String get transportFcm => 'Firebase Cloud Messaging';

  @override
  String get transportWebsocket => 'Background connection to your server';

  @override
  String get errorShowDetails => 'Show API error details';

  @override
  String errorHttpStatus(int code) {
    return 'HTTP $code';
  }

  @override
  String get notificationChannelMessages => 'Messages';

  @override
  String get notificationChannelDescription => 'New messages and alerts';

  @override
  String get notificationSentAttachment => 'Sent an attachment';

  @override
  String get notificationNewMessage => 'New message';

  @override
  String get unnamedChat => 'Unnamed chat';

  @override
  String get unnamedSession => 'Unnamed session';

  @override
  String get tokenMissing => 'Token missing';

  @override
  String get avatarFormatError => 'Avatar must be a JPEG, JPG, or PNG image';

  @override
  String get unableToReadImage => 'Unable to read image';

  @override
  String get avatarUploadFailed => 'Avatar upload failed';

  @override
  String get unableToReadFile => 'Unable to read file';

  @override
  String get fileUploadFailed => 'File upload failed';

  @override
  String get requestFailed => 'Request failed';

  @override
  String get settingsFont => 'Font';

  @override
  String get fontSystemDefault => 'System default';

  @override
  String get fontDownload => 'Download';

  @override
  String get fontDownloading => 'Downloading…';

  @override
  String get fontChooseFromFile => 'Choose from file';

  @override
  String get fontDownloadFailed => 'Couldn\'t download that font';

  @override
  String get fontFileUnreadable => 'That file isn\'t a font';

  @override
  String get fontSample => 'The quick brown fox jumps over the lazy dog';

  @override
  String get fontSubtitle => 'App typeface';

  @override
  String get fontNotLoaded => 'Font not loaded';

  @override
  String get fontDelete => 'Delete';

  @override
  String get fontSource => 'Source';

  @override
  String fontDownloadTitle(String font) {
    return 'Download $font?';
  }

  @override
  String fontDownloadBody(String url) {
    return 'The font is fetched from $url and stored on this device.';
  }

  @override
  String fontDeleteTitle(String font) {
    return 'Delete $font?';
  }

  @override
  String fontDeleteBody(String url) {
    return 'It is removed from this device. You can download it again from $url.';
  }

  @override
  String fontDownloadingLabel(String font) {
    return 'Downloading $font…';
  }

  @override
  String get fontDeleteFailed => 'Couldn\'t delete that font';

  @override
  String get fontSourceFailed => 'Couldn\'t open that link';

  @override
  String get developerPortal => 'Developer portal';

  @override
  String get developerPortalSubtitle => 'Tools for developers on Qutty';

  @override
  String get ugcTitle => 'Stickers and Emojis';

  @override
  String get ugcSubtitle => 'Create and manage your own stickers and emoji';

  @override
  String get ugcPortalTitle => 'Stickers and Emojis';

  @override
  String get ugcCreatePack => 'New pack';

  @override
  String get ugcCreatePackAction => 'Create pack';

  @override
  String get ugcPackNameRequired => 'Pack name is required.';

  @override
  String get ugcNameRequired => 'A name is required.';

  @override
  String get ugcItemImageRequired => 'Choose an image first.';

  @override
  String get ugcChooseImage => 'Choose image';

  @override
  String get ugcPackName => 'Pack name';

  @override
  String get ugcAddItem => 'Add item';

  @override
  String get ugcItemsTitle => 'Items';

  @override
  String get ugcFavoritesTitle => 'Favorites';

  @override
  String get ugcNoPacks =>
      'No packs yet. Create one to add stickers and emoji.';

  @override
  String get ugcNoItems => 'This pack has no items yet.';

  @override
  String get ugcNoFavorites => 'No favorites yet.';

  @override
  String get ugcDeletePackTitle => 'Delete pack?';

  @override
  String ugcDeletePackBody(String name) {
    return 'Delete \"$name\" and all of its items?';
  }

  @override
  String get ugcDeleteItemTitle => 'Delete item?';

  @override
  String ugcDeleteItemBody(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get ugcCreated => 'Created';

  @override
  String get ugcDeleted => 'Deleted';

  @override
  String get ugcCreateFailed => 'Couldn\'t create it';

  @override
  String get ugcPickerAll => 'All';

  @override
  String get ugcPickerFavorites => 'Favorites';

  @override
  String get ugcPickerEmpty =>
      'No stickers yet. Create some in the Developer portal.';

  @override
  String get ugcPickerNoPacks =>
      'No saved packs yet. Save a pack to see its stickers here.';

  @override
  String get ugcPickerLoadFailed => 'Couldn\'t load stickers';

  @override
  String get ugcPickerManage => 'Manage in Developer portal';

  @override
  String get ugcPickerSaved => 'Saved to favorites';

  @override
  String get ugcPickerRemoved => 'Removed from favorites';

  @override
  String get ugcStickerInsert => 'Insert';

  @override
  String get ugcSavePack => 'Save pack';

  @override
  String get ugcUnsavePack => 'Remove saved pack';

  @override
  String get ugcSharePack => 'Share pack';

  @override
  String get ugcLinkCopied => 'Link copied';

  @override
  String get ugcPackTitle => 'Sticker pack';

  @override
  String get ugcPackUnavailable => 'This sticker pack is not available.';

  @override
  String get ugcStickerPreview => 'Sticker';
}

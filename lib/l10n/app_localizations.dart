import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ru'),
    Locale('uk'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Qutty'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get commonSaveChanges;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get commonCopy;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get commonRevoke;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get commonOpen;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get commonNotAvailable;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'loading'**
  String get commonLoading;

  /// No description provided for @commonDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get commonDetails;

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonHandle.
  ///
  /// In en, this message translates to:
  /// **'Handle'**
  String get commonHandle;

  /// No description provided for @commonDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @optionalEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get optionalEmail;

  /// No description provided for @usernamePasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Username and password are required.'**
  String get usernamePasswordRequired;

  /// No description provided for @loginCreateAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get loginCreateAccountTitle;

  /// No description provided for @loginWelcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBackTitle;

  /// No description provided for @loginJoinConversation.
  ///
  /// In en, this message translates to:
  /// **'Join the conversation.'**
  String get loginJoinConversation;

  /// No description provided for @loginSignInConversations.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your conversations.'**
  String get loginSignInConversations;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @newToQutty.
  ///
  /// In en, this message translates to:
  /// **'New to Qutty? Create an account'**
  String get newToQutty;

  /// Shown when the app cannot connect to the server
  ///
  /// In en, this message translates to:
  /// **'Could not connect to Qutty: {error}'**
  String couldNotConnect(Object error);

  /// No description provided for @quttyApiServiceDebugging.
  ///
  /// In en, this message translates to:
  /// **'Qutty ApiService Debugging'**
  String get quttyApiServiceDebugging;

  /// No description provided for @developerOptions.
  ///
  /// In en, this message translates to:
  /// **'Options for developers'**
  String get developerOptions;

  /// No description provided for @apiUrl.
  ///
  /// In en, this message translates to:
  /// **'API URL'**
  String get apiUrl;

  /// No description provided for @jwtToken.
  ///
  /// In en, this message translates to:
  /// **'JWT token'**
  String get jwtToken;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loginByToken.
  ///
  /// In en, this message translates to:
  /// **'Login by token'**
  String get loginByToken;

  /// No description provided for @enterJwtToken.
  ///
  /// In en, this message translates to:
  /// **'Enter a JWT token.'**
  String get enterJwtToken;

  /// No description provided for @couldNotValidateToken.
  ///
  /// In en, this message translates to:
  /// **'Could not validate the token.'**
  String get couldNotValidateToken;

  /// No description provided for @selectChat.
  ///
  /// In en, this message translates to:
  /// **'Select a chat'**
  String get selectChat;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page Not Found'**
  String get pageNotFound;

  /// No description provided for @pageNotFoundDescription.
  ///
  /// In en, this message translates to:
  /// **'This indicates that an invalid page was somehow opened.'**
  String get pageNotFoundDescription;

  /// No description provided for @chatsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats, channels, users'**
  String get chatsSearchHint;

  /// No description provided for @chatsProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get chatsProfileTooltip;

  /// No description provided for @chatsNewChannel.
  ///
  /// In en, this message translates to:
  /// **'New Channel'**
  String get chatsNewChannel;

  /// No description provided for @chatsNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get chatsNewChat;

  /// No description provided for @chatsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get chatsEmptyTitle;

  /// No description provided for @chatsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a chat to get started.'**
  String get chatsEmptySubtitle;

  /// No description provided for @chatsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get chatsNoMatches;

  /// No description provided for @chatsPreviewAndJoin.
  ///
  /// In en, this message translates to:
  /// **'Preview and join'**
  String get chatsPreviewAndJoin;

  /// No description provided for @chatsMessageUser.
  ///
  /// In en, this message translates to:
  /// **'Message user'**
  String get chatsMessageUser;

  /// No description provided for @chatBackToChats.
  ///
  /// In en, this message translates to:
  /// **'Back to chats'**
  String get chatBackToChats;

  /// No description provided for @chatConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get chatConversation;

  /// No description provided for @chatStartCall.
  ///
  /// In en, this message translates to:
  /// **'Start call'**
  String get chatStartCall;

  /// No description provided for @chatEndCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get chatEndCall;

  /// No description provided for @chatIncomingCall.
  ///
  /// In en, this message translates to:
  /// **'{name} is calling'**
  String chatIncomingCall(String name);

  /// No description provided for @chatOpenCall.
  ///
  /// In en, this message translates to:
  /// **'Open call'**
  String get chatOpenCall;

  /// No description provided for @chatDismissCall.
  ///
  /// In en, this message translates to:
  /// **'Dismiss call'**
  String get chatDismissCall;

  /// No description provided for @chatJoinCall.
  ///
  /// In en, this message translates to:
  /// **'Join call'**
  String get chatJoinCall;

  /// No description provided for @chatLeaveCall.
  ///
  /// In en, this message translates to:
  /// **'Leave call'**
  String get chatLeaveCall;

  /// No description provided for @chatMinimizeCall.
  ///
  /// In en, this message translates to:
  /// **'Minimize call'**
  String get chatMinimizeCall;

  /// No description provided for @chatConnectingCall.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get chatConnectingCall;

  /// No description provided for @chatCalling.
  ///
  /// In en, this message translates to:
  /// **'Calling…'**
  String get chatCalling;

  /// No description provided for @chatEnableWebcam.
  ///
  /// In en, this message translates to:
  /// **'Camera on'**
  String get chatEnableWebcam;

  /// No description provided for @chatDisableWebcam.
  ///
  /// In en, this message translates to:
  /// **'Camera off'**
  String get chatDisableWebcam;

  /// No description provided for @chatEnableScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Share screen'**
  String get chatEnableScreenShare;

  /// No description provided for @chatDisableScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get chatDisableScreenShare;

  /// No description provided for @chatEnableSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker on'**
  String get chatEnableSpeaker;

  /// No description provided for @chatDisableSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker off'**
  String get chatDisableSpeaker;

  /// No description provided for @chatMuteMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Mute microphone'**
  String get chatMuteMicrophone;

  /// No description provided for @chatUnmuteMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Unmute microphone'**
  String get chatUnmuteMicrophone;

  /// No description provided for @chatInCall.
  ///
  /// In en, this message translates to:
  /// **'In call'**
  String get chatInCall;

  /// No description provided for @chatCallsUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Server doesnt support calls'**
  String get chatCallsUnsupported;

  /// No description provided for @chatUnableToOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Unable to open attachment'**
  String get chatUnableToOpenAttachment;

  /// No description provided for @chatUnableToOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Unable to open link'**
  String get chatUnableToOpenLink;

  /// No description provided for @chatJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined chat'**
  String get chatJoined;

  /// No description provided for @chatNoJoinLink.
  ///
  /// In en, this message translates to:
  /// **'This chat does not have a join link'**
  String get chatNoJoinLink;

  /// No description provided for @chatSendFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Send your first message'**
  String get chatSendFirstMessage;

  /// No description provided for @chatNoWritePermission.
  ///
  /// In en, this message translates to:
  /// **'No permissions to write messages'**
  String get chatNoWritePermission;

  /// No description provided for @chatJoin.
  ///
  /// In en, this message translates to:
  /// **'Join chat'**
  String get chatJoin;

  /// No description provided for @chatAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get chatAttachFile;

  /// No description provided for @chatEmojiSelectButton.
  ///
  /// In en, this message translates to:
  /// **'Choose emojis, gifs and stickers'**
  String get chatEmojiSelectButton;

  /// No description provided for @mediaPickerStickerTab.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get mediaPickerStickerTab;

  /// No description provided for @mediaPickerEmojiTab.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get mediaPickerEmojiTab;

  /// No description provided for @mediaPickerGifTab.
  ///
  /// In en, this message translates to:
  /// **'GIF'**
  String get mediaPickerGifTab;

  /// No description provided for @mediaPickerGifSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search GIFs'**
  String get mediaPickerGifSearchHint;

  /// No description provided for @mediaPickerGifFavorite.
  ///
  /// In en, this message translates to:
  /// **'Save to favorites'**
  String get mediaPickerGifFavorite;

  /// No description provided for @mediaPickerGifUnfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get mediaPickerGifUnfavorite;

  /// No description provided for @mediaPickerGifClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get mediaPickerGifClearSearch;

  /// No description provided for @mediaPickerGifNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No saved GIFs yet. Search to find one, then long-press to save it.'**
  String get mediaPickerGifNoFavorites;

  /// No description provided for @mediaPickerGifEmpty.
  ///
  /// In en, this message translates to:
  /// **'No GIFs found'**
  String get mediaPickerGifEmpty;

  /// No description provided for @mediaPickerGifLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load GIFs'**
  String get mediaPickerGifLoadFailed;

  /// No description provided for @mediaPickerGifPoweredBy.
  ///
  /// In en, this message translates to:
  /// **'GIFs by Klipy'**
  String get mediaPickerGifPoweredBy;

  /// No description provided for @mediaPickerGifSend.
  ///
  /// In en, this message translates to:
  /// **'Send GIF'**
  String get mediaPickerGifSend;

  /// No description provided for @mediaPickerEmojiLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Emoji could not be loaded.'**
  String get mediaPickerEmojiLoadFailed;

  /// No description provided for @mediaPickerGroupSmileysEmotion.
  ///
  /// In en, this message translates to:
  /// **'Smileys & Emotion'**
  String get mediaPickerGroupSmileysEmotion;

  /// No description provided for @mediaPickerGroupPeopleBody.
  ///
  /// In en, this message translates to:
  /// **'People & Body'**
  String get mediaPickerGroupPeopleBody;

  /// No description provided for @mediaPickerGroupAnimalsNature.
  ///
  /// In en, this message translates to:
  /// **'Animals & Nature'**
  String get mediaPickerGroupAnimalsNature;

  /// No description provided for @mediaPickerGroupFoodDrink.
  ///
  /// In en, this message translates to:
  /// **'Food & Drink'**
  String get mediaPickerGroupFoodDrink;

  /// No description provided for @mediaPickerGroupTravelPlaces.
  ///
  /// In en, this message translates to:
  /// **'Travel & Places'**
  String get mediaPickerGroupTravelPlaces;

  /// No description provided for @mediaPickerGroupActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get mediaPickerGroupActivities;

  /// No description provided for @mediaPickerGroupObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get mediaPickerGroupObjects;

  /// No description provided for @mediaPickerGroupSymbols.
  ///
  /// In en, this message translates to:
  /// **'Symbols'**
  String get mediaPickerGroupSymbols;

  /// No description provided for @mediaPickerGroupFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get mediaPickerGroupFlags;

  /// No description provided for @mediaPickerSkinTone.
  ///
  /// In en, this message translates to:
  /// **'Skin tone'**
  String get mediaPickerSkinTone;

  /// No description provided for @mediaPickerSkinToneDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get mediaPickerSkinToneDefault;

  /// No description provided for @mediaPickerSkinToneLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get mediaPickerSkinToneLight;

  /// No description provided for @mediaPickerSkinToneMediumLight.
  ///
  /// In en, this message translates to:
  /// **'Medium-light'**
  String get mediaPickerSkinToneMediumLight;

  /// No description provided for @mediaPickerSkinToneMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediaPickerSkinToneMedium;

  /// No description provided for @mediaPickerSkinToneMediumDark.
  ///
  /// In en, this message translates to:
  /// **'Medium-dark'**
  String get mediaPickerSkinToneMediumDark;

  /// No description provided for @mediaPickerSkinToneDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get mediaPickerSkinToneDark;

  /// No description provided for @chatWriteMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get chatWriteMessage;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatMessageId.
  ///
  /// In en, this message translates to:
  /// **'Message ID: {id}'**
  String chatMessageId(int id);

  /// No description provided for @chatMessageRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatMessageRead;

  /// No description provided for @chatMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get chatMessageSent;

  /// No description provided for @chatReadBy.
  ///
  /// In en, this message translates to:
  /// **'Read by {count}'**
  String chatReadBy(int count);

  /// No description provided for @chatSelectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String chatSelectionCount(int count);

  /// No description provided for @chatSelectionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop selecting'**
  String get chatSelectionStop;

  /// No description provided for @chatMenuReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatMenuReply;

  /// No description provided for @chatReplyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original message'**
  String get chatReplyUnavailable;

  /// No description provided for @chatMenuForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get chatMenuForward;

  /// No description provided for @chatMenuSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get chatMenuSelect;

  /// No description provided for @chatMenuMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get chatMenuMore;

  /// No description provided for @chatMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get chatMessageCopied;

  /// No description provided for @chatActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available yet'**
  String get chatActionUnavailable;

  /// No description provided for @chatForwardTitle.
  ///
  /// In en, this message translates to:
  /// **'Forward to'**
  String get chatForwardTitle;

  /// No description provided for @chatForwardSearch.
  ///
  /// In en, this message translates to:
  /// **'Search chats'**
  String get chatForwardSearch;

  /// No description provided for @chatForwardNoChats.
  ///
  /// In en, this message translates to:
  /// **'No chats to forward to'**
  String get chatForwardNoChats;

  /// No description provided for @chatForwarded.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get chatForwarded;

  /// No description provided for @chatForwardedFrom.
  ///
  /// In en, this message translates to:
  /// **'Forwarded from {author}'**
  String chatForwardedFrom(String author);

  /// No description provided for @chatForwardedOpen.
  ///
  /// In en, this message translates to:
  /// **'Open original'**
  String get chatForwardedOpen;

  /// No description provided for @chatForwardedTo.
  ///
  /// In en, this message translates to:
  /// **'Forwarded to {chat}'**
  String chatForwardedTo(String chat);

  /// No description provided for @settingsChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get settingsChats;

  /// No description provided for @settingsReadCount.
  ///
  /// In en, this message translates to:
  /// **'Show read count instead of ticks'**
  String get settingsReadCount;

  /// No description provided for @settingsReadCountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'In direct chats, show how many people have read each message instead of a check mark'**
  String get settingsReadCountSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsCustomization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get settingsCustomization;

  /// No description provided for @settingsCustomizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme and accent color'**
  String get settingsCustomizationSubtitle;

  /// No description provided for @settingsConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get settingsConnectivity;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get settingsAccounts;

  /// No description provided for @settingsAccountDefaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccountDefaultLabel;

  /// No description provided for @settingsAccountSafety.
  ///
  /// In en, this message translates to:
  /// **'Account safety'**
  String get settingsAccountSafety;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get settingsChangePasswordSubtitle;

  /// No description provided for @settingsChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get settingsChangeEmail;

  /// No description provided for @settingsNoEmailOnFile.
  ///
  /// In en, this message translates to:
  /// **'No email on file'**
  String get settingsNoEmailOnFile;

  /// No description provided for @settingsActiveSessions.
  ///
  /// In en, this message translates to:
  /// **'Active sessions'**
  String get settingsActiveSessions;

  /// No description provided for @settingsActiveSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage devices signed in to your account'**
  String get settingsActiveSessionsSubtitle;

  /// No description provided for @settingsRemoveAccount.
  ///
  /// In en, this message translates to:
  /// **'Remove account'**
  String get settingsRemoveAccount;

  /// No description provided for @settingsAddAccount.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get settingsAddAccount;

  /// No description provided for @settingsAddAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to another server or account'**
  String get settingsAddAccountSubtitle;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your Qutty account'**
  String get settingsDeleteAccountSubtitle;

  /// No description provided for @settingsVersionPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Placeholder#424738'**
  String get settingsVersionPlaceholder;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogOut;

  /// No description provided for @settingsPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get settingsPasswordUpdated;

  /// No description provided for @settingsEmailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Email updated'**
  String get settingsEmailUpdated;

  /// No description provided for @settingsLogOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogOutTitle;

  /// No description provided for @settingsLogOutBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to enter your password again to sign back in.'**
  String get settingsLogOutBody;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Type your username and password to permanently delete your account and all data.'**
  String get settingsDeleteAccountBody;

  /// No description provided for @settingsEditProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settingsEditProfileTooltip;

  /// No description provided for @settingsCalls.
  ///
  /// In en, this message translates to:
  /// **'Calls'**
  String get settingsCalls;

  /// No description provided for @settingsCallWebcam.
  ///
  /// In en, this message translates to:
  /// **'Webcam'**
  String get settingsCallWebcam;

  /// No description provided for @settingsCallWebcamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start calls with the webcam on'**
  String get settingsCallWebcamSubtitle;

  /// No description provided for @settingsCallCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get settingsCallCamera;

  /// No description provided for @settingsCallCameraFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get settingsCallCameraFront;

  /// No description provided for @settingsCallCameraBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get settingsCallCameraBack;

  /// No description provided for @settingsCallLoudspeaker.
  ///
  /// In en, this message translates to:
  /// **'Loudspeaker'**
  String get settingsCallLoudspeaker;

  /// No description provided for @settingsCallLoudspeakerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play call audio through the speaker'**
  String get settingsCallLoudspeakerSubtitle;

  /// No description provided for @settingsCallMic.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get settingsCallMic;

  /// No description provided for @settingsCallMicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start calls with the microphone on'**
  String get settingsCallMicSubtitle;

  /// No description provided for @settingsCallScreenShare.
  ///
  /// In en, this message translates to:
  /// **'Screencast'**
  String get settingsCallScreenShare;

  /// No description provided for @settingsCallScreenShareSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow sharing your screen during calls'**
  String get settingsCallScreenShareSubtitle;

  /// No description provided for @settingsAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get settingsAudio;

  /// No description provided for @settingsAudioInput.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get settingsAudioInput;

  /// No description provided for @settingsAudioOutput.
  ///
  /// In en, this message translates to:
  /// **'Speakers'**
  String get settingsAudioOutput;

  /// No description provided for @settingsAudioCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get settingsAudioCamera;

  /// No description provided for @settingsAudioSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsAudioSystemDefault;

  /// No description provided for @settingsAudioNoDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get settingsAudioNoDevices;

  /// No description provided for @settingsAudioNoiseReduction.
  ///
  /// In en, this message translates to:
  /// **'Noise reduction'**
  String get settingsAudioNoiseReduction;

  /// No description provided for @settingsAudioNoiseReductionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Suppress background noise during calls'**
  String get settingsAudioNoiseReductionSubtitle;

  /// No description provided for @settingsAudioMicVolume.
  ///
  /// In en, this message translates to:
  /// **'Microphone volume'**
  String get settingsAudioMicVolume;

  /// No description provided for @settingsAudioSpeakerVolume.
  ///
  /// In en, this message translates to:
  /// **'Speaker volume'**
  String get settingsAudioSpeakerVolume;

  /// No description provided for @cacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline cache'**
  String get cacheTitle;

  /// No description provided for @cacheTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep conversations and media on this device'**
  String get cacheTitleSubtitle;

  /// No description provided for @cacheOfflineSection.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get cacheOfflineSection;

  /// No description provided for @cacheStorageSection.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get cacheStorageSection;

  /// No description provided for @cacheContentsSection.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get cacheContentsSection;

  /// No description provided for @cacheClearSection.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get cacheClearSection;

  /// No description provided for @cacheMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get cacheMessagesLabel;

  /// No description provided for @cacheProfilesLabel.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get cacheProfilesLabel;

  /// No description provided for @cacheMediaToggle.
  ///
  /// In en, this message translates to:
  /// **'Cache media'**
  String get cacheMediaToggle;

  /// No description provided for @cacheMediaToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep pictures and attachments on the device'**
  String get cacheMediaToggleSubtitle;

  /// No description provided for @cacheChatsToggle.
  ///
  /// In en, this message translates to:
  /// **'Cache conversations'**
  String get cacheChatsToggle;

  /// No description provided for @cacheChatsToggleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep conversations, messages and profiles on the device'**
  String get cacheChatsToggleSubtitle;

  /// No description provided for @cacheMediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get cacheMediaLabel;

  /// No description provided for @cacheChatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get cacheChatsLabel;

  /// No description provided for @cacheTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get cacheTotalLabel;

  /// No description provided for @cacheMediaFiles.
  ///
  /// In en, this message translates to:
  /// **'{count} files'**
  String cacheMediaFiles(int count);

  /// No description provided for @cacheChatCount.
  ///
  /// In en, this message translates to:
  /// **'{count} conversations'**
  String cacheChatCount(int count);

  /// No description provided for @cacheMessageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} messages'**
  String cacheMessageCount(int count);

  /// No description provided for @cacheProfileCount.
  ///
  /// In en, this message translates to:
  /// **'{count} profiles'**
  String cacheProfileCount(int count);

  /// No description provided for @cacheLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Media limit'**
  String get cacheLimitLabel;

  /// No description provided for @cacheLimitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How much space media may take on this device'**
  String get cacheLimitSubtitle;

  /// No description provided for @cacheClearMedia.
  ///
  /// In en, this message translates to:
  /// **'Clear media cache'**
  String get cacheClearMedia;

  /// No description provided for @cacheClearChats.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation cache'**
  String get cacheClearChats;

  /// No description provided for @cacheClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all cache'**
  String get cacheClearAll;

  /// No description provided for @cacheClearMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear media cache?'**
  String get cacheClearMediaTitle;

  /// No description provided for @cacheClearMediaBody.
  ///
  /// In en, this message translates to:
  /// **'Pictures and attachments on this device will be downloaded again when they are needed.'**
  String get cacheClearMediaBody;

  /// No description provided for @cacheClearChatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear conversation cache?'**
  String get cacheClearChatsTitle;

  /// No description provided for @cacheClearChatsBody.
  ///
  /// In en, this message translates to:
  /// **'Saved conversations, messages and profiles will be removed from this device.'**
  String get cacheClearChatsBody;

  /// No description provided for @cacheClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all cache?'**
  String get cacheClearAllTitle;

  /// No description provided for @cacheClearAllBody.
  ///
  /// In en, this message translates to:
  /// **'Everything Qutty keeps on this device for offline use will be removed.'**
  String get cacheClearAllBody;

  /// No description provided for @cacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get cacheCleared;

  /// No description provided for @chatOfflineMessages.
  ///
  /// In en, this message translates to:
  /// **'Showing saved messages — you are offline'**
  String get chatOfflineMessages;

  /// No description provided for @screenSharePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what to share'**
  String get screenSharePickTitle;

  /// No description provided for @screenSharePickScreens.
  ///
  /// In en, this message translates to:
  /// **'Screens'**
  String get screenSharePickScreens;

  /// No description provided for @screenSharePickWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get screenSharePickWindows;

  /// No description provided for @screenSharePickEmpty.
  ///
  /// In en, this message translates to:
  /// **'No screens or windows found'**
  String get screenSharePickEmpty;

  /// No description provided for @screenSharePickError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load screens and windows'**
  String get screenSharePickError;

  /// No description provided for @screenSharePickRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get screenSharePickRetry;

  /// No description provided for @notificationsToggle.
  ///
  /// In en, this message translates to:
  /// **'Message notifications'**
  String get notificationsToggle;

  /// No description provided for @notificationsOffForDevice.
  ///
  /// In en, this message translates to:
  /// **'Off for this device'**
  String get notificationsOffForDevice;

  /// No description provided for @notificationsOpenWithBackground.
  ///
  /// In en, this message translates to:
  /// **'Alerts while the app is open and in the background'**
  String get notificationsOpenWithBackground;

  /// No description provided for @notificationsOpenOnly.
  ///
  /// In en, this message translates to:
  /// **'Alerts while the app is open'**
  String get notificationsOpenOnly;

  /// No description provided for @notificationsOpenBackgroundConnection.
  ///
  /// In en, this message translates to:
  /// **'Alerts while the app is open (background connection)'**
  String get notificationsOpenBackgroundConnection;

  /// No description provided for @notificationsPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications for Qutty in system settings to receive alerts in the background.'**
  String get notificationsPermissionHint;

  /// No description provided for @connectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Connection status'**
  String get connectionStatus;

  /// No description provided for @connectionLiveWebsocket.
  ///
  /// In en, this message translates to:
  /// **'Live websocket status'**
  String get connectionLiveWebsocket;

  /// No description provided for @connectionReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get connectionReconnect;

  /// No description provided for @connectionConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectionConnected;

  /// No description provided for @connectionConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connectionConnecting;

  /// No description provided for @connectionDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get connectionDisconnected;

  /// No description provided for @sessionsRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke {name}?'**
  String sessionsRevokeTitle(String name);

  /// No description provided for @sessionsRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'Other devices using this session will be signed out.'**
  String get sessionsRevokeBody;

  /// No description provided for @sessionsRevoked.
  ///
  /// In en, this message translates to:
  /// **'Session revoked'**
  String get sessionsRevoked;

  /// No description provided for @sessionsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load sessions'**
  String get sessionsLoadFailed;

  /// No description provided for @sessionsNone.
  ///
  /// In en, this message translates to:
  /// **'No active sessions'**
  String get sessionsNone;

  /// No description provided for @sessionsThisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get sessionsThisDevice;

  /// No description provided for @sessionsLastActive.
  ///
  /// In en, this message translates to:
  /// **'Last active {time}'**
  String sessionsLastActive(String time);

  /// No description provided for @sessionsCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get sessionsCurrentBadge;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageSubtitle;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @accentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColorLabel;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get themeLight;

  /// No description provided for @accentQuttyBlue.
  ///
  /// In en, this message translates to:
  /// **'Qutty Blue'**
  String get accentQuttyBlue;

  /// No description provided for @accentCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get accentCustom;

  /// No description provided for @customAccentColor.
  ///
  /// In en, this message translates to:
  /// **'Custom accent color'**
  String get customAccentColor;

  /// No description provided for @hexColor.
  ///
  /// In en, this message translates to:
  /// **'Hex color'**
  String get hexColor;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get roleRestricted;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @accountNewEmail.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get accountNewEmail;

  /// No description provided for @accountCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountCurrentPassword;

  /// No description provided for @accountConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get accountConfirmPassword;

  /// No description provided for @accountNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountNewPassword;

  /// No description provided for @chatSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat settings'**
  String get chatSettingsTitle;

  /// No description provided for @chatSettingsLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave chat?'**
  String get chatSettingsLeaveTitle;

  /// No description provided for @chatSettingsLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to this chat unless an admin invites you again.'**
  String get chatSettingsLeaveBody;

  /// No description provided for @chatSettingsLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get chatSettingsLeave;

  /// No description provided for @chatSettingsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String chatSettingsDeleteTitle(String name);

  /// No description provided for @chatSettingsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'All messages and members will be permanently removed. This cannot be undone.'**
  String get chatSettingsDeleteBody;

  /// No description provided for @chatSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load settings'**
  String get chatSettingsLoadFailed;

  /// No description provided for @chatSettingsProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get chatSettingsProfileSection;

  /// No description provided for @chatSettingsEditProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, handle, description and picture'**
  String get chatSettingsEditProfileSubtitle;

  /// No description provided for @chatSettingsCreateInvite.
  ///
  /// In en, this message translates to:
  /// **'Create invite link'**
  String get chatSettingsCreateInvite;

  /// No description provided for @chatSettingsCreateInviteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a shareable invite'**
  String get chatSettingsCreateInviteSubtitle;

  /// No description provided for @chatSettingsPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get chatSettingsPermissions;

  /// No description provided for @chatSettingsMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get chatSettingsMembers;

  /// No description provided for @chatSettingsMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View and manage participants'**
  String get chatSettingsMembersSubtitle;

  /// No description provided for @chatSettingsAccessControl.
  ///
  /// In en, this message translates to:
  /// **'Access control'**
  String get chatSettingsAccessControl;

  /// No description provided for @chatSettingsAccessControlSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Default permissions for members'**
  String get chatSettingsAccessControlSubtitle;

  /// No description provided for @chatSettingsDirectMessage.
  ///
  /// In en, this message translates to:
  /// **'Direct message'**
  String get chatSettingsDirectMessage;

  /// No description provided for @chatSettingsOpenContactProfile.
  ///
  /// In en, this message translates to:
  /// **'Open contact profile'**
  String get chatSettingsOpenContactProfile;

  /// No description provided for @chatSettingsDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get chatSettingsDangerZone;

  /// No description provided for @chatSettingsLeaveTile.
  ///
  /// In en, this message translates to:
  /// **'Leave chat'**
  String get chatSettingsLeaveTile;

  /// No description provided for @chatSettingsDeleteTile.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get chatSettingsDeleteTile;

  /// No description provided for @chatSettingsDeleteTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only the creator can delete this chat'**
  String get chatSettingsDeleteTileSubtitle;

  /// No description provided for @chatSettingsInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite link'**
  String get chatSettingsInviteTitle;

  /// No description provided for @chatSettingsInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Share this link with people you want to invite. It has been copied to your clipboard.'**
  String get chatSettingsInviteBody;

  /// No description provided for @chatSettingsInviteCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied'**
  String get chatSettingsInviteCopied;

  /// No description provided for @aclDefaultPermissions.
  ///
  /// In en, this message translates to:
  /// **'Default member permissions'**
  String get aclDefaultPermissions;

  /// No description provided for @aclDescription.
  ///
  /// In en, this message translates to:
  /// **'These permissions apply to regular members. Administrators always have management access.'**
  String get aclDescription;

  /// No description provided for @aclSavePermissions.
  ///
  /// In en, this message translates to:
  /// **'Save permissions'**
  String get aclSavePermissions;

  /// No description provided for @aclEditMessages.
  ///
  /// In en, this message translates to:
  /// **'Edit messages'**
  String get aclEditMessages;

  /// No description provided for @aclEditMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow members to edit messages.'**
  String get aclEditMessagesDescription;

  /// No description provided for @permissionWriteMessages.
  ///
  /// In en, this message translates to:
  /// **'Send messages'**
  String get permissionWriteMessages;

  /// No description provided for @permissionWriteMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow members to send new messages.'**
  String get permissionWriteMessagesDescription;

  /// No description provided for @permissionDeleteOthersMessages.
  ///
  /// In en, this message translates to:
  /// **'Delete other messages'**
  String get permissionDeleteOthersMessages;

  /// No description provided for @permissionDeleteOthersMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow members to remove messages from other people.'**
  String get permissionDeleteOthersMessagesDescription;

  /// No description provided for @permissionEditOthersMessages.
  ///
  /// In en, this message translates to:
  /// **'Edit other messages'**
  String get permissionEditOthersMessages;

  /// No description provided for @permissionEditOthersMessagesDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow members to edit messages from other people.'**
  String get permissionEditOthersMessagesDescription;

  /// No description provided for @permissionRestrictUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage members'**
  String get permissionRestrictUsers;

  /// No description provided for @permissionRestrictUsersDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow members to remove or restrict other members.'**
  String get permissionRestrictUsersDescription;

  /// No description provided for @permissionEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit chat profile'**
  String get permissionEditProfile;

  /// No description provided for @permissionEditProfileDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow members to update the chat name and description.'**
  String get permissionEditProfileDescription;

  /// No description provided for @permissionAddAdmins.
  ///
  /// In en, this message translates to:
  /// **'Manage administrators'**
  String get permissionAddAdmins;

  /// No description provided for @permissionAddAdminsDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow members to promote other members.'**
  String get permissionAddAdminsDescription;

  /// No description provided for @membersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersTitle;

  /// No description provided for @membersLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load members'**
  String get membersLoadFailed;

  /// No description provided for @membersYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get membersYou;

  /// No description provided for @membersMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get membersMore;

  /// No description provided for @membersViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get membersViewProfile;

  /// No description provided for @membersGiveChat.
  ///
  /// In en, this message translates to:
  /// **'Give {name} to this user'**
  String membersGiveChat(String name);

  /// No description provided for @membersManagePermissions.
  ///
  /// In en, this message translates to:
  /// **'Manage permissions'**
  String get membersManagePermissions;

  /// No description provided for @membersRemoveFromChat.
  ///
  /// In en, this message translates to:
  /// **'Remove from chat'**
  String get membersRemoveFromChat;

  /// No description provided for @membersRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String membersRemoveTitle(String name);

  /// No description provided for @membersRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'They will lose access to this chat immediately.'**
  String get membersRemoveBody;

  /// No description provided for @membersOwnershipGiven.
  ///
  /// In en, this message translates to:
  /// **'Chat ownership given to {name}'**
  String membersOwnershipGiven(String name);

  /// No description provided for @membersTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Target User Info'**
  String get membersTransferTitle;

  /// No description provided for @membersTransferAttention.
  ///
  /// In en, this message translates to:
  /// **'!ATTENTION!'**
  String get membersTransferAttention;

  /// No description provided for @membersTransferUsername.
  ///
  /// In en, this message translates to:
  /// **'USERNAME: {username}'**
  String membersTransferUsername(String username);

  /// No description provided for @membersTransferAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I acknowledge that I will lose ownership of {chat}, and {username} will get {chat}.'**
  String membersTransferAcknowledge(String chat, String username);

  /// No description provided for @membersEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get membersEnterPassword;

  /// No description provided for @membersGiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Give {chat} to {username}'**
  String membersGiveConfirm(String chat, String username);

  /// No description provided for @membersOwnerLocked.
  ///
  /// In en, this message translates to:
  /// **'The chat owner cannot be modified.'**
  String get membersOwnerLocked;

  /// No description provided for @createChatNewChannel.
  ///
  /// In en, this message translates to:
  /// **'New channel'**
  String get createChatNewChannel;

  /// No description provided for @createChatNewChat.
  ///
  /// In en, this message translates to:
  /// **'New chat'**
  String get createChatNewChat;

  /// No description provided for @createChatClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get createChatClose;

  /// No description provided for @createChatCreateChannel.
  ///
  /// In en, this message translates to:
  /// **'Create channel'**
  String get createChatCreateChannel;

  /// No description provided for @createChatCreateChat.
  ///
  /// In en, this message translates to:
  /// **'Create chat'**
  String get createChatCreateChat;

  /// No description provided for @createChatChooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose avatar'**
  String get createChatChooseAvatar;

  /// No description provided for @createChatDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get createChatDisplayName;

  /// No description provided for @createChatUsernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (optional)'**
  String get createChatUsernameOptional;

  /// No description provided for @createChatUsernameOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'You can leave this empty and add one later.'**
  String get createChatUsernameOptionalHelper;

  /// No description provided for @createChatNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required.'**
  String get createChatNameRequired;

  /// No description provided for @joinPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Join chat'**
  String get joinPreviewTitle;

  /// No description provided for @joinPreviewInvalidLink.
  ///
  /// In en, this message translates to:
  /// **'Invalid join link'**
  String get joinPreviewInvalidLink;

  /// No description provided for @joinPreviewJoining.
  ///
  /// In en, this message translates to:
  /// **'Joining...'**
  String get joinPreviewJoining;

  /// No description provided for @joinPreviewJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinPreviewJoin;

  /// No description provided for @editProfileChangeAvatar.
  ///
  /// In en, this message translates to:
  /// **'Change avatar'**
  String get editProfileChangeAvatar;

  /// No description provided for @editProfileRemoveAvatar.
  ///
  /// In en, this message translates to:
  /// **'Remove avatar'**
  String get editProfileRemoveAvatar;

  /// No description provided for @editProfileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get editProfileBio;

  /// No description provided for @editProfileNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Display name cannot be empty'**
  String get editProfileNameEmpty;

  /// No description provided for @editProfileHandleReserved.
  ///
  /// In en, this message translates to:
  /// **'Handle cannot be _, this exact handle reserved to reset handle'**
  String get editProfileHandleReserved;

  /// No description provided for @editChatChannelSettings.
  ///
  /// In en, this message translates to:
  /// **'Channel settings'**
  String get editChatChannelSettings;

  /// No description provided for @editChatTapForPicture.
  ///
  /// In en, this message translates to:
  /// **'Tap to change the chat picture'**
  String get editChatTapForPicture;

  /// No description provided for @editChatUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get editChatUpload;

  /// No description provided for @editChatReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get editChatReplace;

  /// No description provided for @editChatHandleHelper.
  ///
  /// In en, this message translates to:
  /// **'Used to share the chat via @handle'**
  String get editChatHandleHelper;

  /// No description provided for @profileUnableToOpen.
  ///
  /// In en, this message translates to:
  /// **'Unable to open'**
  String get profileUnableToOpen;

  /// No description provided for @profileError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String profileError(String error);

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @profileChatId.
  ///
  /// In en, this message translates to:
  /// **'Chat ID: {id}'**
  String profileChatId(int id);

  /// No description provided for @profileUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID: {id}'**
  String profileUserId(int id);

  /// No description provided for @profileTabMedia.
  ///
  /// In en, this message translates to:
  /// **'Media ({count})'**
  String profileTabMedia(int count);

  /// No description provided for @profileTabGifs.
  ///
  /// In en, this message translates to:
  /// **'Gifs ({count})'**
  String profileTabGifs(int count);

  /// No description provided for @profileTabLinks.
  ///
  /// In en, this message translates to:
  /// **'Links ({count})'**
  String profileTabLinks(int count);

  /// No description provided for @profileTabFiles.
  ///
  /// In en, this message translates to:
  /// **'Files ({count})'**
  String profileTabFiles(int count);

  /// No description provided for @profileNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media yet'**
  String get profileNoMedia;

  /// No description provided for @profileNoGifs.
  ///
  /// In en, this message translates to:
  /// **'No gifs yet'**
  String get profileNoGifs;

  /// No description provided for @profileNoLinks.
  ///
  /// In en, this message translates to:
  /// **'No links yet'**
  String get profileNoLinks;

  /// No description provided for @profileNoFiles.
  ///
  /// In en, this message translates to:
  /// **'No files yet'**
  String get profileNoFiles;

  /// No description provided for @aboutTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service & Privacy Policy'**
  String get aboutTerms;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get aboutLicenses;

  /// No description provided for @aboutBuild.
  ///
  /// In en, this message translates to:
  /// **'Build: {build}'**
  String aboutBuild(String build);

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'Qutty - RdProjects 2026 © All rights reserved\nVersion: {version}'**
  String aboutCopyright(String version);

  /// No description provided for @debugTitle.
  ///
  /// In en, this message translates to:
  /// **'Quttycaka'**
  String get debugTitle;

  /// No description provided for @debugWarning.
  ///
  /// In en, this message translates to:
  /// **'These settings are for development/debug purposes only. \nChanging them may cause unexpected behavior.\nContinue if you know what you are doing.\n - QuttyTeam at RdProjects'**
  String get debugWarning;

  /// No description provided for @debugSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deveelopment/Debug settings a.k.a Quttycaka'**
  String get debugSubtitle;

  /// No description provided for @debugApiEndpoint.
  ///
  /// In en, this message translates to:
  /// **'API endpoint'**
  String get debugApiEndpoint;

  /// No description provided for @debugDeveloperInfo.
  ///
  /// In en, this message translates to:
  /// **'Developer Info'**
  String get debugDeveloperInfo;

  /// No description provided for @debugDeveloperInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show IDs for profiles and messages'**
  String get debugDeveloperInfoSubtitle;

  /// No description provided for @debugFallbackSelectorCast.
  ///
  /// In en, this message translates to:
  /// **'FallBackSelectorCast'**
  String get debugFallbackSelectorCast;

  /// No description provided for @debugFallbackSelectorCastSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always use the app\'s own screen picker instead of the system one'**
  String get debugFallbackSelectorCastSubtitle;

  /// No description provided for @debugKeepWebsocketAlive.
  ///
  /// In en, this message translates to:
  /// **'Keep websocket alive in background'**
  String get debugKeepWebsocketAlive;

  /// No description provided for @debugKeepWebsocketAliveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep the websocket connected while the app is backgrounded'**
  String get debugKeepWebsocketAliveSubtitle;

  /// No description provided for @debugBackgroundAllowTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow background without limits?'**
  String get debugBackgroundAllowTitle;

  /// No description provided for @debugBackgroundAllowMessage.
  ///
  /// In en, this message translates to:
  /// **'This lets the app keep the websocket open while it is not in the foreground. On Android it asks for permission to run in the background without limits. Continue?'**
  String get debugBackgroundAllowMessage;

  /// No description provided for @debugForceGroupCall.
  ///
  /// In en, this message translates to:
  /// **'Force group call layout'**
  String get debugForceGroupCall;

  /// No description provided for @debugForceGroupCallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the group call layout even in direct calls'**
  String get debugForceGroupCallSubtitle;

  /// No description provided for @debugJumpTo.
  ///
  /// In en, this message translates to:
  /// **'Jump to'**
  String get debugJumpTo;

  /// No description provided for @debugJumpToSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a page by URL or route path'**
  String get debugJumpToSubtitle;

  /// No description provided for @debugJumpToTitle.
  ///
  /// In en, this message translates to:
  /// **'Jump to page'**
  String get debugJumpToTitle;

  /// No description provided for @debugPageUrlOrRoute.
  ///
  /// In en, this message translates to:
  /// **'Page URL or route'**
  String get debugPageUrlOrRoute;

  /// No description provided for @debugBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get debugBaseUrl;

  /// No description provided for @debugApiEndpointUpdated.
  ///
  /// In en, this message translates to:
  /// **'API endpoint updated'**
  String get debugApiEndpointUpdated;

  /// No description provided for @debugTransport.
  ///
  /// In en, this message translates to:
  /// **'Notification transport'**
  String get debugTransport;

  /// No description provided for @debugTransportNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get debugTransportNotSelected;

  /// No description provided for @debugTransportUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available in this build'**
  String get debugTransportUnavailable;

  /// No description provided for @debugTransportNowUsing.
  ///
  /// In en, this message translates to:
  /// **'Notifications now use {label}'**
  String debugTransportNowUsing(String label);

  /// No description provided for @transportApns.
  ///
  /// In en, this message translates to:
  /// **'Apple Push Notification service'**
  String get transportApns;

  /// No description provided for @transportFcm.
  ///
  /// In en, this message translates to:
  /// **'Firebase Cloud Messaging'**
  String get transportFcm;

  /// No description provided for @transportWebsocket.
  ///
  /// In en, this message translates to:
  /// **'Background connection to your server'**
  String get transportWebsocket;

  /// No description provided for @errorShowDetails.
  ///
  /// In en, this message translates to:
  /// **'Show API error details'**
  String get errorShowDetails;

  /// No description provided for @errorHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'HTTP {code}'**
  String errorHttpStatus(int code);

  /// No description provided for @notificationChannelMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get notificationChannelMessages;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'New messages and alerts'**
  String get notificationChannelDescription;

  /// No description provided for @notificationSentAttachment.
  ///
  /// In en, this message translates to:
  /// **'Sent an attachment'**
  String get notificationSentAttachment;

  /// No description provided for @notificationNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message'**
  String get notificationNewMessage;

  /// No description provided for @unnamedChat.
  ///
  /// In en, this message translates to:
  /// **'Unnamed chat'**
  String get unnamedChat;

  /// No description provided for @unnamedSession.
  ///
  /// In en, this message translates to:
  /// **'Unnamed session'**
  String get unnamedSession;

  /// No description provided for @tokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Token missing'**
  String get tokenMissing;

  /// No description provided for @avatarFormatError.
  ///
  /// In en, this message translates to:
  /// **'Avatar must be a JPEG, JPG, or PNG image'**
  String get avatarFormatError;

  /// No description provided for @unableToReadImage.
  ///
  /// In en, this message translates to:
  /// **'Unable to read image'**
  String get unableToReadImage;

  /// No description provided for @avatarUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Avatar upload failed'**
  String get avatarUploadFailed;

  /// No description provided for @unableToReadFile.
  ///
  /// In en, this message translates to:
  /// **'Unable to read file'**
  String get unableToReadFile;

  /// No description provided for @fileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'File upload failed'**
  String get fileUploadFailed;

  /// No description provided for @requestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed'**
  String get requestFailed;

  /// No description provided for @settingsFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsFont;

  /// No description provided for @fontSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get fontSystemDefault;

  /// No description provided for @fontDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get fontDownload;

  /// No description provided for @fontDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get fontDownloading;

  /// No description provided for @fontChooseFromFile.
  ///
  /// In en, this message translates to:
  /// **'Choose from file'**
  String get fontChooseFromFile;

  /// No description provided for @fontDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download that font'**
  String get fontDownloadFailed;

  /// No description provided for @fontFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a font'**
  String get fontFileUnreadable;

  /// No description provided for @fontSample.
  ///
  /// In en, this message translates to:
  /// **'The quick brown fox jumps over the lazy dog'**
  String get fontSample;

  /// No description provided for @fontSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App typeface'**
  String get fontSubtitle;

  /// No description provided for @fontNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Font not loaded'**
  String get fontNotLoaded;

  /// fontDelete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get fontDelete;

  /// fontSource
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get fontSource;

  /// fontDownloadTitle
  ///
  /// In en, this message translates to:
  /// **'Download {font}?'**
  String fontDownloadTitle(String font);

  /// fontDownloadBody
  ///
  /// In en, this message translates to:
  /// **'The font is fetched from {url} and stored on this device.'**
  String fontDownloadBody(String url);

  /// fontDeleteTitle
  ///
  /// In en, this message translates to:
  /// **'Delete {font}?'**
  String fontDeleteTitle(String font);

  /// fontDeleteBody
  ///
  /// In en, this message translates to:
  /// **'It is removed from this device. You can download it again from {url}.'**
  String fontDeleteBody(String url);

  /// fontDownloadingLabel
  ///
  /// In en, this message translates to:
  /// **'Downloading {font}…'**
  String fontDownloadingLabel(String font);

  /// fontDeleteFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete that font'**
  String get fontDeleteFailed;

  /// fontSourceFailed
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open that link'**
  String get fontSourceFailed;

  /// No description provided for @developerPortal.
  ///
  /// In en, this message translates to:
  /// **'Developer portal'**
  String get developerPortal;

  /// No description provided for @developerPortalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tools for developers on Qutty'**
  String get developerPortalSubtitle;

  /// No description provided for @botsPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get botsPortalTitle;

  /// No description provided for @botsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bots'**
  String get botsTitle;

  /// No description provided for @botsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage your own bots'**
  String get botsSubtitle;

  /// No description provided for @botsCreate.
  ///
  /// In en, this message translates to:
  /// **'New bot'**
  String get botsCreate;

  /// No description provided for @botsCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create bot'**
  String get botsCreateAction;

  /// No description provided for @botsNoBots.
  ///
  /// In en, this message translates to:
  /// **'No bots yet. Create one to get started.'**
  String get botsNoBots;

  /// No description provided for @botsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load bots'**
  String get botsLoadFailed;

  /// No description provided for @botsCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create it'**
  String get botsCreateFailed;

  /// No description provided for @botsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Bot updated'**
  String get botsUpdated;

  /// No description provided for @botsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get botsDeleted;

  /// No description provided for @botsCreated.
  ///
  /// In en, this message translates to:
  /// **'Bot created'**
  String get botsCreated;

  /// No description provided for @botsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete bot?'**
  String get botsDeleteTitle;

  /// No description provided for @botsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"? The bot and its token will be gone.'**
  String botsDeleteBody(String name);

  /// No description provided for @botsResetTokenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset token'**
  String get botsResetTokenTooltip;

  /// No description provided for @botsResetTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset bot token?'**
  String get botsResetTokenTitle;

  /// No description provided for @botsResetTokenBody.
  ///
  /// In en, this message translates to:
  /// **'The current token will stop working immediately. The new token is shown once, so copy it now.'**
  String get botsResetTokenBody;

  /// No description provided for @botsResetTokenAction.
  ///
  /// In en, this message translates to:
  /// **'Reset token'**
  String get botsResetTokenAction;

  /// No description provided for @botsTokenTitle.
  ///
  /// In en, this message translates to:
  /// **'Bot token'**
  String get botsTokenTitle;

  /// No description provided for @botsTokenCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get botsTokenCopy;

  /// No description provided for @botsTokenCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get botsTokenCopied;

  /// No description provided for @botsTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'Token missing'**
  String get botsTokenMissing;

  /// No description provided for @botsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the bot'**
  String get botsActionFailed;

  /// No description provided for @ugcTitle.
  ///
  /// In en, this message translates to:
  /// **'Stickers and Emojis'**
  String get ugcTitle;

  /// No description provided for @ugcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create and manage your own stickers and emoji'**
  String get ugcSubtitle;

  /// No description provided for @ugcPortalTitle.
  ///
  /// In en, this message translates to:
  /// **'Stickers and Emojis'**
  String get ugcPortalTitle;

  /// No description provided for @ugcCreatePack.
  ///
  /// In en, this message translates to:
  /// **'New pack'**
  String get ugcCreatePack;

  /// No description provided for @ugcCreatePackAction.
  ///
  /// In en, this message translates to:
  /// **'Create pack'**
  String get ugcCreatePackAction;

  /// No description provided for @ugcPackNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Pack name is required.'**
  String get ugcPackNameRequired;

  /// No description provided for @ugcNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A name is required.'**
  String get ugcNameRequired;

  /// No description provided for @ugcItemImageRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose an image first.'**
  String get ugcItemImageRequired;

  /// No description provided for @ugcChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get ugcChooseImage;

  /// No description provided for @ugcPackName.
  ///
  /// In en, this message translates to:
  /// **'Pack name'**
  String get ugcPackName;

  /// No description provided for @ugcAddItem.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get ugcAddItem;

  /// No description provided for @ugcItemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get ugcItemsTitle;

  /// No description provided for @ugcFavoritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get ugcFavoritesTitle;

  /// No description provided for @ugcNoPacks.
  ///
  /// In en, this message translates to:
  /// **'No packs yet. Create one to add stickers and emoji.'**
  String get ugcNoPacks;

  /// No description provided for @ugcNoItems.
  ///
  /// In en, this message translates to:
  /// **'This pack has no items yet.'**
  String get ugcNoItems;

  /// No description provided for @ugcNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet.'**
  String get ugcNoFavorites;

  /// No description provided for @ugcDeletePackTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete pack?'**
  String get ugcDeletePackTitle;

  /// ugcDeletePackBody
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all of its items?'**
  String ugcDeletePackBody(String name);

  /// No description provided for @ugcDeleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete item?'**
  String get ugcDeleteItemTitle;

  /// ugcDeleteItemBody
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String ugcDeleteItemBody(String name);

  /// No description provided for @ugcCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get ugcCreated;

  /// No description provided for @ugcDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get ugcDeleted;

  /// No description provided for @ugcCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create it'**
  String get ugcCreateFailed;

  /// No description provided for @ugcPickerAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ugcPickerAll;

  /// No description provided for @ugcPickerFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get ugcPickerFavorites;

  /// No description provided for @ugcPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No stickers yet. Create some in the Developer portal.'**
  String get ugcPickerEmpty;

  /// No description provided for @ugcPickerNoPacks.
  ///
  /// In en, this message translates to:
  /// **'No saved packs yet. Save a pack to see its stickers here.'**
  String get ugcPickerNoPacks;

  /// No description provided for @ugcPickerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load stickers'**
  String get ugcPickerLoadFailed;

  /// No description provided for @ugcPickerManage.
  ///
  /// In en, this message translates to:
  /// **'Manage in Developer portal'**
  String get ugcPickerManage;

  /// No description provided for @ugcPickerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved to favorites'**
  String get ugcPickerSaved;

  /// No description provided for @ugcPickerRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get ugcPickerRemoved;

  /// No description provided for @ugcStickerInsert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get ugcStickerInsert;

  /// No description provided for @ugcSavePack.
  ///
  /// In en, this message translates to:
  /// **'Save pack'**
  String get ugcSavePack;

  /// No description provided for @ugcUnsavePack.
  ///
  /// In en, this message translates to:
  /// **'Remove saved pack'**
  String get ugcUnsavePack;

  /// No description provided for @ugcSharePack.
  ///
  /// In en, this message translates to:
  /// **'Share pack'**
  String get ugcSharePack;

  /// No description provided for @ugcLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get ugcLinkCopied;

  /// No description provided for @ugcPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Sticker pack'**
  String get ugcPackTitle;

  /// No description provided for @ugcPackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This sticker pack is not available.'**
  String get ugcPackUnavailable;

  /// No description provided for @ugcStickerPreview.
  ///
  /// In en, this message translates to:
  /// **'Sticker'**
  String get ugcStickerPreview;

  /// No description provided for @debugPushServer.
  ///
  /// In en, this message translates to:
  /// **'Push server'**
  String get debugPushServer;

  /// No description provided for @debugPushProvider.
  ///
  /// In en, this message translates to:
  /// **'Push provider'**
  String get debugPushProvider;

  /// No description provided for @debugPushRegistrationStatus.
  ///
  /// In en, this message translates to:
  /// **'Push registration status'**
  String get debugPushRegistrationStatus;

  /// No description provided for @debugPushNotRegistered.
  ///
  /// In en, this message translates to:
  /// **'Not registered'**
  String get debugPushNotRegistered;

  /// No description provided for @debugPushRegisteredId.
  ///
  /// In en, this message translates to:
  /// **'Registered (id: {id})'**
  String debugPushRegisteredId(String id);

  /// No description provided for @debugUnregisterPush.
  ///
  /// In en, this message translates to:
  /// **'Unregister push'**
  String get debugUnregisterPush;

  /// No description provided for @debugUnregisterPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manually unregister this device'**
  String get debugUnregisterPushSubtitle;

  /// No description provided for @debugPushUnregistered.
  ///
  /// In en, this message translates to:
  /// **'Push unregistered'**
  String get debugPushUnregistered;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ru',
    'uk',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

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
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OBS Pad'**
  String get appTitle;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Technical details'**
  String get details;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @navPad.
  ///
  /// In en, this message translates to:
  /// **'Buttons'**
  String get navPad;

  /// No description provided for @navMixer.
  ///
  /// In en, this message translates to:
  /// **'Mixer'**
  String get navMixer;

  /// No description provided for @navSounds.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get navSounds;

  /// No description provided for @navMetrics.
  ///
  /// In en, this message translates to:
  /// **'Metrics'**
  String get navMetrics;

  /// No description provided for @menuProfiles.
  ///
  /// In en, this message translates to:
  /// **'Saved computers'**
  String get menuProfiles;

  /// No description provided for @menuRemote.
  ///
  /// In en, this message translates to:
  /// **'Access from outside home'**
  String get menuRemote;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuGuide.
  ///
  /// In en, this message translates to:
  /// **'Setup guide'**
  String get menuGuide;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @onbStep1Title.
  ///
  /// In en, this message translates to:
  /// **'Open OBS on your computer'**
  String get onbStep1Title;

  /// No description provided for @onbStep1Body.
  ///
  /// In en, this message translates to:
  /// **'Use OBS Studio version 28 or newer. It already includes everything OBS Pad needs — nothing else to install on the PC.'**
  String get onbStep1Body;

  /// No description provided for @onbStep1Hint.
  ///
  /// In en, this message translates to:
  /// **'Not sure about the version? In OBS, click Help > About.'**
  String get onbStep1Hint;

  /// No description provided for @onbStep2Title.
  ///
  /// In en, this message translates to:
  /// **'Turn on OBS remote control'**
  String get onbStep2Title;

  /// No description provided for @onbStep2a.
  ///
  /// In en, this message translates to:
  /// **'In OBS, click the Tools menu'**
  String get onbStep2a;

  /// No description provided for @onbStep2b.
  ///
  /// In en, this message translates to:
  /// **'Choose WebSocket Server Settings'**
  String get onbStep2b;

  /// No description provided for @onbStep2c.
  ///
  /// In en, this message translates to:
  /// **'Check \"Enable WebSocket server\"'**
  String get onbStep2c;

  /// No description provided for @onbStep2d.
  ///
  /// In en, this message translates to:
  /// **'Check \"Enable Authentication\" and create a password'**
  String get onbStep2d;

  /// No description provided for @onbStep2e.
  ///
  /// In en, this message translates to:
  /// **'Keep port 4455 and click OK'**
  String get onbStep2e;

  /// No description provided for @onbStep2Hint.
  ///
  /// In en, this message translates to:
  /// **'Tip: the \"Show Connect Info\" button shows the PC IP and the password.'**
  String get onbStep2Hint;

  /// No description provided for @onbStep3Title.
  ///
  /// In en, this message translates to:
  /// **'Same Wi-Fi network'**
  String get onbStep3Title;

  /// No description provided for @onbStep3Body.
  ///
  /// In en, this message translates to:
  /// **'Your PC and your phone must be on the same Wi-Fi network (the same router). Mobile data will not work here.'**
  String get onbStep3Body;

  /// No description provided for @onbFindIp.
  ///
  /// In en, this message translates to:
  /// **'How to find the PC IP address'**
  String get onbFindIp;

  /// No description provided for @onbIpWindows.
  ///
  /// In en, this message translates to:
  /// **'Windows: press Windows + R, type cmd and press Enter. In the black window type ipconfig and press Enter. Look for \"IPv4 Address\" (e.g. 192.168.0.15).'**
  String get onbIpWindows;

  /// No description provided for @onbIpMac.
  ///
  /// In en, this message translates to:
  /// **'Mac: open System Settings > Network, click your Wi-Fi connection and look for \"IP Address\".'**
  String get onbIpMac;

  /// No description provided for @onbIpLinux.
  ///
  /// In en, this message translates to:
  /// **'Linux: open a terminal and run hostname -I.'**
  String get onbIpLinux;

  /// No description provided for @onbStep4Title.
  ///
  /// In en, this message translates to:
  /// **'Test the connection'**
  String get onbStep4Title;

  /// No description provided for @onbStep4Body.
  ///
  /// In en, this message translates to:
  /// **'Type the details you saw in OBS and tap the button.'**
  String get onbStep4Body;

  /// No description provided for @fieldProfileName.
  ///
  /// In en, this message translates to:
  /// **'Name for this computer'**
  String get fieldProfileName;

  /// No description provided for @defaultProfileName.
  ///
  /// In en, this message translates to:
  /// **'My PC'**
  String get defaultProfileName;

  /// No description provided for @fieldHost.
  ///
  /// In en, this message translates to:
  /// **'Computer IP'**
  String get fieldHost;

  /// No description provided for @fieldHostHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 192.168.0.15'**
  String get fieldHostHint;

  /// No description provided for @fieldPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get fieldPort;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'WebSocket password'**
  String get fieldPassword;

  /// No description provided for @fieldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if you did not enable authentication'**
  String get fieldPasswordHint;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing…'**
  String get testing;

  /// No description provided for @testSuccess.
  ///
  /// In en, this message translates to:
  /// **'All set! Connected to OBS {version}.'**
  String testSuccess(String version);

  /// No description provided for @testOldObs.
  ///
  /// In en, this message translates to:
  /// **'OBS {version} is old. Some features may not work; update to 28 or newer.'**
  String testOldObs(String version);

  /// No description provided for @onbSoundTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip about sounds'**
  String get onbSoundTipTitle;

  /// No description provided for @onbSoundTip.
  ///
  /// In en, this message translates to:
  /// **'A sound only reaches the live if its source is in the scene that is on air. When adding sounds with OBS Pad, keep \"Add to every scene\" checked — or put your sounds in one scene and add that scene as a source in the others.'**
  String get onbSoundTip;

  /// No description provided for @errHostEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type the computer IP'**
  String get errHostEmpty;

  /// No description provided for @errHostScheme.
  ///
  /// In en, this message translates to:
  /// **'Type only the IP, without ws://'**
  String get errHostScheme;

  /// No description provided for @errHostPort.
  ///
  /// In en, this message translates to:
  /// **'Put the port in the Port field, not next to the IP'**
  String get errHostPort;

  /// No description provided for @errHostInvalid.
  ///
  /// In en, this message translates to:
  /// **'This IP does not look right. Example: 192.168.0.15'**
  String get errHostInvalid;

  /// No description provided for @errPort.
  ///
  /// In en, this message translates to:
  /// **'Invalid port (usually 4455)'**
  String get errPort;

  /// No description provided for @errNameEmpty.
  ///
  /// In en, this message translates to:
  /// **'Give it a name'**
  String get errNameEmpty;

  /// No description provided for @failWrongPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get failWrongPasswordTitle;

  /// No description provided for @failWrongPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'The password does not match the one in OBS. Check it in Tools > WebSocket Server Settings > Show Connect Info.'**
  String get failWrongPasswordHint;

  /// No description provided for @failServerOffTitle.
  ///
  /// In en, this message translates to:
  /// **'OBS did not answer'**
  String get failServerOffTitle;

  /// No description provided for @failServerOffHint.
  ///
  /// In en, this message translates to:
  /// **'The computer was found, but the WebSocket server seems off. Open OBS and check that \"Enable WebSocket server\" is on and the port is 4455.'**
  String get failServerOffHint;

  /// No description provided for @failTimeoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the computer'**
  String get failTimeoutTitle;

  /// No description provided for @failTimeoutHint.
  ///
  /// In en, this message translates to:
  /// **'Check that the IP is right and both are on the same Wi-Fi. On Windows, the Firewall may be blocking port 4455.'**
  String get failTimeoutHint;

  /// No description provided for @failUnreachableTitle.
  ///
  /// In en, this message translates to:
  /// **'Different network'**
  String get failUnreachableTitle;

  /// No description provided for @failUnreachableHint.
  ///
  /// In en, this message translates to:
  /// **'The phone cannot see this address. Make sure it is on the same Wi-Fi as the PC (not on mobile data).'**
  String get failUnreachableHint;

  /// No description provided for @failInvalidAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid address'**
  String get failInvalidAddressTitle;

  /// No description provided for @failInvalidAddressHint.
  ///
  /// In en, this message translates to:
  /// **'I could not find this address. Type the IP like 192.168.0.15.'**
  String get failInvalidAddressHint;

  /// No description provided for @failNotObsTitle.
  ///
  /// In en, this message translates to:
  /// **'This does not look like OBS'**
  String get failNotObsTitle;

  /// No description provided for @failNotObsHint.
  ///
  /// In en, this message translates to:
  /// **'Something answered on this port, but it is not OBS WebSocket. Check the port (default 4455).'**
  String get failNotObsHint;

  /// No description provided for @failUnsupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'OBS is too old'**
  String get failUnsupportedTitle;

  /// No description provided for @failUnsupportedHint.
  ///
  /// In en, this message translates to:
  /// **'Update to OBS 28 or newer.'**
  String get failUnsupportedHint;

  /// No description provided for @failNotConnectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not connected to OBS'**
  String get failNotConnectedTitle;

  /// No description provided for @failNotConnectedHint.
  ///
  /// In en, this message translates to:
  /// **'Wait for it to reconnect or tap Try now.'**
  String get failNotConnectedHint;

  /// No description provided for @failNotFoundNamed.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" was not found in OBS'**
  String failNotFoundNamed(String name);

  /// No description provided for @failNotFound.
  ///
  /// In en, this message translates to:
  /// **'Item not found in OBS'**
  String get failNotFound;

  /// No description provided for @failNotFoundHint.
  ///
  /// In en, this message translates to:
  /// **'It may have been renamed or deleted in OBS. Edit the button and pick it again.'**
  String get failNotFoundHint;

  /// No description provided for @failAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Something with this name already exists in OBS.'**
  String get failAlreadyExists;

  /// No description provided for @failOutputActive.
  ///
  /// In en, this message translates to:
  /// **'It is already running.'**
  String get failOutputActive;

  /// No description provided for @failOutputNotActive.
  ///
  /// In en, this message translates to:
  /// **'It is not running.'**
  String get failOutputNotActive;

  /// No description provided for @failOutputDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature turned off in OBS'**
  String get failOutputDisabledTitle;

  /// No description provided for @failOutputDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Turn it on in OBS Settings > Output (e.g. Replay Buffer).'**
  String get failOutputDisabledHint;

  /// No description provided for @failInvalidStateNamed.
  ///
  /// In en, this message translates to:
  /// **'OBS cannot do this with \"{name}\" right now.'**
  String failInvalidStateNamed(String name);

  /// No description provided for @failInvalidState.
  ///
  /// In en, this message translates to:
  /// **'OBS cannot do this right now.'**
  String get failInvalidState;

  /// No description provided for @failInvalidInputKind.
  ///
  /// In en, this message translates to:
  /// **'Your OBS does not have this kind of source.'**
  String get failInvalidInputKind;

  /// No description provided for @failRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'OBS could not do this.'**
  String get failRequestFailed;

  /// No description provided for @failUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get failUnknown;

  /// No description provided for @firewallHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'How to allow OBS in the Windows Firewall'**
  String get firewallHelpTitle;

  /// No description provided for @firewallHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Open Start and search for \"Allow an app through Windows Firewall\". Click \"Change settings\", find \"OBS Studio\" and check \"Private\". If it is not listed, click \"Allow another app\" and choose obs64.exe. Also make sure your Wi-Fi is set as a Private network.'**
  String get firewallHelpBody;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to OBS…'**
  String get statusConnecting;

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Connection lost. Trying again in {seconds}s (attempt {attempt})'**
  String statusReconnecting(int seconds, int attempt);

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect: {reason}'**
  String statusFailed(String reason);

  /// No description provided for @statusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected to OBS'**
  String get statusDisconnected;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @tryNow.
  ///
  /// In en, this message translates to:
  /// **'Try now'**
  String get tryNow;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @profilesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved computers'**
  String get profilesTitle;

  /// No description provided for @profilesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No computer saved yet.'**
  String get profilesEmpty;

  /// No description provided for @addProfile.
  ///
  /// In en, this message translates to:
  /// **'Add computer'**
  String get addProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit computer'**
  String get editProfile;

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteProfileConfirm(String name);

  /// No description provided for @profileInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get profileInUse;

  /// No description provided for @saveWithoutTest.
  ///
  /// In en, this message translates to:
  /// **'Save without testing'**
  String get saveWithoutTest;

  /// No description provided for @testAndSave.
  ///
  /// In en, this message translates to:
  /// **'Test and save'**
  String get testAndSave;

  /// No description provided for @scenesTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenes'**
  String get scenesTitle;

  /// No description provided for @scenesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scenes found in OBS.'**
  String get scenesEmpty;

  /// No description provided for @onAir.
  ///
  /// In en, this message translates to:
  /// **'On air'**
  String get onAir;

  /// No description provided for @sceneSwitched.
  ///
  /// In en, this message translates to:
  /// **'Scene: {name}'**
  String sceneSwitched(String name);

  /// No description provided for @remoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Access from outside home'**
  String get remoteTitle;

  /// No description provided for @remoteIntro.
  ///
  /// In en, this message translates to:
  /// **'Want to control OBS when your phone is not on the same Wi-Fi (e.g. on 4G)? Use a free private network app (VPN) like Tailscale or NetBird. It connects your phone and PC safely, as if they were at home.'**
  String get remoteIntro;

  /// No description provided for @remoteWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Never open port 4455 on your router'**
  String get remoteWarningTitle;

  /// No description provided for @remoteWarning.
  ///
  /// In en, this message translates to:
  /// **'Do NOT use \"port forwarding\" to expose port 4455 to the internet. Anyone could try to guess your password and take control of your OBS and your live.'**
  String get remoteWarning;

  /// No description provided for @remoteOptionTailscale.
  ///
  /// In en, this message translates to:
  /// **'Option 1: Tailscale'**
  String get remoteOptionTailscale;

  /// No description provided for @remoteOptionNetbird.
  ///
  /// In en, this message translates to:
  /// **'Option 2: NetBird'**
  String get remoteOptionNetbird;

  /// No description provided for @remoteStep1.
  ///
  /// In en, this message translates to:
  /// **'Create a free account at {site}'**
  String remoteStep1(String site);

  /// No description provided for @remoteStep2.
  ///
  /// In en, this message translates to:
  /// **'Install {app} on the PC (where OBS is) and sign in'**
  String remoteStep2(String app);

  /// No description provided for @remoteStep3.
  ///
  /// In en, this message translates to:
  /// **'Install the {app} app on your phone and sign in with the same account'**
  String remoteStep3(String app);

  /// No description provided for @remoteStep4.
  ///
  /// In en, this message translates to:
  /// **'On the PC, open {app} and copy its IP (it starts with 100.)'**
  String remoteStep4(String app);

  /// No description provided for @remoteStep5.
  ///
  /// In en, this message translates to:
  /// **'In OBS Pad, add a new computer using that 100.x.x.x IP, with the same port and password'**
  String get remoteStep5;

  /// No description provided for @remoteFootnote.
  ///
  /// In en, this message translates to:
  /// **'Keep the VPN turned on in both the PC and the phone while you use it.'**
  String get remoteFootnote;

  /// No description provided for @remoteAddProfile.
  ///
  /// In en, this message translates to:
  /// **'Add computer with VPN IP'**
  String get remoteAddProfile;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Same as phone'**
  String get languageSystem;

  /// No description provided for @settingsKeepScreenOn.
  ///
  /// In en, this message translates to:
  /// **'Keep screen on'**
  String get settingsKeepScreenOn;

  /// No description provided for @settingsKeepScreenOnHint.
  ///
  /// In en, this message translates to:
  /// **'The phone screen will not turn off while OBS Pad is open. If the screen turns off or you switch apps, the phone cuts the connection to OBS: running macros and alerts stop until you come back.'**
  String get settingsKeepScreenOnHint;

  /// No description provided for @settingsHaptics.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on touch'**
  String get settingsHaptics;

  /// No description provided for @settingsGuide.
  ///
  /// In en, this message translates to:
  /// **'See the setup guide again'**
  String get settingsGuide;

  /// No description provided for @obsMockTitle.
  ///
  /// In en, this message translates to:
  /// **'WebSocket Server Settings'**
  String get obsMockTitle;

  /// No description provided for @obsMockEnableServer.
  ///
  /// In en, this message translates to:
  /// **'Enable WebSocket server'**
  String get obsMockEnableServer;

  /// No description provided for @obsMockEnableAuth.
  ///
  /// In en, this message translates to:
  /// **'Enable Authentication'**
  String get obsMockEnableAuth;

  /// No description provided for @obsMockPort.
  ///
  /// In en, this message translates to:
  /// **'Server Port'**
  String get obsMockPort;

  /// No description provided for @actionSwitchScene.
  ///
  /// In en, this message translates to:
  /// **'Switch scene'**
  String get actionSwitchScene;

  /// No description provided for @actionToggleSource.
  ///
  /// In en, this message translates to:
  /// **'Show/hide a source'**
  String get actionToggleSource;

  /// No description provided for @actionToggleMute.
  ///
  /// In en, this message translates to:
  /// **'Mute/unmute audio'**
  String get actionToggleMute;

  /// No description provided for @actionToggleStream.
  ///
  /// In en, this message translates to:
  /// **'Start/stop live'**
  String get actionToggleStream;

  /// No description provided for @actionStartStream.
  ///
  /// In en, this message translates to:
  /// **'Start live'**
  String get actionStartStream;

  /// No description provided for @actionStopStream.
  ///
  /// In en, this message translates to:
  /// **'Stop live'**
  String get actionStopStream;

  /// No description provided for @actionToggleRecord.
  ///
  /// In en, this message translates to:
  /// **'Start/stop recording'**
  String get actionToggleRecord;

  /// No description provided for @actionStartRecord.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get actionStartRecord;

  /// No description provided for @actionStopRecord.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get actionStopRecord;

  /// No description provided for @actionToggleRecordPause.
  ///
  /// In en, this message translates to:
  /// **'Pause/resume recording'**
  String get actionToggleRecordPause;

  /// No description provided for @actionSaveReplay.
  ///
  /// In en, this message translates to:
  /// **'Save replay'**
  String get actionSaveReplay;

  /// No description provided for @actionHotkey.
  ///
  /// In en, this message translates to:
  /// **'OBS hotkey'**
  String get actionHotkey;

  /// No description provided for @actionMacro.
  ///
  /// In en, this message translates to:
  /// **'Macro (several actions)'**
  String get actionMacro;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add button'**
  String get addButton;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit button'**
  String get editButton;

  /// No description provided for @editButtons.
  ///
  /// In en, this message translates to:
  /// **'Edit buttons'**
  String get editButtons;

  /// No description provided for @doneEditing.
  ///
  /// In en, this message translates to:
  /// **'Done editing'**
  String get doneEditing;

  /// No description provided for @editModeHint.
  ///
  /// In en, this message translates to:
  /// **'Hold and drag to reorder. Tap to edit.'**
  String get editModeHint;

  /// No description provided for @columns.
  ///
  /// In en, this message translates to:
  /// **'Columns'**
  String get columns;

  /// No description provided for @padEmpty.
  ///
  /// In en, this message translates to:
  /// **'No buttons in this layout yet.'**
  String get padEmpty;

  /// No description provided for @buttonIncomplete.
  ///
  /// In en, this message translates to:
  /// **'This button is not finished: choose what it should control.'**
  String get buttonIncomplete;

  /// No description provided for @buttonsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No new buttons} =1{1 button added} other{{count} buttons added}}'**
  String buttonsAdded(int count);

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmStopLiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop the live?'**
  String get confirmStopLiveTitle;

  /// No description provided for @confirmStopLiveBody.
  ///
  /// In en, this message translates to:
  /// **'Your live will end for everyone watching.'**
  String get confirmStopLiveBody;

  /// No description provided for @layoutLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get layoutLive;

  /// No description provided for @layoutRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get layoutRecording;

  /// No description provided for @layoutAudioOnly.
  ///
  /// In en, this message translates to:
  /// **'Audio only'**
  String get layoutAudioOnly;

  /// No description provided for @layoutMenu.
  ///
  /// In en, this message translates to:
  /// **'Layouts'**
  String get layoutMenu;

  /// No description provided for @layoutNew.
  ///
  /// In en, this message translates to:
  /// **'New layout'**
  String get layoutNew;

  /// No description provided for @layoutRename.
  ///
  /// In en, this message translates to:
  /// **'Rename layout'**
  String get layoutRename;

  /// No description provided for @layoutDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete layout'**
  String get layoutDelete;

  /// No description provided for @layoutDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete layout \"{name}\"?'**
  String layoutDeleteConfirm(String name);

  /// No description provided for @layoutDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its buttons will be deleted too.'**
  String get layoutDeleteBody;

  /// No description provided for @layoutAddSceneButtons.
  ///
  /// In en, this message translates to:
  /// **'Add a button for each scene'**
  String get layoutAddSceneButtons;

  /// No description provided for @layoutAddMuteButtons.
  ///
  /// In en, this message translates to:
  /// **'Add a mute button for each audio'**
  String get layoutAddMuteButtons;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldAction.
  ///
  /// In en, this message translates to:
  /// **'What does it do?'**
  String get fieldAction;

  /// No description provided for @fieldScene.
  ///
  /// In en, this message translates to:
  /// **'Scene'**
  String get fieldScene;

  /// No description provided for @fieldSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get fieldSource;

  /// No description provided for @fieldAudioInput.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get fieldAudioInput;

  /// No description provided for @fieldHotkey.
  ///
  /// In en, this message translates to:
  /// **'Hotkey name'**
  String get fieldHotkey;

  /// No description provided for @fieldHotkeyHelp.
  ///
  /// In en, this message translates to:
  /// **'Pick from the list of OBS hotkeys. Hotkeys of plugins also appear there.'**
  String get fieldHotkeyHelp;

  /// No description provided for @fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get fieldLabel;

  /// No description provided for @fieldSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fieldSize;

  /// No description provided for @fieldColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get fieldColor;

  /// No description provided for @fieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get fieldIcon;

  /// No description provided for @fieldEmoji.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get fieldEmoji;

  /// No description provided for @noEmoji.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noEmoji;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get sizeLarge;

  /// No description provided for @pickFromObs.
  ///
  /// In en, this message translates to:
  /// **'Pick from OBS'**
  String get pickFromObs;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @macroHelp.
  ///
  /// In en, this message translates to:
  /// **'Steps run in order. The wait happens after each step.'**
  String get macroHelp;

  /// No description provided for @macroStep.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String macroStep(int number);

  /// No description provided for @macroStepCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step} other{{count} steps}}'**
  String macroStepCount(int count);

  /// No description provided for @macroDelay.
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds} s before the next step'**
  String macroDelay(String seconds);

  /// No description provided for @macroAddStep.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get macroAddStep;

  /// No description provided for @badgeOnAir.
  ///
  /// In en, this message translates to:
  /// **'ON AIR'**
  String get badgeOnAir;

  /// No description provided for @badgeVisible.
  ///
  /// In en, this message translates to:
  /// **'VISIBLE'**
  String get badgeVisible;

  /// No description provided for @badgeMuted.
  ///
  /// In en, this message translates to:
  /// **'MUTED'**
  String get badgeMuted;

  /// No description provided for @badgeLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get badgeLive;

  /// No description provided for @badgeRecording.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get badgeRecording;

  /// No description provided for @badgePaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get badgePaused;

  /// No description provided for @badgeReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get badgeReady;

  /// No description provided for @badgePlaying.
  ///
  /// In en, this message translates to:
  /// **'PLAYING'**
  String get badgePlaying;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @mixerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No audio sources found in OBS.'**
  String get mixerEmpty;

  /// No description provided for @statusReconnectingShort.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get statusReconnectingShort;

  /// No description provided for @metricLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get metricLive;

  /// No description provided for @metricRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get metricRecording;

  /// No description provided for @metricOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get metricOff;

  /// No description provided for @metricAirTime.
  ///
  /// In en, this message translates to:
  /// **'Time on air'**
  String get metricAirTime;

  /// No description provided for @metricBitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get metricBitrate;

  /// No description provided for @metricCpu.
  ///
  /// In en, this message translates to:
  /// **'OBS CPU'**
  String get metricCpu;

  /// No description provided for @metricMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get metricMemory;

  /// No description provided for @metricFps.
  ///
  /// In en, this message translates to:
  /// **'Active FPS'**
  String get metricFps;

  /// No description provided for @metricRenderDropped.
  ///
  /// In en, this message translates to:
  /// **'Render frames lost'**
  String get metricRenderDropped;

  /// No description provided for @metricOutputDropped.
  ///
  /// In en, this message translates to:
  /// **'Output frames lost'**
  String get metricOutputDropped;

  /// No description provided for @metricCongestion.
  ///
  /// In en, this message translates to:
  /// **'Congestion'**
  String get metricCongestion;

  /// No description provided for @chartWindow.
  ///
  /// In en, this message translates to:
  /// **'Chart history'**
  String get chartWindow;

  /// No description provided for @chartBitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get chartBitrate;

  /// No description provided for @chartCpu.
  ///
  /// In en, this message translates to:
  /// **'OBS CPU'**
  String get chartCpu;

  /// No description provided for @chartDropped.
  ///
  /// In en, this message translates to:
  /// **'Frames lost (last seconds)'**
  String get chartDropped;

  /// No description provided for @alertFramesTitle.
  ///
  /// In en, this message translates to:
  /// **'Frames are being lost'**
  String get alertFramesTitle;

  /// No description provided for @alertFramesBody.
  ///
  /// In en, this message translates to:
  /// **'More than 1% of frames were lost. Viewers may see stutters. Close heavy programs, lower the bitrate or the resolution.'**
  String get alertFramesBody;

  /// No description provided for @alertBitrateTitle.
  ///
  /// In en, this message translates to:
  /// **'The bitrate dropped sharply'**
  String get alertBitrateTitle;

  /// No description provided for @alertBitrateBody.
  ///
  /// In en, this message translates to:
  /// **'Your internet upload may be unstable. If it keeps happening, lower the bitrate in OBS > Settings > Output.'**
  String get alertBitrateBody;

  /// No description provided for @soundProfileDefault.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get soundProfileDefault;

  /// No description provided for @soundPageDefault.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get soundPageDefault;

  /// No description provided for @soundProfiles.
  ///
  /// In en, this message translates to:
  /// **'Sound profiles'**
  String get soundProfiles;

  /// No description provided for @soundProfileNew.
  ///
  /// In en, this message translates to:
  /// **'New sound profile'**
  String get soundProfileNew;

  /// No description provided for @soundProfileRename.
  ///
  /// In en, this message translates to:
  /// **'Rename profile'**
  String get soundProfileRename;

  /// No description provided for @soundProfileDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get soundProfileDelete;

  /// No description provided for @soundPageNew.
  ///
  /// In en, this message translates to:
  /// **'New page'**
  String get soundPageNew;

  /// No description provided for @soundPageRename.
  ///
  /// In en, this message translates to:
  /// **'Rename page'**
  String get soundPageRename;

  /// No description provided for @soundPageDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete page'**
  String get soundPageDelete;

  /// No description provided for @soundEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sounds here yet. Tap \"Add sound\".'**
  String get soundEmpty;

  /// No description provided for @soundAdd.
  ///
  /// In en, this message translates to:
  /// **'Add sound'**
  String get soundAdd;

  /// No description provided for @soundEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit sound'**
  String get soundEdit;

  /// No description provided for @panicButton.
  ///
  /// In en, this message translates to:
  /// **'Stop all'**
  String get panicButton;

  /// No description provided for @panicDone.
  ///
  /// In en, this message translates to:
  /// **'All sounds stopped.'**
  String get panicDone;

  /// No description provided for @panicPartial.
  ///
  /// In en, this message translates to:
  /// **'Stopped, but {count} sound(s) were not found in OBS.'**
  String panicPartial(int count);

  /// No description provided for @soundMissing.
  ///
  /// In en, this message translates to:
  /// **'The sound source \"{name}\" does not exist in OBS. Edit the pad or add the sound again.'**
  String soundMissing(String name);

  /// No description provided for @soundPlayFromStart.
  ///
  /// In en, this message translates to:
  /// **'Play from the start'**
  String get soundPlayFromStart;

  /// No description provided for @soundResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get soundResume;

  /// No description provided for @soundPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get soundPause;

  /// No description provided for @soundStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get soundStop;

  /// No description provided for @soundAddIntro.
  ///
  /// In en, this message translates to:
  /// **'The audio file stays on your PC — the phone does not send audio. OBS Pad creates a Media Source in OBS that plays the file, and this pad triggers it.'**
  String get soundAddIntro;

  /// No description provided for @soundAddNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Connect to OBS to create the sound source.'**
  String get soundAddNeedsConnection;

  /// No description provided for @soundFromFile.
  ///
  /// In en, this message translates to:
  /// **'File on the PC'**
  String get soundFromFile;

  /// No description provided for @soundFromExisting.
  ///
  /// In en, this message translates to:
  /// **'Existing source'**
  String get soundFromExisting;

  /// No description provided for @soundLabelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Applause'**
  String get soundLabelHint;

  /// No description provided for @soundPathField.
  ///
  /// In en, this message translates to:
  /// **'File path on the PC'**
  String get soundPathField;

  /// No description provided for @soundPathHelp.
  ///
  /// In en, this message translates to:
  /// **'Tip: on Windows, Shift + right-click the file and choose \"Copy as path\" (remove the quotes). On Mac, Option + right-click > \"Copy as Pathname\".'**
  String get soundPathHelp;

  /// No description provided for @soundPathEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type where the file is on the PC'**
  String get soundPathEmpty;

  /// No description provided for @soundPathInvalid.
  ///
  /// In en, this message translates to:
  /// **'This does not look like a file path. Example: C:\\Users\\Ana\\Music\\applause.mp3'**
  String get soundPathInvalid;

  /// No description provided for @soundAllScenes.
  ///
  /// In en, this message translates to:
  /// **'Add to every scene (recommended)'**
  String get soundAllScenes;

  /// No description provided for @soundAllScenesHelp.
  ///
  /// In en, this message translates to:
  /// **'A sound only reaches the live if its source is in the scene on air.'**
  String get soundAllScenesHelp;

  /// No description provided for @soundMonitor.
  ///
  /// In en, this message translates to:
  /// **'Also play on my headphones'**
  String get soundMonitor;

  /// No description provided for @soundMonitorHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses OBS \"Monitor and Output\", so you hear it too.'**
  String get soundMonitorHelp;

  /// No description provided for @soundLoop.
  ///
  /// In en, this message translates to:
  /// **'Repeat (loop)'**
  String get soundLoop;

  /// No description provided for @soundLoopHelp.
  ///
  /// In en, this message translates to:
  /// **'Plays again and again until you stop it.'**
  String get soundLoopHelp;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @soundInputNameField.
  ///
  /// In en, this message translates to:
  /// **'Source name in OBS'**
  String get soundInputNameField;

  /// No description provided for @soundInputNameHelp.
  ///
  /// In en, this message translates to:
  /// **'If a source with this name already exists, its file is replaced.'**
  String get soundInputNameHelp;

  /// No description provided for @soundInputNameDefault.
  ///
  /// In en, this message translates to:
  /// **'Sound - {label}'**
  String soundInputNameDefault(String label);

  /// No description provided for @soundCreateInObs.
  ///
  /// In en, this message translates to:
  /// **'Create in OBS'**
  String get soundCreateInObs;

  /// No description provided for @soundAddPad.
  ///
  /// In en, this message translates to:
  /// **'Add pad'**
  String get soundAddPad;

  /// No description provided for @soundAdded.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" added.'**
  String soundAdded(String name);

  /// No description provided for @soundSourceField.
  ///
  /// In en, this message translates to:
  /// **'Media source in OBS'**
  String get soundSourceField;

  /// No description provided for @soundSourceHelp.
  ///
  /// In en, this message translates to:
  /// **'The Media Source this pad plays.'**
  String get soundSourceHelp;

  /// No description provided for @soundNoMediaSources.
  ///
  /// In en, this message translates to:
  /// **'No Media Source found in OBS.'**
  String get soundNoMediaSources;

  /// No description provided for @soundPickSource.
  ///
  /// In en, this message translates to:
  /// **'Choose which OBS media source this pad plays.'**
  String get soundPickSource;

  /// No description provided for @soundModeTitle.
  ///
  /// In en, this message translates to:
  /// **'How it plays'**
  String get soundModeTitle;

  /// No description provided for @soundModeToEnd.
  ///
  /// In en, this message translates to:
  /// **'Play to the end'**
  String get soundModeToEnd;

  /// No description provided for @soundModeHold.
  ///
  /// In en, this message translates to:
  /// **'Hold to play'**
  String get soundModeHold;

  /// No description provided for @soundModeToEndHelp.
  ///
  /// In en, this message translates to:
  /// **'Tap to play from the start. Tap again to stop. Hold for more options.'**
  String get soundModeToEndHelp;

  /// No description provided for @soundModeHoldHelp.
  ///
  /// In en, this message translates to:
  /// **'Plays only while your finger is on the pad.'**
  String get soundModeHoldHelp;

  /// No description provided for @soundVolume.
  ///
  /// In en, this message translates to:
  /// **'Set volume'**
  String get soundVolume;

  /// No description provided for @soundVolumeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep the volume set in OBS'**
  String get soundVolumeKeep;

  /// No description provided for @duckingTitle.
  ///
  /// In en, this message translates to:
  /// **'Lower another audio while it plays'**
  String get duckingTitle;

  /// No description provided for @duckingHelp.
  ///
  /// In en, this message translates to:
  /// **'E.g. lower the mic or the music, and bring it back when the sound ends. If the connection drops mid-sound, the volume goes back to normal as soon as OBS Pad reconnects.'**
  String get duckingHelp;

  /// No description provided for @duckingTarget.
  ///
  /// In en, this message translates to:
  /// **'Audio to lower'**
  String get duckingTarget;

  /// No description provided for @duckingAmount.
  ///
  /// In en, this message translates to:
  /// **'Lower by {db} dB'**
  String duckingAmount(int db);

  /// No description provided for @manualTitle.
  ///
  /// In en, this message translates to:
  /// **'Do it by hand in OBS'**
  String get manualTitle;

  /// No description provided for @manualStep1.
  ///
  /// In en, this message translates to:
  /// **'In OBS, select the scene and click + under Sources > Media Source.'**
  String get manualStep1;

  /// No description provided for @manualStep2.
  ///
  /// In en, this message translates to:
  /// **'Give it a name and keep \"Local File\" checked. Click Browse and choose the audio file.'**
  String get manualStep2;

  /// No description provided for @manualStep3.
  ///
  /// In en, this message translates to:
  /// **'Check \"Close file when inactive\" and uncheck \"Restart playback when source becomes active\". Click OK.'**
  String get manualStep3;

  /// No description provided for @manualStep4.
  ///
  /// In en, this message translates to:
  /// **'In the Audio Mixer, click ⋮ (or the gear) > Advanced Audio Properties. On the line of your sound, make sure Track 1 is checked.'**
  String get manualStep4;

  /// No description provided for @manualStep5.
  ///
  /// In en, this message translates to:
  /// **'Optional: set Audio Monitoring to \"Monitor and Output\" to hear it on your headphones.'**
  String get manualStep5;

  /// No description provided for @manualStep6.
  ///
  /// In en, this message translates to:
  /// **'Back here, choose \"Existing source\" and pick the source you created.'**
  String get manualStep6;

  /// No description provided for @metricsForegroundHint.
  ///
  /// In en, this message translates to:
  /// **'Alerts only work while OBS Pad is open with the screen on. With the app closed or in the background, nothing is watching your live.'**
  String get metricsForegroundHint;

  /// No description provided for @failRecordPauseTitle.
  ///
  /// In en, this message translates to:
  /// **'OBS did not pause the recording'**
  String get failRecordPauseTitle;

  /// No description provided for @failRecordPauseHint.
  ///
  /// In en, this message translates to:
  /// **'This happens when the recording uses the same quality as the live. In OBS: Settings › Output › Recording Quality: pick another option (e.g. \"High Quality\"). Then stop and start the recording again.'**
  String get failRecordPauseHint;

  /// No description provided for @failReplayOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Replay Buffer is off'**
  String get failReplayOffTitle;

  /// No description provided for @failReplayOffHint.
  ///
  /// In en, this message translates to:
  /// **'In OBS: Settings › Output › check \"Enable Replay Buffer\". Then click \"Start Replay Buffer\" on the main window.'**
  String get failReplayOffHint;

  /// No description provided for @soundNotOnAir.
  ///
  /// In en, this message translates to:
  /// **'OBS did not play \"{name}\": this sound is not in the scene on air, and OBS only plays sounds of the scenes on air.'**
  String soundNotOnAir(String name);

  /// No description provided for @soundAddToAllScenes.
  ///
  /// In en, this message translates to:
  /// **'Add to all scenes'**
  String get soundAddToAllScenes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

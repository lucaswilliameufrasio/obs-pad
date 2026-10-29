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
  /// **'OBS Pad Desktop'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep this app open while you use OBS Pad on your phone. It finds this computer for the phone and receives the sounds you send.'**
  String get appSubtitle;

  /// No description provided for @obsSection.
  ///
  /// In en, this message translates to:
  /// **'OBS on this computer'**
  String get obsSection;

  /// No description provided for @obsNotFound.
  ///
  /// In en, this message translates to:
  /// **'OBS settings not found. Open OBS once (version 28 or newer), close it and come back here.'**
  String get obsNotFound;

  /// No description provided for @obsRunning.
  ///
  /// In en, this message translates to:
  /// **'OBS is open'**
  String get obsRunning;

  /// No description provided for @obsClosed.
  ///
  /// In en, this message translates to:
  /// **'OBS is closed'**
  String get obsClosed;

  /// No description provided for @phoneControlOn.
  ///
  /// In en, this message translates to:
  /// **'Phone control is on (port {port}, with password)'**
  String phoneControlOn(int port);

  /// No description provided for @phoneControlOff.
  ///
  /// In en, this message translates to:
  /// **'Phone control is off'**
  String get phoneControlOff;

  /// No description provided for @phoneControlNoPassword.
  ///
  /// In en, this message translates to:
  /// **'Phone control is on, but without a password'**
  String get phoneControlNoPassword;

  /// No description provided for @enableButton.
  ///
  /// In en, this message translates to:
  /// **'Turn on phone control'**
  String get enableButton;

  /// No description provided for @enableNeedsClosedObs.
  ///
  /// In en, this message translates to:
  /// **'Close OBS first: it undoes this change when it closes. Then press the button.'**
  String get enableNeedsClosedObs;

  /// No description provided for @enableExplain.
  ///
  /// In en, this message translates to:
  /// **'This turns on the OBS WebSocket server with a password, the same as doing it in OBS under Tools › WebSocket Server Settings.'**
  String get enableExplain;

  /// No description provided for @enableDone.
  ///
  /// In en, this message translates to:
  /// **'Done! Open OBS again and connect the phone below.'**
  String get enableDone;

  /// No description provided for @enableFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not change the OBS settings. Do it in OBS: Tools › WebSocket Server Settings › Enable, with a password.'**
  String get enableFailed;

  /// No description provided for @connectSection.
  ///
  /// In en, this message translates to:
  /// **'Connect the phone'**
  String get connectSection;

  /// No description provided for @connectHowTo.
  ///
  /// In en, this message translates to:
  /// **'In OBS Pad on the phone, tap \"Read QR code\" and point the camera here. Or tap \"Find on network\".'**
  String get connectHowTo;

  /// No description provided for @showQr.
  ///
  /// In en, this message translates to:
  /// **'Show QR code'**
  String get showQr;

  /// No description provided for @hideQr.
  ///
  /// In en, this message translates to:
  /// **'Hide QR code'**
  String get hideQr;

  /// No description provided for @qrWarning.
  ///
  /// In en, this message translates to:
  /// **'The QR code contains the OBS password. Only show it to people you trust.'**
  String get qrWarning;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Computer IP'**
  String get addressLabel;

  /// No description provided for @addressVpn.
  ///
  /// In en, this message translates to:
  /// **'{ip} (VPN, works away from home)'**
  String addressVpn(String ip);

  /// No description provided for @noAddress.
  ///
  /// In en, this message translates to:
  /// **'No network found. Connect this computer to the Wi-Fi or cable.'**
  String get noAddress;

  /// No description provided for @portLabel.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get portLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showPassword;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @soundsSection.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get soundsSection;

  /// No description provided for @soundsFolder.
  ///
  /// In en, this message translates to:
  /// **'Sounds sent from the phone are saved in:'**
  String get soundsFolder;

  /// No description provided for @soundsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sounds yet} =1{1 sound} other{{count} sounds}}'**
  String soundsCount(int count);

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open folder'**
  String get openFolder;

  /// No description provided for @firewallSection.
  ///
  /// In en, this message translates to:
  /// **'Windows Firewall'**
  String get firewallSection;

  /// No description provided for @firewallExplain.
  ///
  /// In en, this message translates to:
  /// **'If the phone cannot find or connect to this computer, allow OBS and OBS Pad on private networks. Windows will ask for permission.'**
  String get firewallExplain;

  /// No description provided for @firewallButton.
  ///
  /// In en, this message translates to:
  /// **'Allow on the firewall'**
  String get firewallButton;

  /// No description provided for @firewallDone.
  ///
  /// In en, this message translates to:
  /// **'Done. Also check that the Wi-Fi is set as a Private network.'**
  String get firewallDone;

  /// No description provided for @firewallFailed.
  ///
  /// In en, this message translates to:
  /// **'It was not allowed. Try again and answer \"Yes\" on the Windows prompt.'**
  String get firewallFailed;

  /// No description provided for @serverFailed.
  ///
  /// In en, this message translates to:
  /// **'Another program is using port 4457 (maybe OBS Pad Desktop is already open). The phone will not find this computer or send sounds until you close it.'**
  String get serverFailed;

  /// No description provided for @activitySection.
  ///
  /// In en, this message translates to:
  /// **'What the phone did'**
  String get activitySection;

  /// No description provided for @activityEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet.'**
  String get activityEmpty;

  /// No description provided for @activityDiscovered.
  ///
  /// In en, this message translates to:
  /// **'A phone found this computer ({ip})'**
  String activityDiscovered(String ip);

  /// No description provided for @activityListed.
  ///
  /// In en, this message translates to:
  /// **'The phone opened the sounds list'**
  String get activityListed;

  /// No description provided for @activityUploaded.
  ///
  /// In en, this message translates to:
  /// **'Received \"{name}\"'**
  String activityUploaded(String name);

  /// No description provided for @activityRejected.
  ///
  /// In en, this message translates to:
  /// **'Refused a request from {ip}: the OBS password on the phone is different'**
  String activityRejected(String ip);

  /// No description provided for @activityRejectedOther.
  ///
  /// In en, this message translates to:
  /// **'Refused a request from {ip} ({reason})'**
  String activityRejectedOther(String ip, String reason);
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

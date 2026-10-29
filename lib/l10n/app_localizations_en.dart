// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OBS Pad';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get retry => 'Try again';

  @override
  String get close => 'Close';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String get details => 'Technical details';

  @override
  String get add => 'Add';

  @override
  String get navPad => 'Buttons';

  @override
  String get navMixer => 'Mixer';

  @override
  String get navSounds => 'Sounds';

  @override
  String get navMetrics => 'Metrics';

  @override
  String get menuProfiles => 'Saved computers';

  @override
  String get menuRemote => 'Access from outside home';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuGuide => 'Setup guide';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onbStep1Title => 'Open OBS on your computer';

  @override
  String get onbStep1Body =>
      'Use OBS Studio version 28 or newer. It already includes everything OBS Pad needs — nothing else to install on the PC.';

  @override
  String get onbStep1Hint =>
      'Not sure about the version? In OBS, click Help > About.';

  @override
  String get onbStep2Title => 'Turn on OBS remote control';

  @override
  String get onbStep2a => 'In OBS, click the Tools menu';

  @override
  String get onbStep2b => 'Choose WebSocket Server Settings';

  @override
  String get onbStep2c => 'Check \"Enable WebSocket server\"';

  @override
  String get onbStep2d =>
      'Check \"Enable Authentication\" and create a password';

  @override
  String get onbStep2e => 'Keep port 4455 and click OK';

  @override
  String get onbStep2Hint =>
      'Tip: the \"Show Connect Info\" button shows the PC IP and the password.';

  @override
  String get onbStep3Title => 'Same Wi-Fi network';

  @override
  String get onbStep3Body =>
      'Your PC and your phone must be on the same Wi-Fi network (the same router). Mobile data will not work here.';

  @override
  String get onbFindIp => 'How to find the PC IP address';

  @override
  String get onbIpWindows =>
      'Windows: press Windows + R, type cmd and press Enter. In the black window type ipconfig and press Enter. Look for \"IPv4 Address\" (e.g. 192.168.0.15).';

  @override
  String get onbIpMac =>
      'Mac: open System Settings > Network, click your Wi-Fi connection and look for \"IP Address\".';

  @override
  String get onbIpLinux => 'Linux: open a terminal and run hostname -I.';

  @override
  String get onbStep4Title => 'Test the connection';

  @override
  String get onbStep4Body =>
      'Type the details you saw in OBS and tap the button.';

  @override
  String get fieldProfileName => 'Name for this computer';

  @override
  String get defaultProfileName => 'My PC';

  @override
  String get fieldHost => 'Computer IP';

  @override
  String get fieldHostHint => 'e.g. 192.168.0.15';

  @override
  String get fieldPort => 'Port';

  @override
  String get fieldPassword => 'WebSocket password';

  @override
  String get fieldPasswordHint =>
      'Leave empty if you did not enable authentication';

  @override
  String get showPassword => 'Show password';

  @override
  String get testConnection => 'Test connection';

  @override
  String get testing => 'Testing…';

  @override
  String testSuccess(String version) {
    return 'All set! Connected to OBS $version.';
  }

  @override
  String testOldObs(String version) {
    return 'OBS $version is old. Some features may not work; update to 28 or newer.';
  }

  @override
  String get onbSoundTipTitle => 'Tip about sounds';

  @override
  String get onbSoundTip =>
      'A sound only reaches the live if its source is in the scene that is on air. When adding sounds with OBS Pad, keep \"Add to every scene\" checked — or put your sounds in one scene and add that scene as a source in the others.';

  @override
  String get errHostEmpty => 'Type the computer IP';

  @override
  String get errHostScheme => 'Type only the IP, without ws://';

  @override
  String get errHostPort =>
      'Put the port in the Port field, not next to the IP';

  @override
  String get errHostInvalid =>
      'This IP does not look right. Example: 192.168.0.15';

  @override
  String get errPort => 'Invalid port (usually 4455)';

  @override
  String get errNameEmpty => 'Give it a name';

  @override
  String get failWrongPasswordTitle => 'Wrong password';

  @override
  String get failWrongPasswordHint =>
      'The password does not match the one in OBS. Check it in Tools > WebSocket Server Settings > Show Connect Info.';

  @override
  String get failServerOffTitle => 'OBS did not answer';

  @override
  String get failServerOffHint =>
      'The computer was found, but the WebSocket server seems off. Open OBS and check that \"Enable WebSocket server\" is on and the port is 4455.';

  @override
  String get failTimeoutTitle => 'Could not reach the computer';

  @override
  String get failTimeoutHint =>
      'Check that the IP is right and both are on the same Wi-Fi. On Windows, the Firewall may be blocking port 4455.';

  @override
  String get failUnreachableTitle => 'Different network';

  @override
  String get failUnreachableHint =>
      'The phone cannot see this address. Make sure it is on the same Wi-Fi as the PC (not on mobile data).';

  @override
  String get failInvalidAddressTitle => 'Invalid address';

  @override
  String get failInvalidAddressHint =>
      'I could not find this address. Type the IP like 192.168.0.15.';

  @override
  String get failNotObsTitle => 'This does not look like OBS';

  @override
  String get failNotObsHint =>
      'Something answered on this port, but it is not OBS WebSocket. Check the port (default 4455).';

  @override
  String get failUnsupportedTitle => 'OBS is too old';

  @override
  String get failUnsupportedHint => 'Update to OBS 28 or newer.';

  @override
  String get failNotConnectedTitle => 'Not connected to OBS';

  @override
  String get failNotConnectedHint => 'Wait for it to reconnect or tap Try now.';

  @override
  String failNotFoundNamed(String name) {
    return '\"$name\" was not found in OBS';
  }

  @override
  String get failNotFound => 'Item not found in OBS';

  @override
  String get failNotFoundHint =>
      'It may have been renamed or deleted in OBS. Edit the button and pick it again.';

  @override
  String get failAlreadyExists =>
      'Something with this name already exists in OBS.';

  @override
  String get failOutputActive => 'It is already running.';

  @override
  String get failOutputNotActive => 'It is not running.';

  @override
  String get failOutputDisabledTitle => 'Feature turned off in OBS';

  @override
  String get failOutputDisabledHint =>
      'Turn it on in OBS Settings > Output (e.g. Replay Buffer).';

  @override
  String failInvalidStateNamed(String name) {
    return 'OBS cannot do this with \"$name\" right now.';
  }

  @override
  String get failInvalidState => 'OBS cannot do this right now.';

  @override
  String get failInvalidInputKind =>
      'Your OBS does not have this kind of source.';

  @override
  String get failRequestFailed => 'OBS could not do this.';

  @override
  String get failUnknown => 'Something went wrong.';

  @override
  String get firewallHelpTitle => 'How to allow OBS in the Windows Firewall';

  @override
  String get firewallHelpBody =>
      'Open Start and search for \"Allow an app through Windows Firewall\". Click \"Change settings\", find \"OBS Studio\" and check \"Private\". If it is not listed, click \"Allow another app\" and choose obs64.exe. Also make sure your Wi-Fi is set as a Private network.';

  @override
  String get statusConnecting => 'Connecting to OBS…';

  @override
  String statusReconnecting(int seconds, int attempt) {
    return 'Connection lost. Trying again in ${seconds}s (attempt $attempt)';
  }

  @override
  String statusFailed(String reason) {
    return 'Could not connect: $reason';
  }

  @override
  String get statusDisconnected => 'Not connected to OBS';

  @override
  String get statusConnected => 'Connected';

  @override
  String get tryNow => 'Try now';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get profilesTitle => 'Saved computers';

  @override
  String get profilesEmpty => 'No computer saved yet.';

  @override
  String get addProfile => 'Add computer';

  @override
  String get editProfile => 'Edit computer';

  @override
  String deleteProfileConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get profileInUse => 'In use';

  @override
  String get saveWithoutTest => 'Save without testing';

  @override
  String get testAndSave => 'Test and save';

  @override
  String get scenesTitle => 'Scenes';

  @override
  String get scenesEmpty => 'No scenes found in OBS.';

  @override
  String get onAir => 'On air';

  @override
  String sceneSwitched(String name) {
    return 'Scene: $name';
  }

  @override
  String get remoteTitle => 'Access from outside home';

  @override
  String get remoteIntro =>
      'Want to control OBS when your phone is not on the same Wi-Fi (e.g. on 4G)? Use a free private network app (VPN) like Tailscale or NetBird. It connects your phone and PC safely, as if they were at home.';

  @override
  String get remoteWarningTitle => 'Never open port 4455 on your router';

  @override
  String get remoteWarning =>
      'Do NOT use \"port forwarding\" to expose port 4455 to the internet. Anyone could try to guess your password and take control of your OBS and your live.';

  @override
  String get remoteOptionTailscale => 'Option 1: Tailscale';

  @override
  String get remoteOptionNetbird => 'Option 2: NetBird';

  @override
  String remoteStep1(String site) {
    return 'Create a free account at $site';
  }

  @override
  String remoteStep2(String app) {
    return 'Install $app on the PC (where OBS is) and sign in';
  }

  @override
  String remoteStep3(String app) {
    return 'Install the $app app on your phone and sign in with the same account';
  }

  @override
  String remoteStep4(String app) {
    return 'On the PC, open $app and copy its IP (it starts with 100.)';
  }

  @override
  String get remoteStep5 =>
      'In OBS Pad, add a new computer using that 100.x.x.x IP, with the same port and password';

  @override
  String get remoteFootnote =>
      'Keep the VPN turned on in both the PC and the phone while you use it.';

  @override
  String get remoteAddProfile => 'Add computer with VPN IP';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'Same as phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'Same as phone';

  @override
  String get settingsKeepScreenOn => 'Keep screen on';

  @override
  String get settingsKeepScreenOnHint =>
      'The phone screen will not turn off while OBS Pad is open. If the screen turns off or you switch apps, the phone cuts the connection to OBS: running macros and alerts stop until you come back.';

  @override
  String get settingsHaptics => 'Vibrate on touch';

  @override
  String get settingsGuide => 'See the setup guide again';

  @override
  String get obsMockTitle => 'WebSocket Server Settings';

  @override
  String get obsMockEnableServer => 'Enable WebSocket server';

  @override
  String get obsMockEnableAuth => 'Enable Authentication';

  @override
  String get obsMockPort => 'Server Port';

  @override
  String get actionSwitchScene => 'Switch scene';

  @override
  String get actionToggleSource => 'Show/hide a source';

  @override
  String get actionToggleMute => 'Mute/unmute audio';

  @override
  String get actionToggleStream => 'Start/stop live';

  @override
  String get actionStartStream => 'Start live';

  @override
  String get actionStopStream => 'Stop live';

  @override
  String get actionToggleRecord => 'Start/stop recording';

  @override
  String get actionStartRecord => 'Start recording';

  @override
  String get actionStopRecord => 'Stop recording';

  @override
  String get actionToggleRecordPause => 'Pause/resume recording';

  @override
  String get actionSaveReplay => 'Save replay';

  @override
  String get actionHotkey => 'OBS hotkey';

  @override
  String get actionMacro => 'Macro (several actions)';

  @override
  String get addButton => 'Add button';

  @override
  String get editButton => 'Edit button';

  @override
  String get editButtons => 'Edit buttons';

  @override
  String get doneEditing => 'Done editing';

  @override
  String get editModeHint => 'Hold and drag to reorder. Tap to edit.';

  @override
  String get columns => 'Columns';

  @override
  String get padEmpty => 'No buttons in this layout yet.';

  @override
  String get buttonIncomplete =>
      'This button is not finished: choose what it should control.';

  @override
  String buttonsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count buttons added',
      one: '1 button added',
      zero: 'No new buttons',
    );
    return '$_temp0';
  }

  @override
  String get confirm => 'Confirm';

  @override
  String get confirmStopLiveTitle => 'Stop the live?';

  @override
  String get confirmStopLiveBody => 'Your live will end for everyone watching.';

  @override
  String get layoutLive => 'Live';

  @override
  String get layoutRecording => 'Recording';

  @override
  String get layoutAudioOnly => 'Audio only';

  @override
  String get layoutMenu => 'Layouts';

  @override
  String get layoutNew => 'New layout';

  @override
  String get layoutRename => 'Rename layout';

  @override
  String get layoutDelete => 'Delete layout';

  @override
  String layoutDeleteConfirm(String name) {
    return 'Delete layout \"$name\"?';
  }

  @override
  String get layoutDeleteBody => 'Its buttons will be deleted too.';

  @override
  String get layoutAddSceneButtons => 'Add a button for each scene';

  @override
  String get layoutAddMuteButtons => 'Add a mute button for each audio';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldAction => 'What does it do?';

  @override
  String get fieldScene => 'Scene';

  @override
  String get fieldSource => 'Source';

  @override
  String get fieldAudioInput => 'Audio';

  @override
  String get fieldHotkey => 'Hotkey name';

  @override
  String get fieldHotkeyHelp =>
      'Pick from the list of OBS hotkeys. Hotkeys of plugins also appear there.';

  @override
  String get fieldLabel => 'Label';

  @override
  String get fieldSize => 'Size';

  @override
  String get fieldColor => 'Color';

  @override
  String get fieldIcon => 'Icon';

  @override
  String get fieldEmoji => 'Emoji';

  @override
  String get noEmoji => 'None';

  @override
  String get sizeSmall => 'Small';

  @override
  String get sizeMedium => 'Medium';

  @override
  String get sizeLarge => 'Large';

  @override
  String get pickFromObs => 'Pick from OBS';

  @override
  String get search => 'Search';

  @override
  String get moveUp => 'Move up';

  @override
  String get macroHelp =>
      'Steps run in order. The wait happens after each step.';

  @override
  String macroStep(int number) {
    return 'Step $number';
  }

  @override
  String macroStepCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps',
      one: '1 step',
    );
    return '$_temp0';
  }

  @override
  String macroDelay(String seconds) {
    return 'Wait $seconds s before the next step';
  }

  @override
  String get macroAddStep => 'Add step';

  @override
  String get badgeOnAir => 'ON AIR';

  @override
  String get badgeVisible => 'VISIBLE';

  @override
  String get badgeMuted => 'MUTED';

  @override
  String get badgeLive => 'LIVE';

  @override
  String get badgeRecording => 'REC';

  @override
  String get badgePaused => 'PAUSED';

  @override
  String get badgeReady => 'READY';

  @override
  String get badgePlaying => 'PLAYING';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get mixerEmpty => 'No audio sources found in OBS.';

  @override
  String get statusReconnectingShort => 'Reconnecting';

  @override
  String get metricLive => 'Live';

  @override
  String get metricRecording => 'Recording';

  @override
  String get metricOff => 'Off';

  @override
  String get metricAirTime => 'Time on air';

  @override
  String get metricBitrate => 'Bitrate';

  @override
  String get metricCpu => 'OBS CPU';

  @override
  String get metricMemory => 'Memory';

  @override
  String get metricFps => 'Active FPS';

  @override
  String get metricRenderDropped => 'Render frames lost';

  @override
  String get metricOutputDropped => 'Output frames lost';

  @override
  String get metricCongestion => 'Congestion';

  @override
  String get chartWindow => 'Chart history';

  @override
  String get chartBitrate => 'Bitrate';

  @override
  String get chartCpu => 'OBS CPU';

  @override
  String get chartDropped => 'Frames lost (last seconds)';

  @override
  String get alertFramesTitle => 'Frames are being lost';

  @override
  String get alertFramesBody =>
      'More than 1% of frames were lost. Viewers may see stutters. Close heavy programs, lower the bitrate or the resolution.';

  @override
  String get alertBitrateTitle => 'The bitrate dropped sharply';

  @override
  String get alertBitrateBody =>
      'Your internet upload may be unstable. If it keeps happening, lower the bitrate in OBS > Settings > Output.';

  @override
  String get soundProfileDefault => 'Main';

  @override
  String get soundPageDefault => 'Sounds';

  @override
  String get soundProfiles => 'Sound profiles';

  @override
  String get soundProfileNew => 'New sound profile';

  @override
  String get soundProfileRename => 'Rename profile';

  @override
  String get soundProfileDelete => 'Delete profile';

  @override
  String get soundPageNew => 'New page';

  @override
  String get soundPageRename => 'Rename page';

  @override
  String get soundPageDelete => 'Delete page';

  @override
  String get soundEmpty => 'No sounds here yet. Tap \"Add sound\".';

  @override
  String get soundAdd => 'Add sound';

  @override
  String get soundEdit => 'Edit sound';

  @override
  String get panicButton => 'Stop all';

  @override
  String get panicDone => 'All sounds stopped.';

  @override
  String panicPartial(int count) {
    return 'Stopped, but $count sound(s) were not found in OBS.';
  }

  @override
  String soundMissing(String name) {
    return 'The sound source \"$name\" does not exist in OBS. Edit the pad or add the sound again.';
  }

  @override
  String get soundPlayFromStart => 'Play from the start';

  @override
  String get soundResume => 'Resume';

  @override
  String get soundPause => 'Pause';

  @override
  String get soundStop => 'Stop';

  @override
  String get soundAddIntro =>
      'The audio file stays on your PC — the phone does not send audio. OBS Pad creates a Media Source in OBS that plays the file, and this pad triggers it.';

  @override
  String get soundAddNeedsConnection =>
      'Connect to OBS to create the sound source.';

  @override
  String get soundFromFile => 'File on the PC';

  @override
  String get soundFromExisting => 'Existing source';

  @override
  String get soundLabelHint => 'e.g. Applause';

  @override
  String get soundPathField => 'File path on the PC';

  @override
  String get soundPathHelp =>
      'Tip: on Windows, Shift + right-click the file and choose \"Copy as path\" (remove the quotes). On Mac, Option + right-click > \"Copy as Pathname\".';

  @override
  String get soundPathEmpty => 'Type where the file is on the PC';

  @override
  String get soundPathInvalid =>
      'This does not look like a file path. Example: C:\\Users\\Ana\\Music\\applause.mp3';

  @override
  String get soundAllScenes => 'Add to every scene (recommended)';

  @override
  String get soundAllScenesHelp =>
      'A sound only reaches the live if its source is in the scene on air.';

  @override
  String get soundMonitor => 'Also play on my headphones';

  @override
  String get soundMonitorHelp =>
      'Uses OBS \"Monitor and Output\", so you hear it too.';

  @override
  String get soundLoop => 'Repeat (loop)';

  @override
  String get soundLoopHelp => 'Plays again and again until you stop it.';

  @override
  String get advanced => 'Advanced';

  @override
  String get soundInputNameField => 'Source name in OBS';

  @override
  String get soundInputNameHelp =>
      'If a source with this name already exists, its file is replaced.';

  @override
  String soundInputNameDefault(String label) {
    return 'Sound - $label';
  }

  @override
  String get soundCreateInObs => 'Create in OBS';

  @override
  String get soundAddPad => 'Add pad';

  @override
  String soundAdded(String name) {
    return '\"$name\" added.';
  }

  @override
  String get soundSourceField => 'Media source in OBS';

  @override
  String get soundSourceHelp => 'The Media Source this pad plays.';

  @override
  String get soundNoMediaSources => 'No Media Source found in OBS.';

  @override
  String get soundPickSource => 'Choose which OBS media source this pad plays.';

  @override
  String get soundModeTitle => 'How it plays';

  @override
  String get soundModeToEnd => 'Play to the end';

  @override
  String get soundModeHold => 'Hold to play';

  @override
  String get soundModeToEndHelp =>
      'Tap to play from the start. Tap again to stop. Hold for more options.';

  @override
  String get soundModeHoldHelp => 'Plays only while your finger is on the pad.';

  @override
  String get soundVolume => 'Set volume';

  @override
  String get soundVolumeKeep => 'Keep the volume set in OBS';

  @override
  String get duckingTitle => 'Lower another audio while it plays';

  @override
  String get duckingHelp =>
      'E.g. lower the mic or the music, and bring it back when the sound ends. If the connection drops mid-sound, the volume goes back to normal as soon as OBS Pad reconnects.';

  @override
  String get duckingTarget => 'Audio to lower';

  @override
  String duckingAmount(int db) {
    return 'Lower by $db dB';
  }

  @override
  String get manualTitle => 'Do it by hand in OBS';

  @override
  String get manualStep1 =>
      'In OBS, select the scene and click + under Sources > Media Source.';

  @override
  String get manualStep2 =>
      'Give it a name and keep \"Local File\" checked. Click Browse and choose the audio file.';

  @override
  String get manualStep3 =>
      'Check \"Close file when inactive\" and uncheck \"Restart playback when source becomes active\". Click OK.';

  @override
  String get manualStep4 =>
      'In the Audio Mixer, click ⋮ (or the gear) > Advanced Audio Properties. On the line of your sound, make sure Track 1 is checked.';

  @override
  String get manualStep5 =>
      'Optional: set Audio Monitoring to \"Monitor and Output\" to hear it on your headphones.';

  @override
  String get manualStep6 =>
      'Back here, choose \"Existing source\" and pick the source you created.';

  @override
  String get metricsForegroundHint =>
      'Alerts only work while OBS Pad is open with the screen on. With the app closed or in the background, nothing is watching your live.';

  @override
  String get failRecordPauseTitle => 'OBS did not pause the recording';

  @override
  String get failRecordPauseHint =>
      'This happens when the recording uses the same quality as the live. In OBS: Settings › Output › Recording Quality: pick another option (e.g. \"High Quality\"). Then stop and start the recording again.';

  @override
  String get failReplayOffTitle => 'Replay Buffer is off';

  @override
  String get failReplayOffHint =>
      'In OBS: Settings › Output › check \"Enable Replay Buffer\". Then click \"Start Replay Buffer\" on the main window.';
}

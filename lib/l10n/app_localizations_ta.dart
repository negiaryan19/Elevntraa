// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'Rxvarta';

  @override
  String get appTagline => 'ஸ்மார்ட் மருத்துவ ஆவணப்படுத்தல்';

  @override
  String get online => 'ஆன்லைன்';

  @override
  String get offline => 'ஆஃப்லைன்';

  @override
  String get checking => 'சரிபார்க்கிறது';

  @override
  String get goodMorning => 'காலை வணக்கம்';

  @override
  String get goodAfternoon => 'மதிய வணக்கம்';

  @override
  String get goodEvening => 'மாலை வணக்கம்';

  @override
  String get doctorFallback => 'மருத்துவர்';

  @override
  String get startNewConsultation => 'புதிய ஆலோசனையைத் தொடங்கு';

  @override
  String get startNewConsultationSubtitle =>
      'நோயாளி வருகையைப் பதிவு செய்து படியெடு';

  @override
  String get newPatient => 'புதிய நோயாளி';

  @override
  String get findPatient => 'நோயாளியைத் தேடு';

  @override
  String get allPatients => 'அனைத்து நோயாளிகள்';

  @override
  String get recentPatients => 'சமீபத்திய நோயாளிகள்';

  @override
  String get seeAll => 'அனைத்தையும் பார்';

  @override
  String get noPatientsYet => 'இதுவரை நோயாளிகள் இல்லை';

  @override
  String get noPatientsYetSubtitle =>
      'உங்கள் முதல் நோயாளியைச் சேர்க்க ஆலோசனையைத் தொடங்குங்கள்.';

  @override
  String get securityFooter =>
      'பாதுகாப்பானது - HIPAA இணக்கம் - எண்ட்-டு-எண்ட் என்க்ரிப்ஷன்';

  @override
  String get male => 'ஆண்';

  @override
  String get female => 'பெண்';

  @override
  String get other => 'மற்றவை';

  @override
  String get years => 'வயது';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get settingsSubtitle => 'உங்கள் ஆப் விருப்பங்களை நிர்வகிக்கவும்';

  @override
  String get sectionAccount => 'கணக்கு';

  @override
  String get sectionPreferences => 'விருப்பங்கள்';

  @override
  String get sectionDataPrivacy => 'தரவு & தனியுரிமை';

  @override
  String get sectionSupport => 'ஆதரவு';

  @override
  String get profileSettings => 'சுயவிவர அமைப்புகள்';

  @override
  String get profileSettingsSubtitle =>
      'பெயர், தகுதிகள், பதிவு & மருத்துவமனை விவரங்கள்';

  @override
  String get profileUpdated => 'சுயவிவரம் புதுப்பிக்கப்பட்டது';

  @override
  String get darkMode => 'டார்க் மோட்';

  @override
  String get darkThemeActive => 'டார்க் தீம் செயலில்';

  @override
  String get lightThemeActive => 'லைட் தீம் செயலில்';

  @override
  String get appLanguage => 'ஆப் மொழி';

  @override
  String get appLanguageSubtitle =>
      'ஆப் இடைமுகத்தின் மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get chooseLanguage => 'மொழியைத் தேர்ந்தெடு';

  @override
  String get exportData => 'தரவை ஏற்றுமதி செய்';

  @override
  String get backupTitle => 'பேக்அப் & ஒத்திசைவு';

  @override
  String get backupIntro =>
      'உங்கள் பதிவுகளின் நகலை உங்கள் சொந்த தனிப்பட்ட கிளவுட் கோப்புறையில் வைக்கிறது, இந்த ஃபோன் தொலைந்தாலும் எதுவும் இழக்கப்படாது.';

  @override
  String get backupIncludes =>
      'அடங்கும்: நோயாளிகள், ஆலோசனைகள், மருந்துச்சீட்டுகள், அறிக்கை புகைப்படங்கள், உங்கள் சுயவிவரம் மற்றும் கையொப்பம்.';

  @override
  String get backupExcludes =>
      'அடங்காது: ஆலோசனை பதிவுகள் (செயலாக்கத்திற்குப் பிறகு அவை நீக்கப்படும்).';

  @override
  String backupLastAt(String time) {
    return 'கடைசி பேக்அப் $time';
  }

  @override
  String get backupNever => 'இதுவரை பேக்அப் இல்லை';

  @override
  String get backupNow => 'இப்போது பேக்அப் எடுக்கவும்';

  @override
  String backupLatestRemote(String time, String size) {
    return 'கிளவுட்டில் சமீபத்தியது: $time ($size)';
  }

  @override
  String get backupNoRemote => 'கிளவுட்டில் இன்னும் பேக்அப் இல்லை';

  @override
  String get backupRestoreLatest => 'சமீபத்திய பேக்அப்பை மீட்டெடுக்கவும்';

  @override
  String get backupRestoreConfirmTitle => 'இந்த ஃபோனின் தரவை மாற்றவா?';

  @override
  String backupRestoreConfirmBody(String time) {
    return 'இந்த ஃபோனில் உள்ள உங்கள் பதிவுகள் $time பேக்அப்பால் மாற்றப்படும். இந்த ஃபோனைப் பயன்படுத்தும் மற்ற மருத்துவர்கள் பாதிக்கப்பட மாட்டார்கள். இதை மீட்டெடுக்க முடியாது.';
  }

  @override
  String get backupRestoreConfirm => 'மீட்டெடு';

  @override
  String get backupStageCollecting => 'உங்கள் பதிவுகள் சேகரிக்கப்படுகின்றன…';

  @override
  String get backupStageZipping => 'தொகுக்கப்படுகிறது…';

  @override
  String get backupStageUploading => 'பதிவேற்றப்படுகிறது…';

  @override
  String get backupStageDownloading => 'பேக்அப் பதிவிறக்கப்படுகிறது…';

  @override
  String get backupStageRestoring => 'மீட்டெடுக்கப்படுகிறது…';

  @override
  String get backupDone => 'பேக்அப் முடிந்தது';

  @override
  String get backupRestored => 'பேக்அப் மீட்டெடுக்கப்பட்டது';

  @override
  String get backupRestartHint =>
      'மீட்டெடுக்கப்பட்ட பதிவுகளைக் காண ஆப்ஸை மூடி மீண்டும் திறக்கவும்.';

  @override
  String backupFailed(String reason) {
    return 'பேக்அப் தோல்வி: $reason';
  }

  @override
  String backupRestoreFailed(String reason) {
    return 'மீட்டெடுப்பு தோல்வி: $reason';
  }

  @override
  String get backupNeedsInternet => 'பேக்அப் எடுக்க இணையத்துடன் இணைக்கவும்.';

  @override
  String get exportPreparing => 'உங்கள் ஏற்றுமதி தயாராகிறது…';

  @override
  String get exportShareSubject => 'Rxvarta தரவு ஏற்றுமதி';

  @override
  String get exportShareText => 'எனது Rxvarta பதிவுகளின் ஏற்றுமதி.';

  @override
  String exportFailed(String reason) {
    return 'தரவை ஏற்றுமதி செய்ய முடியவில்லை: $reason';
  }

  @override
  String get exportEmpty => 'ஏற்றுமதி செய்ய இன்னும் எதுவும் இல்லை.';

  @override
  String exportSavedTo(String path) {
    return '$path இல் சேமிக்கப்பட்டது';
  }

  @override
  String get privacySecurity => 'தனியுரிமை & பாதுகாப்பு';

  @override
  String get termsConditions => 'விதிமுறைகள் & நிபந்தனைகள்';

  @override
  String get termsConditionsSubtitle => 'எங்கள் சேவை விதிமுறைகளைப் படிக்கவும்';

  @override
  String get helpSupport => 'உதவி & ஆதரவு';

  @override
  String get helpSupportSubtitle =>
      'உதவி பெறுங்கள் அல்லது எங்களைத் தொடர்பு கொள்ளுங்கள்';

  @override
  String get settingsProfileSetUp => 'உங்கள் சுயவிவரத்தை அமைக்கவும்';

  @override
  String get settingsProfileIncompleteChip =>
      'சுயவிவரம் முழுமையடையவில்லை — மருந்துச்சீட்டுகளில் கையொப்பமிட முடியாது';

  @override
  String get settingsSignature => 'கையொப்பம்';

  @override
  String get settingsSignatureSubtitleAdded =>
      'சேர்க்கப்பட்டது — நீங்கள் கையொப்பமிடும் ஒவ்வொரு மருந்துச்சீட்டிலும் அச்சிடப்படும்';

  @override
  String get settingsSignatureSubtitleMissing => 'இன்னும் சேர்க்கப்படவில்லை';

  @override
  String get settingsBackupSync => 'பேக்அப் & ஒத்திசைவு';

  @override
  String get settingsBackupSubtitleNever => 'இதுவரை பேக்அப் இல்லை';

  @override
  String settingsBackupSubtitleLast(String time) {
    return 'கடைசி பேக்அப் $time';
  }

  @override
  String get settingsExportSubtitle =>
      'உங்கள் அனைத்து பதிவுகளின் நகலைச் சேமிக்கவும் அல்லது பகிரவும்';

  @override
  String get settingsPrivacySubtitle =>
      'உங்கள் தரவு எங்கு இருக்கிறது, அதை எப்படி நீக்குவது';

  @override
  String get settingsSectionLegal => 'சட்டப்பூர்வம்';

  @override
  String get settingsPrivacyPolicy => 'தனியுரிமைக் கொள்கை';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'உங்கள் மற்றும் உங்கள் நோயாளிகளின் தரவு எப்படிக் கையாளப்படுகிறது';

  @override
  String settingsVersion(String version, String build) {
    return 'Rxvarta v$version ($build)';
  }

  @override
  String get settingsTimeJustNow => 'இப்போதுதான்';

  @override
  String settingsTimeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n நிமிடங்களுக்கு முன்',
      one: '1 நிமிடத்திற்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n மணி நேரத்திற்கு முன்',
      one: '1 மணி நேரத்திற்கு முன்',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n நாட்களுக்கு முன்',
      one: 'நேற்று',
    );
    return '$_temp0';
  }

  @override
  String get settingsSigningOut => 'வெளியேறுகிறது…';

  @override
  String get logoutConfirmTitle => 'வெளியேறவா?';

  @override
  String get logoutConfirmBody =>
      'Rxvarta ஐப் பயன்படுத்த மீண்டும் உள்நுழைய வேண்டும். இந்தச் சாதனத்தில் சேமித்த பதிவுகள் இங்கேயே இருக்கும்.';

  @override
  String get logoutConfirm => 'வெளியேறு';

  @override
  String get privacyIntro =>
      'நோயாளிகளின் பதிவுகள் மருத்துவரின் கட்டுப்பாட்டில் இருக்கும் வகையில் Rxvarta உருவாக்கப்பட்டுள்ளது. தரவு எங்கு வைக்கப்படுகிறது, அதை யார் செயலாக்குகிறார்கள், அதை எப்படி நீக்குவது என்பதை இந்தப் பக்கம் எளிய வார்த்தைகளில் விளக்குகிறது.';

  @override
  String get privacyWhereStoredTitle => 'உங்கள் தரவு எங்கு இருக்கிறது';

  @override
  String get privacyWhereStoredDevice =>
      'இந்தச் சாதனம் — நோயாளிகள், வருகைகள், உரைப்பதிவுகள், மருந்துச்சீட்டுகள், அறிக்கை புகைப்படங்கள் மற்றும் ஒலிப்பதிவுகள் இந்த ஃபோனில் ஆப்ஸின் தனிப்பட்ட சேமிப்பில் இருக்கும்.';

  @override
  String get privacyWhereStoredCloud =>
      'மும்பை, இந்தியா (ap-south-1) இல் ஹோஸ்ட் செய்யப்பட்ட Supabase திட்டம் — உங்கள் கணக்கு, மருத்துவர் சுயவிவரம், கையொப்பம் மற்றும் பேக்அப்கள்.';

  @override
  String get privacyWhereStoredAudio =>
      'ஒலிப்பதிவுகள் செயலாக்கத்திற்காக மட்டுமே தனிப்பட்ட சேமிப்பகத்திற்கு பதிவேற்றப்படுகின்றன, நீண்டகால சேமிப்பிற்கு அல்ல.';

  @override
  String get privacyProcessorsTitle => 'இதை யார் செயலாக்குகிறார்கள்';

  @override
  String get privacyProcessorSarvam =>
      'Sarvam AI — ஒலிப்பதிவை உரையாக மாற்றுகிறது (பேச்சு-உரை).';

  @override
  String get privacyProcessorGoogle =>
      'Google Gemini — உரைப்பதிவிலிருந்து நீங்கள் பரிசீலிக்க மருந்துச்சீட்டு வரைவை உருவாக்குகிறது.';

  @override
  String get privacyProcessorSupabase =>
      'Supabase — உள்நுழைவு, கோப்பு சேமிப்பு மற்றும் உங்கள் கணக்கின் தரவுத்தளம்.';

  @override
  String get privacyRetentionTitle => 'எவ்வளவு காலம் வைக்கப்படுகிறது';

  @override
  String get privacyRetentionAudio =>
      'ஒலிப்பதிவுகள்: செயலாக்கம் வெற்றிபெற்றவுடன் சர்வரிலிருந்து நீக்கப்படும்; அதுவரை இந்தச் சாதனத்தில் இருக்கும்.';

  @override
  String get privacyRetentionTranscript =>
      'உரைப்பதிவுகளும் மருந்துச்சீட்டுகளும்: நீங்கள் நீக்கும் வரை இந்தச் சாதனத்திலும் உங்கள் பேக்அப்களிலும் இருக்கும்.';

  @override
  String get privacyRetentionJobs =>
      'செயலாக்க தேக்ககம்: முடிவு ஆப்ஸுக்கு வழங்கப்பட்ட பிறகு அழிக்கப்படும்.';

  @override
  String get privacyRoleTitle => 'உங்கள் பங்கும் எங்கள் பங்கும்';

  @override
  String get privacyRoleBody =>
      'டிஜிட்டல் தனிநபர் தரவு பாதுகாப்புச் சட்டம், 2023 இன் கீழ் உங்கள் நோயாளிகளின் பதிவுகளுக்கான தரவு நம்பிக்கையாளராக நீங்கள், அதாவது மருத்துவரே, இருக்கிறீர்கள். Rxvarta அவற்றை உங்கள் அறிவுறுத்தலின் பேரில் மட்டுமே, தரவு செயலாக்குநராகச் செயலாக்குகிறது.';

  @override
  String get privacySecurityTitle => 'பாதுகாப்பு நடவடிக்கைகள்';

  @override
  String get privacySecurityBody =>
      'தரவு மறையாக்கப்பட்ட இணைப்புகள் (TLS) வழியாகச் செல்கிறது. சர்வரில் உள்ள பதிவுகள் ஒவ்வொரு கணக்குக்கும் தனித்தனி அணுகல் விதிகளால் பாதுகாக்கப்படுகின்றன, எனவே உங்கள் உள்நுழைவால் மட்டுமே அவற்றைப் படிக்க முடியும். உங்கள் ஃபோனைப் பூட்டி வைக்கவும்: அதைத் திறக்கக்கூடிய எவரும் ஆப்ஸைத் திறக்க முடியும்.';

  @override
  String get privacyDeleteTitle => 'தரவை நீக்குதல்';

  @override
  String get privacyDeleteBody =>
      'இந்த ஃபோனிலிருந்து உங்கள் தரவை அகற்ற கீழே உள்ள பொத்தானைப் பயன்படுத்தவும். இந்த ஃபோனில் உள்நுழையும் மற்ற மருத்துவர்களின் தரவு அப்படியே இருக்கும். நோயாளர் பதிவுகளை இன்னும் ஒவ்வொன்றாக நீக்க முடியாது. உங்கள் கணக்கையும் எங்கள் சர்வர்களில் உள்ள தரவையும் நீக்க, நீங்கள் பதிவு செய்த மின்னஞ்சல் முகவரியிலிருந்து எங்களுக்கு எழுதுங்கள்.';

  @override
  String get privacyDeleteLocal => 'இந்தச் சாதனத்திலிருந்து என் தரவை நீக்கவும்';

  @override
  String get privacyDeleteLocalSubtitle =>
      'இந்த ஃபோனிலிருந்து உங்கள் நோயாளிகள், வருகைகள், ஒலிப்பதிவுகள், அறிக்கைகள், சுயவிவர தேக்ககம் மற்றும் கையொப்பத்தை அகற்றி உங்களை வெளியேற்றும். சர்வரில் உள்ள உங்கள் கணக்கும் பேக்அப்களும் பாதிக்கப்படாது.';

  @override
  String privacyDeleteLocalBody(String word) {
    return 'இந்த ஃபோனில் சேமிக்கப்பட்ட உங்கள் ஒவ்வொரு நோயாளி, வருகை, ஒலிப்பதிவு மற்றும் அறிக்கை அகற்றப்படும், நீங்கள் வெளியேற்றப்படுவீர்கள். இந்த ஃபோனில் உள்ள மற்ற மருத்துவர்களின் தரவும் சர்வரில் உள்ள உங்கள் பேக்அப்களும் பாதிக்கப்படாது. இதை மீட்டெடுக்க முடியாது.\n\nஉறுதிப்படுத்த $word என தட்டச்சு செய்யவும்.';
  }

  @override
  String get privacyDeleteLocalWord => 'DELETE';

  @override
  String privacyDeleteLocalHint(String word) {
    return '$word எனத் தட்டச்சு செய்யவும்';
  }

  @override
  String get privacyDeleteLocalConfirm => 'அனைத்தையும் நீக்கு';

  @override
  String get privacyDeleting => 'உள்ளூர் தரவு நீக்கப்படுகிறது…';

  @override
  String get privacyDeleted => 'உள்ளூர் தரவு நீக்கப்பட்டது';

  @override
  String privacyDeletePartial(String details) {
    return 'சில உருப்படிகளை நீக்க முடியவில்லை: $details';
  }

  @override
  String get privacyReadPolicy => 'முழு தனியுரிமைக் கொள்கையைப் படிக்கவும்';

  @override
  String get legalTerms => 'விதிமுறைகள் & நிபந்தனைகள்';

  @override
  String get legalPrivacyPolicy => 'தனியுரிமைக் கொள்கை';

  @override
  String legalLastUpdated(String date) {
    return 'கடைசியாகப் புதுப்பிக்கப்பட்டது: $date';
  }

  @override
  String get legalReviewNotice =>
      'ஆப்ஸுடன் வந்த நகல் — ஆஃப்லைனில் கிடைக்கும். ஆன்லைனில் புதிய பதிப்பு வெளியிடப்பட்டால், ஆன்லைன் பதிப்பே பொருந்தும்.';

  @override
  String get legalViewOnline => 'ஆன்லைன் பதிப்பைக் காண்க';

  @override
  String get legalLoadFailed => 'இந்த ஆவணத்தை ஏற்ற முடியவில்லை.';

  @override
  String get helpTitle => 'உதவி & ஆதரவு';

  @override
  String get helpSubtitle =>
      'ஆப்ஸ் குறித்த கேள்விகள், கருத்துகள் அல்லது சிக்கலா? உதவ நாங்கள் தயார்.';

  @override
  String helpVersion(String version, String build) {
    return 'ஆப்ஸ் பதிப்பு $version ($build)';
  }

  @override
  String get helpEmail => 'மின்னஞ்சல் ஆதரவு';

  @override
  String get helpWhatsapp => 'WhatsApp ஆதரவு';

  @override
  String get helpReportProblem => 'சிக்கலைத் தெரிவிக்கவும்';

  @override
  String get helpReportProblemSubtitle =>
      'என்ன நடந்தது, அதை மீண்டும் எப்படிப் பார்ப்பது என்பதைச் சொல்லுங்கள்';

  @override
  String get helpNotConfigured => 'ஆதரவுத் தொடர்பு இன்னும் அமைக்கப்படவில்லை';

  @override
  String get helpCouldNotOpen => 'இதை உங்கள் சாதனத்தில் திறக்க முடியவில்லை.';

  @override
  String get helpEmailSubject => 'Rxvarta ஆதரவு';

  @override
  String helpEmailBody(String version, String platform) {
    return 'ஆப்ஸ் பதிப்பு: $version\nதளம்: $platform\n\n';
  }

  @override
  String get helpReportSubject => 'Rxvarta — சிக்கல் அறிக்கை';

  @override
  String helpReportBody(String version, String platform) {
    return 'என்ன நடந்தது:\n\n\nமீண்டும் பார்க்கும் படிகள்:\n1. \n2. \n3. \n\nஆப்ஸ் பதிப்பு: $version\nதளம்: $platform\n';
  }

  @override
  String get logout => 'வெளியேறு';

  @override
  String get authSignIn => 'உள்நுழை';

  @override
  String get authSignInTitle => 'மீண்டும் வரவேற்கிறோம்';

  @override
  String get authSignInSubtitle => 'உங்கள் ஆலோசனைகளைத் தொடர உள்நுழையவும்.';

  @override
  String get authEmail => 'மின்னஞ்சல்';

  @override
  String get authEmailHint => 'doctor@clinic.com';

  @override
  String get authEmailInvalid => 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்';

  @override
  String get authPassword => 'கடவுச்சொல்';

  @override
  String get authPasswordHint => 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get authPasswordRequired => 'உங்கள் கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get authPasswordRules => 'குறைந்தது 8 எழுத்துகள்';

  @override
  String get authPasswordsDoNotMatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get authShowPassword => 'கடவுச்சொல்லைக் காட்டு';

  @override
  String get authHidePassword => 'கடவுச்சொல்லை மறை';

  @override
  String get authForgotPassword => 'கடவுச்சொல்லை மறந்துவிட்டீர்களா?';

  @override
  String get authNoAccount => 'Rxvarta க்குப் புதியவரா?';

  @override
  String get authCreateAccount => 'கணக்கை உருவாக்கு';

  @override
  String get authHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா?';

  @override
  String get authSignUpTitle => 'உங்கள் கணக்கை உருவாக்கவும்';

  @override
  String get authSignUpSubtitle =>
      'ஒவ்வொரு மருத்துவருக்கும் ஒரு கணக்கு. உங்கள் நோயாளிகளும் மருந்துச்சீட்டுகளும் உங்களுக்கு மட்டுமே தனிப்பட்டவை.';

  @override
  String get authConfirmPassword => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get authSignInInstead => 'அதற்குப் பதிலாக உள்நுழையவும்';

  @override
  String get authVerifyTitle => 'உங்கள் மின்னஞ்சலைப் பாருங்கள்';

  @override
  String authVerifyBody(String email) {
    return '$email க்கு 8 இலக்கக் குறியீட்டை அனுப்பியுள்ளோம். தொடர அதை கீழே உள்ளிடவும்.';
  }

  @override
  String get authCode => 'சரிபார்ப்புக் குறியீடு';

  @override
  String get authCodeIncomplete => 'குறியீட்டின் 8 இலக்கங்களையும் உள்ளிடவும்';

  @override
  String get authVerify => 'சரிபார்';

  @override
  String get authResendCode => 'குறியீட்டை மீண்டும் அனுப்பு';

  @override
  String authResendIn(int seconds) {
    return '$seconds வினாடிகளில் குறியீட்டை மீண்டும் அனுப்பு';
  }

  @override
  String get authCodeSent =>
      'உங்கள் மின்னஞ்சலுக்குப் புதிய குறியீடு அனுப்பப்பட்டது.';

  @override
  String get authForgotTitle => 'உங்கள் கடவுச்சொல்லை மீட்டமைக்கவும்';

  @override
  String get authForgotSubtitle =>
      'நீங்கள் பதிவு செய்த மின்னஞ்சலை உள்ளிடவும், உங்களுக்குக் குறியீட்டை அனுப்புவோம்.';

  @override
  String get authSendCode => 'குறியீட்டை அனுப்பு';

  @override
  String get authResetTitle => 'புதிய கடவுச்சொல்லைத் தேர்வுசெய்யவும்';

  @override
  String get authResetSubtitle =>
      'Rxvarta இல் இதற்கு முன் பயன்படுத்தாத கடவுச்சொல்லைப் பயன்படுத்தவும்.';

  @override
  String get authNewPassword => 'புதிய கடவுச்சொல்';

  @override
  String get authUpdatePassword => 'கடவுச்சொல்லைப் புதுப்பி';

  @override
  String get authPasswordUpdated => 'கடவுச்சொல் புதுப்பிக்கப்பட்டது';

  @override
  String get authBackToSignIn => 'உள்நுழைவுக்குத் திரும்பு';

  @override
  String get authBack => 'பின்';

  @override
  String get authNotConfiguredTitle => 'ஆப்ஸ் கட்டமைக்கப்படவில்லை';

  @override
  String get authNotConfiguredBody =>
      'இந்த பில்டில் பின்தள இணைப்பு இல்லை, எனவே உள்நுழைவு கிடைக்காது. ஆப்ஸை --dart-define-from-file=config/app_config.json உடன் பில்ட் செய்யவும் (README ஐப் பார்க்கவும்).';

  @override
  String get authSplashLoading => 'உங்கள் பணியிடம் தயாராகிறது…';

  @override
  String get authSecureNote =>
      'மறையாக்கப்பட்டது, உங்கள் கணக்குக்கு மட்டுமே தனிப்பட்டது.';

  @override
  String get authErrorInvalidCredentials =>
      'மின்னஞ்சல் அல்லது கடவுச்சொல் தவறு.';

  @override
  String get authErrorEmailNotConfirmed =>
      'முதலில் உங்கள் மின்னஞ்சல் முகவரியைச் சரிபார்க்கவும்.';

  @override
  String get authErrorUserExists =>
      'இந்த மின்னஞ்சலுடன் ஏற்கனவே ஒரு கணக்கு உள்ளது.';

  @override
  String get authErrorWeakPassword =>
      'வலுவான கடவுச்சொல்லைத் தேர்வுசெய்யவும்: குறைந்தது 8 எழுத்துகள், தற்போதையதிலிருந்து வேறுபட்டது.';

  @override
  String get authErrorOtpExpired =>
      'இந்தக் குறியீட்டின் காலம் முடிந்தது. புதியதைக் கோரவும்.';

  @override
  String get authErrorOtpInvalid =>
      'அந்தக் குறியீடு சரியில்லை. சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authErrorRateLimited =>
      'அதிக முயற்சிகள். ஒரு நிமிடம் காத்திருந்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authErrorNetwork =>
      'இணைய இணைப்பு இல்லை. உங்கள் நெட்வொர்க்கைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authErrorSignupDisabled =>
      'புதிய பதிவுகள் தற்போது முடக்கப்பட்டுள்ளன.';

  @override
  String get authErrorValidation =>
      'நீங்கள் உள்ளிட்ட விவரங்களைச் சரிபார்க்கவும்.';

  @override
  String get authErrorNotConfigured =>
      'ஆப்ஸ் எந்தப் பின்தளத்துடனும் இணைக்கப்படவில்லை.';

  @override
  String get authErrorUnknown => 'ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get authErrorDetails => 'விவரங்கள்';

  @override
  String get regPrefix => 'பதிவு';

  @override
  String get allRightsReserved => 'அனைத்து உரிமைகளும் பாதுகாக்கப்பட்டவை';

  @override
  String get editProfile => 'சுயவிவரத்தைத் திருத்து';

  @override
  String get editProfileSubtitle => 'மருந்துச்சீட்டு லெட்டர்ஹெட்டில் தோன்றும்.';

  @override
  String get doctorName => 'மருத்துவர் பெயர்';

  @override
  String get qualifications => 'தகுதிகள்';

  @override
  String get registrationNumber => 'பதிவு எண்';

  @override
  String get clinicName => 'மருத்துவமனை பெயர்';

  @override
  String get clinicAddress => 'மருத்துவமனை முகவரி';

  @override
  String get clinicPhone => 'மருத்துவமனை தொலைபேசி';

  @override
  String get profilePhone => 'உங்கள் மொபைல் எண்';

  @override
  String get profileOptional => 'விருப்பத்தேர்வு';

  @override
  String get profileRequiredHint =>
      '* குறியிட்ட புலங்கள் ஒவ்வொரு மருந்துச்சீட்டிலும் அச்சிடப்படும், சட்டப்படி கட்டாயம்.';

  @override
  String get profileSectionDoctor => 'மருத்துவர் விவரங்கள்';

  @override
  String get profileSectionClinic => 'கிளினிக் விவரங்கள்';

  @override
  String get profileNameHint => 'எ.கா. Dr. Asha Verma';

  @override
  String get profileQualificationsHint => 'எ.கா. MBBS, MD (Medicine)';

  @override
  String get profileRegNoHint => 'மாநில மருத்துவ கவுன்சில் எண்';

  @override
  String get profilePhoneHint => '10 இலக்க மொபைல் எண்';

  @override
  String get profilePhoneInvalid => 'சரியான மொபைல் எண்ணை உள்ளிடவும்';

  @override
  String get profileClinicNameHint => 'கிளினிக் அல்லது மருத்துவமனையின் பெயர்';

  @override
  String get profileClinicAddressHint =>
      'பகுதி, நகரம், மாநிலம், அஞ்சல் குறியீடு';

  @override
  String get profileClinicPhoneHint => 'லேண்ட்லைன் அல்லது வரவேற்பு எண்';

  @override
  String get profileSavedOffline =>
      'இந்தச் சாதனத்தில் சேமிக்கப்பட்டது — ஆன்லைனில் வரும்போது ஒத்திசைக்கப்படும்';

  @override
  String get profileSaveFailed => 'சுயவிவரத்தைச் சேமிக்க முடியவில்லை';

  @override
  String get profileRetry => 'மீண்டும் முயற்சி';

  @override
  String get profileIncompleteNudgeTitle =>
      'மருந்துச்சீட்டுகளில் கையொப்பமிட உங்கள் சுயவிவரத்தை முடிக்கவும்';

  @override
  String get profileIncompleteNudgeBody =>
      'உங்கள் பெயர், பதிவு எண், கிளினிக் மற்றும் கையொப்பத்தைச் சேர்க்கவும்.';

  @override
  String get signatureTitle => 'கையொப்பம்';

  @override
  String get signatureSubtitle =>
      'நீங்கள் கையொப்பமிடும் ஒவ்வொரு மருந்துச்சீட்டிலும் அச்சிடப்படும்.';

  @override
  String get signatureAdd => 'கையொப்பத்தைச் சேர்';

  @override
  String get signatureUpdate => 'கையொப்பத்தை மாற்று';

  @override
  String get signatureDraw => 'வரை';

  @override
  String get signatureUpload => 'பதிவேற்று';

  @override
  String get signatureClear => 'அழி';

  @override
  String get signatureUse => 'இந்தக் கையொப்பத்தைப் பயன்படுத்து';

  @override
  String get signatureEmptyError => 'முதலில் உங்கள் கையொப்பத்தை வரையவும்.';

  @override
  String get signatureHint =>
      'கோட்டுக்கு மேலே விரலால் அல்லது மவுஸால் கையொப்பமிடவும்';

  @override
  String get signatureUploadHint =>
      'வெள்ளைத் தாளில் உள்ள உங்கள் கையொப்பத்தின் தெளிவான புகைப்படம் அல்லது ஸ்கேனைத் தேர்வுசெய்யவும் (PNG அல்லது JPEG).';

  @override
  String get signatureChooseImage => 'படத்தைத் தேர்வுசெய்';

  @override
  String get signatureChangeImage => 'வேறொன்றைத் தேர்வுசெய்';

  @override
  String get signatureUnsupportedFormat =>
      'PNG அல்லது JPEG படத்தைத் தேர்வுசெய்யவும்.';

  @override
  String get signatureLoadFailed => 'அந்தப் படத்தை ஏற்ற முடியவில்லை';

  @override
  String get signatureNone => 'இன்னும் கையொப்பம் இல்லை';

  @override
  String get signatureSaved => 'கையொப்பம் சேமிக்கப்பட்டது';

  @override
  String get signatureSaveFailed => 'கையொப்பத்தைச் சேமிக்க முடியவில்லை';

  @override
  String get onboardingTitle => 'உங்கள் மருந்துச்சீட்டை அமைக்கவும்';

  @override
  String get onboardingSubtitle =>
      'இந்த விவரங்கள் நீங்கள் கையொப்பமிடும் ஒவ்வொரு மருந்துச்சீட்டிலும் தோன்றும்.';

  @override
  String get onboardingStepDoctor => 'மருத்துவர்';

  @override
  String get onboardingStepClinic => 'கிளினிக்';

  @override
  String get onboardingStepSignature => 'கையொப்பம்';

  @override
  String get onboardingDoctorTitle => 'உங்கள் விவரங்கள்';

  @override
  String get onboardingDoctorBody =>
      'லெட்டர்ஹெட்டில் எப்படித் தோன்ற வேண்டுமோ அப்படியே.';

  @override
  String get onboardingClinicTitle => 'உங்கள் கிளினிக்';

  @override
  String get onboardingClinicBody =>
      'மருந்துச்சீட்டில் அச்சிடப்படும் பயிற்சியின் பெயரும் முகவரியும்.';

  @override
  String get onboardingSignatureTitle => 'உங்கள் கையொப்பம்';

  @override
  String get onboardingSignatureBody =>
      'அதை ஒரு முறை வரையவும் அல்லது புகைப்படத்தைப் பதிவேற்றவும். அது தனிப்பட்ட முறையில் சேமிக்கப்பட்டு, நீங்கள் கையொப்பமிடும் மருந்துச்சீட்டுகளில் மட்டுமே அச்சிடப்படும்.';

  @override
  String get onboardingContinue => 'தொடர்';

  @override
  String get onboardingBack => 'பின்';

  @override
  String get onboardingFinish => 'முடி';

  @override
  String get onboardingSignatureRequired =>
      'முடிக்க உங்கள் கையொப்பத்தைச் சேர்க்கவும்.';

  @override
  String get onboardingSignOut => 'வெளியேறு';

  @override
  String onboardingSignedInAs(String email) {
    return '$email ஆக உள்நுழைந்துள்ளீர்கள்';
  }

  @override
  String get signGateTitle => 'கையொப்பமிட உங்கள் சுயவிவரத்தை முடிக்கவும்';

  @override
  String get signGateBody =>
      'மருந்துச்சீட்டில் பரிந்துரைத்த மருத்துவரின் விவரங்கள் இருக்க வேண்டும். கையொப்பமிடும் முன் இவற்றைச் சேர்க்கவும்:';

  @override
  String get signGateCompleteProfile => 'சுயவிவரத்தை முடிக்கவும்';

  @override
  String get signGateOk => 'சரி';

  @override
  String get signGatePatientNameTitle => 'நோயாளியின் பெயர் இல்லை';

  @override
  String get signGatePatientNameBody =>
      'மருந்துச்சீட்டில் கையொப்பமிடும் முன் நோயாளியின் பெயரை உள்ளிடவும்.';

  @override
  String get signGateMedicineNameTitle => 'மருந்தின் பெயர் இல்லை';

  @override
  String signGateMedicineNameBody(int n) {
    return 'மருந்து $n க்குப் பெயர் இல்லை. கையொப்பமிடும் முன் பெயரை உள்ளிடவும் அல்லது அதை அகற்றவும்.';
  }

  @override
  String get pdfAwaitingSignature => 'கையொப்பத்திற்காகக் காத்திருக்கிறது';

  @override
  String get unsavedChanges => 'சேமிக்கப்படாத மாற்றங்கள்';

  @override
  String get unsavedChangesBody =>
      'சேமிக்கப்படாத மாற்றங்கள் உள்ளன. அவற்றைச் சேமிக்கவா அல்லது நிராகரிக்கவா?';

  @override
  String get discard => 'நிராகரி';

  @override
  String get save => 'சேமி';

  @override
  String get cancel => 'ரத்து';

  @override
  String get done => 'முடிந்தது';

  @override
  String get required => 'தேவை';

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navPatients => 'நோயாளிகள்';

  @override
  String get navSettings => 'அமைப்புகள்';

  @override
  String get notFound => 'கிடைக்கவில்லை';

  @override
  String get newConsultation => 'புதிய ஆலோசனை';

  @override
  String get whoIsThisFor => 'இந்த ஆலோசனை யாருக்காக?';

  @override
  String get newPatientTitle => 'புதிய நோயாளி';

  @override
  String get newPatientDesc =>
      'முதல் முறை வரும் நோயாளியின் பெயர், வயது, பாலினம் மற்றும் கைபேசி எண்ணைச் சேர்க்கவும்.';

  @override
  String get existingPatientTitle => 'ஏற்கனவே உள்ள நோயாளி';

  @override
  String get existingPatientDesc =>
      'வரலாற்றிலிருந்து நோயாளியைத் தேடி, அவர்களின் அறிக்கையைப் பார்த்து, புதிய ஆலோசனையைத் தொடங்குங்கள்.';

  @override
  String get stepDetails => 'விவரங்கள்';

  @override
  String get stepRecording => 'பதிவு';

  @override
  String get stepReview => 'மதிப்பாய்வு';

  @override
  String get stepShare => 'பகிர்';

  @override
  String get patientDetails => 'நோயாளி விவரங்கள்';

  @override
  String get enterBasicInfo => 'நோயாளியின் அடிப்படைத் தகவலை உள்ளிடவும்';

  @override
  String get confirmDetailsConsent => 'விவரங்கள் & ஒப்புதலை உறுதிப்படுத்தவும்';

  @override
  String get patientName => 'நோயாளி பெயர்';

  @override
  String get patientNameHint => 'நோயாளியின் முழுப் பெயரை உள்ளிடவும்';

  @override
  String get nameRequired => 'பெயர் தேவை';

  @override
  String get age => 'வயது';

  @override
  String get gender => 'பாலினம்';

  @override
  String get select => 'தேர்ந்தெடு';

  @override
  String get whatsappNumber => 'வாட்ஸ்அப் எண்';

  @override
  String get mobileHint => '10 இலக்க கைபேசி எண்';

  @override
  String get prescriptionShareNote =>
      'இந்த எண்ணுக்கு மருந்துச்சீட்டு அனுப்பப்படும்';

  @override
  String get previousReports => 'முந்தைய அறிக்கைகள் (விருப்பம்)';

  @override
  String get previousReportsDesc =>
      'முந்தைய அறிக்கைகளை ஸ்கேன் செய்யவும் அல்லது இணைக்கவும் — அவை மருந்துச்சீட்டு PDFஇல் சேர்க்கப்படும்.';

  @override
  String get addReport => 'அறிக்கை சேர்';

  @override
  String get takePhoto => 'புகைப்படம் எடு';

  @override
  String get chooseFromGallery => 'கேலரியிலிருந்து தேர்ந்தெடு';

  @override
  String get reportLabelHint => 'லேபிள் (எ.கா. இரத்தப் பரிசோதனை, ஜன 2)';

  @override
  String get consentLine =>
      'நோயாளி பதிவு செய்ய ஒப்புதல் அளித்துள்ளார் (DPDP சட்டம்)';

  @override
  String get continueToRecording => 'பதிவுக்குச் செல்';

  @override
  String get couldNotAddReport => 'அறிக்கையைச் சேர்க்க முடியவில்லை';

  @override
  String get couldNotSavePatient => 'நோயாளியைச் சேமிக்க முடியவில்லை';

  @override
  String get couldNotSaveChanges => 'உங்கள் மாற்றங்களைச் சேமிக்க முடியவில்லை';

  @override
  String get nothingHeardInRecording =>
      'இந்தப் பதிவில் எந்த ஆலோசனையும் கேட்கவில்லை. மைக்ரோஃபோன் இயங்குகிறதா எனச் சரிபார்த்து, மீண்டும் பதிவு செய்யவும்.';

  @override
  String get retryProcessing => 'இதே பதிவுடன் மீண்டும் முயலவும்';

  @override
  String get recordAgain => 'மீண்டும் பதிவு செய்யவும்';

  @override
  String get consultationErrorOffline =>
      'இணைய இணைப்பு இல்லை. உங்கள் பதிவு இந்த ஃபோனில் சேமிக்கப்பட்டுள்ளது; இணையம் வந்ததும் மீண்டும் முயலவும் என்பதைத் தட்டவும்.';

  @override
  String get consultationErrorProcessing =>
      'பதிவைச் செயலாக்க முடியவில்லை. இது இந்த ஃபோனில் சேமிக்கப்பட்டுள்ளது; மீண்டும் முயலவும் என்பதைத் தட்டவும்.';

  @override
  String get errorSessionExpired =>
      'உங்கள் அமர்வு காலாவதியானது. மீண்டும் உள்நுழையவும்.';

  @override
  String get consultationErrorStorage =>
      'பதிவை இந்த ஃபோனில் சேமிக்க முடியவில்லை. இலவச சேமிப்பிடத்தைச் சரிபார்த்து மீண்டும் பதிவு செய்யவும்.';

  @override
  String get errorUnexpected => 'ஏதோ தவறு நடந்தது. மீண்டும் முயலவும்.';

  @override
  String get errorOffline => 'இணைய இணைப்பு இல்லை.';

  @override
  String get errorStorage =>
      'இந்த ஃபோனில் உள்ள கோப்புகளைப் படிக்கவோ சேமிக்கவோ முடியவில்லை. இலவச சேமிப்பிடம் உள்ளதா எனப் பார்க்கவும்.';

  @override
  String get errorPermission =>
      'அனுமதி மறுக்கப்பட்டது. ஃபோன் அமைப்புகளில் Rxvarta-க்கு அனுமதி வழங்கவும்.';

  @override
  String get errorInvalidBackup =>
      'இந்தக் கோப்பு உங்கள் கணக்கிற்குப் பயன்படுத்தக்கூடிய Rxvarta பேக்அப் அல்ல.';

  @override
  String get errorBackupTooNew =>
      'இந்த பேக்அப் Rxvarta-இன் புதிய பதிப்பில் உருவாக்கப்பட்டது. ஆப்பைப் புதுப்பித்து, பிறகு மீட்டமைக்கவும்.';

  @override
  String get patientAlreadyExists => 'நோயாளி ஏற்கனவே உள்ளார்';

  @override
  String get patientExistsBody =>
      'இந்த எண்ணுடன் ஒரு நோயாளி ஏற்கனவே உங்கள் பதிவுகளில் உள்ளார்:';

  @override
  String get patientExistsQuestion =>
      'இந்த ஆலோசனையை அவர்களின் தற்போதைய வரலாற்றில் சேர்க்கவா?';

  @override
  String get createNew => 'புதிதாக உருவாக்கு';

  @override
  String get useExisting => 'ஏற்கனவே உள்ளதைப் பயன்படுத்து';

  @override
  String get consultationRecording => 'ஆலோசனை பதிவு';

  @override
  String get processingAudio => 'ஆடியோ செயலாக்கப்படுகிறது...';

  @override
  String get chooseRecordingOption => 'பதிவு விருப்பத்தைத் தேர்ந்தெடு';

  @override
  String get paused => 'இடைநிறுத்தப்பட்டது';

  @override
  String get recordingConversation => 'உரையாடல் பதிவாகிறது...';

  @override
  String get doctorPlusPatient => 'மருத்துவர் + நோயாளி';

  @override
  String get saySomething => 'ஏதாவது சொல்லுங்கள்...';

  @override
  String get readyBothVoices => 'தயார் — இரு குரல்களும் பதிவாகும்';

  @override
  String get transcribingConversation => 'உரையாடல் படியெடுக்கப்படுகிறது...';

  @override
  String get extractingPrescription =>
      'மருந்துச்சீட்டு பிரித்தெடுக்கப்படுகிறது...';

  @override
  String get recordingTip =>
      'மருத்துவருக்கும் நோயாளிக்கும் இடையே மேசையில் தொலைபேசியை வைத்து, தொடங்கு அழுத்தவும்.';

  @override
  String get addingToConsultation =>
      'ஆலோசனையில் சேர்க்கப்படுகிறது — புதிய ஆடியோ தற்போதைய படியெடுப்புடன் இணைக்கப்படும்.';

  @override
  String get startConsultation => 'ஆலோசனையைத் தொடங்கு';

  @override
  String get checkingConnection => 'இணைப்பு சரிபார்க்கப்படுகிறது…';

  @override
  String get offlineReconnect => 'ஆஃப்லைன் — பதிவு செய்ய மீண்டும் இணைக்கவும்';

  @override
  String get resume => 'தொடர்';

  @override
  String get pause => 'இடைநிறுத்து';

  @override
  String get minimumFiveSeconds => 'குறைந்தது 5 வினாடிகள் தேவை';

  @override
  String get recordingApproachingLimit => 'பதிவு வரம்பை நெருங்குகிறது';

  @override
  String get offlineNotice =>
      'இணைய இணைப்பு இல்லை. ஆலோசனையைப் படியெடுத்து செயலாக்க இணையம் தேவை.';

  @override
  String get checkingConnectionRetry =>
      'உங்கள் இணைப்பு சரிபார்க்கப்படுகிறது — சிறிது நேரம் கழித்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get internetLostStillRecording =>
      'இணையம் இல்லை. பதிவு தொடர்கிறது; இணையம் வந்ததும் ஆலோசனை செயலாக்கப்படும்.';

  @override
  String get recordingNotificationTitle => 'ஆலோசனை பதிவாகிறது';

  @override
  String get recordingNotificationText =>
      'திரை அணைந்திருந்தாலும் Rxvarta பதிவைத் தொடர்கிறது.';

  @override
  String get micPermissionNeeded =>
      'ஆலோசனையைப் பதிவு செய்ய மைக்ரோஃபோன் அனுமதி தேவை.';

  @override
  String get micAccessNeeded => 'மைக்ரோஃபோன் அணுகல் தேவை';

  @override
  String get micEnableInSettings =>
      'பதிவு செய்ய அமைப்புகளில் மைக்ரோஃபோன் அனுமதியை இயக்கவும்.';

  @override
  String get openSettings => 'அமைப்புகளைத் திற';

  @override
  String get stopRecordingGoBack => 'பதிவை நிறுத்தி திரும்பவா?';

  @override
  String get recordingWillBeLost =>
      'உங்கள் பதிவு இழக்கப்படும். இதை மீட்க முடியாது.';

  @override
  String get stopAndGoBack => 'நிறுத்தி திரும்பு';

  @override
  String get discardRecording => 'பதிவை நிராகரிக்கவா?';

  @override
  String get audioWillBeDiscarded =>
      'நீங்கள் பதிவு செய்த ஆடியோ நிராகரிக்கப்படும். இதை மீட்க முடியாது.';

  @override
  String get discardAndGoBack => 'நிராகரித்து திரும்பு';

  @override
  String get startFresh => 'புதிதாகத் தொடங்கவா?';

  @override
  String get startFreshBody => 'இது உங்கள் தற்போதைய ஆலோசனைத் தரவை மாற்றும்.';

  @override
  String get startFreshConfirm => 'புதிதாகத் தொடங்கு';

  @override
  String get existingRecordingNotice =>
      'இந்த ஆலோசனைக்கு உங்களிடம் ஏற்கனவே பதிவு உள்ளது.';

  @override
  String get duration => 'கால அளவு';

  @override
  String get addExtraConversation => 'கூடுதல் உரையாடலைச் சேர்';

  @override
  String get addExtraDesc => 'மேலும் பதிவு செய்து தற்போதைய தரவுடன் இணைக்கவும்';

  @override
  String get startNewConversation => 'புதிய உரையாடலைத் தொடங்கு';

  @override
  String get startNewDesc => 'முந்தையதை அழித்து புதிதாகப் பதிவு செய்';

  @override
  String get patientHistory => 'நோயாளி வரலாறு';

  @override
  String get viewAllConsultations =>
      'அனைத்து ஆலோசனைகள் மற்றும் பதிவுகளைப் பார்';

  @override
  String get statTotal => 'மொத்தம்';

  @override
  String get statThisWeek => 'இந்த வாரம்';

  @override
  String get statToday => 'இன்று';

  @override
  String get searchPatientsHint => 'நோயாளிகளைத் தேடு...';

  @override
  String get noPatientsFound => 'நோயாளிகள் இல்லை';

  @override
  String get noConsultationsYet => 'இதுவரை ஆலோசனைகள் இல்லை';

  @override
  String get unknownPatient => 'அறியப்படாத நோயாளி';

  @override
  String get yesterday => 'நேற்று';

  @override
  String get consultationOne => 'ஆலோசனை';

  @override
  String get consultationMany => 'ஆலோசனைகள்';

  @override
  String get findPatientTitle => 'நோயாளியைத் தேடு';

  @override
  String get searchByNameOrNumber => 'பெயர் அல்லது எண்ணால் தேடு…';

  @override
  String get noMatchingPatients => 'பொருந்தும் நோயாளிகள் இல்லை';

  @override
  String get patientFallback => 'நோயாளி';

  @override
  String get patientNotFound => 'நோயாளி கிடைக்கவில்லை';

  @override
  String get consultationHistory => 'ஆலோசனை வரலாறு';

  @override
  String get visitsWillAppearHere =>
      'இந்த நோயாளியின் வருகைப் பதிவுகள் இங்கே தோன்றும்.';

  @override
  String get signed => 'கையொப்பமிடப்பட்டது';

  @override
  String get diagnosisLabel => 'நோயறிதல்';

  @override
  String get symptomsLabel => 'அறிகுறிகள்';

  @override
  String get medicinesLabel => 'மருந்துகள்';

  @override
  String get noMedicinesRecorded => 'மருந்துகள் பதிவு செய்யப்படவில்லை.';

  @override
  String get followUpLabel => 'தொடர் சந்திப்பு';

  @override
  String get afterDaysOne => '1 நாள் கழித்து';

  @override
  String afterDaysMany(int n) {
    return '$n நாட்கள் கழித்து';
  }

  @override
  String get opening => 'திறக்கிறது…';

  @override
  String get viewPrescription => 'மருந்துச்சீட்டைப் பார்';

  @override
  String get share => 'பகிர்';

  @override
  String get couldNotSharePrescription => 'மருந்துச்சீட்டைப் பகிர முடியவில்லை';

  @override
  String get couldNotSharePdf => 'PDF பகிர முடியவில்லை';

  @override
  String get prescriptionFallback => 'மருந்துச்சீட்டு';

  @override
  String get newConsultationTooltip =>
      'இந்த நோயாளியின் அடிப்படையில் புதிய ஆலோசனையை உருவாக்கு';

  @override
  String get couldNotGeneratePrescription =>
      'மருந்துச்சீட்டை உருவாக்க முடியவில்லை';

  @override
  String get generatingPrescription => 'மருந்துச்சீட்டு உருவாக்கப்படுகிறது...';

  @override
  String get preparingPdf => 'PDF தயாராகிறது…';

  @override
  String get shareOnWhatsapp => 'வாட்ஸ்அப்பில் பகிர்';

  @override
  String get shareViaOtherApps => 'மற்ற ஆப்ஸ் மூலம் பகிர்';

  @override
  String get startNewConsultationCta => 'புதிய ஆலோசனையைத் தொடங்கு';

  @override
  String get reviewPrescription => 'மருந்துச்சீட்டு மதிப்பாய்வு';

  @override
  String get verifyDetails =>
      'படியெடுக்கப்பட்ட விவரங்களைச் சரிபார்த்துத் திருத்தவும்';

  @override
  String get reviewTitle => 'மதிப்பாய்வு';

  @override
  String get visitNotFound => 'வருகை கிடைக்கவில்லை';

  @override
  String get goBackToRecording => 'பதிவுக்குத் திரும்பவா?';

  @override
  String get goBackToRecordingBody =>
      'இந்த ஆலோசனையில் மேலும் சேர்க்கலாம் அல்லது புதிய பதிவைத் தொடங்கலாம்.';

  @override
  String get stay => 'இங்கேயே இரு';

  @override
  String get goBack => 'திரும்பு';

  @override
  String get consultationSummary => 'ஆலோசனைச் சுருக்கம்';

  @override
  String get transcriptTitle => 'படியெடுப்பு';

  @override
  String get transcriptSubtitle => 'Sarvam STT கேட்டபடி';

  @override
  String get tapToAddSummary => 'சுருக்கம் சேர்க்க பென்சிலைத் தட்டவும்';

  @override
  String get summaryHint =>
      'நோயாளி ஏன் வந்தார், திட்டம் என்ன என்பதைச் சுருக்கமாக எழுதுங்கள்';

  @override
  String get patientInformation => 'நோயாளி தகவல்';

  @override
  String get nameLabel => 'பெயர்';

  @override
  String get yearsLabel => 'ஆண்டுகள்';

  @override
  String get whatsappLabel => 'வாட்ஸ்அப்';

  @override
  String get mobileNumber => 'கைபேசி எண்';

  @override
  String get tapToSet => 'அமைக்க தட்டவும்';

  @override
  String get diagnosisHint => 'எ.கா. வைரல் காய்ச்சல்';

  @override
  String get noDiagnosisTapPencil =>
      'நோயறிதல் இல்லை — சேர்க்க பென்சிலைத் தட்டவும்';

  @override
  String get adviceTitle => 'அறிவுரை';

  @override
  String get noAdviceTapPencil =>
      'இன்னும் அறிவுரை இல்லை — சேர்க்க பென்சிலைத் தட்டவும்';

  @override
  String get adviceHint => 'பொது வழிகாட்டுதல் — வரிக்கு ஒன்று';

  @override
  String get instructionsTitle => 'அறிவுறுத்தல்கள்';

  @override
  String get noInstructionsTapPencil =>
      'இன்னும் அறிவுறுத்தல்கள் இல்லை — சேர்க்க பென்சிலைத் தட்டவும்';

  @override
  String get instructionsHint => 'மருத்துவ அறிவுறுத்தல்கள் — வரிக்கு ஒன்று';

  @override
  String get noFollowUpSet => 'தொடர் சந்திப்பு அமைக்கப்படவில்லை';

  @override
  String get daysSuffix => 'நாட்கள்';

  @override
  String get prescribedMedicines => 'பரிந்துரைக்கப்பட்ட மருந்துகள்';

  @override
  String get noMedicationsYet => 'இன்னும் மருந்துகள் பதிவு செய்யப்படவில்லை.';

  @override
  String get addMedicine => 'மருந்து சேர்';

  @override
  String get medicineLabel => 'மருந்து';

  @override
  String get removeMedicine => 'மருந்தை நீக்கு';

  @override
  String get dosageLabel => 'அளவு';

  @override
  String get durationLabel => 'கால அளவு';

  @override
  String get frequencyLabel => 'அதிர்வெண்';

  @override
  String get timingLabel => 'நேரம்';

  @override
  String get timingBeforeFood => 'உணவுக்கு முன்';

  @override
  String get timingAfterFood => 'உணவுக்குப் பின்';

  @override
  String get timingWithFood => 'உணவுடன்';

  @override
  String get timingEmptyStomach => 'வெறும் வயிற்றில்';

  @override
  String get timingBeforeBed => 'தூங்குவதற்கு முன்';

  @override
  String get timingAsDirected => 'அறிவுறுத்தலின்படி';

  @override
  String get aiDisclaimer =>
      'AI மருத்துவர் சொன்னதை மட்டுமே எடுக்கிறது. கையொப்பமிடும் முன் சுருக்கத்தையும் மருந்துகளையும் மதிப்பாய்வு செய்யவும்.';

  @override
  String get generatePdf => 'மருந்துச்சீட்டு PDF உருவாக்கு';

  @override
  String get signAndGeneratePdf => 'கையொப்பமிட்டு PDF உருவாக்கு';

  @override
  String get icdCodeTitle => 'ICD-10 குறியீடு';

  @override
  String get icdVerifyWarning =>
      'AI பரிந்துரை — இதை நம்புவதற்கு முன் குறியீட்டைச் சரிபார்க்கவும்.';

  @override
  String get icdCodeField => 'குறியீடு (எ.கா. B34.9)';

  @override
  String get descriptionField => 'விளக்கம்';

  @override
  String get icdFooterNote =>
      'இந்தக் குறியீட்டை நோயறிதலின் அடிப்படையில் AI பரிந்துரைத்தது. மருத்துவ அல்லது கட்டண பயன்பாட்டுக்கு முன் துல்லியத்தைச் சரிபார்க்கவும்.';

  @override
  String get suggestedDifferentials => 'பரிந்துரைக்கப்பட்ட வேறுபாட்டு நோயறிதல்';

  @override
  String get aiSuggestionVerify => 'AI பரிந்துரை — சரிபார்க்கவும்';

  @override
  String get differentialsBasedOn =>
      'தெரிவிக்கப்பட்ட அறிகுறிகளின் அடிப்படையில். மருத்துவர் சரிபார்க்க வேண்டும்.';

  @override
  String get accept => 'ஏற்றுக்கொள்';

  @override
  String get prescriptionReady => 'மருந்துச்சீட்டு தயார்';

  @override
  String get reviewAndShare => 'மதிப்பாய்வு செய்து நோயாளிக்கு அனுப்பு';

  @override
  String get generatingPdfLong => 'மருந்துச்சீட்டு PDF உருவாக்கப்படுகிறது…';

  @override
  String get couldNotGeneratePdf => 'PDF உருவாக்க முடியவில்லை';
}

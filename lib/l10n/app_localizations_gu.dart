// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appName => 'Rxvarta';

  @override
  String get appTagline => 'સ્માર્ટ મેડિકલ ડોક્યુમેન્ટેશન';

  @override
  String get online => 'ઓનલાઇન';

  @override
  String get offline => 'ઓફલાઇન';

  @override
  String get checking => 'તપાસી રહ્યું છે';

  @override
  String get goodMorning => 'સુપ્રભાત';

  @override
  String get goodAfternoon => 'શુભ બપોર';

  @override
  String get goodEvening => 'શુભ સાંજ';

  @override
  String get doctorFallback => 'ડૉક્ટર';

  @override
  String get startNewConsultation => 'નવી પરામર્શ શરૂ કરો';

  @override
  String get startNewConsultationSubtitle =>
      'દર્દીની મુલાકાત રેકોર્ડ અને ટ્રાન્સક્રાઇબ કરો';

  @override
  String get newPatient => 'નવો દર્દી';

  @override
  String get findPatient => 'દર્દી શોધો';

  @override
  String get allPatients => 'બધા દર્દીઓ';

  @override
  String get recentPatients => 'તાજેતરના દર્દીઓ';

  @override
  String get seeAll => 'બધું જુઓ';

  @override
  String get noPatientsYet => 'હજી કોઈ દર્દી નથી';

  @override
  String get noPatientsYetSubtitle =>
      'તમારો પ્રથમ દર્દી ઉમેરવા માટે પરામર્શ શરૂ કરો.';

  @override
  String get securityFooter =>
      'સુરક્ષિત - HIPAA સુસંગત - એન્ડ-ટુ-એન્ડ એન્ક્રિપ્ટેડ';

  @override
  String get male => 'પુરુષ';

  @override
  String get female => 'સ્ત્રી';

  @override
  String get other => 'અન્ય';

  @override
  String get years => 'વર્ષ';

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get settingsSubtitle => 'તમારી એપ્લિકેશન પસંદગીઓ સંચાલિત કરો';

  @override
  String get sectionAccount => 'ખાતું';

  @override
  String get sectionPreferences => 'પસંદગીઓ';

  @override
  String get sectionDataPrivacy => 'ડેટા અને ગોપનીયતા';

  @override
  String get sectionSupport => 'સપોર્ટ';

  @override
  String get profileSettings => 'પ્રોફાઇલ સેટિંગ્સ';

  @override
  String get profileSettingsSubtitle => 'નામ, લાયકાત, નોંધણી અને ક્લિનિક વિગતો';

  @override
  String get profileUpdated => 'પ્રોફાઇલ અપડેટ થઈ';

  @override
  String get darkMode => 'ડાર્ક મોડ';

  @override
  String get darkThemeActive => 'ડાર્ક થીમ સક્રિય';

  @override
  String get lightThemeActive => 'લાઇટ થીમ સક્રિય';

  @override
  String get appLanguage => 'એપ્લિકેશન ભાષા';

  @override
  String get appLanguageSubtitle => 'એપ્લિકેશન ઇન્ટરફેસની ભાષા પસંદ કરો';

  @override
  String get chooseLanguage => 'ભાષા પસંદ કરો';

  @override
  String get exportData => 'ડેટા નિકાસ કરો';

  @override
  String get backupTitle => 'બૅકઅપ અને સિંક';

  @override
  String get backupIntro =>
      'તમારા રેકોર્ડની એક નકલ તમારા પોતાના ખાનગી ક્લાઉડ ફોલ્ડરમાં રાખે છે, જેથી ફોન ખોવાઈ જાય તો પણ કશું જતું નથી.';

  @override
  String get backupIncludes =>
      'સમાવિષ્ટ: દર્દીઓ, પરામર્શ, પ્રિસ્ક્રિપ્શન, રિપોર્ટ ફોટા, તમારી પ્રોફાઇલ અને સહી.';

  @override
  String get backupExcludes =>
      'સમાવિષ્ટ નથી: પરામર્શના રેકોર્ડિંગ (પ્રક્રિયા પછી તે કાઢી નાખવામાં આવે છે).';

  @override
  String backupLastAt(String time) {
    return 'છેલ્લું બૅકઅપ $time';
  }

  @override
  String get backupNever => 'હજી સુધી બૅકઅપ નથી';

  @override
  String get backupNow => 'હમણાં બૅકઅપ લો';

  @override
  String backupLatestRemote(String time, String size) {
    return 'ક્લાઉડમાં નવીનતમ: $time ($size)';
  }

  @override
  String get backupNoRemote => 'ક્લાઉડમાં હજી કોઈ બૅકઅપ નથી';

  @override
  String get backupRestoreLatest => 'નવીનતમ બૅકઅપ પુનઃસ્થાપિત કરો';

  @override
  String get backupRestoreConfirmTitle => 'આ ફોનનો ડેટા બદલવો છે?';

  @override
  String backupRestoreConfirmBody(String time) {
    return 'આ ફોન પરના તમારા રેકોર્ડ $time ના બૅકઅપથી બદલાઈ જશે. આ ફોન વાપરતા બીજા ડૉક્ટરો પર તેની અસર નહીં થાય. આ પાછું લઈ શકાશે નહીં.';
  }

  @override
  String get backupRestoreConfirm => 'પુનઃસ્થાપિત કરો';

  @override
  String get backupStageCollecting => 'તમારા રેકોર્ડ એકત્ર કરાઈ રહ્યા છે…';

  @override
  String get backupStageZipping => 'પૅક કરાઈ રહ્યું છે…';

  @override
  String get backupStageUploading => 'અપલોડ થઈ રહ્યું છે…';

  @override
  String get backupStageDownloading => 'બૅકઅપ ડાઉનલોડ થઈ રહ્યું છે…';

  @override
  String get backupStageRestoring => 'પુનઃસ્થાપિત થઈ રહ્યું છે…';

  @override
  String get backupDone => 'બૅકઅપ પૂર્ણ થયું';

  @override
  String get backupRestored => 'બૅકઅપ પુનઃસ્થાપિત થયું';

  @override
  String get backupRestartHint =>
      'પુનઃસ્થાપિત રેકોર્ડ જોવા માટે ઍપ બંધ કરીને ફરી ખોલો.';

  @override
  String backupFailed(String reason) {
    return 'બૅકઅપ નિષ્ફળ: $reason';
  }

  @override
  String backupRestoreFailed(String reason) {
    return 'પુનઃસ્થાપન નિષ્ફળ: $reason';
  }

  @override
  String get backupNeedsInternet => 'બૅકઅપ લેવા માટે ઇન્ટરનેટ સાથે જોડાઓ.';

  @override
  String get exportPreparing => 'તમારી નિકાસ તૈયાર થઈ રહી છે…';

  @override
  String get exportShareSubject => 'Rxvarta ડેટા નિકાસ';

  @override
  String get exportShareText => 'મારા Rxvarta રેકોર્ડની નિકાસ.';

  @override
  String exportFailed(String reason) {
    return 'ડેટા નિકાસ કરી શકાયો નહીં: $reason';
  }

  @override
  String get exportEmpty => 'નિકાસ કરવા માટે હજી કશું નથી.';

  @override
  String exportSavedTo(String path) {
    return '$path પર સાચવ્યું';
  }

  @override
  String get privacySecurity => 'ગોપનીયતા અને સુરક્ષા';

  @override
  String get termsConditions => 'નિયમો અને શરતો';

  @override
  String get termsConditionsSubtitle => 'અમારી સેવા શરતો વાંચો';

  @override
  String get helpSupport => 'મદદ અને સપોર્ટ';

  @override
  String get helpSupportSubtitle => 'મદદ મેળવો અથવા અમારો સંપર્ક કરો';

  @override
  String get settingsProfileSetUp => 'તમારી પ્રોફાઇલ સેટ કરો';

  @override
  String get settingsProfileIncompleteChip =>
      'પ્રોફાઇલ અધૂરી — પ્રિસ્ક્રિપ્શન પર સહી કરી શકાશે નહીં';

  @override
  String get settingsSignature => 'સહી';

  @override
  String get settingsSignatureSubtitleAdded =>
      'ઉમેરાઈ — તમે સહી કરેલા દરેક પ્રિસ્ક્રિપ્શન પર છપાય છે';

  @override
  String get settingsSignatureSubtitleMissing => 'હજી ઉમેરાઈ નથી';

  @override
  String get settingsBackupSync => 'બૅકઅપ અને સિંક';

  @override
  String get settingsBackupSubtitleNever => 'હજી સુધી બૅકઅપ નથી';

  @override
  String settingsBackupSubtitleLast(String time) {
    return 'છેલ્લું બૅકઅપ $time';
  }

  @override
  String get settingsExportSubtitle =>
      'તમારા બધા રેકોર્ડની નકલ સાચવો અથવા શેર કરો';

  @override
  String get settingsPrivacySubtitle =>
      'તમારો ડેટા ક્યાં રહે છે અને તેને કેવી રીતે કાઢવો';

  @override
  String get settingsSectionLegal => 'કાનૂની';

  @override
  String get settingsPrivacyPolicy => 'ગોપનીયતા નીતિ';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'તમારા અને તમારા દર્દીઓના ડેટાનું શું થાય છે';

  @override
  String settingsVersion(String version, String build) {
    return 'Rxvarta v$version ($build)';
  }

  @override
  String get settingsTimeJustNow => 'હમણાં જ';

  @override
  String settingsTimeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n મિનિટ પહેલાં',
      one: '1 મિનિટ પહેલાં',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n કલાક પહેલાં',
      one: '1 કલાક પહેલાં',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n દિવસ પહેલાં',
      one: 'ગઈકાલે',
    );
    return '$_temp0';
  }

  @override
  String get settingsSigningOut => 'સાઇન આઉટ થઈ રહ્યું છે…';

  @override
  String get logoutConfirmTitle => 'સાઇન આઉટ કરવું છે?';

  @override
  String get logoutConfirmBody =>
      'Rxvarta વાપરવા માટે તમારે ફરી સાઇન ઇન કરવું પડશે. આ ઉપકરણ પર સાચવેલા રેકોર્ડ અહીં જ રહેશે.';

  @override
  String get logoutConfirm => 'સાઇન આઉટ';

  @override
  String get privacyIntro =>
      'Rxvarta એવી રીતે બનાવ્યું છે કે દર્દીઓના રેકોર્ડ ડૉક્ટરના નિયંત્રણમાં જ રહે. ડેટા ક્યાં રખાય છે, તેને કોણ પ્રોસેસ કરે છે અને તેને કેવી રીતે કાઢવો તે આ પાનું સરળ શબ્દોમાં સમજાવે છે.';

  @override
  String get privacyWhereStoredTitle => 'તમારો ડેટા ક્યાં રહે છે';

  @override
  String get privacyWhereStoredDevice =>
      'આ ઉપકરણ — દર્દીઓ, મુલાકાતો, ટ્રાન્સક્રિપ્ટ, પ્રિસ્ક્રિપ્શન, રિપોર્ટ ફોટા અને રેકોર્ડિંગ આ ફોનમાં ઍપના ખાનગી સ્ટોરેજમાં રહે છે.';

  @override
  String get privacyWhereStoredCloud =>
      'મુંબઈ, ભારત (ap-south-1) માં હોસ્ટ કરેલો Supabase પ્રોજેક્ટ — તમારું ખાતું, ડૉક્ટર પ્રોફાઇલ, સહી અને બૅકઅપ.';

  @override
  String get privacyWhereStoredAudio =>
      'રેકોર્ડિંગ માત્ર પ્રક્રિયા માટે ખાનગી સ્ટોરેજ બકેટમાં અપલોડ થાય છે, લાંબા ગાળાના સંગ્રહ માટે નહીં.';

  @override
  String get privacyProcessorsTitle => 'તેને કોણ પ્રોસેસ કરે છે';

  @override
  String get privacyProcessorSarvam =>
      'Sarvam AI — રેકોર્ડિંગને લખાણમાં ફેરવે છે (સ્પીચ-ટુ-ટેક્સ્ટ).';

  @override
  String get privacyProcessorGoogle =>
      'Google Gemini — ટ્રાન્સક્રિપ્ટમાંથી તમારી સમીક્ષા માટે પ્રિસ્ક્રિપ્શનનો મુસદ્દો બનાવે છે.';

  @override
  String get privacyProcessorSupabase =>
      'Supabase — સાઇન-ઇન, ફાઇલ સ્ટોરેજ અને તમારા ખાતાનું ડેટાબેઝ.';

  @override
  String get privacyRetentionTitle => 'કેટલો સમય રખાય છે';

  @override
  String get privacyRetentionAudio =>
      'રેકોર્ડિંગ: પ્રક્રિયા સફળ થતાં જ સર્વરમાંથી કાઢી નખાય છે; ત્યાં સુધી આ ઉપકરણમાં રહે છે.';

  @override
  String get privacyRetentionTranscript =>
      'ટ્રાન્સક્રિપ્ટ અને પ્રિસ્ક્રિપ્શન: તમે કાઢો નહીં ત્યાં સુધી આ ઉપકરણમાં અને તમારા બૅકઅપમાં રહે છે.';

  @override
  String get privacyRetentionJobs =>
      'પ્રક્રિયા કૅશ: પરિણામ ઍપ સુધી પહોંચ્યા પછી સાફ કરાય છે.';

  @override
  String get privacyRoleTitle => 'તમારી અને અમારી ભૂમિકા';

  @override
  String get privacyRoleBody =>
      'ડિજિટલ પર્સનલ ડેટા પ્રોટેક્શન ઍક્ટ, 2023 હેઠળ તમારા દર્દીઓના રેકોર્ડ માટે ડેટા ફિડ્યુશિયરી તમે, એટલે કે ડૉક્ટર જ, રહો છો. Rxvarta તેમને ફક્ત તમારી સૂચના મુજબ, ડેટા પ્રોસેસર તરીકે પ્રોસેસ કરે છે.';

  @override
  String get privacySecurityTitle => 'સુરક્ષા પગલાં';

  @override
  String get privacySecurityBody =>
      'ડેટા એન્ક્રિપ્ટેડ કનેક્શન (TLS) મારફતે જાય છે. સર્વર પરના રેકોર્ડ દરેક ખાતા માટે અલગ ઍક્સેસ નિયમોથી સુરક્ષિત છે, તેથી તેમને ફક્ત તમારું સાઇન-ઇન જ વાંચી શકે. તમારો ફોન લૉક રાખો: જે તેને અનલૉક કરી શકે તે ઍપ ખોલી શકે.';

  @override
  String get privacyDeleteTitle => 'ડેટા કાઢવો';

  @override
  String get privacyDeleteBody =>
      'આ ફોનમાંથી તમારો ડેટા દૂર કરવા નીચેનું બટન વાપરો. આ ફોન પર સાઇન ઇન કરતા બીજા ડૉક્ટરોનો ડેટા એમ જ રહેશે. દર્દીઓના રેકોર્ડ હજી એક-એક કરીને કાઢી શકાતા નથી. તમારું ખાતું અને અમારા સર્વર પરનો ડેટા કાઢવા માટે, જે ઇમેઇલથી સાઇન અપ કર્યું હતું તેનાથી અમને લખો.';

  @override
  String get privacyDeleteLocal => 'આ ઉપકરણમાંથી મારો ડેટા કાઢો';

  @override
  String get privacyDeleteLocalSubtitle =>
      'આ ફોનમાંથી તમારા દર્દીઓ, મુલાકાતો, રેકોર્ડિંગ, રિપોર્ટ, પ્રોફાઇલ કૅશ અને સહી દૂર કરીને તમને સાઇન આઉટ કરે છે. સર્વર પરનું તમારું ખાતું અને બૅકઅપ પ્રભાવિત થતા નથી.';

  @override
  String privacyDeleteLocalBody(String word) {
    return 'આ ફોનમાં સાચવેલા તમારા દરેક દર્દી, મુલાકાત, રેકોર્ડિંગ અને રિપોર્ટ દૂર કરવામાં આવશે અને તમે સાઇન આઉટ થઈ જશો. આ ફોન પરના બીજા ડૉક્ટરોનો ડેટા અને સર્વર પરના તમારા બૅકઅપ પ્રભાવિત થશે નહીં. આ પાછું લઈ શકાશે નહીં.\n\nખાતરી માટે $word ટાઇપ કરો.';
  }

  @override
  String get privacyDeleteLocalWord => 'DELETE';

  @override
  String privacyDeleteLocalHint(String word) {
    return '$word ટાઇપ કરો';
  }

  @override
  String get privacyDeleteLocalConfirm => 'બધું કાઢો';

  @override
  String get privacyDeleting => 'સ્થાનિક ડેટા કાઢવામાં આવી રહ્યો છે…';

  @override
  String get privacyDeleted => 'સ્થાનિક ડેટા કાઢી નાખ્યો';

  @override
  String privacyDeletePartial(String details) {
    return 'કેટલીક વસ્તુઓ કાઢી શકાઈ નહીં: $details';
  }

  @override
  String get privacyReadPolicy => 'સંપૂર્ણ ગોપનીયતા નીતિ વાંચો';

  @override
  String get legalTerms => 'નિયમો અને શરતો';

  @override
  String get legalPrivacyPolicy => 'ગોપનીયતા નીતિ';

  @override
  String legalLastUpdated(String date) {
    return 'છેલ્લે અપડેટ: $date';
  }

  @override
  String get legalReviewNotice =>
      'ઍપ સાથે આવેલી નકલ — ઑફલાઇન ઉપલબ્ધ. ઑનલાઇન નવું સંસ્કરણ પ્રકાશિત થાય તો ઑનલાઇન સંસ્કરણ લાગુ પડશે.';

  @override
  String get legalViewOnline => 'ઑનલાઇન સંસ્કરણ જુઓ';

  @override
  String get legalLoadFailed => 'આ દસ્તાવેજ લોડ કરી શકાયો નહીં.';

  @override
  String get helpTitle => 'મદદ અને સહાય';

  @override
  String get helpSubtitle =>
      'ઍપ વિશે પ્રશ્નો, સૂચનો કે તકલીફ? અમે મદદ કરવા તૈયાર છીએ.';

  @override
  String helpVersion(String version, String build) {
    return 'ઍપ સંસ્કરણ $version ($build)';
  }

  @override
  String get helpEmail => 'ઇમેઇલ સહાય';

  @override
  String get helpWhatsapp => 'WhatsApp સહાય';

  @override
  String get helpReportProblem => 'સમસ્યાની જાણ કરો';

  @override
  String get helpReportProblemSubtitle =>
      'શું થયું અને તે ફરી કેવી રીતે જોઈ શકાય તે જણાવો';

  @override
  String get helpNotConfigured => 'સહાય સંપર્ક હજી સેટ કરેલો નથી';

  @override
  String get helpCouldNotOpen => 'આ તમારા ઉપકરણ પર ખોલી શકાયું નહીં.';

  @override
  String get helpEmailSubject => 'Rxvarta સહાય';

  @override
  String helpEmailBody(String version, String platform) {
    return 'ઍપ સંસ્કરણ: $version\nપ્લેટફોર્મ: $platform\n\n';
  }

  @override
  String get helpReportSubject => 'Rxvarta — સમસ્યા અહેવાલ';

  @override
  String helpReportBody(String version, String platform) {
    return 'શું થયું:\n\n\nફરી જોવાનાં પગલાં:\n1. \n2. \n3. \n\nઍપ સંસ્કરણ: $version\nપ્લેટફોર્મ: $platform\n';
  }

  @override
  String get logout => 'લોગ આઉટ';

  @override
  String get authSignIn => 'સાઇન ઇન';

  @override
  String get authSignInTitle => 'ફરી સ્વાગત છે';

  @override
  String get authSignInSubtitle => 'તમારા પરામર્શ ચાલુ રાખવા સાઇન ઇન કરો.';

  @override
  String get authEmail => 'ઇમેઇલ';

  @override
  String get authEmailHint => 'doctor@clinic.com';

  @override
  String get authEmailInvalid => 'માન્ય ઇમેઇલ સરનામું દાખલ કરો';

  @override
  String get authPassword => 'પાસવર્ડ';

  @override
  String get authPasswordHint => 'તમારો પાસવર્ડ દાખલ કરો';

  @override
  String get authPasswordRequired => 'તમારો પાસવર્ડ દાખલ કરો';

  @override
  String get authPasswordRules => 'ઓછામાં ઓછા 8 અક્ષર';

  @override
  String get authPasswordsDoNotMatch => 'પાસવર્ડ મેળ ખાતા નથી';

  @override
  String get authShowPassword => 'પાસવર્ડ બતાવો';

  @override
  String get authHidePassword => 'પાસવર્ડ છુપાવો';

  @override
  String get authForgotPassword => 'પાસવર્ડ ભૂલી ગયા?';

  @override
  String get authNoAccount => 'Rxvarta પર નવા છો?';

  @override
  String get authCreateAccount => 'ખાતું બનાવો';

  @override
  String get authHaveAccount => 'પહેલેથી ખાતું છે?';

  @override
  String get authSignUpTitle => 'તમારું ખાતું બનાવો';

  @override
  String get authSignUpSubtitle =>
      'દરેક ડૉક્ટર માટે એક ખાતું. તમારા દર્દીઓ અને પ્રિસ્ક્રિપ્શન ફક્ત તમારા જ રહે છે.';

  @override
  String get authConfirmPassword => 'પાસવર્ડની ખાતરી કરો';

  @override
  String get authSignInInstead => 'તેના બદલે સાઇન ઇન કરો';

  @override
  String get authVerifyTitle => 'તમારો ઇમેઇલ જુઓ';

  @override
  String authVerifyBody(String email) {
    return 'અમે $email પર 8 અંકનો કોડ મોકલ્યો છે. આગળ વધવા તેને નીચે દાખલ કરો.';
  }

  @override
  String get authCode => 'ચકાસણી કોડ';

  @override
  String get authCodeIncomplete => 'કોડના બધા 8 અંક દાખલ કરો';

  @override
  String get authVerify => 'ચકાસો';

  @override
  String get authResendCode => 'કોડ ફરી મોકલો';

  @override
  String authResendIn(int seconds) {
    return '$seconds સેકન્ડમાં કોડ ફરી મોકલો';
  }

  @override
  String get authCodeSent => 'તમારા ઇમેઇલ પર નવો કોડ મોકલ્યો છે.';

  @override
  String get authForgotTitle => 'તમારો પાસવર્ડ રીસેટ કરો';

  @override
  String get authForgotSubtitle =>
      'જે ઇમેઇલથી સાઇન અપ કર્યું હતું તે દાખલ કરો, અમે તમને કોડ મોકલીશું.';

  @override
  String get authSendCode => 'કોડ મોકલો';

  @override
  String get authResetTitle => 'નવો પાસવર્ડ પસંદ કરો';

  @override
  String get authResetSubtitle =>
      'Rxvarta પર અગાઉ ન વાપર્યો હોય તેવો પાસવર્ડ વાપરો.';

  @override
  String get authNewPassword => 'નવો પાસવર્ડ';

  @override
  String get authUpdatePassword => 'પાસવર્ડ અપડેટ કરો';

  @override
  String get authPasswordUpdated => 'પાસવર્ડ અપડેટ થયો';

  @override
  String get authBackToSignIn => 'સાઇન ઇન પર પાછા જાઓ';

  @override
  String get authBack => 'પાછળ';

  @override
  String get authNotConfiguredTitle => 'ઍપ કૉન્ફિગર થયેલી નથી';

  @override
  String get authNotConfiguredBody =>
      'આ બિલ્ડમાં બૅકએન્ડ કનેક્શન નથી, તેથી સાઇન-ઇન ઉપલબ્ધ નથી. ઍપને --dart-define-from-file=config/app_config.json સાથે બિલ્ડ કરો (README જુઓ).';

  @override
  String get authSplashLoading => 'તમારું વર્કસ્પેસ તૈયાર થઈ રહ્યું છે…';

  @override
  String get authSecureNote => 'એન્ક્રિપ્ટેડ અને ફક્ત તમારા ખાતા પૂરતું.';

  @override
  String get authErrorInvalidCredentials => 'ઇમેઇલ કે પાસવર્ડ ખોટો છે.';

  @override
  String get authErrorEmailNotConfirmed =>
      'કૃપા કરીને પહેલાં તમારું ઇમેઇલ સરનામું ચકાસો.';

  @override
  String get authErrorUserExists => 'આ ઇમેઇલથી પહેલેથી એક ખાતું છે.';

  @override
  String get authErrorWeakPassword =>
      'વધુ મજબૂત પાસવર્ડ પસંદ કરો: ઓછામાં ઓછા 8 અક્ષર અને હાલના કરતાં અલગ.';

  @override
  String get authErrorOtpExpired =>
      'આ કોડની મુદત પૂરી થઈ ગઈ છે. નવો કોડ મંગાવો.';

  @override
  String get authErrorOtpInvalid => 'એ કોડ સાચો નથી. તપાસીને ફરી પ્રયાસ કરો.';

  @override
  String get authErrorRateLimited =>
      'ઘણા પ્રયાસ થયા. એક મિનિટ રાહ જોઈને ફરી પ્રયાસ કરો.';

  @override
  String get authErrorNetwork =>
      'ઇન્ટરનેટ કનેક્શન નથી. તમારું નેટવર્ક તપાસીને ફરી પ્રયાસ કરો.';

  @override
  String get authErrorSignupDisabled => 'નવા સાઇન-અપ હાલ બંધ છે.';

  @override
  String get authErrorValidation => 'કૃપા કરીને દાખલ કરેલી વિગતો તપાસો.';

  @override
  String get authErrorNotConfigured => 'ઍપ કોઈ બૅકએન્ડ સાથે જોડાયેલી નથી.';

  @override
  String get authErrorUnknown => 'કંઈક ખોટું થયું. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get authErrorDetails => 'વિગતો';

  @override
  String get regPrefix => 'નોંધ.';

  @override
  String get allRightsReserved => 'સર્વ હક્ક સ્વાધીન';

  @override
  String get editProfile => 'પ્રોફાઇલ સંપાદિત કરો';

  @override
  String get editProfileSubtitle => 'પ્રિસ્ક્રિપ્શન લેટરહેડ પર દેખાય છે.';

  @override
  String get doctorName => 'ડૉક્ટરનું નામ';

  @override
  String get qualifications => 'લાયકાત';

  @override
  String get registrationNumber => 'નોંધણી નંબર';

  @override
  String get clinicName => 'ક્લિનિક / હોસ્પિટલનું નામ';

  @override
  String get clinicAddress => 'ક્લિનિકનું સરનામું';

  @override
  String get clinicPhone => 'ક્લિનિક ફોન';

  @override
  String get profilePhone => 'તમારો મોબાઇલ નંબર';

  @override
  String get profileOptional => 'વૈકલ્પિક';

  @override
  String get profileRequiredHint =>
      '* વાળાં ખાનાં દરેક પ્રિસ્ક્રિપ્શન પર છપાય છે અને કાયદા મુજબ જરૂરી છે.';

  @override
  String get profileSectionDoctor => 'ડૉક્ટરની વિગતો';

  @override
  String get profileSectionClinic => 'ક્લિનિકની વિગતો';

  @override
  String get profileNameHint => 'દા.ત. Dr. Asha Verma';

  @override
  String get profileQualificationsHint => 'દા.ત. MBBS, MD (Medicine)';

  @override
  String get profileRegNoHint => 'રાજ્ય મેડિકલ કાઉન્સિલ નંબર';

  @override
  String get profilePhoneHint => '10 અંકનો મોબાઇલ નંબર';

  @override
  String get profilePhoneInvalid => 'માન્ય મોબાઇલ નંબર દાખલ કરો';

  @override
  String get profileClinicNameHint => 'ક્લિનિક કે હૉસ્પિટલનું નામ';

  @override
  String get profileClinicAddressHint => 'વિસ્તાર, શહેર, રાજ્ય, પિન';

  @override
  String get profileClinicPhoneHint => 'લેન્ડલાઇન કે રિસેપ્શન નંબર';

  @override
  String get profileSavedOffline =>
      'આ ઉપકરણ પર સાચવ્યું — ઑનલાઇન થતાં સિંક થશે';

  @override
  String get profileSaveFailed => 'પ્રોફાઇલ સાચવી શકાઈ નહીં';

  @override
  String get profileRetry => 'ફરી પ્રયાસ કરો';

  @override
  String get profileIncompleteNudgeTitle =>
      'પ્રિસ્ક્રિપ્શન પર સહી કરવા પ્રોફાઇલ પૂરી કરો';

  @override
  String get profileIncompleteNudgeBody =>
      'તમારું નામ, નોંધણી નંબર, ક્લિનિક અને સહી ઉમેરો.';

  @override
  String get signatureTitle => 'સહી';

  @override
  String get signatureSubtitle =>
      'તમે સહી કરેલા દરેક પ્રિસ્ક્રિપ્શન પર છપાય છે.';

  @override
  String get signatureAdd => 'સહી ઉમેરો';

  @override
  String get signatureUpdate => 'સહી બદલો';

  @override
  String get signatureDraw => 'દોરો';

  @override
  String get signatureUpload => 'અપલોડ કરો';

  @override
  String get signatureClear => 'ભૂંસો';

  @override
  String get signatureUse => 'આ સહી વાપરો';

  @override
  String get signatureEmptyError => 'કૃપા કરીને પહેલાં તમારી સહી દોરો.';

  @override
  String get signatureHint => 'લીટીની ઉપર આંગળી કે માઉસથી સહી કરો';

  @override
  String get signatureUploadHint =>
      'સફેદ કાગળ પરની તમારી સહીનો સ્પષ્ટ ફોટો કે સ્કૅન પસંદ કરો (PNG કે JPEG).';

  @override
  String get signatureChooseImage => 'છબી પસંદ કરો';

  @override
  String get signatureChangeImage => 'બીજી પસંદ કરો';

  @override
  String get signatureUnsupportedFormat =>
      'કૃપા કરીને PNG કે JPEG છબી પસંદ કરો.';

  @override
  String get signatureLoadFailed => 'એ છબી લોડ કરી શકાઈ નહીં';

  @override
  String get signatureNone => 'હજી સહી નથી';

  @override
  String get signatureSaved => 'સહી સાચવી';

  @override
  String get signatureSaveFailed => 'સહી સાચવી શકાઈ નહીં';

  @override
  String get onboardingTitle => 'તમારું પ્રિસ્ક્રિપ્શન સેટ કરો';

  @override
  String get onboardingSubtitle =>
      'આ વિગતો તમે સહી કરેલા દરેક પ્રિસ્ક્રિપ્શન પર દેખાય છે.';

  @override
  String get onboardingStepDoctor => 'ડૉક્ટર';

  @override
  String get onboardingStepClinic => 'ક્લિનિક';

  @override
  String get onboardingStepSignature => 'સહી';

  @override
  String get onboardingDoctorTitle => 'તમારી વિગતો';

  @override
  String get onboardingDoctorBody => 'લેટરહેડ પર જેમ દેખાવી જોઈએ બરાબર તેમ જ.';

  @override
  String get onboardingClinicTitle => 'તમારું ક્લિનિક';

  @override
  String get onboardingClinicBody =>
      'પ્રિસ્ક્રિપ્શન પર છપાતું પ્રૅક્ટિસનું નામ અને સરનામું.';

  @override
  String get onboardingSignatureTitle => 'તમારી સહી';

  @override
  String get onboardingSignatureBody =>
      'તેને એક વાર દોરો અથવા ફોટો અપલોડ કરો. તે ખાનગી રીતે સચવાય છે અને ફક્ત તમે સહી કરેલા પ્રિસ્ક્રિપ્શન પર છપાય છે.';

  @override
  String get onboardingContinue => 'આગળ વધો';

  @override
  String get onboardingBack => 'પાછળ';

  @override
  String get onboardingFinish => 'પૂર્ણ કરો';

  @override
  String get onboardingSignatureRequired => 'પૂર્ણ કરવા તમારી સહી ઉમેરો.';

  @override
  String get onboardingSignOut => 'સાઇન આઉટ';

  @override
  String onboardingSignedInAs(String email) {
    return '$email તરીકે સાઇન ઇન';
  }

  @override
  String get signGateTitle => 'સહી કરવા પ્રોફાઇલ પૂરી કરો';

  @override
  String get signGateBody =>
      'પ્રિસ્ક્રિપ્શન પર લખી આપનાર ડૉક્ટરની વિગતો હોવી જરૂરી છે. સહી કરતાં પહેલાં આ ઉમેરો:';

  @override
  String get signGateCompleteProfile => 'પ્રોફાઇલ પૂરી કરો';

  @override
  String get signGateOk => 'ઠીક છે';

  @override
  String get signGatePatientNameTitle => 'દર્દીનું નામ નથી';

  @override
  String get signGatePatientNameBody =>
      'પ્રિસ્ક્રિપ્શન પર સહી કરતાં પહેલાં દર્દીનું નામ દાખલ કરો.';

  @override
  String get signGateMedicineNameTitle => 'દવાનું નામ નથી';

  @override
  String signGateMedicineNameBody(int n) {
    return 'દવા $n નું કોઈ નામ નથી. સહી કરતાં પહેલાં નામ દાખલ કરો અથવા તેને દૂર કરો.';
  }

  @override
  String get pdfAwaitingSignature => 'સહીની રાહ';

  @override
  String get unsavedChanges => 'સાચવ્યા વગરના ફેરફારો';

  @override
  String get unsavedChangesBody =>
      'તમારી પાસે સાચવ્યા વગરના ફેરફારો છે. શું તમે તેમને સાચવવા માંગો છો કે કાઢી નાખવા?';

  @override
  String get discard => 'કાઢી નાખો';

  @override
  String get save => 'સાચવો';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get done => 'પૂર્ણ';

  @override
  String get required => 'જરૂરી';

  @override
  String get navHome => 'હોમ';

  @override
  String get navPatients => 'દર્દીઓ';

  @override
  String get navSettings => 'સેટિંગ્સ';

  @override
  String get notFound => 'મળ્યું નથી';

  @override
  String get newConsultation => 'નવી પરામર્શ';

  @override
  String get whoIsThisFor => 'આ પરામર્શ કોના માટે છે?';

  @override
  String get newPatientTitle => 'નવો દર્દી';

  @override
  String get newPatientDesc =>
      'પ્રથમ વખતના દર્દીનું નામ, ઉંમર, લિંગ અને મોબાઇલ નંબર ઉમેરો.';

  @override
  String get existingPatientTitle => 'હાલનો દર્દી';

  @override
  String get existingPatientDesc =>
      'ઇતિહાસમાંથી દર્દી શોધો, તેમનો રિપોર્ટ જુઓ, પછી નવી પરામર્શ શરૂ કરો.';

  @override
  String get stepDetails => 'વિગતો';

  @override
  String get stepRecording => 'રેકોર્ડિંગ';

  @override
  String get stepReview => 'સમીક્ષા';

  @override
  String get stepShare => 'શેર';

  @override
  String get patientDetails => 'દર્દીની વિગતો';

  @override
  String get enterBasicInfo => 'દર્દીની મૂળભૂત માહિતી દાખલ કરો';

  @override
  String get confirmDetailsConsent => 'વિગતો અને સંમતિની પુષ્ટિ કરો';

  @override
  String get patientName => 'દર્દીનું નામ';

  @override
  String get patientNameHint => 'દર્દીનું પૂરું નામ દાખલ કરો';

  @override
  String get nameRequired => 'નામ જરૂરી છે';

  @override
  String get age => 'ઉંમર';

  @override
  String get gender => 'લિંગ';

  @override
  String get select => 'પસંદ કરો';

  @override
  String get whatsappNumber => 'વોટ્સએપ નંબર';

  @override
  String get mobileHint => '10 અંકનો મોબાઇલ નંબર';

  @override
  String get prescriptionShareNote => 'આ નંબર પર પ્રિસ્ક્રિપ્શન મોકલવામાં આવશે';

  @override
  String get previousReports => 'અગાઉના રિપોર્ટ (વૈકલ્પિક)';

  @override
  String get previousReportsDesc =>
      'અગાઉના રિપોર્ટ સ્કેન કરો અથવા જોડો — તે પ્રિસ્ક્રિપ્શન PDFમાં ઉમેરાય છે.';

  @override
  String get addReport => 'રિપોર્ટ ઉમેરો';

  @override
  String get takePhoto => 'ફોટો લો';

  @override
  String get chooseFromGallery => 'ગેલેરીમાંથી પસંદ કરો';

  @override
  String get reportLabelHint => 'લેબલ (દા.ત. લોહી તપાસ, 2 જાન્યુઆરી)';

  @override
  String get consentLine => 'દર્દીએ રેકોર્ડિંગ માટે સંમતિ આપી છે (DPDP કાયદો)';

  @override
  String get continueToRecording => 'રેકોર્ડિંગ પર જાઓ';

  @override
  String get couldNotAddReport => 'રિપોર્ટ ઉમેરી શકાયો નથી';

  @override
  String get couldNotSavePatient => 'દર્દી સાચવી શકાયો નથી';

  @override
  String get couldNotSaveChanges => 'તમારા ફેરફારો સાચવી શકાયા નથી';

  @override
  String get nothingHeardInRecording =>
      'આ રેકોર્ડિંગમાં કોઈ પરામર્શ સંભળાયો નથી. માઇક્રોફોન કામ કરે છે કે નહીં તે તપાસો, પછી ફરી રેકોર્ડ કરો.';

  @override
  String get patientAlreadyExists => 'દર્દી પહેલેથી હાજર છે';

  @override
  String get patientExistsBody => 'આ નંબરનો દર્દી પહેલેથી તમારા રેકોર્ડમાં છે:';

  @override
  String get patientExistsQuestion =>
      'શું આ પરામર્શ તેમના હાલના ઇતિહાસમાં ઉમેરવો?';

  @override
  String get createNew => 'નવું બનાવો';

  @override
  String get useExisting => 'હાલનું વાપરો';

  @override
  String get consultationRecording => 'પરામર્શ રેકોર્ડિંગ';

  @override
  String get processingAudio => 'ઓડિયો પ્રોસેસ થઈ રહ્યું છે...';

  @override
  String get chooseRecordingOption => 'રેકોર્ડિંગ વિકલ્પ પસંદ કરો';

  @override
  String get paused => 'થોભાવેલ';

  @override
  String get recordingConversation => 'વાતચીત રેકોર્ડ થઈ રહી છે...';

  @override
  String get doctorPlusPatient => 'ડૉક્ટર + દર્દી';

  @override
  String get saySomething => 'કંઈક બોલો...';

  @override
  String get readyBothVoices => 'તૈયાર — બંને અવાજ રેકોર્ડ થશે';

  @override
  String get transcribingConversation => 'વાતચીત ટ્રાન્સક્રાઇબ થઈ રહી છે...';

  @override
  String get extractingPrescription =>
      'પ્રિસ્ક્રિપ્શન કાઢવામાં આવી રહ્યું છે...';

  @override
  String get recordingTip =>
      'ફોન ડૉક્ટર અને દર્દી વચ્ચે ટેબલ પર મૂકો, પછી સ્ટાર્ટ દબાવો.';

  @override
  String get addingToConsultation =>
      'પરામર્શમાં ઉમેરાઈ રહ્યું છે — નવો ઓડિયો હાલની ટ્રાન્સક્રિપ્ટમાં ભળશે.';

  @override
  String get startConsultation => 'પરામર્શ શરૂ કરો';

  @override
  String get checkingConnection => 'કનેક્શન તપાસાઈ રહ્યું છે…';

  @override
  String get offlineReconnect => 'ઓફલાઇન — રેકોર્ડ કરવા ફરી કનેક્ટ કરો';

  @override
  String get resume => 'ફરી શરૂ કરો';

  @override
  String get pause => 'થોભાવો';

  @override
  String get minimumFiveSeconds => 'ઓછામાં ઓછી 5 સેકન્ડ જરૂરી';

  @override
  String get recordingApproachingLimit => 'રેકોર્ડિંગ મર્યાદાની નજીક';

  @override
  String get offlineNotice =>
      'ઇન્ટરનેટ કનેક્શન નથી. પરામર્શ ટ્રાન્સક્રાઇબ અને પ્રોસેસ કરવા ઇન્ટરનેટ જરૂરી છે.';

  @override
  String get checkingConnectionRetry =>
      'તમારું કનેક્શન તપાસાઈ રહ્યું છે — કૃપા કરીને થોડી વારે ફરી પ્રયાસ કરો.';

  @override
  String get internetLostPaused =>
      'ઇન્ટરનેટ ગયું — રેકોર્ડિંગ થોભ્યું. પરામર્શ પૂરો કરવા ફરી કનેક્ટ કરો.';

  @override
  String get internetLostPauseManually =>
      'ઇન્ટરનેટ ગયું અને રેકોર્ડિંગ આપમેળે થોભ્યું નથી — કૃપા કરીને થોભાવો દબાવો.';

  @override
  String get micPermissionNeeded =>
      'પરામર્શ રેકોર્ડ કરવા માઇક્રોફોન પરવાનગી જરૂરી છે.';

  @override
  String get micAccessNeeded => 'માઇક્રોફોન ઍક્સેસ જરૂરી';

  @override
  String get micEnableInSettings =>
      'રેકોર્ડ કરવા સેટિંગ્સમાં માઇક્રોફોન પરવાનગી ચાલુ કરો.';

  @override
  String get openSettings => 'સેટિંગ્સ ખોલો';

  @override
  String get stopRecordingGoBack => 'રેકોર્ડિંગ બંધ કરીને પાછા જવું?';

  @override
  String get recordingWillBeLost =>
      'તમારું રેકોર્ડિંગ ગુમાવાશે. આ પાછું લાવી શકાતું નથી.';

  @override
  String get stopAndGoBack => 'બંધ કરી પાછા જાઓ';

  @override
  String get discardRecording => 'રેકોર્ડિંગ કાઢી નાખવું?';

  @override
  String get audioWillBeDiscarded =>
      'તમારો રેકોર્ડ કરેલો ઓડિયો કાઢી નાખવામાં આવશે. આ પાછું લાવી શકાતું નથી.';

  @override
  String get discardAndGoBack => 'કાઢી નાખી પાછા જાઓ';

  @override
  String get startFresh => 'નવેસરથી શરૂ કરવું?';

  @override
  String get startFreshBody => 'આ તમારો હાલનો પરામર્શ ડેટા બદલી નાખશે.';

  @override
  String get startFreshConfirm => 'નવેસરથી શરૂ કરો';

  @override
  String get existingRecordingNotice =>
      'આ પરામર્શ માટે તમારી પાસે પહેલેથી રેકોર્ડિંગ છે.';

  @override
  String get duration => 'અવધિ';

  @override
  String get addExtraConversation => 'વધારાની વાતચીત ઉમેરો';

  @override
  String get addExtraDesc => 'વધુ રેકોર્ડ કરો અને હાલના ડેટા સાથે ભેળવો';

  @override
  String get startNewConversation => 'નવી વાતચીત શરૂ કરો';

  @override
  String get startNewDesc => 'અગાઉનું સાફ કરી નવેસરથી રેકોર્ડ કરો';

  @override
  String get patientHistory => 'દર્દીનો ઇતિહાસ';

  @override
  String get viewAllConsultations => 'બધા પરામર્શ અને રેકોર્ડ જુઓ';

  @override
  String get statTotal => 'કુલ';

  @override
  String get statThisWeek => 'આ અઠવાડિયે';

  @override
  String get statToday => 'આજે';

  @override
  String get searchPatientsHint => 'દર્દીઓ શોધો...';

  @override
  String get noPatientsFound => 'કોઈ દર્દી મળ્યો નથી';

  @override
  String get noConsultationsYet => 'હજી કોઈ પરામર્શ નથી';

  @override
  String get unknownPatient => 'અજાણ્યો દર્દી';

  @override
  String get yesterday => 'ગઈકાલે';

  @override
  String get consultationOne => 'પરામર્શ';

  @override
  String get consultationMany => 'પરામર્શ';

  @override
  String get findPatientTitle => 'દર્દી શોધો';

  @override
  String get searchByNameOrNumber => 'નામ કે નંબરથી શોધો…';

  @override
  String get noMatchingPatients => 'મેળ ખાતા દર્દી નથી';

  @override
  String get patientFallback => 'દર્દી';

  @override
  String get patientNotFound => 'દર્દી મળ્યો નથી';

  @override
  String get consultationHistory => 'પરામર્શ ઇતિહાસ';

  @override
  String get visitsWillAppearHere =>
      'આ દર્દીની મુલાકાતોના રેકોર્ડ અહીં દેખાશે.';

  @override
  String get signed => 'સહી થયેલ';

  @override
  String get diagnosisLabel => 'નિદાન';

  @override
  String get symptomsLabel => 'લક્ષણો';

  @override
  String get medicinesLabel => 'દવાઓ';

  @override
  String get noMedicinesRecorded => 'કોઈ દવા નોંધાયેલી નથી.';

  @override
  String get followUpLabel => 'ફોલો-અપ';

  @override
  String get afterDaysOne => '1 દિવસ પછી';

  @override
  String afterDaysMany(int n) {
    return '$n દિવસ પછી';
  }

  @override
  String get opening => 'ખૂલી રહ્યું છે…';

  @override
  String get viewPrescription => 'પ્રિસ્ક્રિપ્શન જુઓ';

  @override
  String get share => 'શેર કરો';

  @override
  String get couldNotSharePrescription => 'પ્રિસ્ક્રિપ્શન શેર થઈ શક્યું નથી';

  @override
  String get couldNotSharePdf => 'PDF શેર થઈ શક્યું નથી';

  @override
  String get prescriptionFallback => 'પ્રિસ્ક્રિપ્શન';

  @override
  String get newConsultationTooltip => 'આ દર્દીના આધારે નવો પરામર્શ બનાવો';

  @override
  String get couldNotGeneratePrescription => 'પ્રિસ્ક્રિપ્શન બનાવી શકાયું નથી';

  @override
  String get generatingPrescription => 'પ્રિસ્ક્રિપ્શન બની રહ્યું છે...';

  @override
  String get preparingPdf => 'PDF તૈયાર થઈ રહ્યું છે…';

  @override
  String get shareOnWhatsapp => 'વોટ્સએપ પર શેર કરો';

  @override
  String get shareViaOtherApps => 'અન્ય એપ દ્વારા શેર કરો';

  @override
  String get startNewConsultationCta => 'નવો પરામર્શ શરૂ કરો';

  @override
  String get reviewPrescription => 'પ્રિસ્ક્રિપ્શન સમીક્ષા';

  @override
  String get verifyDetails => 'ટ્રાન્સક્રાઇબ કરેલી વિગતો ચકાસો અને સંપાદિત કરો';

  @override
  String get reviewTitle => 'સમીક્ષા';

  @override
  String get visitNotFound => 'મુલાકાત મળી નથી';

  @override
  String get goBackToRecording => 'રેકોર્ડિંગ પર પાછા જવું?';

  @override
  String get goBackToRecordingBody =>
      'તમે આ પરામર્શમાં વધુ ઉમેરી શકો છો અથવા નવું રેકોર્ડિંગ શરૂ કરી શકો છો.';

  @override
  String get stay => 'અહીં જ રહો';

  @override
  String get goBack => 'પાછા જાઓ';

  @override
  String get consultationSummary => 'પરામર્શ સારાંશ';

  @override
  String get transcriptTitle => 'ટ્રાન્સક્રિપ્ટ';

  @override
  String get transcriptSubtitle => 'Sarvam STT દ્વારા સાંભળ્યા મુજબ';

  @override
  String get tapToAddSummary => 'સારાંશ ઉમેરવા પેન્સિલ દબાવો';

  @override
  String get summaryHint => 'દર્દી કેમ આવ્યો અને યોજના ટૂંકમાં લખો';

  @override
  String get patientInformation => 'દર્દીની માહિતી';

  @override
  String get nameLabel => 'નામ';

  @override
  String get yearsLabel => 'વર્ષ';

  @override
  String get whatsappLabel => 'વોટ્સએપ';

  @override
  String get mobileNumber => 'મોબાઇલ નંબર';

  @override
  String get tapToSet => 'સેટ કરવા દબાવો';

  @override
  String get diagnosisHint => 'દા.ત. વાયરલ તાવ';

  @override
  String get noDiagnosisTapPencil => 'નિદાન નથી — ઉમેરવા પેન્સિલ દબાવો';

  @override
  String get adviceTitle => 'સલાહ';

  @override
  String get noAdviceTapPencil => 'હજી સલાહ નથી — ઉમેરવા પેન્સિલ દબાવો';

  @override
  String get adviceHint => 'સામાન્ય માર્ગદર્શન — લાઇન દીઠ એક';

  @override
  String get instructionsTitle => 'સૂચનાઓ';

  @override
  String get noInstructionsTapPencil => 'હજી સૂચનાઓ નથી — ઉમેરવા પેન્સિલ દબાવો';

  @override
  String get instructionsHint => 'ક્લિનિકલ નિર્દેશ — લાઇન દીઠ એક';

  @override
  String get noFollowUpSet => 'ફોલો-અપ સેટ નથી';

  @override
  String get daysSuffix => 'દિવસ';

  @override
  String get prescribedMedicines => 'સૂચવેલ દવાઓ';

  @override
  String get noMedicationsYet => 'હજી કોઈ દવા નોંધાયેલી નથી.';

  @override
  String get addMedicine => 'દવા ઉમેરો';

  @override
  String get medicineLabel => 'દવા';

  @override
  String get removeMedicine => 'દવા દૂર કરો';

  @override
  String get dosageLabel => 'ડોઝ';

  @override
  String get durationLabel => 'અવધિ';

  @override
  String get frequencyLabel => 'આવર્તન';

  @override
  String get timingLabel => 'સમય';

  @override
  String get timingBeforeFood => 'ભોજન પહેલાં';

  @override
  String get timingAfterFood => 'ભોજન પછી';

  @override
  String get timingWithFood => 'ભોજન સાથે';

  @override
  String get timingEmptyStomach => 'ખાલી પેટે';

  @override
  String get timingBeforeBed => 'સૂતા પહેલાં';

  @override
  String get timingAsDirected => 'સૂચના મુજબ';

  @override
  String get aiDisclaimer =>
      'AI માત્ર ડૉક્ટરે કહ્યું તે જ કાઢે છે. સહી કરતાં પહેલાં સારાંશ અને દવાઓ તપાસો.';

  @override
  String get generatePdf => 'પ્રિસ્ક્રિપ્શન PDF બનાવો';

  @override
  String get signAndGeneratePdf => 'સહી કરીને PDF બનાવો';

  @override
  String get icdCodeTitle => 'ICD-10 કોડ';

  @override
  String get icdVerifyWarning =>
      'AI સૂચન — આના પર આધાર રાખતાં પહેલાં કોડ ચકાસો.';

  @override
  String get icdCodeField => 'કોડ (દા.ત. B34.9)';

  @override
  String get descriptionField => 'વર્ણન';

  @override
  String get icdFooterNote =>
      'આ કોડ નિદાનના આધારે AI એ સૂચવ્યો છે. ક્લિનિકલ કે બિલિંગ ઉપયોગ પહેલાં ચોકસાઈ ચકાસો.';

  @override
  String get suggestedDifferentials => 'સૂચવેલ ડિફરન્શિયલ';

  @override
  String get aiSuggestionVerify => 'AI સૂચન — ચકાસો';

  @override
  String get differentialsBasedOn =>
      'નોંધાયેલા લક્ષણોના આધારે. ડૉક્ટરે ચકાસવું જરૂરી છે.';

  @override
  String get accept => 'સ્વીકારો';

  @override
  String get prescriptionReady => 'પ્રિસ્ક્રિપ્શન તૈયાર';

  @override
  String get reviewAndShare => 'સમીક્ષા કરી દર્દીને મોકલો';

  @override
  String get generatingPdfLong => 'પ્રિસ્ક્રિપ્શન PDF બની રહ્યું છે…';

  @override
  String get couldNotGeneratePdf => 'PDF બનાવી શકાયું નથી';
}

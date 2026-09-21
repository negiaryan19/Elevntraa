// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appName => 'Rxvarta';

  @override
  String get appTagline => 'స్మార్ట్ మెడికల్ డాక్యుమెంటేషన్';

  @override
  String get online => 'ఆన్‌లైన్';

  @override
  String get offline => 'ఆఫ్‌లైన్';

  @override
  String get checking => 'తనిఖీ చేస్తోంది';

  @override
  String get goodMorning => 'శుభోదయం';

  @override
  String get goodAfternoon => 'శుభ మధ్యాహ్నం';

  @override
  String get goodEvening => 'శుభ సాయంత్రం';

  @override
  String get doctorFallback => 'డాక్టర్';

  @override
  String get startNewConsultation => 'కొత్త సంప్రదింపు ప్రారంభించండి';

  @override
  String get startNewConsultationSubtitle =>
      'రోగి సందర్శనను రికార్డ్ చేసి లిప్యంతరీకరించండి';

  @override
  String get newPatient => 'కొత్త రోగి';

  @override
  String get findPatient => 'రోగిని కనుగొనండి';

  @override
  String get allPatients => 'అందరు రోగులు';

  @override
  String get recentPatients => 'ఇటీవలి రోగులు';

  @override
  String get seeAll => 'అన్నీ చూడండి';

  @override
  String get noPatientsYet => 'ఇంకా రోగులు లేరు';

  @override
  String get noPatientsYetSubtitle =>
      'మీ మొదటి రోగిని చేర్చడానికి సంప్రదింపు ప్రారంభించండి.';

  @override
  String get securityFooter =>
      'సురక్షితం - HIPAA అనుకూలం - ఎండ్-టు-ఎండ్ ఎన్‌క్రిప్టెడ్';

  @override
  String get male => 'పురుషుడు';

  @override
  String get female => 'స్త్రీ';

  @override
  String get other => 'ఇతర';

  @override
  String get years => 'సం.';

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get settingsSubtitle => 'మీ యాప్ ప్రాధాన్యతలను నిర్వహించండి';

  @override
  String get sectionAccount => 'ఖాతా';

  @override
  String get sectionPreferences => 'ప్రాధాన్యతలు';

  @override
  String get sectionDataPrivacy => 'డేటా & గోప్యత';

  @override
  String get sectionSupport => 'మద్దతు';

  @override
  String get profileSettings => 'ప్రొఫైల్ సెట్టింగ్‌లు';

  @override
  String get profileSettingsSubtitle =>
      'పేరు, అర్హతలు, నమోదు & క్లినిక్ వివరాలు';

  @override
  String get profileUpdated => 'ప్రొఫైల్ నవీకరించబడింది';

  @override
  String get darkMode => 'డార్క్ మోడ్';

  @override
  String get darkThemeActive => 'డార్క్ థీమ్ యాక్టివ్';

  @override
  String get lightThemeActive => 'లైట్ థీమ్ యాక్టివ్';

  @override
  String get appLanguage => 'యాప్ భాష';

  @override
  String get appLanguageSubtitle => 'యాప్ ఇంటర్‌ఫేస్ భాషను ఎంచుకోండి';

  @override
  String get chooseLanguage => 'భాషను ఎంచుకోండి';

  @override
  String get exportData => 'డేటాను ఎగుమతి చేయండి';

  @override
  String get backupTitle => 'బ్యాకప్ & సింక్';

  @override
  String get backupIntro =>
      'మీ రికార్డుల కాపీని మీ స్వంత ప్రైవేట్ క్లౌడ్ ఫోల్డర్‌లో ఉంచుతుంది, ఫోన్ పోయినా ఏదీ పోదు.';

  @override
  String get backupIncludes =>
      'చేర్చినవి: రోగులు, కన్సల్టేషన్లు, ప్రిస్క్రిప్షన్లు, రిపోర్ట్ ఫోటోలు, మీ ప్రొఫైల్ మరియు సంతకం.';

  @override
  String get backupExcludes =>
      'చేర్చనివి: కన్సల్టేషన్ రికార్డింగ్‌లు (ప్రాసెసింగ్ తర్వాత అవి తొలగించబడతాయి).';

  @override
  String backupLastAt(String time) {
    return 'చివరి బ్యాకప్ $time';
  }

  @override
  String get backupNever => 'ఇంకా బ్యాకప్ లేదు';

  @override
  String get backupNow => 'ఇప్పుడే బ్యాకప్ చేయండి';

  @override
  String backupLatestRemote(String time, String size) {
    return 'క్లౌడ్‌లో తాజాది: $time ($size)';
  }

  @override
  String get backupNoRemote => 'క్లౌడ్‌లో ఇంకా బ్యాకప్ లేదు';

  @override
  String get backupRestoreLatest => 'తాజా బ్యాకప్‌ను పునరుద్ధరించండి';

  @override
  String get backupRestoreConfirmTitle => 'ఈ ఫోన్‌లోని డేటాను మార్చాలా?';

  @override
  String backupRestoreConfirmBody(String time) {
    return 'ఈ ఫోన్‌లోని మీ రికార్డులు $time నాటి బ్యాకప్‌తో భర్తీ చేయబడతాయి. ఈ ఫోన్‌ను ఉపయోగించే ఇతర వైద్యులపై దీని ప్రభావం ఉండదు. దీన్ని వెనక్కి తీసుకోలేరు.';
  }

  @override
  String get backupRestoreConfirm => 'పునరుద్ధరించు';

  @override
  String get backupStageCollecting => 'మీ రికార్డులను సేకరిస్తోంది…';

  @override
  String get backupStageZipping => 'ప్యాక్ చేస్తోంది…';

  @override
  String get backupStageUploading => 'అప్‌లోడ్ అవుతోంది…';

  @override
  String get backupStageDownloading => 'బ్యాకప్ డౌన్‌లోడ్ అవుతోంది…';

  @override
  String get backupStageRestoring => 'పునరుద్ధరిస్తోంది…';

  @override
  String get backupDone => 'బ్యాకప్ పూర్తయింది';

  @override
  String get backupRestored => 'బ్యాకప్ పునరుద్ధరించబడింది';

  @override
  String get backupRestartHint =>
      'పునరుద్ధరించిన రికార్డులను చూడటానికి యాప్‌ను మూసి మళ్లీ తెరవండి.';

  @override
  String backupFailed(String reason) {
    return 'బ్యాకప్ విఫలమైంది: $reason';
  }

  @override
  String backupRestoreFailed(String reason) {
    return 'పునరుద్ధరణ విఫలమైంది: $reason';
  }

  @override
  String get backupNeedsInternet =>
      'బ్యాకప్ చేయడానికి ఇంటర్నెట్‌కు కనెక్ట్ అవ్వండి.';

  @override
  String get exportPreparing => 'మీ ఎగుమతి సిద్ధమవుతోంది…';

  @override
  String get exportShareSubject => 'Rxvarta డేటా ఎగుమతి';

  @override
  String get exportShareText => 'నా Rxvarta రికార్డుల ఎగుమతి.';

  @override
  String exportFailed(String reason) {
    return 'డేటాను ఎగుమతి చేయలేకపోయాం: $reason';
  }

  @override
  String get exportEmpty => 'ఎగుమతి చేయడానికి ఇంకా ఏమీ లేదు.';

  @override
  String exportSavedTo(String path) {
    return '$path వద్ద సేవ్ చేయబడింది';
  }

  @override
  String get privacySecurity => 'గోప్యత & భద్రత';

  @override
  String get termsConditions => 'నిబంధనలు & షరతులు';

  @override
  String get termsConditionsSubtitle => 'మా సేవా నిబంధనలను చదవండి';

  @override
  String get helpSupport => 'సహాయం & మద్దతు';

  @override
  String get helpSupportSubtitle => 'సహాయం పొందండి లేదా మమ్మల్ని సంప్రదించండి';

  @override
  String get settingsProfileSetUp => 'మీ ప్రొఫైల్‌ను సెట్ చేయండి';

  @override
  String get settingsProfileIncompleteChip =>
      'ప్రొఫైల్ అసంపూర్ణం — ప్రిస్క్రిప్షన్లపై సంతకం చేయలేరు';

  @override
  String get settingsSignature => 'సంతకం';

  @override
  String get settingsSignatureSubtitleAdded =>
      'జోడించబడింది — మీరు సంతకం చేసే ప్రతి ప్రిస్క్రిప్షన్‌పై ముద్రితమవుతుంది';

  @override
  String get settingsSignatureSubtitleMissing => 'ఇంకా జోడించలేదు';

  @override
  String get settingsBackupSync => 'బ్యాకప్ & సింక్';

  @override
  String get settingsBackupSubtitleNever => 'ఇంకా బ్యాకప్ లేదు';

  @override
  String settingsBackupSubtitleLast(String time) {
    return 'చివరి బ్యాకప్ $time';
  }

  @override
  String get settingsExportSubtitle =>
      'మీ అన్ని రికార్డుల కాపీని సేవ్ చేయండి లేదా షేర్ చేయండి';

  @override
  String get settingsPrivacySubtitle =>
      'మీ డేటా ఎక్కడ ఉంటుంది మరియు దాన్ని ఎలా తొలగించాలి';

  @override
  String get settingsSectionLegal => 'చట్టపరమైనవి';

  @override
  String get settingsPrivacyPolicy => 'గోప్యతా విధానం';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'మీ మరియు మీ రోగుల డేటా ఎలా నిర్వహించబడుతుంది';

  @override
  String settingsVersion(String version, String build) {
    return 'Rxvarta v$version ($build)';
  }

  @override
  String get settingsTimeJustNow => 'ఇప్పుడే';

  @override
  String settingsTimeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n నిమిషాల క్రితం',
      one: '1 నిమిషం క్రితం',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n గంటల క్రితం',
      one: '1 గంట క్రితం',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n రోజుల క్రితం',
      one: 'నిన్న',
    );
    return '$_temp0';
  }

  @override
  String get settingsSigningOut => 'సైన్ అవుట్ అవుతోంది…';

  @override
  String get logoutConfirmTitle => 'సైన్ అవుట్ చేయాలా?';

  @override
  String get logoutConfirmBody =>
      'Rxvarta ఉపయోగించడానికి మీరు మళ్లీ సైన్ ఇన్ చేయాలి. ఈ పరికరంలో సేవ్ అయిన రికార్డులు ఇక్కడే ఉంటాయి.';

  @override
  String get logoutConfirm => 'సైన్ అవుట్';

  @override
  String get privacyIntro =>
      'రోగుల రికార్డులు వైద్యుని నియంత్రణలోనే ఉండేలా Rxvarta రూపొందించబడింది. డేటా ఎక్కడ ఉంచబడుతుంది, దాన్ని ఎవరు ప్రాసెస్ చేస్తారు మరియు దాన్ని ఎలా తొలగించాలో ఈ పేజీ సరళంగా వివరిస్తుంది.';

  @override
  String get privacyWhereStoredTitle => 'మీ డేటా ఎక్కడ ఉంటుంది';

  @override
  String get privacyWhereStoredDevice =>
      'ఈ పరికరం — రోగులు, సందర్శనలు, ట్రాన్‌స్క్రిప్ట్‌లు, ప్రిస్క్రిప్షన్లు, రిపోర్ట్ ఫోటోలు మరియు రికార్డింగ్‌లు ఈ ఫోన్‌లోని యాప్ ప్రైవేట్ స్టోరేజ్‌లో ఉంటాయి.';

  @override
  String get privacyWhereStoredCloud =>
      'ముంబై, భారతదేశం (ap-south-1) లో హోస్ట్ చేయబడిన Supabase ప్రాజెక్ట్ — మీ ఖాతా, డాక్టర్ ప్రొఫైల్, సంతకం మరియు బ్యాకప్‌లు.';

  @override
  String get privacyWhereStoredAudio =>
      'రికార్డింగ్‌లు ప్రాసెసింగ్ కోసం మాత్రమే ప్రైవేట్ స్టోరేజ్ బకెట్‌కు అప్‌లోడ్ అవుతాయి, దీర్ఘకాలిక నిల్వ కోసం కాదు.';

  @override
  String get privacyProcessorsTitle => 'దీన్ని ఎవరు ప్రాసెస్ చేస్తారు';

  @override
  String get privacyProcessorSarvam =>
      'Sarvam AI — రికార్డింగ్‌ను టెక్స్ట్‌గా మారుస్తుంది (స్పీచ్-టు-టెక్స్ట్).';

  @override
  String get privacyProcessorGoogle =>
      'Google Gemini — మీ సమీక్ష కోసం ట్రాన్‌స్క్రిప్ట్ నుండి ప్రిస్క్రిప్షన్ ముసాయిదాను తయారు చేస్తుంది.';

  @override
  String get privacyProcessorSupabase =>
      'Supabase — సైన్-ఇన్, ఫైల్ స్టోరేజ్ మరియు మీ ఖాతా వెనుక ఉన్న డేటాబేస్.';

  @override
  String get privacyRetentionTitle => 'ఎంతకాలం ఉంచబడుతుంది';

  @override
  String get privacyRetentionAudio =>
      'రికార్డింగ్‌లు: ప్రాసెసింగ్ విజయవంతమైన వెంటనే సర్వర్ నుండి తొలగించబడతాయి; అప్పటివరకు ఈ పరికరంలోనే ఉంటాయి.';

  @override
  String get privacyRetentionTranscript =>
      'ట్రాన్‌స్క్రిప్ట్‌లు మరియు ప్రిస్క్రిప్షన్లు: మీరు తొలగించే వరకు ఈ పరికరంలో మరియు మీ బ్యాకప్‌లలో ఉంటాయి.';

  @override
  String get privacyRetentionJobs =>
      'ప్రాసెసింగ్ కాష్: ఫలితం యాప్‌కు అందిన తర్వాత తొలగించబడుతుంది.';

  @override
  String get privacyRoleTitle => 'మీ పాత్ర మరియు మా పాత్ర';

  @override
  String get privacyRoleBody =>
      'డిజిటల్ పర్సనల్ డేటా ప్రొటెక్షన్ చట్టం, 2023 ప్రకారం మీ రోగుల రికార్డులకు డేటా ఫిడ్యూషియరీగా మీరే, అంటే వైద్యులే, ఉంటారు. Rxvarta వాటిని మీ సూచనల మేరకు మాత్రమే, డేటా ప్రాసెసర్‌గా ప్రాసెస్ చేస్తుంది.';

  @override
  String get privacySecurityTitle => 'భద్రతా చర్యలు';

  @override
  String get privacySecurityBody =>
      'డేటా ఎన్‌క్రిప్టెడ్ కనెక్షన్ల (TLS) ద్వారా ప్రయాణిస్తుంది. సర్వర్‌లోని రికార్డులు ఖాతా వారీ యాక్సెస్ నియమాలతో రక్షించబడతాయి, కాబట్టి వాటిని మీ సైన్-ఇన్ మాత్రమే చదవగలదు. మీ ఫోన్‌ను లాక్ చేసి ఉంచండి: దాన్ని అన్‌లాక్ చేయగలిగిన ఎవరైనా యాప్‌ను తెరవగలరు.';

  @override
  String get privacyDeleteTitle => 'డేటా తొలగింపు';

  @override
  String get privacyDeleteBody =>
      'ఈ ఫోన్ నుండి మీ డేటాను తీసివేయడానికి క్రింది బటన్‌ను ఉపయోగించండి. ఈ ఫోన్‌లో సైన్ ఇన్ చేసే ఇతర వైద్యుల డేటా అలాగే ఉంటుంది. రోగుల రికార్డులను ఇంకా ఒక్కొక్కటిగా తొలగించలేరు. మీ ఖాతాను మరియు మా సర్వర్లలోని డేటాను తొలగించడానికి, మీరు సైన్ అప్ చేసిన ఇమెయిల్ చిరునామా నుండి మాకు వ్రాయండి.';

  @override
  String get privacyDeleteLocal => 'ఈ పరికరంలోని నా డేటాను తొలగించండి';

  @override
  String get privacyDeleteLocalSubtitle =>
      'ఈ ఫోన్ నుండి మీ రోగులు, సందర్శనలు, రికార్డింగ్‌లు, రిపోర్టులు, ప్రొఫైల్ కాష్ మరియు సంతకాన్ని తీసివేసి మిమ్మల్ని సైన్ అవుట్ చేస్తుంది. సర్వర్‌లోని మీ ఖాతా మరియు బ్యాకప్‌లు ప్రభావితం కావు.';

  @override
  String privacyDeleteLocalBody(String word) {
    return 'ఈ ఫోన్‌లో నిల్వ చేసిన మీ ప్రతి రోగి, సందర్శన, రికార్డింగ్ మరియు రిపోర్ట్ తీసివేయబడుతుంది మరియు మీరు సైన్ అవుట్ అవుతారు. ఈ ఫోన్‌లోని ఇతర వైద్యుల డేటా మరియు సర్వర్‌లోని మీ బ్యాకప్‌లు ప్రభావితం కావు. దీన్ని వెనక్కి తీసుకోలేరు.\n\nధృవీకరించడానికి $word టైప్ చేయండి.';
  }

  @override
  String get privacyDeleteLocalWord => 'DELETE';

  @override
  String privacyDeleteLocalHint(String word) {
    return '$word టైప్ చేయండి';
  }

  @override
  String get privacyDeleteLocalConfirm => 'అన్నీ తొలగించు';

  @override
  String get privacyDeleting => 'స్థానిక డేటాను తొలగిస్తోంది…';

  @override
  String get privacyDeleted => 'స్థానిక డేటా తొలగించబడింది';

  @override
  String privacyDeletePartial(String details) {
    return 'కొన్ని అంశాలను తొలగించలేకపోయాం: $details';
  }

  @override
  String get privacyReadPolicy => 'పూర్తి గోప్యతా విధానాన్ని చదవండి';

  @override
  String get legalTerms => 'నిబంధనలు & షరతులు';

  @override
  String get legalPrivacyPolicy => 'గోప్యతా విధానం';

  @override
  String legalLastUpdated(String date) {
    return 'చివరిగా నవీకరించబడింది: $date';
  }

  @override
  String get legalReviewNotice =>
      'యాప్‌తో వచ్చిన కాపీ — ఆఫ్‌లైన్‌లో అందుబాటులో ఉంది. ఆన్‌లైన్‌లో కొత్త వెర్షన్ ప్రచురితమైతే, ఆన్‌లైన్ వెర్షన్ వర్తిస్తుంది.';

  @override
  String get legalViewOnline => 'ఆన్‌లైన్ వెర్షన్ చూడండి';

  @override
  String get legalLoadFailed => 'ఈ పత్రాన్ని లోడ్ చేయలేకపోయాం.';

  @override
  String get helpTitle => 'సహాయం & మద్దతు';

  @override
  String get helpSubtitle =>
      'యాప్ గురించి ప్రశ్నలు, సూచనలు లేదా సమస్యా? మేము సహాయం చేయడానికి సిద్ధం.';

  @override
  String helpVersion(String version, String build) {
    return 'యాప్ వెర్షన్ $version ($build)';
  }

  @override
  String get helpEmail => 'ఇమెయిల్ మద్దతు';

  @override
  String get helpWhatsapp => 'WhatsApp మద్దతు';

  @override
  String get helpReportProblem => 'సమస్యను తెలియజేయండి';

  @override
  String get helpReportProblemSubtitle =>
      'ఏమి జరిగిందో మరియు దాన్ని మళ్లీ ఎలా చూడవచ్చో చెప్పండి';

  @override
  String get helpNotConfigured => 'మద్దతు సంప్రదింపు ఇంకా సెట్ చేయలేదు';

  @override
  String get helpCouldNotOpen => 'దీన్ని మీ పరికరంలో తెరవలేకపోయాం.';

  @override
  String get helpEmailSubject => 'Rxvarta మద్దతు';

  @override
  String helpEmailBody(String version, String platform) {
    return 'యాప్ వెర్షన్: $version\nప్లాట్‌ఫారమ్: $platform\n\n';
  }

  @override
  String get helpReportSubject => 'Rxvarta — సమస్య నివేదిక';

  @override
  String helpReportBody(String version, String platform) {
    return 'ఏమి జరిగింది:\n\n\nమళ్లీ చూడటానికి దశలు:\n1. \n2. \n3. \n\nయాప్ వెర్షన్: $version\nప్లాట్‌ఫారమ్: $platform\n';
  }

  @override
  String get logout => 'లాగ్ అవుట్';

  @override
  String get authSignIn => 'సైన్ ఇన్';

  @override
  String get authSignInTitle => 'మళ్లీ స్వాగతం';

  @override
  String get authSignInSubtitle =>
      'మీ కన్సల్టేషన్లను కొనసాగించడానికి సైన్ ఇన్ చేయండి.';

  @override
  String get authEmail => 'ఇమెయిల్';

  @override
  String get authEmailHint => 'doctor@clinic.com';

  @override
  String get authEmailInvalid => 'సరైన ఇమెయిల్ చిరునామాను నమోదు చేయండి';

  @override
  String get authPassword => 'పాస్‌వర్డ్';

  @override
  String get authPasswordHint => 'మీ పాస్‌వర్డ్‌ను నమోదు చేయండి';

  @override
  String get authPasswordRequired => 'మీ పాస్‌వర్డ్‌ను నమోదు చేయండి';

  @override
  String get authPasswordRules =>
      'కనీసం 8 అక్షరాలు, అందులో ఒక పెద్ద, ఒక చిన్న అక్షరం, ఒక అంకె మరియు ఒక గుర్తు ఉండాలి';

  @override
  String get authPasswordTooShort => 'కనీసం 8 అక్షరాలు వాడండి';

  @override
  String get authPasswordTooLong => 'చాలా పొడవుగా ఉంది — కొంచెం తగ్గించండి';

  @override
  String get authPasswordNeedsLowercase => 'ఒక చిన్న అక్షరం జోడించండి (a–z)';

  @override
  String get authPasswordNeedsUppercase => 'ఒక పెద్ద అక్షరం జోడించండి (A–Z)';

  @override
  String get authPasswordNeedsDigit => 'ఒక అంకె జోడించండి (0–9)';

  @override
  String get authPasswordNeedsSymbol => 'ఒక గుర్తు జోడించండి, ఉదా. ! లేదా @';

  @override
  String authEmailDidYouMean(String suggestion) {
    return 'మీరు $suggestion అని అనుకున్నారా?';
  }

  @override
  String authEmailKeepAsTyped(String button) {
    return 'రాసినట్లే ఉంచడానికి “$button” ను మళ్లీ నొక్కండి.';
  }

  @override
  String get authPasswordsDoNotMatch => 'పాస్‌వర్డ్‌లు సరిపోలడం లేదు';

  @override
  String get authShowPassword => 'పాస్‌వర్డ్ చూపించు';

  @override
  String get authHidePassword => 'పాస్‌వర్డ్ దాచు';

  @override
  String get authForgotPassword => 'పాస్‌వర్డ్ మర్చిపోయారా?';

  @override
  String get authNoAccount => 'Rxvarta కు కొత్తవారా?';

  @override
  String get authCreateAccount => 'ఖాతా సృష్టించండి';

  @override
  String get authHaveAccount => 'ఇప్పటికే ఖాతా ఉందా?';

  @override
  String get authSignUpTitle => 'మీ ఖాతాను సృష్టించండి';

  @override
  String get authSignUpSubtitle =>
      'ప్రతి వైద్యునికి ఒక ఖాతా. మీ రోగులు మరియు ప్రిస్క్రిప్షన్లు మీకే పరిమితంగా ఉంటాయి.';

  @override
  String get authConfirmPassword => 'పాస్‌వర్డ్‌ను నిర్ధారించండి';

  @override
  String get authSignInInstead => 'బదులుగా సైన్ ఇన్ చేయండి';

  @override
  String get authVerifyTitle => 'మీ ఇమెయిల్ చూడండి';

  @override
  String authVerifyBody(String email) {
    return 'మేము $email కు 8 అంకెల కోడ్‌ను పంపాము. కొనసాగించడానికి దాన్ని క్రింద నమోదు చేయండి.';
  }

  @override
  String get authCode => 'ధృవీకరణ కోడ్';

  @override
  String get authCodeIncomplete => 'కోడ్‌లోని మొత్తం 8 అంకెలను నమోదు చేయండి';

  @override
  String get authVerify => 'ధృవీకరించు';

  @override
  String get authResendCode => 'కోడ్‌ను మళ్లీ పంపండి';

  @override
  String authResendIn(int seconds) {
    return '$seconds సెకన్లలో కోడ్‌ను మళ్లీ పంపండి';
  }

  @override
  String get authCodeSent => 'మీ ఇమెయిల్‌కు కొత్త కోడ్ పంపబడింది.';

  @override
  String get authForgotTitle => 'మీ పాస్‌వర్డ్‌ను రీసెట్ చేయండి';

  @override
  String get authForgotSubtitle =>
      'మీరు సైన్ అప్ చేసిన ఇమెయిల్‌ను నమోదు చేయండి, మేము మీకు కోడ్ పంపుతాం.';

  @override
  String get authSendCode => 'కోడ్ పంపండి';

  @override
  String get authResetTitle => 'కొత్త పాస్‌వర్డ్‌ను ఎంచుకోండి';

  @override
  String get authResetSubtitle =>
      'Rxvarta లో ఇంతకు ముందు ఉపయోగించని పాస్‌వర్డ్‌ను ఎంచుకోండి.';

  @override
  String get authNewPassword => 'కొత్త పాస్‌వర్డ్';

  @override
  String get authUpdatePassword => 'పాస్‌వర్డ్‌ను నవీకరించండి';

  @override
  String get authPasswordUpdated => 'పాస్‌వర్డ్ నవీకరించబడింది';

  @override
  String get authBackToSignIn => 'సైన్ ఇన్‌కు తిరిగి వెళ్లండి';

  @override
  String get authBack => 'వెనుకకు';

  @override
  String get authNotConfiguredTitle => 'యాప్ కాన్ఫిగర్ చేయబడలేదు';

  @override
  String get authNotConfiguredBody =>
      'ఈ బిల్డ్‌కు బ్యాకెండ్ కనెక్షన్ లేదు, కాబట్టి సైన్-ఇన్ అందుబాటులో లేదు. యాప్‌ను --dart-define-from-file=config/app_config.json తో బిల్డ్ చేయండి (README చూడండి).';

  @override
  String get authSplashLoading => 'మీ వర్క్‌స్పేస్ సిద్ధమవుతోంది…';

  @override
  String get authSecureNote =>
      'ఎన్‌క్రిప్టెడ్ మరియు మీ ఖాతాకు మాత్రమే పరిమితం.';

  @override
  String get authErrorInvalidCredentials => 'ఇమెయిల్ లేదా పాస్‌వర్డ్ తప్పు.';

  @override
  String get authErrorEmailNotConfirmed =>
      'దయచేసి ముందుగా మీ ఇమెయిల్ చిరునామాను ధృవీకరించండి.';

  @override
  String get authErrorUserExists => 'ఈ ఇమెయిల్‌తో ఇప్పటికే ఒక ఖాతా ఉంది.';

  @override
  String get authErrorWeakPassword =>
      'బలమైన పాస్‌వర్డ్‌ను ఎంచుకోండి: కనీసం 8 అక్షరాలు మరియు ప్రస్తుతం ఉన్నదానికంటే భిన్నంగా.';

  @override
  String get authErrorOtpExpired =>
      'ఈ కోడ్ గడువు ముగిసింది. కొత్తదాన్ని అభ్యర్థించండి.';

  @override
  String get authErrorOtpInvalid =>
      'ఆ కోడ్ సరైనది కాదు. తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get authErrorRateLimited =>
      'చాలా ప్రయత్నాలు. దయచేసి ఒక నిమిషం ఆగి మళ్లీ ప్రయత్నించండి.';

  @override
  String get authErrorEmailSendFailed =>
      'ఇప్పుడు ఇమెయిల్ పంపలేకపోయాం. ఒక నిమిషం తర్వాత మళ్లీ ప్రయత్నించండి.';

  @override
  String get authErrorNetwork =>
      'ఇంటర్నెట్ కనెక్షన్ లేదు. మీ నెట్‌వర్క్‌ను తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get authErrorSignupDisabled =>
      'కొత్త సైన్-అప్‌లు ప్రస్తుతం నిలిపివేయబడ్డాయి.';

  @override
  String get authErrorValidation =>
      'దయచేసి మీరు నమోదు చేసిన వివరాలను తనిఖీ చేయండి.';

  @override
  String get authErrorNotConfigured => 'యాప్ ఏ బ్యాకెండ్‌కు కనెక్ట్ కాలేదు.';

  @override
  String get authErrorUnknown =>
      'ఏదో తప్పు జరిగింది. దయచేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get authErrorDetails => 'వివరాలు';

  @override
  String get regPrefix => 'నమో.';

  @override
  String get allRightsReserved => 'అన్ని హక్కులు రిజర్వ్ చేయబడ్డాయి';

  @override
  String get editProfile => 'ప్రొఫైల్ సవరించండి';

  @override
  String get editProfileSubtitle =>
      'ప్రిస్క్రిప్షన్ లెటర్‌హెడ్‌పై కనిపిస్తుంది.';

  @override
  String get doctorName => 'డాక్టర్ పేరు';

  @override
  String get qualifications => 'అర్హతలు';

  @override
  String get registrationNumber => 'నమోదు సంఖ్య';

  @override
  String get clinicName => 'క్లినిక్ / ఆసుపత్రి పేరు';

  @override
  String get clinicAddress => 'క్లినిక్ చిరునామా';

  @override
  String get clinicPhone => 'క్లినిక్ ఫోన్';

  @override
  String get profilePhone => 'మీ మొబైల్ నంబర్';

  @override
  String get profileOptional => 'ఐచ్ఛికం';

  @override
  String get profileRequiredHint =>
      '* గుర్తున్న ఫీల్డ్‌లు ప్రతి ప్రిస్క్రిప్షన్‌పై ముద్రితమవుతాయి మరియు చట్టప్రకారం తప్పనిసరి.';

  @override
  String get profileSectionDoctor => 'వైద్యుని వివరాలు';

  @override
  String get profileSectionClinic => 'క్లినిక్ వివరాలు';

  @override
  String get profileNameHint => 'ఉదా. Dr. Asha Verma';

  @override
  String get profileQualificationsHint => 'ఉదా. MBBS, MD (Medicine)';

  @override
  String get profileRegNoHint => 'రాష్ట్ర మెడికల్ కౌన్సిల్ నంబర్';

  @override
  String get profilePhoneHint => '10 అంకెల మొబైల్ నంబర్';

  @override
  String get profilePhoneInvalid => 'సరైన మొబైల్ నంబర్‌ను నమోదు చేయండి';

  @override
  String get profileClinicNameHint => 'క్లినిక్ లేదా ఆసుపత్రి పేరు';

  @override
  String get profileClinicAddressHint => 'ప్రాంతం, నగరం, రాష్ట్రం, పిన్';

  @override
  String get profileClinicPhoneHint => 'ల్యాండ్‌లైన్ లేదా రిసెప్షన్ నంబర్';

  @override
  String get profileSavedOffline =>
      'ఈ పరికరంలో సేవ్ చేయబడింది — ఆన్‌లైన్‌లో ఉన్నప్పుడు సింక్ అవుతుంది';

  @override
  String get profileSaveFailed => 'ప్రొఫైల్‌ను సేవ్ చేయలేకపోయాం';

  @override
  String get profileRetry => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get profileIncompleteNudgeTitle =>
      'ప్రిస్క్రిప్షన్లపై సంతకం చేయడానికి మీ ప్రొఫైల్‌ను పూర్తి చేయండి';

  @override
  String get profileIncompleteNudgeBody =>
      'మీ పేరు, నమోదు సంఖ్య, క్లినిక్ మరియు సంతకాన్ని జోడించండి.';

  @override
  String get signatureTitle => 'సంతకం';

  @override
  String get signatureSubtitle =>
      'మీరు సంతకం చేసే ప్రతి ప్రిస్క్రిప్షన్‌పై ముద్రితమవుతుంది.';

  @override
  String get signatureAdd => 'సంతకం జోడించండి';

  @override
  String get signatureUpdate => 'సంతకాన్ని మార్చండి';

  @override
  String get signatureDraw => 'గీయండి';

  @override
  String get signatureUpload => 'అప్‌లోడ్ చేయండి';

  @override
  String get signatureClear => 'తుడిచివేయి';

  @override
  String get signatureUse => 'ఈ సంతకాన్ని ఉపయోగించు';

  @override
  String get signatureEmptyError => 'దయచేసి ముందుగా మీ సంతకాన్ని గీయండి.';

  @override
  String get signatureHint => 'గీత పైన వేలితో లేదా మౌస్‌తో సంతకం చేయండి';

  @override
  String get signatureUploadHint =>
      'తెల్ల కాగితంపై మీ సంతకం యొక్క స్పష్టమైన ఫోటో లేదా స్కాన్‌ను ఎంచుకోండి (PNG లేదా JPEG).';

  @override
  String get signatureChooseImage => 'చిత్రాన్ని ఎంచుకోండి';

  @override
  String get signatureChangeImage => 'మరొకటి ఎంచుకోండి';

  @override
  String get signatureUnsupportedFormat =>
      'దయచేసి PNG లేదా JPEG చిత్రాన్ని ఎంచుకోండి.';

  @override
  String get signatureLoadFailed => 'ఆ చిత్రాన్ని లోడ్ చేయలేకపోయాం';

  @override
  String get signatureNone => 'ఇంకా సంతకం లేదు';

  @override
  String get signatureSaved => 'సంతకం సేవ్ చేయబడింది';

  @override
  String get signatureSaveFailed => 'సంతకాన్ని సేవ్ చేయలేకపోయాం';

  @override
  String get onboardingTitle => 'మీ ప్రిస్క్రిప్షన్‌ను సెట్ చేయండి';

  @override
  String get onboardingSubtitle =>
      'ఈ వివరాలు మీరు సంతకం చేసే ప్రతి ప్రిస్క్రిప్షన్‌పై కనిపిస్తాయి.';

  @override
  String get onboardingStepDoctor => 'వైద్యుడు';

  @override
  String get onboardingStepClinic => 'క్లినిక్';

  @override
  String get onboardingStepSignature => 'సంతకం';

  @override
  String get onboardingDoctorTitle => 'మీ వివరాలు';

  @override
  String get onboardingDoctorBody =>
      'లెటర్‌హెడ్‌పై ఎలా కనిపించాలో సరిగ్గా అలాగే.';

  @override
  String get onboardingClinicTitle => 'మీ క్లినిక్';

  @override
  String get onboardingClinicBody =>
      'ప్రిస్క్రిప్షన్‌పై ముద్రితమయ్యే ప్రాక్టీస్ పేరు మరియు చిరునామా.';

  @override
  String get onboardingSignatureTitle => 'మీ సంతకం';

  @override
  String get onboardingSignatureBody =>
      'దాన్ని ఒకసారి గీయండి లేదా ఫోటోను అప్‌లోడ్ చేయండి. అది ప్రైవేట్‌గా నిల్వ చేయబడుతుంది మరియు మీరు సంతకం చేసే ప్రిస్క్రిప్షన్లపై మాత్రమే ముద్రితమవుతుంది.';

  @override
  String get onboardingContinue => 'కొనసాగించు';

  @override
  String get onboardingBack => 'వెనుకకు';

  @override
  String get onboardingFinish => 'పూర్తి చేయి';

  @override
  String get onboardingSignatureRequired =>
      'పూర్తి చేయడానికి మీ సంతకాన్ని జోడించండి.';

  @override
  String get onboardingSignOut => 'సైన్ అవుట్';

  @override
  String onboardingSignedInAs(String email) {
    return '$email గా సైన్ ఇన్ చేయబడింది';
  }

  @override
  String get signGateTitle => 'సంతకం చేయడానికి మీ ప్రొఫైల్‌ను పూర్తి చేయండి';

  @override
  String get signGateBody =>
      'ప్రిస్క్రిప్షన్‌పై సూచించిన వైద్యుని వివరాలు తప్పనిసరిగా ఉండాలి. సంతకం చేయడానికి ముందు వీటిని జోడించండి:';

  @override
  String get signGateCompleteProfile => 'ప్రొఫైల్‌ను పూర్తి చేయండి';

  @override
  String get signGateOk => 'సరే';

  @override
  String get signGatePatientNameTitle => 'రోగి పేరు లేదు';

  @override
  String get signGatePatientNameBody =>
      'ప్రిస్క్రిప్షన్‌పై సంతకం చేయడానికి ముందు రోగి పేరును నమోదు చేయండి.';

  @override
  String get signGateMedicineNameTitle => 'మందు పేరు లేదు';

  @override
  String signGateMedicineNameBody(int n) {
    return 'మందు $n కు పేరు లేదు. సంతకం చేయడానికి ముందు పేరును నమోదు చేయండి లేదా దాన్ని తీసివేయండి.';
  }

  @override
  String pdfDocumentTitle(String name) {
    return 'ప్రిస్క్రిప్షన్ — $name';
  }

  @override
  String get pdfPatient => 'రోగి';

  @override
  String get pdfDate => 'తేదీ';

  @override
  String get pdfAge => 'వయస్సు';

  @override
  String get pdfGender => 'లింగం';

  @override
  String get pdfPhone => 'ఫోన్';

  @override
  String pdfAgeYears(int age) {
    return '$age సం.';
  }

  @override
  String get pdfRegNo => 'రిజి. నం.';

  @override
  String get pdfDiagnosis => 'నిర్ధారణ';

  @override
  String get pdfNoMedicines => 'మందులు ఏవీ రాయలేదు.';

  @override
  String get pdfColMedicine => 'మందు';

  @override
  String get pdfColDosage => 'మోతాదు';

  @override
  String get pdfColFrequency => 'ఎన్నిసార్లు';

  @override
  String get pdfColDuration => 'వ్యవధి';

  @override
  String get pdfColTiming => 'సమయం';

  @override
  String get pdfInvestigations => 'సూచించిన పరీక్షలు';

  @override
  String get pdfInstructions => 'సూచనలు';

  @override
  String get pdfAdvice => 'సలహా';

  @override
  String get pdfFollowUp => 'ఫాలో-అప్';

  @override
  String pdfFollowUpAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days రోజుల తర్వాత',
      one: '1 రోజు తర్వాత',
    );
    return '$_temp0';
  }

  @override
  String get pdfNextVisit => 'తదుపరి సందర్శన';

  @override
  String get pdfPreviousReports => 'మునుపటి రిపోర్టులు';

  @override
  String pdfReportsAttachedFor(String name) {
    return '$name కోసం జతచేయబడింది';
  }

  @override
  String pdfReportCaption(int number) {
    return 'రిపోర్ట్ $number';
  }

  @override
  String get pdfComputerGenerated => 'ఇది కంప్యూటర్‌లో తయారైన ప్రిస్క్రిప్షన్';

  @override
  String get pdfFooterTagline =>
      'Rxvarta AI ద్వారా తయారైంది  |  సురక్షితం  |  గోప్యం';

  @override
  String get pdfAwaitingSignature => 'సంతకం కోసం వేచి ఉంది';

  @override
  String get unsavedChanges => 'సేవ్ చేయని మార్పులు';

  @override
  String get unsavedChangesBody =>
      'మీకు సేవ్ చేయని మార్పులు ఉన్నాయి. వాటిని సేవ్ చేయాలా లేదా విస్మరించాలా?';

  @override
  String get discard => 'విస్మరించు';

  @override
  String get save => 'సేవ్ చేయి';

  @override
  String get cancel => 'రద్దు చేయి';

  @override
  String get done => 'పూర్తి';

  @override
  String get required => 'అవసరం';

  @override
  String get navHome => 'హోమ్';

  @override
  String get navPatients => 'రోగులు';

  @override
  String get navSettings => 'సెట్టింగ్‌లు';

  @override
  String get notFound => 'కనుగొనబడలేదు';

  @override
  String get newConsultation => 'కొత్త సంప్రదింపు';

  @override
  String get whoIsThisFor => 'ఈ సంప్రదింపు ఎవరి కోసం?';

  @override
  String get newPatientTitle => 'కొత్త రోగి';

  @override
  String get newPatientDesc =>
      'మొదటిసారి వచ్చే రోగి పేరు, వయస్సు, లింగం మరియు మొబైల్ నంబర్ జోడించండి.';

  @override
  String get existingPatientTitle => 'ఇప్పటికే ఉన్న రోగి';

  @override
  String get existingPatientDesc =>
      'చరిత్ర నుండి రోగిని వెతకండి, వారి నివేదికను సమీక్షించి, కొత్త సంప్రదింపు ప్రారంభించండి.';

  @override
  String get stepDetails => 'వివరాలు';

  @override
  String get stepRecording => 'రికార్డింగ్';

  @override
  String get stepReview => 'సమీక్ష';

  @override
  String get stepShare => 'షేర్';

  @override
  String get patientDetails => 'రోగి వివరాలు';

  @override
  String get enterBasicInfo => 'రోగి ప్రాథమిక సమాచారం నమోదు చేయండి';

  @override
  String get confirmDetailsConsent => 'వివరాలు & సమ్మతిని నిర్ధారించండి';

  @override
  String get patientName => 'రోగి పేరు';

  @override
  String get patientNameHint => 'రోగి పూర్తి పేరు నమోదు చేయండి';

  @override
  String get nameRequired => 'పేరు అవసరం';

  @override
  String get age => 'వయస్సు';

  @override
  String get gender => 'లింగం';

  @override
  String get select => 'ఎంచుకోండి';

  @override
  String get whatsappNumber => 'వాట్సాప్ నంబర్';

  @override
  String get mobileHint => '10 అంకెల మొబైల్ నంబర్';

  @override
  String get prescriptionShareNote => 'ఈ నంబర్‌కు ప్రిస్క్రిప్షన్ పంపబడుతుంది';

  @override
  String get previousReports => 'మునుపటి నివేదికలు (ఐచ్ఛికం)';

  @override
  String get previousReportsDesc =>
      'మునుపటి నివేదికలను స్కాన్ చేయండి లేదా జోడించండి — అవి ప్రిస్క్రిప్షన్ PDFలో చేర్చబడతాయి.';

  @override
  String get addReport => 'నివేదిక జోడించండి';

  @override
  String get takePhoto => 'ఫోటో తీయండి';

  @override
  String get chooseFromGallery => 'గ్యాలరీ నుండి ఎంచుకోండి';

  @override
  String get reportLabelHint => 'లేబుల్ (ఉదా. రక్త పరీక్ష, జనవరి 2)';

  @override
  String get consentLine => 'రోగి రికార్డింగ్‌కు సమ్మతించారు (DPDP చట్టం)';

  @override
  String get continueToRecording => 'రికార్డింగ్‌కు కొనసాగండి';

  @override
  String get couldNotAddReport => 'నివేదిక జోడించలేకపోయాము';

  @override
  String get couldNotSavePatient => 'రోగిని సేవ్ చేయలేకపోయాము';

  @override
  String get couldNotSaveChanges => 'మీ మార్పులను సేవ్ చేయలేకపోయాము';

  @override
  String get nothingHeardInRecording =>
      'ఈ రికార్డింగ్‌లో ఎలాంటి సంప్రదింపు వినిపించలేదు. మైక్రోఫోన్ పని చేస్తోందో లేదో చూసి, మళ్లీ రికార్డ్ చేయండి.';

  @override
  String get retryProcessing => 'ఇదే రికార్డింగ్‌తో మళ్లీ ప్రయత్నించండి';

  @override
  String get recordAgain => 'మళ్లీ రికార్డ్ చేయండి';

  @override
  String get consultationErrorOffline =>
      'ఇంటర్నెట్ కనెక్షన్ లేదు. మీ రికార్డింగ్ ఈ ఫోన్‌లో సేవ్ అయింది; ఇంటర్నెట్ వచ్చాక మళ్లీ ప్రయత్నించండి నొక్కండి.';

  @override
  String get consultationErrorProcessing =>
      'రికార్డింగ్‌ను ప్రాసెస్ చేయలేకపోయాము. ఇది ఈ ఫోన్‌లో సేవ్ అయింది; మళ్లీ ప్రయత్నించండి నొక్కండి.';

  @override
  String get errorSessionExpired =>
      'మీ సెషన్ ముగిసింది. దయచేసి మళ్లీ సైన్ ఇన్ చేయండి.';

  @override
  String get consultationErrorStorage =>
      'రికార్డింగ్‌ను ఈ ఫోన్‌లో సేవ్ చేయలేకపోయాము. ఖాళీ స్టోరేజ్ చూసి మళ్లీ రికార్డ్ చేయండి.';

  @override
  String get errorUnexpected =>
      'ఏదో తప్పు జరిగింది. దయచేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get errorOffline => 'ఇంటర్నెట్ కనెక్షన్ లేదు.';

  @override
  String get errorStorage =>
      'ఈ ఫోన్‌లోని ఫైళ్లను చదవలేకపోయాము లేదా సేవ్ చేయలేకపోయాము. ఖాళీ స్టోరేజ్ ఉందో లేదో చూడండి.';

  @override
  String get errorPermission =>
      'అనుమతి నిరాకరించబడింది. ఫోన్ సెట్టింగ్‌లలో Rxvartaకి అనుమతి ఇవ్వండి.';

  @override
  String get errorInvalidBackup =>
      'ఈ ఫైల్ మీ ఖాతాకు ఉపయోగపడే Rxvarta బ్యాకప్ కాదు.';

  @override
  String get errorBackupTooNew =>
      'ఈ బ్యాకప్ Rxvarta కొత్త వెర్షన్‌తో చేయబడింది. యాప్‌ను అప్‌డేట్ చేసి, తర్వాత రిస్టోర్ చేయండి.';

  @override
  String get patientAlreadyExists => 'రోగి ఇప్పటికే ఉన్నారు';

  @override
  String get patientExistsBody =>
      'ఈ నంబర్‌తో ఒక రోగి ఇప్పటికే మీ రికార్డులలో ఉన్నారు:';

  @override
  String get patientExistsQuestion =>
      'ఈ సంప్రదింపును వారి ప్రస్తుత చరిత్రకు జోడించాలా?';

  @override
  String get createNew => 'కొత్తది సృష్టించు';

  @override
  String get useExisting => 'ఉన్నదాన్ని ఉపయోగించు';

  @override
  String get consultationRecording => 'సంప్రదింపు రికార్డింగ్';

  @override
  String get processingAudio => 'ఆడియో ప్రాసెస్ అవుతోంది...';

  @override
  String get chooseRecordingOption => 'రికార్డింగ్ ఎంపికను ఎంచుకోండి';

  @override
  String get paused => 'పాజ్ చేయబడింది';

  @override
  String get recordingConversation => 'సంభాషణ రికార్డ్ అవుతోంది...';

  @override
  String get doctorPlusPatient => 'డాక్టర్ + రోగి';

  @override
  String get saySomething => 'ఏదైనా చెప్పండి...';

  @override
  String get readyBothVoices => 'సిద్ధం — రెండు స్వరాలు రికార్డ్ అవుతాయి';

  @override
  String get transcribingConversation => 'సంభాషణ లిప్యంతరీకరించబడుతోంది...';

  @override
  String get extractingPrescription => 'ప్రిస్క్రిప్షన్ సేకరించబడుతోంది...';

  @override
  String get recordingTip =>
      'ఫోన్‌ను డాక్టర్ మరియు రోగి మధ్య టేబుల్‌పై ఉంచి, స్టార్ట్ నొక్కండి.';

  @override
  String get addingToConsultation =>
      'సంప్రదింపుకు జోడించబడుతోంది — కొత్త ఆడియో ప్రస్తుత లిప్యంతరీకరణతో విలీనం అవుతుంది.';

  @override
  String get startConsultation => 'సంప్రదింపు ప్రారంభించండి';

  @override
  String get checkingConnection => 'కనెక్షన్ తనిఖీ చేస్తోంది…';

  @override
  String get offlineReconnect =>
      'ఆఫ్‌లైన్ — రికార్డ్ చేయడానికి తిరిగి కనెక్ట్ అవ్వండి';

  @override
  String get resume => 'కొనసాగించు';

  @override
  String get pause => 'పాజ్';

  @override
  String get minimumFiveSeconds => 'కనీసం 5 సెకన్లు అవసరం';

  @override
  String get recordingApproachingLimit => 'రికార్డింగ్ పరిమితికి చేరువలో';

  @override
  String get offlineNotice =>
      'ఇంటర్నెట్ కనెక్షన్ లేదు. సంప్రదింపును లిప్యంతరీకరించి ప్రాసెస్ చేయడానికి ఇంటర్నెట్ అవసరం.';

  @override
  String get checkingConnectionRetry =>
      'మీ కనెక్షన్ తనిఖీ చేస్తోంది — దయచేసి కొద్దిసేపటి తర్వాత మళ్లీ ప్రయత్నించండి.';

  @override
  String get internetLostStillRecording =>
      'ఇంటర్నెట్ లేదు. రికార్డింగ్ కొనసాగుతోంది; ఇంటర్నెట్ వచ్చాక సంప్రదింపు ప్రాసెస్ అవుతుంది.';

  @override
  String get recordingNotificationTitle => 'సంప్రదింపు రికార్డ్ అవుతోంది';

  @override
  String get recordingNotificationText =>
      'స్క్రీన్ ఆఫ్‌లో ఉన్నా Rxvarta రికార్డింగ్ కొనసాగిస్తుంది.';

  @override
  String get micPermissionNeeded =>
      'సంప్రదింపు రికార్డ్ చేయడానికి మైక్రోఫోన్ అనుమతి అవసరం.';

  @override
  String get micAccessNeeded => 'మైక్రోఫోన్ యాక్సెస్ అవసరం';

  @override
  String get micEnableInSettings =>
      'రికార్డ్ చేయడానికి సెట్టింగ్‌లలో మైక్రోఫోన్ అనుమతిని ప్రారంభించండి.';

  @override
  String get openSettings => 'సెట్టింగ్‌లు తెరవండి';

  @override
  String get stopRecordingGoBack => 'రికార్డింగ్ ఆపి వెనక్కి వెళ్లాలా?';

  @override
  String get recordingWillBeLost =>
      'మీ రికార్డింగ్ కోల్పోతారు. దీన్ని రద్దు చేయలేరు.';

  @override
  String get stopAndGoBack => 'ఆపి వెనక్కి వెళ్లు';

  @override
  String get discardRecording => 'రికార్డింగ్ విస్మరించాలా?';

  @override
  String get audioWillBeDiscarded =>
      'మీరు రికార్డ్ చేసిన ఆడియో విస్మరించబడుతుంది. దీన్ని రద్దు చేయలేరు.';

  @override
  String get discardAndGoBack => 'విస్మరించి వెనక్కి వెళ్లు';

  @override
  String get startFresh => 'కొత్తగా ప్రారంభించాలా?';

  @override
  String get startFreshBody =>
      'ఇది మీ ప్రస్తుత సంప్రదింపు డేటాను భర్తీ చేస్తుంది.';

  @override
  String get startFreshConfirm => 'కొత్తగా ప్రారంభించు';

  @override
  String get existingRecordingNotice =>
      'ఈ సంప్రదింపుకు మీకు ఇప్పటికే రికార్డింగ్ ఉంది.';

  @override
  String get duration => 'వ్యవధి';

  @override
  String get addExtraConversation => 'అదనపు సంభాషణ జోడించు';

  @override
  String get addExtraDesc =>
      'మరింత రికార్డ్ చేసి ప్రస్తుత డేటాతో విలీనం చేయండి';

  @override
  String get startNewConversation => 'కొత్త సంభాషణ ప్రారంభించు';

  @override
  String get startNewDesc => 'మునుపటిది తొలగించి కొత్తగా రికార్డ్ చేయండి';

  @override
  String get patientHistory => 'రోగి చరిత్ర';

  @override
  String get viewAllConsultations =>
      'అన్ని సంప్రదింపులు మరియు రికార్డులు చూడండి';

  @override
  String get statTotal => 'మొత్తం';

  @override
  String get statThisWeek => 'ఈ వారం';

  @override
  String get statToday => 'ఈరోజు';

  @override
  String get searchPatientsHint => 'రోగులను వెతకండి...';

  @override
  String get noPatientsFound => 'రోగులు కనబడలేదు';

  @override
  String get noConsultationsYet => 'ఇంకా సంప్రదింపులు లేవు';

  @override
  String get unknownPatient => 'తెలియని రోగి';

  @override
  String get yesterday => 'నిన్న';

  @override
  String get consultationOne => 'సంప్రదింపు';

  @override
  String get consultationMany => 'సంప్రదింపులు';

  @override
  String get findPatientTitle => 'రోగిని కనుగొనండి';

  @override
  String get searchByNameOrNumber => 'పేరు లేదా నంబర్‌తో వెతకండి…';

  @override
  String get noMatchingPatients => 'సరిపోలే రోగులు లేరు';

  @override
  String get patientFallback => 'రోగి';

  @override
  String get patientNotFound => 'రోగి కనబడలేదు';

  @override
  String get consultationHistory => 'సంప్రదింపు చరిత్ర';

  @override
  String get visitsWillAppearHere =>
      'ఈ రోగి సందర్శనల రికార్డులు ఇక్కడ కనిపిస్తాయి.';

  @override
  String get signed => 'సంతకం చేయబడింది';

  @override
  String get diagnosisLabel => 'నిర్ధారణ';

  @override
  String get symptomsLabel => 'లక్షణాలు';

  @override
  String get medicinesLabel => 'మందులు';

  @override
  String get noMedicinesRecorded => 'మందులు నమోదు కాలేదు.';

  @override
  String get followUpLabel => 'తదుపరి సందర్శన';

  @override
  String get afterDaysOne => '1 రోజు తర్వాత';

  @override
  String afterDaysMany(int n) {
    return '$n రోజుల తర్వాత';
  }

  @override
  String get opening => 'తెరుస్తోంది…';

  @override
  String get viewPrescription => 'ప్రిస్క్రిప్షన్ చూడండి';

  @override
  String get share => 'షేర్ చేయి';

  @override
  String get couldNotSharePrescription => 'ప్రిస్క్రిప్షన్ షేర్ చేయలేకపోయాము';

  @override
  String get couldNotSharePdf => 'PDF షేర్ చేయలేకపోయాము';

  @override
  String get prescriptionFallback => 'ప్రిస్క్రిప్షన్';

  @override
  String get newConsultationTooltip =>
      'ఈ రోగి ఆధారంగా కొత్త సంప్రదింపు సృష్టించండి';

  @override
  String get couldNotGeneratePrescription =>
      'ప్రిస్క్రిప్షన్ రూపొందించలేకపోయాము';

  @override
  String get generatingPrescription => 'ప్రిస్క్రిప్షన్ రూపొందుతోంది...';

  @override
  String get preparingPdf => 'PDF సిద్ధమవుతోంది…';

  @override
  String get shareOnWhatsapp => 'వాట్సాప్‌లో షేర్ చేయండి';

  @override
  String get shareViaOtherApps => 'ఇతర యాప్‌ల ద్వారా షేర్ చేయండి';

  @override
  String get startNewConsultationCta => 'కొత్త సంప్రదింపు ప్రారంభించండి';

  @override
  String get reviewPrescription => 'ప్రిస్క్రిప్షన్ సమీక్ష';

  @override
  String get verifyDetails => 'లిప్యంతరీకరించిన వివరాలను ధృవీకరించి సవరించండి';

  @override
  String get reviewTitle => 'సమీక్ష';

  @override
  String get visitNotFound => 'సందర్శన కనబడలేదు';

  @override
  String get goBackToRecording => 'రికార్డింగ్‌కు తిరిగి వెళ్లాలా?';

  @override
  String get goBackToRecordingBody =>
      'మీరు ఈ సంప్రదింపుకు మరింత జోడించవచ్చు లేదా కొత్త రికార్డింగ్ ప్రారంభించవచ్చు.';

  @override
  String get stay => 'ఇక్కడే ఉండు';

  @override
  String get goBack => 'వెనక్కి వెళ్లు';

  @override
  String get consultationSummary => 'సంప్రదింపు సారాంశం';

  @override
  String get transcriptTitle => 'ట్రాన్‌స్క్రిప్ట్';

  @override
  String get transcriptSubtitle => 'Sarvam STT విన్న విధంగా';

  @override
  String get tapToAddSummary => 'సారాంశం జోడించడానికి పెన్సిల్ నొక్కండి';

  @override
  String get summaryHint =>
      'రోగి ఎందుకు వచ్చారో మరియు ప్రణాళికను సంక్షిప్తంగా రాయండి';

  @override
  String get patientInformation => 'రోగి సమాచారం';

  @override
  String get nameLabel => 'పేరు';

  @override
  String get yearsLabel => 'సంవత్సరాలు';

  @override
  String get whatsappLabel => 'వాట్సాప్';

  @override
  String get mobileNumber => 'మొబైల్ నంబర్';

  @override
  String get tapToSet => 'సెట్ చేయడానికి నొక్కండి';

  @override
  String get diagnosisHint => 'ఉదా. వైరల్ జ్వరం';

  @override
  String get noDiagnosisTapPencil =>
      'నిర్ధారణ లేదు — జోడించడానికి పెన్సిల్ నొక్కండి';

  @override
  String get investigationsTitle => 'పరీక్షలు';

  @override
  String get noInvestigationsTapPencil =>
      'ఏ పరీక్షలూ లేవు — జోడించడానికి పెన్సిల్ నొక్కండి';

  @override
  String get investigationsHint => 'చేయించవలసిన పరీక్షలు — ఒక్కో లైన్‌కు ఒకటి';

  @override
  String get doctorNotesTitle => 'డాక్టర్ నోట్స్';

  @override
  String get doctorNotesNotPrinted =>
      'మీ రికార్డు కోసం; ప్రిస్క్రిప్షన్‌పై ముద్రించబడవు';

  @override
  String get noDoctorNotesTapPencil =>
      'నోట్స్ లేవు — జోడించడానికి పెన్సిల్ నొక్కండి';

  @override
  String get doctorNotesHint => 'ఈ సంప్రదింపుపై మీ సొంత నోట్స్';

  @override
  String get adviceTitle => 'సలహా';

  @override
  String get noAdviceTapPencil =>
      'ఇంకా సలహా లేదు — జోడించడానికి పెన్సిల్ నొక్కండి';

  @override
  String get adviceHint => 'సాధారణ మార్గదర్శకం — ఒక్కో పంక్తికి ఒకటి';

  @override
  String get instructionsTitle => 'సూచనలు';

  @override
  String get noInstructionsTapPencil =>
      'ఇంకా సూచనలు లేవు — జోడించడానికి పెన్సిల్ నొక్కండి';

  @override
  String get instructionsHint => 'వైద్య ఆదేశాలు — ఒక్కో పంక్తికి ఒకటి';

  @override
  String get noFollowUpSet => 'తదుపరి సందర్శన సెట్ కాలేదు';

  @override
  String get daysSuffix => 'రోజులు';

  @override
  String get prescribedMedicines => 'సూచించిన మందులు';

  @override
  String get noMedicationsYet => 'ఇంకా మందులు నమోదు కాలేదు.';

  @override
  String get addMedicine => 'మందు జోడించు';

  @override
  String get medicineLabel => 'మందు';

  @override
  String get removeMedicine => 'మందు తొలగించు';

  @override
  String get dosageLabel => 'మోతాదు';

  @override
  String get durationLabel => 'వ్యవధి';

  @override
  String get frequencyLabel => 'తరచుదనం';

  @override
  String get timingLabel => 'సమయం';

  @override
  String get timingBeforeFood => 'భోజనానికి ముందు';

  @override
  String get timingAfterFood => 'భోజనం తర్వాత';

  @override
  String get timingWithFood => 'భోజనంతో';

  @override
  String get timingEmptyStomach => 'ఖాళీ కడుపుతో';

  @override
  String get timingBeforeBed => 'నిద్రకు ముందు';

  @override
  String get timingAsDirected => 'సూచించినట్లు';

  @override
  String get aiDisclaimer =>
      'AI డాక్టర్ చెప్పినది మాత్రమే సేకరిస్తుంది. సంతకం చేసే ముందు సారాంశం మరియు మందులను సమీక్షించండి.';

  @override
  String get generatePdf => 'ప్రిస్క్రిప్షన్ PDF రూపొందించండి';

  @override
  String get signAndGeneratePdf => 'సంతకం చేసి PDF రూపొందించండి';

  @override
  String get icdCodeTitle => 'ICD-10 కోడ్';

  @override
  String get icdVerifyWarning =>
      'AI సూచన — దీనిపై ఆధారపడే ముందు కోడ్‌ను ధృవీకరించండి.';

  @override
  String get icdCodeField => 'కోడ్ (ఉదా. B34.9)';

  @override
  String get descriptionField => 'వివరణ';

  @override
  String get icdFooterNote =>
      'ఈ కోడ్‌ను నిర్ధారణ ఆధారంగా AI సూచించింది. వైద్య లేదా బిల్లింగ్ ఉపయోగానికి ముందు ఖచ్చితత్వాన్ని ధృవీకరించండి.';

  @override
  String get suggestedDifferentials => 'సూచించిన భేద నిర్ధారణలు';

  @override
  String get aiSuggestionVerify => 'AI సూచన — ధృవీకరించండి';

  @override
  String get differentialsBasedOn =>
      'నివేదించిన లక్షణాల ఆధారంగా. డాక్టర్ ధృవీకరించాలి.';

  @override
  String get accept => 'అంగీకరించు';

  @override
  String get prescriptionReady => 'ప్రిస్క్రిప్షన్ సిద్ధం';

  @override
  String get reviewAndShare => 'సమీక్షించి రోగికి పంపండి';

  @override
  String get generatingPdfLong => 'ప్రిస్క్రిప్షన్ PDF రూపొందుతోంది…';

  @override
  String get couldNotGeneratePdf => 'PDF రూపొందించలేకపోయాము';
}

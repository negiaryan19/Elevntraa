// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Rxvarta';

  @override
  String get appTagline => 'स्मार्ट मेडिकल डॉक्यूमेंटेशन';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफलाइन';

  @override
  String get checking => 'जाँच हो रही है';

  @override
  String get goodMorning => 'सुप्रभात';

  @override
  String get goodAfternoon => 'नमस्कार';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String get doctorFallback => 'डॉक्टर';

  @override
  String get startNewConsultation => 'नया परामर्श शुरू करें';

  @override
  String get startNewConsultationSubtitle =>
      'मरीज़ की भेंट रिकॉर्ड और ट्रांसक्राइब करें';

  @override
  String get newPatient => 'नया मरीज़';

  @override
  String get findPatient => 'मरीज़ खोजें';

  @override
  String get allPatients => 'सभी मरीज़';

  @override
  String get recentPatients => 'हाल के मरीज़';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get noPatientsYet => 'अभी कोई मरीज़ नहीं';

  @override
  String get noPatientsYetSubtitle =>
      'अपना पहला मरीज़ जोड़ने के लिए परामर्श शुरू करें।';

  @override
  String get securityFooter =>
      'भेजते समय एन्क्रिप्टेड - भारत में होस्ट - आपके रिकॉर्ड आपके नियंत्रण में';

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'महिला';

  @override
  String get other => 'अन्य';

  @override
  String get years => 'वर्ष';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get settingsSubtitle => 'अपनी ऐप प्राथमिकताएँ प्रबंधित करें';

  @override
  String get sectionAccount => 'खाता';

  @override
  String get sectionPreferences => 'प्राथमिकताएँ';

  @override
  String get sectionDataPrivacy => 'डेटा और गोपनीयता';

  @override
  String get sectionSupport => 'सहायता';

  @override
  String get profileSettings => 'प्रोफ़ाइल सेटिंग्स';

  @override
  String get profileSettingsSubtitle =>
      'नाम, योग्यता, पंजीकरण और क्लिनिक विवरण';

  @override
  String get profileUpdated => 'प्रोफ़ाइल अपडेट हो गई';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get darkThemeActive => 'डार्क थीम सक्रिय';

  @override
  String get lightThemeActive => 'लाइट थीम सक्रिय';

  @override
  String get appLanguage => 'ऐप की भाषा';

  @override
  String get appLanguageSubtitle => 'ऐप इंटरफ़ेस की भाषा चुनें';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get exportData => 'डेटा निर्यात करें';

  @override
  String get backupTitle => 'बैकअप और सिंक';

  @override
  String get backupIntro =>
      'आपके रिकॉर्ड की एक कॉपी आपके अपने निजी क्लाउड फ़ोल्डर में रखता है, ताकि फ़ोन खो जाने पर भी कुछ न जाए।';

  @override
  String get backupIncludes =>
      'शामिल: मरीज़, कंसल्टेशन, प्रिस्क्रिप्शन, रिपोर्ट फ़ोटो, आपकी प्रोफ़ाइल और हस्ताक्षर।';

  @override
  String get backupExcludes =>
      'शामिल नहीं: कंसल्टेशन की रिकॉर्डिंग (प्रोसेसिंग के बाद वे हटा दी जाती हैं)।';

  @override
  String backupLastAt(String time) {
    return 'पिछला बैकअप $time';
  }

  @override
  String get backupNever => 'अभी तक कोई बैकअप नहीं';

  @override
  String get backupNow => 'अभी बैकअप लें';

  @override
  String backupLatestRemote(String time, String size) {
    return 'क्लाउड में नवीनतम: $time ($size)';
  }

  @override
  String get backupNoRemote => 'क्लाउड में अभी कोई बैकअप नहीं है';

  @override
  String get backupRestoreLatest => 'नवीनतम बैकअप रिस्टोर करें';

  @override
  String get backupRestoreConfirmTitle => 'इस फ़ोन का डेटा बदलें?';

  @override
  String backupRestoreConfirmBody(String time) {
    return 'इस फ़ोन पर आपके रिकॉर्ड $time के बैकअप से बदल दिए जाएँगे। इस फ़ोन का उपयोग करने वाले दूसरे डॉक्टरों पर इसका असर नहीं होगा। इसे वापस नहीं किया जा सकता।';
  }

  @override
  String get backupRestoreConfirm => 'रिस्टोर करें';

  @override
  String get backupStageCollecting => 'आपके रिकॉर्ड इकट्ठे किए जा रहे हैं…';

  @override
  String get backupStageZipping => 'पैक किया जा रहा है…';

  @override
  String get backupStageUploading => 'अपलोड हो रहा है…';

  @override
  String get backupStageDownloading => 'बैकअप डाउनलोड हो रहा है…';

  @override
  String get backupStageRestoring => 'रिस्टोर हो रहा है…';

  @override
  String get backupDone => 'बैकअप पूरा हुआ';

  @override
  String get backupRestored => 'बैकअप रिस्टोर हो गया';

  @override
  String get backupRestartHint =>
      'रिस्टोर किए गए रिकॉर्ड देखने के लिए ऐप बंद करके दोबारा खोलें।';

  @override
  String backupFailed(String reason) {
    return 'बैकअप विफल: $reason';
  }

  @override
  String backupRestoreFailed(String reason) {
    return 'रिस्टोर विफल: $reason';
  }

  @override
  String get backupNeedsInternet => 'बैकअप लेने के लिए इंटरनेट से जुड़ें।';

  @override
  String get exportPreparing => 'आपका एक्सपोर्ट तैयार हो रहा है…';

  @override
  String get exportShareSubject => 'Rxvarta डेटा एक्सपोर्ट';

  @override
  String get exportShareText => 'मेरे Rxvarta रिकॉर्ड का एक्सपोर्ट।';

  @override
  String exportFailed(String reason) {
    return 'डेटा एक्सपोर्ट नहीं हो सका: $reason';
  }

  @override
  String get exportEmpty => 'अभी एक्सपोर्ट करने के लिए कुछ नहीं है।';

  @override
  String exportSavedTo(String path) {
    return '$path पर सेव किया गया';
  }

  @override
  String get privacySecurity => 'गोपनीयता और सुरक्षा';

  @override
  String get termsConditions => 'नियम और शर्तें';

  @override
  String get termsConditionsSubtitle => 'हमारी सेवा शर्तें पढ़ें';

  @override
  String get helpSupport => 'सहायता और समर्थन';

  @override
  String get helpSupportSubtitle => 'मदद लें या हमसे संपर्क करें';

  @override
  String get settingsProfileSetUp => 'अपनी प्रोफ़ाइल सेट करें';

  @override
  String get settingsProfileIncompleteChip =>
      'प्रोफ़ाइल अधूरी है — प्रिस्क्रिप्शन साइन नहीं हो सकते';

  @override
  String get settingsSignature => 'हस्ताक्षर';

  @override
  String get settingsSignatureSubtitleAdded =>
      'जोड़ा गया — आपके साइन किए हर प्रिस्क्रिप्शन पर छपेगा';

  @override
  String get settingsSignatureSubtitleMissing => 'अभी तक नहीं जोड़ा गया';

  @override
  String get settingsBackupSync => 'बैकअप और सिंक';

  @override
  String get settingsBackupSubtitleNever => 'अभी तक कोई बैकअप नहीं';

  @override
  String settingsBackupSubtitleLast(String time) {
    return 'पिछला बैकअप $time';
  }

  @override
  String get settingsExportSubtitle =>
      'अपने सभी रिकॉर्ड की कॉपी सेव या शेयर करें';

  @override
  String get settingsPrivacySubtitle =>
      'आपका डेटा कहाँ रहता है और उसे कैसे हटाएँ';

  @override
  String get settingsSectionLegal => 'कानूनी';

  @override
  String get settingsPrivacyPolicy => 'प्राइवेसी पॉलिसी';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'आपके और आपके मरीज़ों के डेटा का क्या होता है';

  @override
  String settingsVersion(String version, String build) {
    return 'Rxvarta v$version ($build)';
  }

  @override
  String get settingsTimeJustNow => 'अभी-अभी';

  @override
  String settingsTimeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n मिनट पहले',
      one: '1 मिनट पहले',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n घंटे पहले',
      one: '1 घंटा पहले',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n दिन पहले',
      one: 'कल',
    );
    return '$_temp0';
  }

  @override
  String get settingsSigningOut => 'साइन आउट हो रहा है…';

  @override
  String get logoutConfirmTitle => 'साइन आउट करें?';

  @override
  String get logoutConfirmBody =>
      'Rxvarta इस्तेमाल करने के लिए आपको दोबारा साइन इन करना होगा। इस डिवाइस पर सेव रिकॉर्ड यहीं रहेंगे।';

  @override
  String get logoutConfirm => 'साइन आउट';

  @override
  String get privacyIntro =>
      'Rxvarta इस तरह बनाया गया है कि मरीज़ों के रिकॉर्ड डॉक्टर के नियंत्रण में रहें। यह पेज सरल शब्दों में बताता है कि डेटा कहाँ रखा जाता है, उसे कौन प्रोसेस करता है और उसे कैसे हटाया जाए।';

  @override
  String get privacyWhereStoredTitle => 'आपका डेटा कहाँ रहता है';

  @override
  String get privacyWhereStoredDevice =>
      'यह डिवाइस — मरीज़, विज़िट, ट्रांसक्रिप्ट, प्रिस्क्रिप्शन, रिपोर्ट फ़ोटो और रिकॉर्डिंग इस फ़ोन पर ऐप के निजी स्टोरेज में रहते हैं।';

  @override
  String get privacyWhereStoredCloud =>
      'मुंबई, भारत (ap-south-1) में होस्ट किया गया Supabase प्रोजेक्ट — आपका अकाउंट, डॉक्टर प्रोफ़ाइल, हस्ताक्षर और बैकअप।';

  @override
  String get privacyWhereStoredAudio =>
      'रिकॉर्डिंग सिर्फ़ प्रोसेसिंग के लिए एक निजी स्टोरेज बकेट में अपलोड होती हैं, लंबे समय तक रखने के लिए नहीं।';

  @override
  String get privacyProcessorsTitle => 'इसे कौन प्रोसेस करता है';

  @override
  String get privacyProcessorSarvam =>
      'Sarvam AI — रिकॉर्डिंग को टेक्स्ट में बदलता है (स्पीच-टू-टेक्स्ट)।';

  @override
  String get privacyProcessorGoogle =>
      'Google Gemini — ट्रांसक्रिप्ट से आपकी समीक्षा के लिए प्रिस्क्रिप्शन का ड्राफ़्ट बनाता है।';

  @override
  String get privacyProcessorSupabase =>
      'Supabase — साइन-इन, फ़ाइल स्टोरेज और आपके अकाउंट का डेटाबेस।';

  @override
  String get privacyRetentionTitle => 'कितने समय तक रखा जाता है';

  @override
  String get privacyRetentionAudio =>
      'रिकॉर्डिंग: प्रोसेसिंग सफल होते ही सर्वर से हटा दी जाती हैं; तब तक इसी डिवाइस पर रहती हैं।';

  @override
  String get privacyRetentionTranscript =>
      'ट्रांसक्रिप्ट और प्रिस्क्रिप्शन: जब तक आप उन्हें न हटाएँ, इस डिवाइस पर और आपके बैकअप में रहते हैं।';

  @override
  String get privacyRetentionJobs =>
      'प्रोसेसिंग कैश: नतीजा ऐप तक पहुँचने के बाद साफ़ कर दिया जाता है।';

  @override
  String get privacyRoleTitle => 'आपकी और हमारी भूमिका';

  @override
  String get privacyRoleBody =>
      'डिजिटल पर्सनल डेटा प्रोटेक्शन एक्ट, 2023 के तहत आपके मरीज़ों के रिकॉर्ड के लिए डेटा फ़िड्यूशरी आप, यानी डॉक्टर, ही रहते हैं। Rxvarta उन्हें केवल आपके निर्देश पर, डेटा प्रोसेसर के रूप में प्रोसेस करता है।';

  @override
  String get privacySecurityTitle => 'सुरक्षा उपाय';

  @override
  String get privacySecurityBody =>
      'डेटा एन्क्रिप्टेड कनेक्शन (TLS) से जाता है। सर्वर पर रिकॉर्ड हर अकाउंट के अलग ऐक्सेस नियमों से सुरक्षित हैं, इसलिए उन्हें सिर्फ़ आपका साइन-इन ही पढ़ सकता है। अपना फ़ोन लॉक रखें: जो उसे अनलॉक कर सकता है, वह ऐप खोल सकता है।';

  @override
  String get privacyDeleteTitle => 'डेटा हटाना';

  @override
  String get privacyDeleteBody =>
      'इस फ़ोन से अपना डेटा हटाने के लिए नीचे दिए बटन का उपयोग करें। इस फ़ोन पर साइन इन करने वाले दूसरे डॉक्टरों का डेटा बना रहेगा। मरीज़ों के रिकॉर्ड अभी एक-एक करके नहीं हटाए जा सकते। अपना अकाउंट और हमारे सर्वर पर रखा डेटा हटाने के लिए, जिस ईमेल से साइन अप किया था उसी से हमें लिखें।';

  @override
  String get privacyDeleteLocal => 'इस डिवाइस से मेरा डेटा हटाएँ';

  @override
  String get privacyDeleteLocalSubtitle =>
      'इस फ़ोन से आपके मरीज़, विज़िट, रिकॉर्डिंग, रिपोर्ट, प्रोफ़ाइल कैश और हस्ताक्षर हटाकर आपको साइन आउट कर देता है। सर्वर पर आपका अकाउंट और बैकअप प्रभावित नहीं होते।';

  @override
  String privacyDeleteLocalBody(String word) {
    return 'इस फ़ोन पर सेव आपका हर मरीज़, विज़िट, रिकॉर्डिंग और रिपोर्ट हटा दी जाएगी और आप साइन आउट हो जाएँगे। इस फ़ोन पर दूसरे डॉक्टरों का डेटा और सर्वर पर आपके बैकअप प्रभावित नहीं होंगे। इसे वापस नहीं किया जा सकता।\n\nपुष्टि के लिए $word टाइप करें।';
  }

  @override
  String get privacyDeleteLocalWord => 'DELETE';

  @override
  String privacyDeleteLocalHint(String word) {
    return '$word टाइप करें';
  }

  @override
  String get privacyDeleteLocalConfirm => 'सब कुछ हटाएँ';

  @override
  String get privacyDeleting => 'लोकल डेटा हटाया जा रहा है…';

  @override
  String get privacyDeleted => 'लोकल डेटा हटा दिया गया';

  @override
  String privacyDeletePartial(String details) {
    return 'कुछ चीज़ें नहीं हटाई जा सकीं: $details';
  }

  @override
  String get privacyReadPolicy => 'पूरी प्राइवेसी पॉलिसी पढ़ें';

  @override
  String get legalTerms => 'नियम और शर्तें';

  @override
  String get legalPrivacyPolicy => 'प्राइवेसी पॉलिसी';

  @override
  String legalLastUpdated(String date) {
    return 'अंतिम अपडेट: $date';
  }

  @override
  String get legalReviewNotice =>
      'ऐप में शामिल कॉपी — ऑफ़लाइन उपलब्ध। अगर ऑनलाइन नया संस्करण प्रकाशित हो, तो ऑनलाइन संस्करण लागू होगा।';

  @override
  String get legalViewOnline => 'ऑनलाइन संस्करण देखें';

  @override
  String get legalLoadFailed => 'यह दस्तावेज़ लोड नहीं हो सका।';

  @override
  String get helpTitle => 'हेल्प और सपोर्ट';

  @override
  String get helpSubtitle =>
      'ऐप को लेकर कोई सवाल, सुझाव या दिक्कत? हमें मदद करके खुशी होगी।';

  @override
  String helpVersion(String version, String build) {
    return 'ऐप वर्ज़न $version ($build)';
  }

  @override
  String get helpEmail => 'ईमेल सपोर्ट';

  @override
  String get helpWhatsapp => 'WhatsApp सपोर्ट';

  @override
  String get helpReportProblem => 'समस्या बताएँ';

  @override
  String get helpReportProblemSubtitle =>
      'बताएँ क्या हुआ और उसे दोबारा कैसे देखा जा सकता है';

  @override
  String get helpNotConfigured => 'सपोर्ट संपर्क अभी सेट नहीं है';

  @override
  String get helpCouldNotOpen => 'इसे आपके डिवाइस पर नहीं खोला जा सका।';

  @override
  String get helpEmailSubject => 'Rxvarta सपोर्ट';

  @override
  String helpEmailBody(String version, String platform) {
    return 'ऐप वर्ज़न: $version\nप्लेटफ़ॉर्म: $platform\n\n';
  }

  @override
  String get helpReportSubject => 'Rxvarta — समस्या रिपोर्ट';

  @override
  String helpReportBody(String version, String platform) {
    return 'क्या हुआ:\n\n\nदोबारा देखने के चरण:\n1. \n2. \n3. \n\nऐप वर्ज़न: $version\nप्लेटफ़ॉर्म: $platform\n';
  }

  @override
  String get logout => 'लॉग आउट';

  @override
  String get authSignIn => 'साइन इन';

  @override
  String get authSignInTitle => 'वापसी पर स्वागत है';

  @override
  String get authSignInSubtitle =>
      'अपने कंसल्टेशन जारी रखने के लिए साइन इन करें।';

  @override
  String get authEmail => 'ईमेल';

  @override
  String get authEmailHint => 'doctor@clinic.com';

  @override
  String get authEmailInvalid => 'सही ईमेल पता डालें';

  @override
  String get authPassword => 'पासवर्ड';

  @override
  String get authPasswordHint => 'अपना पासवर्ड डालें';

  @override
  String get authPasswordRequired => 'अपना पासवर्ड डालें';

  @override
  String get authPasswordRules =>
      'कम से कम 8 अक्षर, जिनमें एक बड़ा और एक छोटा अक्षर, एक अंक और एक चिह्न हो';

  @override
  String get authPasswordTooShort => 'कम से कम 8 अक्षर रखें';

  @override
  String get authPasswordTooLong => 'बहुत लंबा है — थोड़ा छोटा करें';

  @override
  String get authPasswordNeedsLowercase => 'एक छोटा अक्षर जोड़ें (a–z)';

  @override
  String get authPasswordNeedsUppercase => 'एक बड़ा अक्षर जोड़ें (A–Z)';

  @override
  String get authPasswordNeedsDigit => 'एक अंक जोड़ें (0–9)';

  @override
  String get authPasswordNeedsSymbol => 'एक चिह्न जोड़ें, जैसे ! या @';

  @override
  String authEmailDidYouMean(String suggestion) {
    return 'क्या आपका मतलब $suggestion था?';
  }

  @override
  String authEmailKeepAsTyped(String button) {
    return 'जैसा लिखा है वैसा ही रखने के लिए “$button” फिर से दबाएँ।';
  }

  @override
  String get authPasswordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get authShowPassword => 'पासवर्ड दिखाएँ';

  @override
  String get authHidePassword => 'पासवर्ड छिपाएँ';

  @override
  String get authForgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get authNoAccount => 'Rxvarta पर नए हैं?';

  @override
  String get authCreateAccount => 'अकाउंट बनाएँ';

  @override
  String get authHaveAccount => 'पहले से अकाउंट है?';

  @override
  String get authSignUpTitle => 'अपना अकाउंट बनाएँ';

  @override
  String get authSignUpSubtitle =>
      'हर डॉक्टर के लिए एक अकाउंट। आपके मरीज़ और प्रिस्क्रिप्शन सिर्फ़ आपके रहते हैं।';

  @override
  String get authConfirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get authSignInInstead => 'इसके बजाय साइन इन करें';

  @override
  String get authVerifyTitle => 'अपना ईमेल देखें';

  @override
  String authVerifyBody(String email) {
    return 'हमने $email पर 8 अंकों का कोड भेजा है। आगे बढ़ने के लिए उसे नीचे डालें।';
  }

  @override
  String get authCode => 'वेरिफ़िकेशन कोड';

  @override
  String get authCodeIncomplete => 'कोड के आठों अंक डालें';

  @override
  String get authVerify => 'वेरिफ़ाई करें';

  @override
  String get authResendCode => 'कोड दोबारा भेजें';

  @override
  String authResendIn(int seconds) {
    return '$seconds सेकंड में कोड दोबारा भेजें';
  }

  @override
  String get authCodeSent => 'आपके ईमेल पर नया कोड भेज दिया गया है।';

  @override
  String get authForgotTitle => 'अपना पासवर्ड रीसेट करें';

  @override
  String get authForgotSubtitle =>
      'जिस ईमेल से साइन अप किया था वह डालें, हम आपको कोड भेजेंगे।';

  @override
  String get authSendCode => 'कोड भेजें';

  @override
  String get authResetTitle => 'नया पासवर्ड चुनें';

  @override
  String get authResetSubtitle =>
      'ऐसा पासवर्ड चुनें जो आपने Rxvarta पर पहले इस्तेमाल न किया हो।';

  @override
  String get authNewPassword => 'नया पासवर्ड';

  @override
  String get authUpdatePassword => 'पासवर्ड अपडेट करें';

  @override
  String get authPasswordUpdated => 'पासवर्ड अपडेट हो गया';

  @override
  String get authBackToSignIn => 'साइन इन पर वापस जाएँ';

  @override
  String get authBack => 'वापस';

  @override
  String get authNotConfiguredTitle => 'ऐप कॉन्फ़िगर नहीं है';

  @override
  String get authNotConfiguredBody =>
      'इस बिल्ड में बैकएंड कनेक्शन नहीं है, इसलिए साइन-इन उपलब्ध नहीं है। ऐप को --dart-define-from-file=config/app_config.json के साथ बिल्ड करें (README देखें)।';

  @override
  String get authSplashLoading => 'आपका वर्कस्पेस तैयार हो रहा है…';

  @override
  String get authSecureNote => 'एन्क्रिप्टेड और सिर्फ़ आपके अकाउंट तक सीमित।';

  @override
  String get authErrorInvalidCredentials => 'ईमेल या पासवर्ड गलत है।';

  @override
  String get authErrorEmailNotConfirmed =>
      'कृपया पहले अपना ईमेल पता वेरिफ़ाई करें।';

  @override
  String get authErrorUserExists => 'इस ईमेल से पहले से एक अकाउंट मौजूद है।';

  @override
  String get authErrorWeakPassword =>
      'मज़बूत पासवर्ड चुनें: कम से कम 8 अक्षर और मौजूदा पासवर्ड से अलग।';

  @override
  String get authErrorOtpExpired => 'यह कोड समाप्त हो चुका है। नया कोड मँगाएँ।';

  @override
  String get authErrorOtpInvalid =>
      'यह कोड सही नहीं है। जाँचकर दोबारा कोशिश करें।';

  @override
  String get authErrorRateLimited =>
      'बहुत ज़्यादा कोशिशें। एक मिनट रुककर दोबारा कोशिश करें।';

  @override
  String get authErrorEmailSendFailed =>
      'अभी ईमेल नहीं भेजा जा सका। एक मिनट बाद दोबारा कोशिश करें।';

  @override
  String get authErrorNetwork =>
      'इंटरनेट कनेक्शन नहीं है। नेटवर्क जाँचकर दोबारा कोशिश करें।';

  @override
  String get authErrorSignupDisabled => 'नए साइन-अप फ़िलहाल बंद हैं।';

  @override
  String get authErrorValidation => 'कृपया डाली गई जानकारी जाँच लें।';

  @override
  String get authErrorNotConfigured => 'ऐप किसी बैकएंड से जुड़ा नहीं है।';

  @override
  String get authErrorUnknown => 'कुछ गड़बड़ हो गई। कृपया दोबारा कोशिश करें।';

  @override
  String get authErrorDetails => 'विवरण';

  @override
  String get regPrefix => 'पंज.';

  @override
  String get allRightsReserved => 'सर्वाधिकार सुरक्षित';

  @override
  String get editProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get editProfileSubtitle => 'प्रिस्क्रिप्शन लेटरहेड पर दिखता है।';

  @override
  String get doctorName => 'डॉक्टर का नाम';

  @override
  String get qualifications => 'योग्यताएँ';

  @override
  String get registrationNumber => 'पंजीकरण संख्या';

  @override
  String get clinicName => 'क्लिनिक / अस्पताल का नाम';

  @override
  String get clinicAddress => 'क्लिनिक का पता';

  @override
  String get clinicPhone => 'क्लिनिक फ़ोन';

  @override
  String get profilePhone => 'आपका मोबाइल नंबर';

  @override
  String get profileOptional => 'वैकल्पिक';

  @override
  String get profileRequiredHint =>
      '* वाले फ़ील्ड हर प्रिस्क्रिप्शन पर छपते हैं और कानूनन ज़रूरी हैं।';

  @override
  String get profileSectionDoctor => 'डॉक्टर की जानकारी';

  @override
  String get profileSectionClinic => 'क्लिनिक की जानकारी';

  @override
  String get profileNameHint => 'जैसे Dr. Asha Verma';

  @override
  String get profileQualificationsHint => 'जैसे MBBS, MD (Medicine)';

  @override
  String get profileRegNoHint => 'राज्य मेडिकल काउंसिल नंबर';

  @override
  String get profilePhoneHint => '10 अंकों का मोबाइल नंबर';

  @override
  String get profilePhoneInvalid => 'सही मोबाइल नंबर डालें';

  @override
  String get profileClinicNameHint => 'क्लिनिक या अस्पताल का नाम';

  @override
  String get profileClinicAddressHint => 'इलाका, शहर, राज्य, पिन';

  @override
  String get profileClinicPhoneHint => 'लैंडलाइन या रिसेप्शन नंबर';

  @override
  String get profileSavedOffline =>
      'इस डिवाइस पर सेव — ऑनलाइन होने पर सिंक होगा';

  @override
  String get profileSaveFailed => 'प्रोफ़ाइल सेव नहीं हो सकी';

  @override
  String get profileRetry => 'दोबारा कोशिश करें';

  @override
  String get profileIncompleteNudgeTitle =>
      'प्रिस्क्रिप्शन साइन करने के लिए प्रोफ़ाइल पूरी करें';

  @override
  String get profileIncompleteNudgeBody =>
      'अपना नाम, रजिस्ट्रेशन नंबर, क्लिनिक और हस्ताक्षर जोड़ें।';

  @override
  String get signatureTitle => 'हस्ताक्षर';

  @override
  String get signatureSubtitle => 'आपके साइन किए हर प्रिस्क्रिप्शन पर छपता है।';

  @override
  String get signatureAdd => 'हस्ताक्षर जोड़ें';

  @override
  String get signatureUpdate => 'हस्ताक्षर बदलें';

  @override
  String get signatureDraw => 'बनाएँ';

  @override
  String get signatureUpload => 'अपलोड करें';

  @override
  String get signatureClear => 'मिटाएँ';

  @override
  String get signatureUse => 'यह हस्ताक्षर उपयोग करें';

  @override
  String get signatureEmptyError => 'कृपया पहले अपने हस्ताक्षर बनाएँ।';

  @override
  String get signatureHint => 'लाइन के ऊपर उँगली या माउस से हस्ताक्षर करें';

  @override
  String get signatureUploadHint =>
      'सफ़ेद कागज़ पर किए अपने हस्ताक्षर की साफ़ फ़ोटो या स्कैन चुनें (PNG या JPEG)।';

  @override
  String get signatureChooseImage => 'इमेज चुनें';

  @override
  String get signatureChangeImage => 'दूसरी चुनें';

  @override
  String get signatureUnsupportedFormat => 'कृपया PNG या JPEG इमेज चुनें।';

  @override
  String get signatureLoadFailed => 'वह इमेज लोड नहीं हो सकी';

  @override
  String get signatureNone => 'अभी कोई हस्ताक्षर नहीं';

  @override
  String get signatureSaved => 'हस्ताक्षर सेव हो गए';

  @override
  String get signatureSaveFailed => 'हस्ताक्षर सेव नहीं हो सके';

  @override
  String get onboardingTitle => 'अपना प्रिस्क्रिप्शन सेट करें';

  @override
  String get onboardingSubtitle =>
      'ये जानकारी आपके साइन किए हर प्रिस्क्रिप्शन पर दिखती है।';

  @override
  String get onboardingStepDoctor => 'डॉक्टर';

  @override
  String get onboardingStepClinic => 'क्लिनिक';

  @override
  String get onboardingStepSignature => 'हस्ताक्षर';

  @override
  String get onboardingDoctorTitle => 'आपकी जानकारी';

  @override
  String get onboardingDoctorBody =>
      'ठीक वैसे ही जैसे वे लेटरहेड पर दिखनी चाहिए।';

  @override
  String get onboardingClinicTitle => 'आपका क्लिनिक';

  @override
  String get onboardingClinicBody =>
      'प्रिस्क्रिप्शन पर छपने वाला प्रैक्टिस का नाम और पता।';

  @override
  String get onboardingSignatureTitle => 'आपके हस्ताक्षर';

  @override
  String get onboardingSignatureBody =>
      'इन्हें एक बार बनाएँ या फ़ोटो अपलोड करें। ये निजी रूप से सेव होते हैं और सिर्फ़ आपके साइन किए प्रिस्क्रिप्शन पर छपते हैं।';

  @override
  String get onboardingContinue => 'आगे बढ़ें';

  @override
  String get onboardingBack => 'वापस';

  @override
  String get onboardingFinish => 'पूरा करें';

  @override
  String get onboardingSignatureRequired =>
      'पूरा करने के लिए अपने हस्ताक्षर जोड़ें।';

  @override
  String get onboardingSignOut => 'साइन आउट';

  @override
  String onboardingSignedInAs(String email) {
    return '$email के रूप में साइन इन';
  }

  @override
  String get signGateTitle => 'साइन करने के लिए प्रोफ़ाइल पूरी करें';

  @override
  String get signGateBody =>
      'प्रिस्क्रिप्शन पर लिखने वाले डॉक्टर की जानकारी होनी चाहिए। साइन करने से पहले ये जोड़ें:';

  @override
  String get signGateCompleteProfile => 'प्रोफ़ाइल पूरी करें';

  @override
  String get signGateOk => 'ठीक है';

  @override
  String get signGatePatientNameTitle => 'मरीज़ का नाम नहीं है';

  @override
  String get signGatePatientNameBody =>
      'प्रिस्क्रिप्शन साइन करने से पहले मरीज़ का नाम डालें।';

  @override
  String get signGateMedicineNameTitle => 'दवा का नाम नहीं है';

  @override
  String signGateMedicineNameBody(int n) {
    return 'दवा $n का कोई नाम नहीं है। साइन करने से पहले नाम डालें या उसे हटाएँ।';
  }

  @override
  String pdfDocumentTitle(String name) {
    return 'प्रिस्क्रिप्शन — $name';
  }

  @override
  String get pdfPatient => 'मरीज़';

  @override
  String get pdfDate => 'दिनांक';

  @override
  String get pdfAge => 'उम्र';

  @override
  String get pdfGender => 'लिंग';

  @override
  String get pdfPhone => 'फ़ोन';

  @override
  String pdfAgeYears(int age) {
    return '$age वर्ष';
  }

  @override
  String get pdfRegNo => 'पंजीकरण सं.';

  @override
  String get pdfDiagnosis => 'निदान';

  @override
  String get pdfNoMedicines => 'कोई दवा नहीं लिखी गई।';

  @override
  String get pdfColMedicine => 'दवा';

  @override
  String get pdfColDosage => 'खुराक';

  @override
  String get pdfColFrequency => 'कितनी बार';

  @override
  String get pdfColDuration => 'अवधि';

  @override
  String get pdfColTiming => 'समय';

  @override
  String get pdfInvestigations => 'सुझाई गई जाँचें';

  @override
  String get pdfInstructions => 'निर्देश';

  @override
  String get pdfAdvice => 'सलाह';

  @override
  String get pdfFollowUp => 'फ़ॉलो-अप';

  @override
  String pdfFollowUpAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days दिन बाद',
      one: '1 दिन बाद',
    );
    return '$_temp0';
  }

  @override
  String get pdfNextVisit => 'अगली मुलाक़ात';

  @override
  String get pdfPreviousReports => 'पिछली रिपोर्टें';

  @override
  String pdfReportsAttachedFor(String name) {
    return '$name के लिए संलग्न';
  }

  @override
  String pdfReportCaption(int number) {
    return 'रिपोर्ट $number';
  }

  @override
  String get pdfComputerGenerated => 'यह कंप्यूटर से बना प्रिस्क्रिप्शन है';

  @override
  String get pdfFooterTagline =>
      'Rxvarta AI द्वारा तैयार  |  सुरक्षित  |  निजी';

  @override
  String get pdfAwaitingSignature => 'हस्ताक्षर बाकी';

  @override
  String get unsavedChanges => 'असहेजे परिवर्तन';

  @override
  String get unsavedChangesBody =>
      'आपके पास असहेजे परिवर्तन हैं। क्या आप उन्हें सहेजना चाहते हैं या छोड़ना चाहते हैं?';

  @override
  String get discard => 'छोड़ें';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get done => 'पूर्ण';

  @override
  String get required => 'आवश्यक';

  @override
  String get navHome => 'होम';

  @override
  String get navPatients => 'मरीज़';

  @override
  String get navSettings => 'सेटिंग्स';

  @override
  String get notFound => 'नहीं मिला';

  @override
  String get newConsultation => 'नया परामर्श';

  @override
  String get whoIsThisFor => 'यह परामर्श किसके लिए है?';

  @override
  String get newPatientTitle => 'नया मरीज़';

  @override
  String get newPatientDesc =>
      'पहली बार आने वाले मरीज़ का नाम, उम्र, लिंग और मोबाइल नंबर जोड़ें।';

  @override
  String get existingPatientTitle => 'मौजूदा मरीज़';

  @override
  String get existingPatientDesc =>
      'इतिहास से मरीज़ खोजें, उनकी रिपोर्ट देखें, फिर नया परामर्श शुरू करें।';

  @override
  String get stepDetails => 'विवरण';

  @override
  String get stepRecording => 'रिकॉर्डिंग';

  @override
  String get stepReview => 'समीक्षा';

  @override
  String get stepShare => 'साझा';

  @override
  String get patientDetails => 'मरीज़ का विवरण';

  @override
  String get editPatientDetails => 'मरीज़ का विवरण संपादित करें';

  @override
  String get enterBasicInfo => 'मरीज़ की बुनियादी जानकारी दर्ज करें';

  @override
  String get confirmDetailsConsent => 'विवरण और सहमति की पुष्टि करें';

  @override
  String get patientName => 'मरीज़ का नाम';

  @override
  String get patientNameHint => 'मरीज़ का पूरा नाम दर्ज करें';

  @override
  String get nameRequired => 'नाम आवश्यक है';

  @override
  String get age => 'उम्र';

  @override
  String get gender => 'लिंग';

  @override
  String get select => 'चुनें';

  @override
  String get whatsappNumber => 'व्हाट्सएप नंबर';

  @override
  String get mobileHint => '10 अंकों का मोबाइल नंबर';

  @override
  String get prescriptionShareNote => 'इस नंबर पर प्रिस्क्रिप्शन भेजा जाएगा';

  @override
  String get previousReports => 'पिछली रिपोर्ट (वैकल्पिक)';

  @override
  String get previousReportsDesc =>
      'पहले की रिपोर्ट स्कैन या संलग्न करें — वे प्रिस्क्रिप्शन PDF में जोड़ी जाती हैं।';

  @override
  String get addReport => 'रिपोर्ट जोड़ें';

  @override
  String get takePhoto => 'फ़ोटो लें';

  @override
  String get chooseFromGallery => 'गैलरी से चुनें';

  @override
  String get reportLabelHint => 'लेबल (जैसे रक्त जाँच, 2 जनवरी)';

  @override
  String get consentLine =>
      'मरीज़ ने रिकॉर्ड किए जाने की सहमति दी है (DPDP अधिनियम)';

  @override
  String get continueToRecording => 'रिकॉर्डिंग पर जाएँ';

  @override
  String get couldNotAddReport => 'रिपोर्ट नहीं जोड़ी जा सकी';

  @override
  String get couldNotSavePatient => 'मरीज़ सहेजा नहीं जा सका';

  @override
  String get couldNotSaveChanges => 'आपके बदलाव सहेजे नहीं जा सके';

  @override
  String get nothingHeardInRecording =>
      'इस रिकॉर्डिंग में कोई परामर्श सुनाई नहीं दिया। जाँच लें कि माइक्रोफ़ोन काम कर रहा है, फिर दोबारा रिकॉर्ड करें।';

  @override
  String get retryProcessing => 'इसी रिकॉर्डिंग से फिर कोशिश करें';

  @override
  String get recordAgain => 'फिर से रिकॉर्ड करें';

  @override
  String get consultationErrorOffline =>
      'इंटरनेट कनेक्शन नहीं है। आपकी रिकॉर्डिंग इस फ़ोन पर सेव है; इंटरनेट आने पर फिर कोशिश करें दबाएँ।';

  @override
  String get consultationErrorProcessing =>
      'रिकॉर्डिंग प्रोसेस नहीं हो सकी। यह इस फ़ोन पर सेव है; फिर कोशिश करें दबाएँ।';

  @override
  String get errorSessionExpired =>
      'आपका सेशन समाप्त हो गया है। कृपया फिर से साइन इन करें।';

  @override
  String get consultationErrorStorage =>
      'रिकॉर्डिंग इस फ़ोन पर सेव नहीं हो सकी। खाली स्टोरेज जाँचें और फिर से रिकॉर्ड करें।';

  @override
  String get errorUnexpected => 'कुछ गलत हो गया। कृपया फिर से कोशिश करें।';

  @override
  String get errorOffline => 'इंटरनेट कनेक्शन नहीं है।';

  @override
  String get errorStorage =>
      'इस फ़ोन पर फ़ाइलें पढ़ी या सेव नहीं की जा सकीं। जाँचें कि स्टोरेज खाली है।';

  @override
  String get errorPermission =>
      'अनुमति नहीं मिली। फ़ोन की सेटिंग्स में Rxvarta को अनुमति दें।';

  @override
  String get errorInvalidBackup =>
      'यह फ़ाइल आपके अकाउंट के लिए उपयोगी Rxvarta बैकअप नहीं है।';

  @override
  String get errorBackupTooNew =>
      'यह बैकअप Rxvarta के नए संस्करण से बना है। ऐप अपडेट करें, फिर रीस्टोर करें।';

  @override
  String get patientAlreadyExists => 'मरीज़ पहले से मौजूद है';

  @override
  String get patientExistsBody =>
      'इस नंबर वाला मरीज़ पहले से आपके रिकॉर्ड में है:';

  @override
  String get patientExistsQuestion =>
      'क्या यह परामर्श उनके मौजूदा इतिहास में जोड़ें?';

  @override
  String get createNew => 'नया बनाएँ';

  @override
  String get useExisting => 'मौजूदा उपयोग करें';

  @override
  String get consultationRecording => 'परामर्श रिकॉर्डिंग';

  @override
  String get processingAudio => 'ऑडियो प्रोसेस हो रहा है...';

  @override
  String get chooseRecordingOption => 'रिकॉर्डिंग विकल्प चुनें';

  @override
  String get paused => 'रुका हुआ';

  @override
  String get recordingConversation => 'बातचीत रिकॉर्ड हो रही है...';

  @override
  String get doctorPlusPatient => 'डॉक्टर + मरीज़';

  @override
  String get saySomething => 'कुछ बोलिए...';

  @override
  String get readyBothVoices => 'तैयार — दोनों आवाज़ें रिकॉर्ड होंगी';

  @override
  String get transcribingConversation => 'बातचीत ट्रांसक्राइब हो रही है...';

  @override
  String get extractingPrescription => 'प्रिस्क्रिप्शन निकाला जा रहा है...';

  @override
  String get recordingTip =>
      'फोन को डॉक्टर और मरीज़ के बीच मेज़ पर रखें, फिर स्टार्ट दबाएँ।';

  @override
  String get addingToConsultation =>
      'परामर्श में जोड़ा जा रहा है — नया ऑडियो मौजूदा ट्रांसक्रिप्ट में मिलाया जाएगा।';

  @override
  String get startConsultation => 'परामर्श शुरू करें';

  @override
  String get checkingConnection => 'कनेक्शन जाँचा जा रहा है…';

  @override
  String get offlineReconnect => 'ऑफलाइन — रिकॉर्ड करने के लिए फिर से जुड़ें';

  @override
  String get resume => 'जारी रखें';

  @override
  String get pause => 'रोकें';

  @override
  String get minimumFiveSeconds => 'कम से कम 5 सेकंड आवश्यक';

  @override
  String get recordingApproachingLimit => 'रिकॉर्डिंग सीमा के करीब';

  @override
  String get offlineNotice =>
      'इंटरनेट कनेक्शन नहीं है। परामर्श ट्रांसक्राइब और प्रोसेस करने के लिए इंटरनेट चाहिए।';

  @override
  String get offlineWillQueue =>
      'आप ऑफ़लाइन हैं। रिकॉर्डिंग इस फ़ोन पर सेव रहेगी और इंटरनेट आने पर प्रोसेस होगी।';

  @override
  String get consultationQueued =>
      'इस फ़ोन पर सेव हो गया। इंटरनेट आने पर प्रोसेस होगा।';

  @override
  String get processLater => 'बाद में प्रोसेस करें';

  @override
  String get pendingTitle => 'प्रोसेस होना बाकी';

  @override
  String get pendingQueued => 'इंटरनेट का इंतज़ार';

  @override
  String get pendingProcessing => 'प्रोसेस हो रहा है…';

  @override
  String get pendingReady => 'समीक्षा के लिए तैयार';

  @override
  String get pendingFailed => 'प्रोसेस नहीं हो सका';

  @override
  String get pendingDismiss => 'हटाएँ';

  @override
  String get checkingConnectionRetry =>
      'आपका कनेक्शन जाँचा जा रहा है — कृपया थोड़ी देर बाद फिर कोशिश करें।';

  @override
  String get internetLostStillRecording =>
      'इंटरनेट नहीं है। रिकॉर्डिंग जारी है; इंटरनेट आने पर परामर्श प्रोसेस होगा।';

  @override
  String get recordingNotificationTitle => 'परामर्श रिकॉर्ड हो रहा है';

  @override
  String get recordingNotificationText =>
      'स्क्रीन बंद होने पर भी Rxvarta रिकॉर्डिंग जारी रखता है।';

  @override
  String get micPermissionNeeded =>
      'परामर्श रिकॉर्ड करने के लिए माइक्रोफ़ोन अनुमति चाहिए।';

  @override
  String get micAccessNeeded => 'माइक्रोफ़ोन एक्सेस चाहिए';

  @override
  String get micEnableInSettings =>
      'रिकॉर्ड करने के लिए सेटिंग्स में माइक्रोफ़ोन अनुमति चालू करें।';

  @override
  String get openSettings => 'सेटिंग्स खोलें';

  @override
  String get stopRecordingGoBack => 'रिकॉर्डिंग रोककर वापस जाएँ?';

  @override
  String get recordingWillBeLost =>
      'आपकी रिकॉर्डिंग खो जाएगी। इसे वापस नहीं लाया जा सकता।';

  @override
  String get stopAndGoBack => 'रोकें और वापस जाएँ';

  @override
  String get discardRecording => 'रिकॉर्डिंग छोड़ें?';

  @override
  String get audioWillBeDiscarded =>
      'आपका रिकॉर्ड किया ऑडियो हटा दिया जाएगा। इसे वापस नहीं लाया जा सकता।';

  @override
  String get discardAndGoBack => 'छोड़ें और वापस जाएँ';

  @override
  String get startFresh => 'नए सिरे से शुरू करें?';

  @override
  String get startFreshBody => 'यह आपके मौजूदा परामर्श डेटा को बदल देगा।';

  @override
  String get startFreshConfirm => 'नए सिरे से शुरू करें';

  @override
  String get existingRecordingNotice =>
      'इस परामर्श के लिए आपके पास पहले से रिकॉर्डिंग है।';

  @override
  String get duration => 'अवधि';

  @override
  String get addExtraConversation => 'अतिरिक्त बातचीत जोड़ें';

  @override
  String get addExtraDesc => 'और रिकॉर्ड करें और मौजूदा डेटा में मिलाएँ';

  @override
  String get startNewConversation => 'नई बातचीत शुरू करें';

  @override
  String get startNewDesc => 'पिछला हटाएँ और नया रिकॉर्ड करें';

  @override
  String get patientHistory => 'मरीज़ का इतिहास';

  @override
  String get viewAllConsultations => 'सभी परामर्श और रिकॉर्ड देखें';

  @override
  String get statTotal => 'कुल';

  @override
  String get statThisWeek => 'इस सप्ताह';

  @override
  String get statToday => 'आज';

  @override
  String get searchPatientsHint => 'मरीज़ खोजें...';

  @override
  String get noPatientsFound => 'कोई मरीज़ नहीं मिला';

  @override
  String get noConsultationsYet => 'अभी कोई परामर्श नहीं';

  @override
  String get unknownPatient => 'अज्ञात मरीज़';

  @override
  String get yesterday => 'कल';

  @override
  String get consultationOne => 'परामर्श';

  @override
  String get consultationMany => 'परामर्श';

  @override
  String get findPatientTitle => 'मरीज़ खोजें';

  @override
  String get searchByNameOrNumber => 'नाम या नंबर से खोजें…';

  @override
  String get noMatchingPatients => 'कोई मेल खाता मरीज़ नहीं';

  @override
  String get patientFallback => 'मरीज़';

  @override
  String get patientNotFound => 'मरीज़ नहीं मिला';

  @override
  String get consultationHistory => 'परामर्श इतिहास';

  @override
  String get visitsWillAppearHere =>
      'इस मरीज़ की भेंटों के रिकॉर्ड यहाँ दिखेंगे।';

  @override
  String get signed => 'हस्ताक्षरित';

  @override
  String get diagnosisLabel => 'निदान';

  @override
  String get symptomsLabel => 'लक्षण';

  @override
  String get medicinesLabel => 'दवाइयाँ';

  @override
  String get noMedicinesRecorded => 'कोई दवा दर्ज नहीं।';

  @override
  String get followUpLabel => 'फॉलो-अप';

  @override
  String get afterDaysOne => '1 दिन बाद';

  @override
  String afterDaysMany(int n) {
    return '$n दिन बाद';
  }

  @override
  String get opening => 'खोला जा रहा है…';

  @override
  String get viewPrescription => 'प्रिस्क्रिप्शन देखें';

  @override
  String get share => 'साझा करें';

  @override
  String get couldNotSharePrescription => 'प्रिस्क्रिप्शन साझा नहीं हो सका';

  @override
  String get couldNotSharePdf => 'PDF साझा नहीं हो सका';

  @override
  String get prescriptionFallback => 'प्रिस्क्रिप्शन';

  @override
  String get newConsultationTooltip => 'इस मरीज़ के आधार पर नया परामर्श बनाएँ';

  @override
  String get couldNotGeneratePrescription => 'प्रिस्क्रिप्शन नहीं बन सका';

  @override
  String get generatingPrescription => 'प्रिस्क्रिप्शन बन रहा है...';

  @override
  String get preparingPdf => 'PDF तैयार हो रहा है…';

  @override
  String get shareOnWhatsapp => 'व्हाट्सएप पर साझा करें';

  @override
  String get shareViaOtherApps => 'अन्य ऐप से साझा करें';

  @override
  String get startNewConsultationCta => 'नया परामर्श शुरू करें';

  @override
  String get reviewPrescription => 'प्रिस्क्रिप्शन की समीक्षा';

  @override
  String get verifyDetails => 'ट्रांसक्राइब किए विवरण जाँचें और संपादित करें';

  @override
  String get reviewTitle => 'समीक्षा';

  @override
  String get visitNotFound => 'भेंट नहीं मिली';

  @override
  String get goBackToRecording => 'रिकॉर्डिंग पर वापस जाएँ?';

  @override
  String get goBackToRecordingBody =>
      'आप इस परामर्श में और जोड़ सकते हैं या नई रिकॉर्डिंग शुरू कर सकते हैं।';

  @override
  String get stay => 'यहीं रहें';

  @override
  String get goBack => 'वापस जाएँ';

  @override
  String get consultationSummary => 'परामर्श सारांश';

  @override
  String get transcriptTitle => 'प्रतिलेख';

  @override
  String get transcriptSubtitle => 'जैसा Sarvam STT ने सुना';

  @override
  String get tapToAddSummary => 'सारांश जोड़ने के लिए पेंसिल दबाएँ';

  @override
  String get summaryHint => 'मरीज़ क्यों आया और आगे की योजना संक्षेप में लिखें';

  @override
  String get patientInformation => 'मरीज़ की जानकारी';

  @override
  String get nameLabel => 'नाम';

  @override
  String get yearsLabel => 'वर्ष';

  @override
  String get whatsappLabel => 'व्हाट्सएप';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get tapToSet => 'सेट करने के लिए दबाएँ';

  @override
  String get diagnosisHint => 'जैसे वायरल बुखार';

  @override
  String get noDiagnosisTapPencil =>
      'कोई निदान नहीं — जोड़ने के लिए पेंसिल दबाएँ';

  @override
  String get investigationsTitle => 'जाँचें';

  @override
  String get noInvestigationsTapPencil =>
      'कोई जाँच नहीं — जोड़ने के लिए पेंसिल दबाएँ';

  @override
  String get investigationsHint => 'कराई जाने वाली जाँचें — प्रति पंक्ति एक';

  @override
  String get doctorNotesTitle => 'डॉक्टर के नोट्स';

  @override
  String get doctorNotesNotPrinted =>
      'आपके रिकॉर्ड के लिए; प्रिस्क्रिप्शन पर नहीं छपते';

  @override
  String get noDoctorNotesTapPencil =>
      'कोई नोट नहीं — जोड़ने के लिए पेंसिल दबाएँ';

  @override
  String get doctorNotesHint => 'इस परामर्श पर आपके अपने नोट्स';

  @override
  String get adviceTitle => 'सलाह';

  @override
  String get noAdviceTapPencil =>
      'अभी कोई सलाह नहीं — जोड़ने के लिए पेंसिल दबाएँ';

  @override
  String get adviceHint => 'सामान्य मार्गदर्शन — प्रति पंक्ति एक';

  @override
  String get instructionsTitle => 'निर्देश';

  @override
  String get noInstructionsTapPencil =>
      'अभी कोई निर्देश नहीं — जोड़ने के लिए पेंसिल दबाएँ';

  @override
  String get instructionsHint => 'नैदानिक निर्देश — प्रति पंक्ति एक';

  @override
  String get noFollowUpSet => 'कोई फॉलो-अप नहीं';

  @override
  String get daysSuffix => 'दिन';

  @override
  String get prescribedMedicines => 'निर्धारित दवाइयाँ';

  @override
  String get noMedicationsYet => 'अभी कोई दवा दर्ज नहीं।';

  @override
  String get addMedicine => 'दवा जोड़ें';

  @override
  String get medicineLabel => 'दवा';

  @override
  String get removeMedicine => 'दवा हटाएँ';

  @override
  String get dosageLabel => 'खुराक';

  @override
  String get durationLabel => 'अवधि';

  @override
  String get frequencyLabel => 'आवृत्ति';

  @override
  String get timingLabel => 'समय';

  @override
  String get timingBeforeFood => 'भोजन से पहले';

  @override
  String get timingAfterFood => 'भोजन के बाद';

  @override
  String get timingWithFood => 'भोजन के साथ';

  @override
  String get timingEmptyStomach => 'खाली पेट';

  @override
  String get timingBeforeBed => 'सोने से पहले';

  @override
  String get timingAsDirected => 'निर्देशानुसार';

  @override
  String get aiDisclaimer =>
      'AI केवल वही निकालता है जो डॉक्टर ने कहा। हस्ताक्षर से पहले सारांश और दवाइयाँ जाँचें।';

  @override
  String get generatePdf => 'प्रिस्क्रिप्शन PDF बनाएँ';

  @override
  String get signAndGeneratePdf => 'हस्ताक्षर करें और PDF बनाएँ';

  @override
  String get icdCodeTitle => 'ICD-10 कोड';

  @override
  String get icdVerifyWarning =>
      'AI सुझाव — इस पर भरोसा करने से पहले कोड जाँच लें।';

  @override
  String get icdCodeField => 'कोड (जैसे B34.9)';

  @override
  String get descriptionField => 'विवरण';

  @override
  String get icdFooterNote =>
      'यह कोड निदान के आधार पर AI ने सुझाया है। नैदानिक या बिलिंग उपयोग से पहले सटीकता जाँचें।';

  @override
  String get suggestedDifferentials => 'संभावित विभेदक निदान';

  @override
  String get aiSuggestionVerify => 'AI सुझाव — जाँचें';

  @override
  String get differentialsBasedOn =>
      'बताए गए लक्षणों के आधार पर। डॉक्टर को जाँचना आवश्यक है।';

  @override
  String get accept => 'स्वीकारें';

  @override
  String get prescriptionReady => 'प्रिस्क्रिप्शन तैयार';

  @override
  String get reviewAndShare => 'जाँचें और मरीज़ को भेजें';

  @override
  String get generatingPdfLong => 'प्रिस्क्रिप्शन PDF बन रहा है…';

  @override
  String get couldNotGeneratePdf => 'PDF नहीं बन सका';
}

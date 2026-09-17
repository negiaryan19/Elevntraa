// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appName => 'Rxvarta';

  @override
  String get appTagline => 'स्मार्ट मेडिकल डॉक्युमेंटेशन';

  @override
  String get online => 'ऑनलाइन';

  @override
  String get offline => 'ऑफलाइन';

  @override
  String get checking => 'तपासत आहे';

  @override
  String get goodMorning => 'सुप्रभात';

  @override
  String get goodAfternoon => 'नमस्कार';

  @override
  String get goodEvening => 'शुभ संध्याकाळ';

  @override
  String get doctorFallback => 'डॉक्टर';

  @override
  String get startNewConsultation => 'नवीन सल्लामसलत सुरू करा';

  @override
  String get startNewConsultationSubtitle =>
      'रुग्णाची भेट रेकॉर्ड आणि ट्रान्सक्राइब करा';

  @override
  String get newPatient => 'नवीन रुग्ण';

  @override
  String get findPatient => 'रुग्ण शोधा';

  @override
  String get allPatients => 'सर्व रुग्ण';

  @override
  String get recentPatients => 'अलीकडील रुग्ण';

  @override
  String get seeAll => 'सर्व पहा';

  @override
  String get noPatientsYet => 'अद्याप कोणतेही रुग्ण नाहीत';

  @override
  String get noPatientsYetSubtitle =>
      'तुमचा पहिला रुग्ण जोडण्यासाठी सल्लामसलत सुरू करा.';

  @override
  String get securityFooter =>
      'सुरक्षित - HIPAA अनुरूप - एंड-टू-एंड एन्क्रिप्टेड';

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'स्त्री';

  @override
  String get other => 'इतर';

  @override
  String get years => 'वर्षे';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get settingsSubtitle => 'तुमच्या अ‍ॅप प्राधान्ये व्यवस्थापित करा';

  @override
  String get sectionAccount => 'खाते';

  @override
  String get sectionPreferences => 'प्राधान्ये';

  @override
  String get sectionDataPrivacy => 'डेटा आणि गोपनीयता';

  @override
  String get sectionSupport => 'सहाय्य';

  @override
  String get profileSettings => 'प्रोफाइल सेटिंग्ज';

  @override
  String get profileSettingsSubtitle =>
      'नाव, पात्रता, नोंदणी आणि क्लिनिक तपशील';

  @override
  String get profileUpdated => 'प्रोफाइल अद्ययावत झाले';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get darkThemeActive => 'डार्क थीम सक्रिय';

  @override
  String get lightThemeActive => 'लाइट थीम सक्रिय';

  @override
  String get appLanguage => 'अ‍ॅपची भाषा';

  @override
  String get appLanguageSubtitle => 'अ‍ॅप इंटरफेसची भाषा निवडा';

  @override
  String get chooseLanguage => 'भाषा निवडा';

  @override
  String get exportData => 'डेटा निर्यात करा';

  @override
  String get backupTitle => 'बॅकअप आणि सिंक';

  @override
  String get backupIntro =>
      'तुमच्या नोंदींची एक प्रत तुमच्याच खासगी क्लाउड फोल्डरमध्ये ठेवते, त्यामुळे फोन हरवला तरी काही जात नाही.';

  @override
  String get backupIncludes =>
      'समाविष्ट: रुग्ण, कन्सल्टेशन, प्रिस्क्रिप्शन, रिपोर्ट फोटो, तुमची प्रोफाइल आणि सही.';

  @override
  String get backupExcludes =>
      'समाविष्ट नाही: कन्सल्टेशनच्या रेकॉर्डिंग (प्रोसेसिंगनंतर त्या हटवल्या जातात).';

  @override
  String backupLastAt(String time) {
    return 'शेवटचा बॅकअप $time';
  }

  @override
  String get backupNever => 'अद्याप बॅकअप नाही';

  @override
  String get backupNow => 'आता बॅकअप घ्या';

  @override
  String backupLatestRemote(String time, String size) {
    return 'क्लाउडमधील नवीनतम: $time ($size)';
  }

  @override
  String get backupNoRemote => 'क्लाउडमध्ये अजून बॅकअप नाही';

  @override
  String get backupRestoreLatest => 'नवीनतम बॅकअप पुनर्संचयित करा';

  @override
  String get backupRestoreConfirmTitle => 'या फोनवरील डेटा बदलायचा?';

  @override
  String backupRestoreConfirmBody(String time) {
    return 'या फोनवरील तुमच्या नोंदी $time च्या बॅकअपने बदलल्या जातील. हा फोन वापरणाऱ्या इतर डॉक्टरांवर याचा परिणाम होणार नाही. हे पूर्ववत करता येणार नाही.';
  }

  @override
  String get backupRestoreConfirm => 'पुनर्संचयित करा';

  @override
  String get backupStageCollecting => 'तुमच्या नोंदी गोळा करत आहोत…';

  @override
  String get backupStageZipping => 'पॅक करत आहोत…';

  @override
  String get backupStageUploading => 'अपलोड होत आहे…';

  @override
  String get backupStageDownloading => 'बॅकअप डाउनलोड होत आहे…';

  @override
  String get backupStageRestoring => 'पुनर्संचयित होत आहे…';

  @override
  String get backupDone => 'बॅकअप पूर्ण झाला';

  @override
  String get backupRestored => 'बॅकअप पुनर्संचयित झाला';

  @override
  String get backupRestartHint =>
      'पुनर्संचयित नोंदी पाहण्यासाठी अ‍ॅप बंद करून पुन्हा उघडा.';

  @override
  String backupFailed(String reason) {
    return 'बॅकअप अयशस्वी: $reason';
  }

  @override
  String backupRestoreFailed(String reason) {
    return 'पुनर्संचयन अयशस्वी: $reason';
  }

  @override
  String get backupNeedsInternet => 'बॅकअप घेण्यासाठी इंटरनेटला जोडा.';

  @override
  String get exportPreparing => 'तुमचा एक्सपोर्ट तयार होत आहे…';

  @override
  String get exportShareSubject => 'Rxvarta डेटा एक्सपोर्ट';

  @override
  String get exportShareText => 'माझ्या Rxvarta नोंदींचा एक्सपोर्ट.';

  @override
  String exportFailed(String reason) {
    return 'डेटा एक्सपोर्ट करता आला नाही: $reason';
  }

  @override
  String get exportEmpty => 'एक्सपोर्ट करण्यासाठी अजून काही नाही.';

  @override
  String exportSavedTo(String path) {
    return '$path येथे सेव्ह केले';
  }

  @override
  String get privacySecurity => 'गोपनीयता आणि सुरक्षा';

  @override
  String get termsConditions => 'अटी आणि शर्ती';

  @override
  String get termsConditionsSubtitle => 'आमच्या सेवा अटी वाचा';

  @override
  String get helpSupport => 'मदत आणि सहाय्य';

  @override
  String get helpSupportSubtitle => 'मदत मिळवा किंवा आमच्याशी संपर्क साधा';

  @override
  String get settingsProfileSetUp => 'तुमची प्रोफाइल तयार करा';

  @override
  String get settingsProfileIncompleteChip =>
      'प्रोफाइल अपूर्ण — प्रिस्क्रिप्शनवर सही करता येणार नाही';

  @override
  String get settingsSignature => 'सही';

  @override
  String get settingsSignatureSubtitleAdded =>
      'जोडली — तुम्ही सही केलेल्या प्रत्येक प्रिस्क्रिप्शनवर छापली जाते';

  @override
  String get settingsSignatureSubtitleMissing => 'अद्याप जोडलेली नाही';

  @override
  String get settingsBackupSync => 'बॅकअप आणि सिंक';

  @override
  String get settingsBackupSubtitleNever => 'अद्याप बॅकअप नाही';

  @override
  String settingsBackupSubtitleLast(String time) {
    return 'शेवटचा बॅकअप $time';
  }

  @override
  String get settingsExportSubtitle =>
      'तुमच्या सर्व नोंदींची प्रत सेव्ह किंवा शेअर करा';

  @override
  String get settingsPrivacySubtitle =>
      'तुमचा डेटा कुठे राहतो आणि तो कसा हटवायचा';

  @override
  String get settingsSectionLegal => 'कायदेशीर';

  @override
  String get settingsPrivacyPolicy => 'प्रायव्हसी पॉलिसी';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'तुमच्या आणि तुमच्या रुग्णांच्या डेटाचे काय होते';

  @override
  String settingsVersion(String version, String build) {
    return 'Rxvarta v$version ($build)';
  }

  @override
  String get settingsTimeJustNow => 'आत्ताच';

  @override
  String settingsTimeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n मिनिटांपूर्वी',
      one: '1 मिनिटापूर्वी',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n तासांपूर्वी',
      one: '1 तासापूर्वी',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n दिवसांपूर्वी',
      one: 'काल',
    );
    return '$_temp0';
  }

  @override
  String get settingsSigningOut => 'साइन आउट होत आहे…';

  @override
  String get logoutConfirmTitle => 'साइन आउट करायचे?';

  @override
  String get logoutConfirmBody =>
      'Rxvarta वापरण्यासाठी तुम्हाला पुन्हा साइन इन करावे लागेल. या डिव्हाइसवरील नोंदी इथेच राहतील.';

  @override
  String get logoutConfirm => 'साइन आउट';

  @override
  String get privacyIntro =>
      'Rxvarta अशा प्रकारे बनवले आहे की रुग्णांच्या नोंदी डॉक्टरांच्याच नियंत्रणात राहतील. हे पान सोप्या शब्दांत सांगते की डेटा कुठे ठेवला जातो, त्यावर कोण प्रक्रिया करते आणि तो कसा हटवायचा.';

  @override
  String get privacyWhereStoredTitle => 'तुमचा डेटा कुठे राहतो';

  @override
  String get privacyWhereStoredDevice =>
      'हे डिव्हाइस — रुग्ण, भेटी, ट्रान्स्क्रिप्ट, प्रिस्क्रिप्शन, रिपोर्ट फोटो आणि रेकॉर्डिंग या फोनवरील अ‍ॅपच्या खासगी स्टोरेजमध्ये राहतात.';

  @override
  String get privacyWhereStoredCloud =>
      'मुंबई, भारत (ap-south-1) येथे होस्ट केलेला Supabase प्रोजेक्ट — तुमचे खाते, डॉक्टर प्रोफाइल, सही आणि बॅकअप.';

  @override
  String get privacyWhereStoredAudio =>
      'रेकॉर्डिंग फक्त प्रोसेसिंगसाठी खासगी स्टोरेज बकेटमध्ये अपलोड होतात, दीर्घकाळ ठेवण्यासाठी नाही.';

  @override
  String get privacyProcessorsTitle => 'यावर प्रक्रिया कोण करते';

  @override
  String get privacyProcessorSarvam =>
      'Sarvam AI — रेकॉर्डिंगचे मजकुरात रूपांतर करते (स्पीच-टू-टेक्स्ट).';

  @override
  String get privacyProcessorGoogle =>
      'Google Gemini — ट्रान्स्क्रिप्टवरून तुमच्या पुनरावलोकनासाठी प्रिस्क्रिप्शनचा मसुदा तयार करते.';

  @override
  String get privacyProcessorSupabase =>
      'Supabase — साइन-इन, फाइल स्टोरेज आणि तुमच्या खात्यामागील डेटाबेस.';

  @override
  String get privacyRetentionTitle => 'किती काळ ठेवला जातो';

  @override
  String get privacyRetentionAudio =>
      'रेकॉर्डिंग: प्रोसेसिंग यशस्वी होताच सर्व्हरवरून हटवली जातात; तोपर्यंत याच डिव्हाइसवर राहतात.';

  @override
  String get privacyRetentionTranscript =>
      'ट्रान्स्क्रिप्ट आणि प्रिस्क्रिप्शन: तुम्ही हटवेपर्यंत या डिव्हाइसवर आणि तुमच्या बॅकअपमध्ये राहतात.';

  @override
  String get privacyRetentionJobs =>
      'प्रोसेसिंग कॅशे: निकाल अ‍ॅपपर्यंत पोहोचल्यावर साफ केला जातो.';

  @override
  String get privacyRoleTitle => 'तुमची आणि आमची भूमिका';

  @override
  String get privacyRoleBody =>
      'डिजिटल पर्सनल डेटा प्रोटेक्शन अ‍ॅक्ट, 2023 अंतर्गत तुमच्या रुग्णांच्या नोंदींसाठी डेटा फिड्युशरी तुम्ही, म्हणजे डॉक्टरच, राहता. Rxvarta त्यांवर फक्त तुमच्या सूचनेनुसार, डेटा प्रोसेसर म्हणून प्रक्रिया करते.';

  @override
  String get privacySecurityTitle => 'सुरक्षा उपाय';

  @override
  String get privacySecurityBody =>
      'डेटा एन्क्रिप्टेड कनेक्शनवरून (TLS) जातो. सर्व्हरवरील नोंदी प्रत्येक खात्यासाठी वेगळ्या अ‍ॅक्सेस नियमांनी सुरक्षित असतात, त्यामुळे त्या फक्त तुमचे साइन-इनच वाचू शकते. तुमचा फोन लॉक ठेवा: जो तो अनलॉक करू शकतो, तो अ‍ॅप उघडू शकतो.';

  @override
  String get privacyDeleteTitle => 'डेटा हटवणे';

  @override
  String get privacyDeleteBody =>
      'या फोनवरून तुमचा डेटा काढून टाकण्यासाठी खालील बटण वापरा. या फोनवर साइन इन करणाऱ्या इतर डॉक्टरांचा डेटा तसाच राहील. रुग्णांच्या नोंदी अद्याप एक-एक करून काढता येत नाहीत. तुमचे खाते आणि आमच्या सर्व्हरवरील डेटा हटवण्यासाठी, ज्या ईमेलने साइन अप केले होते त्याच ईमेलवरून आम्हाला लिहा.';

  @override
  String get privacyDeleteLocal => 'या डिव्हाइसवरील माझा डेटा हटवा';

  @override
  String get privacyDeleteLocalSubtitle =>
      'या फोनवरून तुमचे रुग्ण, भेटी, रेकॉर्डिंग, रिपोर्ट, प्रोफाइल कॅशे आणि सही काढून टाकते आणि तुम्हाला साइन आउट करते. सर्व्हरवरील तुमचे खाते आणि बॅकअप यावर परिणाम होत नाही.';

  @override
  String privacyDeleteLocalBody(String word) {
    return 'या फोनवर साठवलेला तुमचा प्रत्येक रुग्ण, भेट, रेकॉर्डिंग आणि रिपोर्ट काढून टाकला जाईल आणि तुम्ही साइन आउट व्हाल. या फोनवरील इतर डॉक्टरांचा डेटा आणि सर्व्हरवरील तुमचे बॅकअप यावर परिणाम होणार नाही. हे पूर्ववत करता येणार नाही.\n\nपुष्टीसाठी $word टाइप करा.';
  }

  @override
  String get privacyDeleteLocalWord => 'DELETE';

  @override
  String privacyDeleteLocalHint(String word) {
    return '$word टाइप करा';
  }

  @override
  String get privacyDeleteLocalConfirm => 'सर्व काही हटवा';

  @override
  String get privacyDeleting => 'स्थानिक डेटा हटवत आहोत…';

  @override
  String get privacyDeleted => 'स्थानिक डेटा हटवला';

  @override
  String privacyDeletePartial(String details) {
    return 'काही गोष्टी हटवता आल्या नाहीत: $details';
  }

  @override
  String get privacyReadPolicy => 'संपूर्ण प्रायव्हसी पॉलिसी वाचा';

  @override
  String get legalTerms => 'नियम आणि अटी';

  @override
  String get legalPrivacyPolicy => 'प्रायव्हसी पॉलिसी';

  @override
  String legalLastUpdated(String date) {
    return 'शेवटचे अपडेट: $date';
  }

  @override
  String get legalReviewNotice =>
      'अ‍ॅपसोबत आलेली प्रत — ऑफलाइन उपलब्ध. ऑनलाइन नवीन आवृत्ती प्रकाशित झाल्यास ऑनलाइन आवृत्ती लागू होईल.';

  @override
  String get legalViewOnline => 'ऑनलाइन आवृत्ती पहा';

  @override
  String get legalLoadFailed => 'हा दस्तऐवज लोड करता आला नाही.';

  @override
  String get helpTitle => 'मदत आणि सपोर्ट';

  @override
  String get helpSubtitle =>
      'अ‍ॅपबद्दल प्रश्न, सूचना किंवा अडचण? आम्हाला मदत करायला आवडेल.';

  @override
  String helpVersion(String version, String build) {
    return 'अ‍ॅप आवृत्ती $version ($build)';
  }

  @override
  String get helpEmail => 'ईमेल सपोर्ट';

  @override
  String get helpWhatsapp => 'WhatsApp सपोर्ट';

  @override
  String get helpReportProblem => 'समस्या कळवा';

  @override
  String get helpReportProblemSubtitle =>
      'काय झाले आणि ते पुन्हा कसे पाहता येईल ते सांगा';

  @override
  String get helpNotConfigured => 'सपोर्ट संपर्क अजून सेट केलेला नाही';

  @override
  String get helpCouldNotOpen => 'हे तुमच्या डिव्हाइसवर उघडता आले नाही.';

  @override
  String get helpEmailSubject => 'Rxvarta सपोर्ट';

  @override
  String helpEmailBody(String version, String platform) {
    return 'अ‍ॅप आवृत्ती: $version\nप्लॅटफॉर्म: $platform\n\n';
  }

  @override
  String get helpReportSubject => 'Rxvarta — समस्या अहवाल';

  @override
  String helpReportBody(String version, String platform) {
    return 'काय झाले:\n\n\nपुन्हा पाहण्याच्या पायऱ्या:\n1. \n2. \n3. \n\nअ‍ॅप आवृत्ती: $version\nप्लॅटफॉर्म: $platform\n';
  }

  @override
  String get logout => 'लॉग आउट';

  @override
  String get authSignIn => 'साइन इन';

  @override
  String get authSignInTitle => 'पुन्हा स्वागत आहे';

  @override
  String get authSignInSubtitle =>
      'तुमची कन्सल्टेशन सुरू ठेवण्यासाठी साइन इन करा.';

  @override
  String get authEmail => 'ईमेल';

  @override
  String get authEmailHint => 'doctor@clinic.com';

  @override
  String get authEmailInvalid => 'वैध ईमेल पत्ता टाका';

  @override
  String get authPassword => 'पासवर्ड';

  @override
  String get authPasswordHint => 'तुमचा पासवर्ड टाका';

  @override
  String get authPasswordRequired => 'तुमचा पासवर्ड टाका';

  @override
  String get authPasswordRules => 'किमान 8 अक्षरे';

  @override
  String get authPasswordsDoNotMatch => 'पासवर्ड जुळत नाहीत';

  @override
  String get authShowPassword => 'पासवर्ड दाखवा';

  @override
  String get authHidePassword => 'पासवर्ड लपवा';

  @override
  String get authForgotPassword => 'पासवर्ड विसरलात?';

  @override
  String get authNoAccount => 'Rxvarta वर नवीन आहात?';

  @override
  String get authCreateAccount => 'खाते तयार करा';

  @override
  String get authHaveAccount => 'आधीच खाते आहे?';

  @override
  String get authSignUpTitle => 'तुमचे खाते तयार करा';

  @override
  String get authSignUpSubtitle =>
      'प्रत्येक डॉक्टरसाठी एक खाते. तुमचे रुग्ण आणि प्रिस्क्रिप्शन फक्त तुमच्यापुरते राहतात.';

  @override
  String get authConfirmPassword => 'पासवर्डची खात्री करा';

  @override
  String get authSignInInstead => 'त्याऐवजी साइन इन करा';

  @override
  String get authVerifyTitle => 'तुमचा ईमेल तपासा';

  @override
  String authVerifyBody(String email) {
    return 'आम्ही $email वर 8 अंकी कोड पाठवला आहे. पुढे जाण्यासाठी तो खाली टाका.';
  }

  @override
  String get authCode => 'व्हेरिफिकेशन कोड';

  @override
  String get authCodeIncomplete => 'कोडचे सर्व 8 अंक टाका';

  @override
  String get authVerify => 'व्हेरिफाय करा';

  @override
  String get authResendCode => 'कोड पुन्हा पाठवा';

  @override
  String authResendIn(int seconds) {
    return '$seconds सेकंदांत कोड पुन्हा पाठवा';
  }

  @override
  String get authCodeSent => 'तुमच्या ईमेलवर नवीन कोड पाठवला आहे.';

  @override
  String get authForgotTitle => 'तुमचा पासवर्ड रीसेट करा';

  @override
  String get authForgotSubtitle =>
      'ज्या ईमेलने साइन अप केले तो टाका, आम्ही तुम्हाला कोड पाठवू.';

  @override
  String get authSendCode => 'कोड पाठवा';

  @override
  String get authResetTitle => 'नवीन पासवर्ड निवडा';

  @override
  String get authResetSubtitle => 'Rxvarta वर याआधी न वापरलेला पासवर्ड निवडा.';

  @override
  String get authNewPassword => 'नवीन पासवर्ड';

  @override
  String get authUpdatePassword => 'पासवर्ड अपडेट करा';

  @override
  String get authPasswordUpdated => 'पासवर्ड अपडेट झाला';

  @override
  String get authBackToSignIn => 'साइन इनकडे परत जा';

  @override
  String get authBack => 'मागे';

  @override
  String get authNotConfiguredTitle => 'अ‍ॅप कॉन्फिगर केलेले नाही';

  @override
  String get authNotConfiguredBody =>
      'या बिल्डमध्ये बॅकएंड कनेक्शन नाही, त्यामुळे साइन-इन उपलब्ध नाही. अ‍ॅप --dart-define-from-file=config/app_config.json सह बिल्ड करा (README पहा).';

  @override
  String get authSplashLoading => 'तुमचे वर्कस्पेस तयार होत आहे…';

  @override
  String get authSecureNote => 'एन्क्रिप्टेड आणि फक्त तुमच्या खात्यापुरते.';

  @override
  String get authErrorInvalidCredentials => 'ईमेल किंवा पासवर्ड चुकीचा आहे.';

  @override
  String get authErrorEmailNotConfirmed =>
      'कृपया आधी तुमचा ईमेल पत्ता व्हेरिफाय करा.';

  @override
  String get authErrorUserExists => 'या ईमेलचे खाते आधीपासून आहे.';

  @override
  String get authErrorWeakPassword =>
      'अधिक मजबूत पासवर्ड निवडा: किमान 8 अक्षरे आणि सध्याच्यापेक्षा वेगळा.';

  @override
  String get authErrorOtpExpired => 'हा कोड कालबाह्य झाला आहे. नवीन कोड मागवा.';

  @override
  String get authErrorOtpInvalid =>
      'हा कोड बरोबर नाही. तपासून पुन्हा प्रयत्न करा.';

  @override
  String get authErrorRateLimited =>
      'खूप प्रयत्न झाले. एक मिनिट थांबून पुन्हा प्रयत्न करा.';

  @override
  String get authErrorNetwork =>
      'इंटरनेट कनेक्शन नाही. नेटवर्क तपासून पुन्हा प्रयत्न करा.';

  @override
  String get authErrorSignupDisabled => 'नवीन साइन-अप सध्या बंद आहेत.';

  @override
  String get authErrorValidation => 'कृपया भरलेली माहिती तपासा.';

  @override
  String get authErrorNotConfigured => 'अ‍ॅप कोणत्याही बॅकएंडशी जोडलेले नाही.';

  @override
  String get authErrorUnknown => 'काहीतरी चुकले. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get authErrorDetails => 'तपशील';

  @override
  String get regPrefix => 'नोंद.';

  @override
  String get allRightsReserved => 'सर्व हक्क राखीव';

  @override
  String get editProfile => 'प्रोफाइल संपादित करा';

  @override
  String get editProfileSubtitle => 'प्रिस्क्रिप्शन लेटरहेडवर दिसते.';

  @override
  String get doctorName => 'डॉक्टरचे नाव';

  @override
  String get qualifications => 'पात्रता';

  @override
  String get registrationNumber => 'नोंदणी क्रमांक';

  @override
  String get clinicName => 'क्लिनिक / रुग्णालयाचे नाव';

  @override
  String get clinicAddress => 'क्लिनिकचा पत्ता';

  @override
  String get clinicPhone => 'क्लिनिक फोन';

  @override
  String get profilePhone => 'तुमचा मोबाइल नंबर';

  @override
  String get profileOptional => 'ऐच्छिक';

  @override
  String get profileRequiredHint =>
      '* असलेली फील्ड प्रत्येक प्रिस्क्रिप्शनवर छापली जातात आणि कायद्याने आवश्यक आहेत.';

  @override
  String get profileSectionDoctor => 'डॉक्टरांची माहिती';

  @override
  String get profileSectionClinic => 'क्लिनिकची माहिती';

  @override
  String get profileNameHint => 'उदा. Dr. Asha Verma';

  @override
  String get profileQualificationsHint => 'उदा. MBBS, MD (Medicine)';

  @override
  String get profileRegNoHint => 'राज्य मेडिकल कौन्सिल नंबर';

  @override
  String get profilePhoneHint => '10 अंकी मोबाइल नंबर';

  @override
  String get profilePhoneInvalid => 'वैध मोबाइल नंबर टाका';

  @override
  String get profileClinicNameHint => 'क्लिनिक किंवा रुग्णालयाचे नाव';

  @override
  String get profileClinicAddressHint => 'भाग, शहर, राज्य, पिन';

  @override
  String get profileClinicPhoneHint => 'लँडलाइन किंवा रिसेप्शन नंबर';

  @override
  String get profileSavedOffline =>
      'या डिव्हाइसवर सेव्ह — ऑनलाइन झाल्यावर सिंक होईल';

  @override
  String get profileSaveFailed => 'प्रोफाइल सेव्ह करता आली नाही';

  @override
  String get profileRetry => 'पुन्हा प्रयत्न करा';

  @override
  String get profileIncompleteNudgeTitle =>
      'प्रिस्क्रिप्शनवर सही करण्यासाठी प्रोफाइल पूर्ण करा';

  @override
  String get profileIncompleteNudgeBody =>
      'तुमचे नाव, नोंदणी क्रमांक, क्लिनिक आणि सही जोडा.';

  @override
  String get signatureTitle => 'सही';

  @override
  String get signatureSubtitle =>
      'तुम्ही सही केलेल्या प्रत्येक प्रिस्क्रिप्शनवर छापली जाते.';

  @override
  String get signatureAdd => 'सही जोडा';

  @override
  String get signatureUpdate => 'सही बदला';

  @override
  String get signatureDraw => 'काढा';

  @override
  String get signatureUpload => 'अपलोड करा';

  @override
  String get signatureClear => 'पुसा';

  @override
  String get signatureUse => 'ही सही वापरा';

  @override
  String get signatureEmptyError => 'कृपया आधी तुमची सही काढा.';

  @override
  String get signatureHint => 'रेषेच्या वर बोटाने किंवा माउसने सही करा';

  @override
  String get signatureUploadHint =>
      'पांढऱ्या कागदावरील तुमच्या सहीचा स्पष्ट फोटो किंवा स्कॅन निवडा (PNG किंवा JPEG).';

  @override
  String get signatureChooseImage => 'प्रतिमा निवडा';

  @override
  String get signatureChangeImage => 'दुसरी निवडा';

  @override
  String get signatureUnsupportedFormat =>
      'कृपया PNG किंवा JPEG प्रतिमा निवडा.';

  @override
  String get signatureLoadFailed => 'ती प्रतिमा लोड करता आली नाही';

  @override
  String get signatureNone => 'अद्याप सही नाही';

  @override
  String get signatureSaved => 'सही सेव्ह झाली';

  @override
  String get signatureSaveFailed => 'सही सेव्ह करता आली नाही';

  @override
  String get onboardingTitle => 'तुमचे प्रिस्क्रिप्शन तयार करा';

  @override
  String get onboardingSubtitle =>
      'ही माहिती तुम्ही सही केलेल्या प्रत्येक प्रिस्क्रिप्शनवर दिसते.';

  @override
  String get onboardingStepDoctor => 'डॉक्टर';

  @override
  String get onboardingStepClinic => 'क्लिनिक';

  @override
  String get onboardingStepSignature => 'सही';

  @override
  String get onboardingDoctorTitle => 'तुमची माहिती';

  @override
  String get onboardingDoctorBody => 'लेटरहेडवर जशी दिसावी अगदी तशीच.';

  @override
  String get onboardingClinicTitle => 'तुमचे क्लिनिक';

  @override
  String get onboardingClinicBody =>
      'प्रिस्क्रिप्शनवर छापले जाणारे प्रॅक्टिसचे नाव आणि पत्ता.';

  @override
  String get onboardingSignatureTitle => 'तुमची सही';

  @override
  String get onboardingSignatureBody =>
      'ती एकदा काढा किंवा फोटो अपलोड करा. ती खासगीरित्या साठवली जाते आणि फक्त तुम्ही सही केलेल्या प्रिस्क्रिप्शनवर छापली जाते.';

  @override
  String get onboardingContinue => 'पुढे चला';

  @override
  String get onboardingBack => 'मागे';

  @override
  String get onboardingFinish => 'पूर्ण करा';

  @override
  String get onboardingSignatureRequired => 'पूर्ण करण्यासाठी तुमची सही जोडा.';

  @override
  String get onboardingSignOut => 'साइन आउट';

  @override
  String onboardingSignedInAs(String email) {
    return '$email म्हणून साइन इन';
  }

  @override
  String get signGateTitle => 'सही करण्यासाठी प्रोफाइल पूर्ण करा';

  @override
  String get signGateBody =>
      'प्रिस्क्रिप्शनवर लिहून देणाऱ्या डॉक्टरांची माहिती असणे आवश्यक आहे. सही करण्यापूर्वी हे जोडा:';

  @override
  String get signGateCompleteProfile => 'प्रोफाइल पूर्ण करा';

  @override
  String get signGateOk => 'ठीक आहे';

  @override
  String get signGatePatientNameTitle => 'रुग्णाचे नाव नाही';

  @override
  String get signGatePatientNameBody =>
      'प्रिस्क्रिप्शनवर सही करण्यापूर्वी रुग्णाचे नाव टाका.';

  @override
  String get signGateMedicineNameTitle => 'औषधाचे नाव नाही';

  @override
  String signGateMedicineNameBody(int n) {
    return 'औषध $n ला नाव नाही. सही करण्यापूर्वी नाव टाका किंवा ते काढून टाका.';
  }

  @override
  String get pdfAwaitingSignature => 'सहीची प्रतीक्षा';

  @override
  String get unsavedChanges => 'न जतन केलेले बदल';

  @override
  String get unsavedChangesBody =>
      'तुमच्याकडे न जतन केलेले बदल आहेत. तुम्हाला ते जतन करायचे आहेत की टाकून द्यायचे आहेत?';

  @override
  String get discard => 'टाकून द्या';

  @override
  String get save => 'जतन करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get done => 'पूर्ण';

  @override
  String get required => 'आवश्यक';

  @override
  String get navHome => 'होम';

  @override
  String get navPatients => 'रुग्ण';

  @override
  String get navSettings => 'सेटिंग्ज';

  @override
  String get notFound => 'सापडले नाही';

  @override
  String get newConsultation => 'नवीन सल्लामसलत';

  @override
  String get whoIsThisFor => 'ही सल्लामसलत कोणासाठी आहे?';

  @override
  String get newPatientTitle => 'नवीन रुग्ण';

  @override
  String get newPatientDesc =>
      'प्रथमच येणाऱ्या रुग्णाचे नाव, वय, लिंग आणि मोबाइल क्रमांक जोडा.';

  @override
  String get existingPatientTitle => 'विद्यमान रुग्ण';

  @override
  String get existingPatientDesc =>
      'इतिहासातून रुग्ण शोधा, त्यांचा अहवाल पहा, नंतर नवीन सल्लामसलत सुरू करा.';

  @override
  String get stepDetails => 'तपशील';

  @override
  String get stepRecording => 'रेकॉर्डिंग';

  @override
  String get stepReview => 'पुनरावलोकन';

  @override
  String get stepShare => 'सामायिक';

  @override
  String get patientDetails => 'रुग्णाचे तपशील';

  @override
  String get enterBasicInfo => 'रुग्णाची मूलभूत माहिती प्रविष्ट करा';

  @override
  String get confirmDetailsConsent => 'तपशील आणि संमतीची पुष्टी करा';

  @override
  String get patientName => 'रुग्णाचे नाव';

  @override
  String get patientNameHint => 'रुग्णाचे पूर्ण नाव प्रविष्ट करा';

  @override
  String get nameRequired => 'नाव आवश्यक आहे';

  @override
  String get age => 'वय';

  @override
  String get gender => 'लिंग';

  @override
  String get select => 'निवडा';

  @override
  String get whatsappNumber => 'व्हॉट्सअ‍ॅप क्रमांक';

  @override
  String get mobileHint => '10 अंकी मोबाइल क्रमांक';

  @override
  String get prescriptionShareNote =>
      'या क्रमांकावर प्रिस्क्रिप्शन पाठवले जाईल';

  @override
  String get previousReports => 'मागील अहवाल (पर्यायी)';

  @override
  String get previousReportsDesc =>
      'पूर्वीचे अहवाल स्कॅन करा किंवा जोडा — ते प्रिस्क्रिप्शन PDF मध्ये जोडले जातात.';

  @override
  String get addReport => 'अहवाल जोडा';

  @override
  String get takePhoto => 'फोटो घ्या';

  @override
  String get chooseFromGallery => 'गॅलरीमधून निवडा';

  @override
  String get reportLabelHint => 'लेबल (उदा. रक्त तपासणी, 2 जानेवारी)';

  @override
  String get consentLine => 'रुग्णाने रेकॉर्डिंगला संमती दिली आहे (DPDP कायदा)';

  @override
  String get continueToRecording => 'रेकॉर्डिंगकडे जा';

  @override
  String get couldNotAddReport => 'अहवाल जोडता आला नाही';

  @override
  String get couldNotSavePatient => 'रुग्ण जतन करता आला नाही';

  @override
  String get couldNotSaveChanges => 'तुमचे बदल जतन करता आले नाहीत';

  @override
  String get nothingHeardInRecording =>
      'या रेकॉर्डिंगमध्ये कोणताही सल्ला ऐकू आला नाही. मायक्रोफोन काम करत आहे का ते तपासा आणि पुन्हा रेकॉर्ड करा.';

  @override
  String get patientAlreadyExists => 'रुग्ण आधीच अस्तित्वात आहे';

  @override
  String get patientExistsBody =>
      'या क्रमांकाचा रुग्ण आधीच तुमच्या नोंदींमध्ये आहे:';

  @override
  String get patientExistsQuestion =>
      'ही सल्लामसलत त्यांच्या विद्यमान इतिहासात जोडायची?';

  @override
  String get createNew => 'नवीन तयार करा';

  @override
  String get useExisting => 'विद्यमान वापरा';

  @override
  String get consultationRecording => 'सल्लामसलत रेकॉर्डिंग';

  @override
  String get processingAudio => 'ऑडिओ प्रक्रिया सुरू आहे...';

  @override
  String get chooseRecordingOption => 'रेकॉर्डिंग पर्याय निवडा';

  @override
  String get paused => 'थांबवले';

  @override
  String get recordingConversation => 'संभाषण रेकॉर्ड होत आहे...';

  @override
  String get doctorPlusPatient => 'डॉक्टर + रुग्ण';

  @override
  String get saySomething => 'काहीतरी बोला...';

  @override
  String get readyBothVoices => 'तयार — दोन्ही आवाज रेकॉर्ड होतील';

  @override
  String get transcribingConversation => 'संभाषण ट्रान्सक्राइब होत आहे...';

  @override
  String get extractingPrescription => 'प्रिस्क्रिप्शन काढले जात आहे...';

  @override
  String get recordingTip =>
      'फोन डॉक्टर आणि रुग्णाच्या दरम्यान टेबलवर ठेवा, नंतर स्टार्ट दाबा.';

  @override
  String get addingToConsultation =>
      'सल्लामसलतीत जोडले जात आहे — नवीन ऑडिओ विद्यमान ट्रान्सक्रिप्टमध्ये विलीन होईल.';

  @override
  String get startConsultation => 'सल्लामसलत सुरू करा';

  @override
  String get checkingConnection => 'कनेक्शन तपासत आहे…';

  @override
  String get offlineReconnect =>
      'ऑफलाइन — रेकॉर्ड करण्यासाठी पुन्हा कनेक्ट करा';

  @override
  String get resume => 'पुन्हा सुरू करा';

  @override
  String get pause => 'थांबवा';

  @override
  String get minimumFiveSeconds => 'किमान 5 सेकंद आवश्यक';

  @override
  String get recordingApproachingLimit => 'रेकॉर्डिंग मर्यादेजवळ';

  @override
  String get offlineNotice =>
      'इंटरनेट कनेक्शन नाही. सल्लामसलत ट्रान्सक्राइब आणि प्रक्रिया करण्यासाठी इंटरनेट आवश्यक आहे.';

  @override
  String get checkingConnectionRetry =>
      'तुमचे कनेक्शन तपासत आहे — कृपया थोड्या वेळाने पुन्हा प्रयत्न करा.';

  @override
  String get internetLostPaused =>
      'इंटरनेट गेले — रेकॉर्डिंग थांबली. सल्लामसलत पूर्ण करण्यासाठी पुन्हा कनेक्ट करा.';

  @override
  String get internetLostPauseManually =>
      'इंटरनेट गेले आणि रेकॉर्डिंग आपोआप थांबली नाही — कृपया थांबवा दाबा.';

  @override
  String get micPermissionNeeded =>
      'सल्लामसलत रेकॉर्ड करण्यासाठी मायक्रोफोन परवानगी आवश्यक आहे.';

  @override
  String get micAccessNeeded => 'मायक्रोफोन प्रवेश आवश्यक';

  @override
  String get micEnableInSettings =>
      'रेकॉर्ड करण्यासाठी सेटिंग्जमध्ये मायक्रोफोन परवानगी सुरू करा.';

  @override
  String get openSettings => 'सेटिंग्ज उघडा';

  @override
  String get stopRecordingGoBack => 'रेकॉर्डिंग थांबवून परत जायचे?';

  @override
  String get recordingWillBeLost =>
      'तुमची रेकॉर्डिंग गमावली जाईल. हे पूर्ववत करता येणार नाही.';

  @override
  String get stopAndGoBack => 'थांबवा आणि परत जा';

  @override
  String get discardRecording => 'रेकॉर्डिंग टाकून द्यायची?';

  @override
  String get audioWillBeDiscarded =>
      'तुमचा रेकॉर्ड केलेला ऑडिओ टाकून दिला जाईल. हे पूर्ववत करता येणार नाही.';

  @override
  String get discardAndGoBack => 'टाकून द्या आणि परत जा';

  @override
  String get startFresh => 'नव्याने सुरू करायचे?';

  @override
  String get startFreshBody => 'हे तुमचा सध्याचा सल्लामसलत डेटा बदलेल.';

  @override
  String get startFreshConfirm => 'नव्याने सुरू करा';

  @override
  String get existingRecordingNotice =>
      'या सल्लामसलतीसाठी तुमच्याकडे आधीच रेकॉर्डिंग आहे.';

  @override
  String get duration => 'कालावधी';

  @override
  String get addExtraConversation => 'अतिरिक्त संभाषण जोडा';

  @override
  String get addExtraDesc =>
      'अधिक रेकॉर्ड करा आणि विद्यमान डेटामध्ये विलीन करा';

  @override
  String get startNewConversation => 'नवीन संभाषण सुरू करा';

  @override
  String get startNewDesc => 'मागील साफ करा आणि नवीन रेकॉर्ड करा';

  @override
  String get patientHistory => 'रुग्णाचा इतिहास';

  @override
  String get viewAllConsultations => 'सर्व सल्लामसलत आणि नोंदी पहा';

  @override
  String get statTotal => 'एकूण';

  @override
  String get statThisWeek => 'या आठवड्यात';

  @override
  String get statToday => 'आज';

  @override
  String get searchPatientsHint => 'रुग्ण शोधा...';

  @override
  String get noPatientsFound => 'कोणतेही रुग्ण सापडले नाहीत';

  @override
  String get noConsultationsYet => 'अद्याप कोणतीही सल्लामसलत नाही';

  @override
  String get unknownPatient => 'अज्ञात रुग्ण';

  @override
  String get yesterday => 'काल';

  @override
  String get consultationOne => 'सल्लामसलत';

  @override
  String get consultationMany => 'सल्लामसलती';

  @override
  String get findPatientTitle => 'रुग्ण शोधा';

  @override
  String get searchByNameOrNumber => 'नाव किंवा क्रमांकाने शोधा…';

  @override
  String get noMatchingPatients => 'जुळणारे रुग्ण नाहीत';

  @override
  String get patientFallback => 'रुग्ण';

  @override
  String get patientNotFound => 'रुग्ण सापडला नाही';

  @override
  String get consultationHistory => 'सल्लामसलत इतिहास';

  @override
  String get visitsWillAppearHere =>
      'या रुग्णाच्या भेटींच्या नोंदी येथे दिसतील.';

  @override
  String get signed => 'स्वाक्षरी केलेले';

  @override
  String get diagnosisLabel => 'निदान';

  @override
  String get symptomsLabel => 'लक्षणे';

  @override
  String get medicinesLabel => 'औषधे';

  @override
  String get noMedicinesRecorded => 'कोणतीही औषधे नोंदवली नाहीत.';

  @override
  String get followUpLabel => 'फॉलो-अप';

  @override
  String get afterDaysOne => '1 दिवसानंतर';

  @override
  String afterDaysMany(int n) {
    return '$n दिवसांनंतर';
  }

  @override
  String get opening => 'उघडत आहे…';

  @override
  String get viewPrescription => 'प्रिस्क्रिप्शन पहा';

  @override
  String get share => 'सामायिक करा';

  @override
  String get couldNotSharePrescription =>
      'प्रिस्क्रिप्शन सामायिक करता आले नाही';

  @override
  String get couldNotSharePdf => 'PDF सामायिक करता आले नाही';

  @override
  String get prescriptionFallback => 'प्रिस्क्रिप्शन';

  @override
  String get newConsultationTooltip =>
      'या रुग्णाच्या आधारे नवीन सल्लामसलत तयार करा';

  @override
  String get couldNotGeneratePrescription =>
      'प्रिस्क्रिप्शन तयार होऊ शकले नाही';

  @override
  String get generatingPrescription => 'प्रिस्क्रिप्शन तयार होत आहे...';

  @override
  String get preparingPdf => 'PDF तयार होत आहे…';

  @override
  String get shareOnWhatsapp => 'व्हॉट्सअ‍ॅपवर सामायिक करा';

  @override
  String get shareViaOtherApps => 'इतर अ‍ॅपद्वारे सामायिक करा';

  @override
  String get startNewConsultationCta => 'नवीन सल्लामसलत सुरू करा';

  @override
  String get reviewPrescription => 'प्रिस्क्रिप्शन पुनरावलोकन';

  @override
  String get verifyDetails =>
      'ट्रान्सक्राइब केलेले तपशील तपासा आणि संपादित करा';

  @override
  String get reviewTitle => 'पुनरावलोकन';

  @override
  String get visitNotFound => 'भेट सापडली नाही';

  @override
  String get goBackToRecording => 'रेकॉर्डिंगकडे परत जायचे?';

  @override
  String get goBackToRecordingBody =>
      'तुम्ही या सल्लामसलतीत अधिक जोडू शकता किंवा नवीन रेकॉर्डिंग सुरू करू शकता.';

  @override
  String get stay => 'इथेच रहा';

  @override
  String get goBack => 'परत जा';

  @override
  String get consultationSummary => 'सल्लामसलत सारांश';

  @override
  String get transcriptTitle => 'प्रतिलेखन';

  @override
  String get transcriptSubtitle => 'Sarvam STT ने ऐकल्याप्रमाणे';

  @override
  String get tapToAddSummary => 'सारांश जोडण्यासाठी पेन्सिल दाबा';

  @override
  String get summaryHint => 'रुग्ण का आला आणि पुढील योजना थोडक्यात लिहा';

  @override
  String get patientInformation => 'रुग्णाची माहिती';

  @override
  String get nameLabel => 'नाव';

  @override
  String get yearsLabel => 'वर्षे';

  @override
  String get whatsappLabel => 'व्हॉट्सअ‍ॅप';

  @override
  String get mobileNumber => 'मोबाइल क्रमांक';

  @override
  String get tapToSet => 'सेट करण्यासाठी दाबा';

  @override
  String get diagnosisHint => 'उदा. व्हायरल ताप';

  @override
  String get noDiagnosisTapPencil => 'निदान नाही — जोडण्यासाठी पेन्सिल दाबा';

  @override
  String get adviceTitle => 'सल्ला';

  @override
  String get noAdviceTapPencil =>
      'अद्याप सल्ला नाही — जोडण्यासाठी पेन्सिल दाबा';

  @override
  String get adviceHint => 'सामान्य मार्गदर्शन — प्रत्येक ओळीत एक';

  @override
  String get instructionsTitle => 'सूचना';

  @override
  String get noInstructionsTapPencil =>
      'अद्याप सूचना नाहीत — जोडण्यासाठी पेन्सिल दाबा';

  @override
  String get instructionsHint => 'क्लिनिकल निर्देश — प्रत्येक ओळीत एक';

  @override
  String get noFollowUpSet => 'फॉलो-अप सेट नाही';

  @override
  String get daysSuffix => 'दिवस';

  @override
  String get prescribedMedicines => 'लिहून दिलेली औषधे';

  @override
  String get noMedicationsYet => 'अद्याप कोणतीही औषधे नोंदवली नाहीत.';

  @override
  String get addMedicine => 'औषध जोडा';

  @override
  String get medicineLabel => 'औषध';

  @override
  String get removeMedicine => 'औषध काढा';

  @override
  String get dosageLabel => 'मात्रा';

  @override
  String get durationLabel => 'कालावधी';

  @override
  String get frequencyLabel => 'वारंवारता';

  @override
  String get timingLabel => 'वेळ';

  @override
  String get timingBeforeFood => 'जेवणापूर्वी';

  @override
  String get timingAfterFood => 'जेवणानंतर';

  @override
  String get timingWithFood => 'जेवणासोबत';

  @override
  String get timingEmptyStomach => 'रिकाम्या पोटी';

  @override
  String get timingBeforeBed => 'झोपण्यापूर्वी';

  @override
  String get timingAsDirected => 'निर्देशानुसार';

  @override
  String get aiDisclaimer =>
      'AI फक्त डॉक्टरांनी सांगितलेलेच काढते. स्वाक्षरीपूर्वी सारांश आणि औषधे तपासा.';

  @override
  String get generatePdf => 'प्रिस्क्रिप्शन PDF तयार करा';

  @override
  String get signAndGeneratePdf => 'स्वाक्षरी करा आणि PDF तयार करा';

  @override
  String get icdCodeTitle => 'ICD-10 कोड';

  @override
  String get icdVerifyWarning => 'AI सूचना — यावर विसंबण्यापूर्वी कोड तपासा.';

  @override
  String get icdCodeField => 'कोड (उदा. B34.9)';

  @override
  String get descriptionField => 'वर्णन';

  @override
  String get icdFooterNote =>
      'हा कोड निदानाच्या आधारे AI ने सुचवला आहे. क्लिनिकल किंवा बिलिंग वापरापूर्वी अचूकता तपासा.';

  @override
  String get suggestedDifferentials => 'संभाव्य विभेदक निदान';

  @override
  String get aiSuggestionVerify => 'AI सूचना — तपासा';

  @override
  String get differentialsBasedOn =>
      'नोंदवलेल्या लक्षणांवर आधारित. डॉक्टरांनी तपासणे आवश्यक आहे.';

  @override
  String get accept => 'स्वीकारा';

  @override
  String get prescriptionReady => 'प्रिस्क्रिप्शन तयार';

  @override
  String get reviewAndShare => 'तपासा आणि रुग्णाला पाठवा';

  @override
  String get generatingPdfLong => 'प्रिस्क्रिप्शन PDF तयार होत आहे…';

  @override
  String get couldNotGeneratePdf => 'PDF तयार होऊ शकले नाही';
}

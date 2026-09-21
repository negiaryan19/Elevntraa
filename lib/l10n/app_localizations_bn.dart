// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appName => 'Rxvarta';

  @override
  String get appTagline => 'স্মার্ট মেডিকেল ডকুমেন্টেশন';

  @override
  String get online => 'অনলাইন';

  @override
  String get offline => 'অফলাইন';

  @override
  String get checking => 'পরীক্ষা করা হচ্ছে';

  @override
  String get goodMorning => 'সুপ্রভাত';

  @override
  String get goodAfternoon => 'শুভ অপরাহ্ন';

  @override
  String get goodEvening => 'শুভ সন্ধ্যা';

  @override
  String get doctorFallback => 'ডাক্তার';

  @override
  String get startNewConsultation => 'নতুন পরামর্শ শুরু করুন';

  @override
  String get startNewConsultationSubtitle =>
      'রোগীর সাক্ষাৎ রেকর্ড ও প্রতিলিপি করুন';

  @override
  String get newPatient => 'নতুন রোগী';

  @override
  String get findPatient => 'রোগী খুঁজুন';

  @override
  String get allPatients => 'সব রোগী';

  @override
  String get recentPatients => 'সাম্প্রতিক রোগী';

  @override
  String get seeAll => 'সব দেখুন';

  @override
  String get noPatientsYet => 'এখনও কোনো রোগী নেই';

  @override
  String get noPatientsYetSubtitle =>
      'আপনার প্রথম রোগী যোগ করতে পরামর্শ শুরু করুন।';

  @override
  String get securityFooter =>
      'সুরক্ষিত - HIPAA সম্মত - এন্ড-টু-এন্ড এনক্রিপ্টেড';

  @override
  String get male => 'পুরুষ';

  @override
  String get female => 'মহিলা';

  @override
  String get other => 'অন্যান্য';

  @override
  String get years => 'বছর';

  @override
  String get settings => 'সেটিংস';

  @override
  String get settingsSubtitle => 'আপনার অ্যাপ পছন্দ পরিচালনা করুন';

  @override
  String get sectionAccount => 'অ্যাকাউন্ট';

  @override
  String get sectionPreferences => 'পছন্দসমূহ';

  @override
  String get sectionDataPrivacy => 'ডেটা ও গোপনীয়তা';

  @override
  String get sectionSupport => 'সহায়তা';

  @override
  String get profileSettings => 'প্রোফাইল সেটিংস';

  @override
  String get profileSettingsSubtitle => 'নাম, যোগ্যতা, নিবন্ধন ও ক্লিনিক বিবরণ';

  @override
  String get profileUpdated => 'প্রোফাইল আপডেট হয়েছে';

  @override
  String get darkMode => 'ডার্ক মোড';

  @override
  String get darkThemeActive => 'ডার্ক থিম সক্রিয়';

  @override
  String get lightThemeActive => 'লাইট থিম সক্রিয়';

  @override
  String get appLanguage => 'অ্যাপের ভাষা';

  @override
  String get appLanguageSubtitle => 'অ্যাপ ইন্টারফেসের ভাষা বেছে নিন';

  @override
  String get chooseLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get exportData => 'ডেটা রপ্তানি করুন';

  @override
  String get backupTitle => 'ব্যাকআপ ও সিঙ্ক';

  @override
  String get backupIntro =>
      'আপনার রেকর্ডের একটি কপি আপনার নিজের ব্যক্তিগত ক্লাউড ফোল্ডারে রাখে, ফলে ফোন হারিয়ে গেলেও কিছু হারায় না।';

  @override
  String get backupIncludes =>
      'অন্তর্ভুক্ত: রোগী, পরামর্শ, প্রেসক্রিপশন, রিপোর্টের ছবি, আপনার প্রোফাইল ও স্বাক্ষর।';

  @override
  String get backupExcludes =>
      'অন্তর্ভুক্ত নয়: পরামর্শের রেকর্ডিং (প্রক্রিয়াকরণের পর সেগুলি মুছে ফেলা হয়)।';

  @override
  String backupLastAt(String time) {
    return 'সর্বশেষ ব্যাকআপ $time';
  }

  @override
  String get backupNever => 'এখনও ব্যাকআপ নেই';

  @override
  String get backupNow => 'এখনই ব্যাকআপ নিন';

  @override
  String backupLatestRemote(String time, String size) {
    return 'ক্লাউডে সর্বশেষ: $time ($size)';
  }

  @override
  String get backupNoRemote => 'ক্লাউডে এখনও কোনো ব্যাকআপ নেই';

  @override
  String get backupRestoreLatest => 'সর্বশেষ ব্যাকআপ পুনরুদ্ধার করুন';

  @override
  String get backupRestoreConfirmTitle => 'এই ফোনের ডেটা বদলাবেন?';

  @override
  String backupRestoreConfirmBody(String time) {
    return 'এই ফোনে আপনার রেকর্ড $time-এর ব্যাকআপ দিয়ে বদলে যাবে। এই ফোন ব্যবহার করা অন্য ডাক্তারদের এতে কোনো প্রভাব পড়বে না। এটি ফেরানো যাবে না।';
  }

  @override
  String get backupRestoreConfirm => 'পুনরুদ্ধার করুন';

  @override
  String get backupStageCollecting => 'আপনার রেকর্ড সংগ্রহ করা হচ্ছে…';

  @override
  String get backupStageZipping => 'প্যাক করা হচ্ছে…';

  @override
  String get backupStageUploading => 'আপলোড হচ্ছে…';

  @override
  String get backupStageDownloading => 'ব্যাকআপ ডাউনলোড হচ্ছে…';

  @override
  String get backupStageRestoring => 'পুনরুদ্ধার হচ্ছে…';

  @override
  String get backupDone => 'ব্যাকআপ সম্পূর্ণ';

  @override
  String get backupRestored => 'ব্যাকআপ পুনরুদ্ধার হয়েছে';

  @override
  String get backupRestartHint =>
      'পুনরুদ্ধার করা রেকর্ড দেখতে অ্যাপটি বন্ধ করে আবার খুলুন।';

  @override
  String backupFailed(String reason) {
    return 'ব্যাকআপ ব্যর্থ: $reason';
  }

  @override
  String backupRestoreFailed(String reason) {
    return 'পুনরুদ্ধার ব্যর্থ: $reason';
  }

  @override
  String get backupNeedsInternet => 'ব্যাকআপ নিতে ইন্টারনেটে সংযুক্ত হন।';

  @override
  String get exportPreparing => 'আপনার এক্সপোর্ট তৈরি হচ্ছে…';

  @override
  String get exportShareSubject => 'Rxvarta ডেটা এক্সপোর্ট';

  @override
  String get exportShareText => 'আমার Rxvarta রেকর্ডের এক্সপোর্ট।';

  @override
  String exportFailed(String reason) {
    return 'ডেটা এক্সপোর্ট করা যায়নি: $reason';
  }

  @override
  String get exportEmpty => 'এক্সপোর্ট করার মতো এখনও কিছু নেই।';

  @override
  String exportSavedTo(String path) {
    return '$path-এ সংরক্ষিত হয়েছে';
  }

  @override
  String get privacySecurity => 'গোপনীয়তা ও নিরাপত্তা';

  @override
  String get termsConditions => 'শর্তাবলী';

  @override
  String get termsConditionsSubtitle => 'আমাদের পরিষেবার শর্তাবলী পড়ুন';

  @override
  String get helpSupport => 'সাহায্য ও সহায়তা';

  @override
  String get helpSupportSubtitle => 'সাহায্য নিন বা আমাদের সাথে যোগাযোগ করুন';

  @override
  String get settingsProfileSetUp => 'আপনার প্রোফাইল সেট করুন';

  @override
  String get settingsProfileIncompleteChip =>
      'প্রোফাইল অসম্পূর্ণ — প্রেসক্রিপশনে সই করা যাবে না';

  @override
  String get settingsSignature => 'স্বাক্ষর';

  @override
  String get settingsSignatureSubtitleAdded =>
      'যোগ করা হয়েছে — আপনার সই করা প্রতিটি প্রেসক্রিপশনে ছাপা হয়';

  @override
  String get settingsSignatureSubtitleMissing => 'এখনও যোগ করা হয়নি';

  @override
  String get settingsBackupSync => 'ব্যাকআপ ও সিঙ্ক';

  @override
  String get settingsBackupSubtitleNever => 'এখনও ব্যাকআপ নেই';

  @override
  String settingsBackupSubtitleLast(String time) {
    return 'সর্বশেষ ব্যাকআপ $time';
  }

  @override
  String get settingsExportSubtitle =>
      'আপনার সব রেকর্ডের একটি কপি সংরক্ষণ বা শেয়ার করুন';

  @override
  String get settingsPrivacySubtitle =>
      'আপনার ডেটা কোথায় থাকে এবং কীভাবে মুছবেন';

  @override
  String get settingsSectionLegal => 'আইনি';

  @override
  String get settingsPrivacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'আপনার ও আপনার রোগীদের ডেটা কীভাবে পরিচালিত হয়';

  @override
  String settingsVersion(String version, String build) {
    return 'Rxvarta v$version ($build)';
  }

  @override
  String get settingsTimeJustNow => 'এইমাত্র';

  @override
  String settingsTimeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n মিনিট আগে',
      one: '1 মিনিট আগে',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ঘণ্টা আগে',
      one: '1 ঘণ্টা আগে',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n দিন আগে',
      one: 'গতকাল',
    );
    return '$_temp0';
  }

  @override
  String get settingsSigningOut => 'সাইন আউট হচ্ছে…';

  @override
  String get logoutConfirmTitle => 'সাইন আউট করবেন?';

  @override
  String get logoutConfirmBody =>
      'Rxvarta ব্যবহার করতে আপনাকে আবার সাইন ইন করতে হবে। এই ডিভাইসে সংরক্ষিত রেকর্ড এখানেই থাকবে।';

  @override
  String get logoutConfirm => 'সাইন আউট';

  @override
  String get privacyIntro =>
      'রোগীর রেকর্ড যাতে ডাক্তারের নিয়ন্ত্রণেই থাকে, সেভাবেই Rxvarta তৈরি। ডেটা কোথায় রাখা হয়, কারা তা প্রক্রিয়া করে এবং কীভাবে মুছবেন—এই পাতা তা সহজ ভাষায় ব্যাখ্যা করে।';

  @override
  String get privacyWhereStoredTitle => 'আপনার ডেটা কোথায় থাকে';

  @override
  String get privacyWhereStoredDevice =>
      'এই ডিভাইস — রোগী, ভিজিট, ট্রান্সক্রিপ্ট, প্রেসক্রিপশন, রিপোর্টের ছবি ও রেকর্ডিং এই ফোনে অ্যাপের ব্যক্তিগত স্টোরেজে থাকে।';

  @override
  String get privacyWhereStoredCloud =>
      'মুম্বাই, ভারত (ap-south-1)-এ হোস্ট করা Supabase প্রকল্প — আপনার অ্যাকাউন্ট, ডাক্তার প্রোফাইল, স্বাক্ষর ও ব্যাকআপ।';

  @override
  String get privacyWhereStoredAudio =>
      'রেকর্ডিং শুধুমাত্র প্রক্রিয়াকরণের জন্য একটি ব্যক্তিগত স্টোরেজ বাকেটে আপলোড হয়, দীর্ঘমেয়াদি সংরক্ষণের জন্য নয়।';

  @override
  String get privacyProcessorsTitle => 'কারা এটি প্রক্রিয়া করে';

  @override
  String get privacyProcessorSarvam =>
      'Sarvam AI — রেকর্ডিংকে লেখায় রূপান্তর করে (স্পিচ-টু-টেক্সট)।';

  @override
  String get privacyProcessorGoogle =>
      'Google Gemini — ট্রান্সক্রিপ্ট থেকে আপনার পর্যালোচনার জন্য প্রেসক্রিপশনের খসড়া তৈরি করে।';

  @override
  String get privacyProcessorSupabase =>
      'Supabase — সাইন-ইন, ফাইল স্টোরেজ ও আপনার অ্যাকাউন্টের ডেটাবেস।';

  @override
  String get privacyRetentionTitle => 'কত দিন রাখা হয়';

  @override
  String get privacyRetentionAudio =>
      'রেকর্ডিং: প্রক্রিয়াকরণ সফল হলেই সার্ভার থেকে মুছে যায়; তার আগে পর্যন্ত এই ডিভাইসে থাকে।';

  @override
  String get privacyRetentionTranscript =>
      'ট্রান্সক্রিপ্ট ও প্রেসক্রিপশন: আপনি না মোছা পর্যন্ত এই ডিভাইসে ও আপনার ব্যাকআপে থাকে।';

  @override
  String get privacyRetentionJobs =>
      'প্রক্রিয়াকরণ ক্যাশ: ফল অ্যাপে পৌঁছানোর পর মুছে ফেলা হয়।';

  @override
  String get privacyRoleTitle => 'আপনার ভূমিকা ও আমাদের ভূমিকা';

  @override
  String get privacyRoleBody =>
      'ডিজিটাল পার্সোনাল ডেটা প্রোটেকশন অ্যাক্ট, ২০২৩ অনুযায়ী আপনার রোগীদের রেকর্ডের ডেটা ফিডুশিয়ারি আপনি, অর্থাৎ ডাক্তারই থাকেন। Rxvarta সেগুলি শুধুমাত্র আপনার নির্দেশে, ডেটা প্রসেসর হিসেবে প্রক্রিয়া করে।';

  @override
  String get privacySecurityTitle => 'নিরাপত্তা ব্যবস্থা';

  @override
  String get privacySecurityBody =>
      'ডেটা এনক্রিপ্ট করা সংযোগে (TLS) যায়। সার্ভারের রেকর্ড প্রতি-অ্যাকাউন্ট অ্যাক্সেস নিয়মে সুরক্ষিত, তাই শুধু আপনার সাইন-ইনই তা পড়তে পারে। ফোন লক করে রাখুন: যিনি এটি আনলক করতে পারেন, তিনি অ্যাপ খুলতে পারেন।';

  @override
  String get privacyDeleteTitle => 'ডেটা মুছে ফেলা';

  @override
  String get privacyDeleteBody =>
      'এই ফোন থেকে আপনার ডেটা সরাতে নিচের বোতামটি ব্যবহার করুন। এই ফোনে সাইন ইন করা অন্য ডাক্তারদের ডেটা যেমন আছে থাকবে। রোগীর রেকর্ড এখনও একটি একটি করে মোছা যায় না। আপনার অ্যাকাউন্ট ও আমাদের সার্ভারে রাখা ডেটা মুছতে, যে ইমেল দিয়ে সাইন আপ করেছিলেন সেখান থেকে আমাদের লিখুন।';

  @override
  String get privacyDeleteLocal => 'এই ডিভাইস থেকে আমার ডেটা মুছুন';

  @override
  String get privacyDeleteLocalSubtitle =>
      'এই ফোন থেকে আপনার রোগী, ভিজিট, রেকর্ডিং, রিপোর্ট, প্রোফাইল ক্যাশ ও স্বাক্ষর সরিয়ে আপনাকে সাইন আউট করে। সার্ভারে আপনার অ্যাকাউন্ট ও ব্যাকআপ অপরিবর্তিত থাকে।';

  @override
  String privacyDeleteLocalBody(String word) {
    return 'এই ফোনে সংরক্ষিত আপনার প্রতিটি রোগী, ভিজিট, রেকর্ডিং ও রিপোর্ট সরিয়ে ফেলা হবে এবং আপনি সাইন আউট হয়ে যাবেন। এই ফোনে অন্য ডাক্তারদের ডেটা ও সার্ভারে আপনার ব্যাকআপ অপরিবর্তিত থাকবে। এটি ফেরানো যাবে না।\n\nনিশ্চিত করতে $word টাইপ করুন।';
  }

  @override
  String get privacyDeleteLocalWord => 'DELETE';

  @override
  String privacyDeleteLocalHint(String word) {
    return '$word টাইপ করুন';
  }

  @override
  String get privacyDeleteLocalConfirm => 'সবকিছু মুছুন';

  @override
  String get privacyDeleting => 'স্থানীয় ডেটা মোছা হচ্ছে…';

  @override
  String get privacyDeleted => 'স্থানীয় ডেটা মুছে ফেলা হয়েছে';

  @override
  String privacyDeletePartial(String details) {
    return 'কিছু জিনিস মোছা যায়নি: $details';
  }

  @override
  String get privacyReadPolicy => 'সম্পূর্ণ গোপনীয়তা নীতি পড়ুন';

  @override
  String get legalTerms => 'শর্তাবলী';

  @override
  String get legalPrivacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String legalLastUpdated(String date) {
    return 'সর্বশেষ আপডেট: $date';
  }

  @override
  String get legalReviewNotice =>
      'অ্যাপের সঙ্গে আসা কপি — অফলাইনে পাওয়া যায়। অনলাইনে নতুন সংস্করণ প্রকাশিত হলে অনলাইন সংস্করণ প্রযোজ্য।';

  @override
  String get legalViewOnline => 'অনলাইন সংস্করণ দেখুন';

  @override
  String get legalLoadFailed => 'এই নথিটি লোড করা যায়নি।';

  @override
  String get helpTitle => 'সাহায্য ও সহায়তা';

  @override
  String get helpSubtitle =>
      'অ্যাপ নিয়ে প্রশ্ন, মতামত বা সমস্যা? আমরা সাহায্য করতে প্রস্তুত।';

  @override
  String helpVersion(String version, String build) {
    return 'অ্যাপ সংস্করণ $version ($build)';
  }

  @override
  String get helpEmail => 'ইমেল সহায়তা';

  @override
  String get helpWhatsapp => 'WhatsApp সহায়তা';

  @override
  String get helpReportProblem => 'সমস্যা জানান';

  @override
  String get helpReportProblemSubtitle =>
      'কী হয়েছে এবং কীভাবে তা আবার দেখা যাবে তা বলুন';

  @override
  String get helpNotConfigured => 'সহায়তার যোগাযোগ এখনও সেট করা হয়নি';

  @override
  String get helpCouldNotOpen => 'এটি আপনার ডিভাইসে খোলা যায়নি।';

  @override
  String get helpEmailSubject => 'Rxvarta সহায়তা';

  @override
  String helpEmailBody(String version, String platform) {
    return 'অ্যাপ সংস্করণ: $version\nপ্ল্যাটফর্ম: $platform\n\n';
  }

  @override
  String get helpReportSubject => 'Rxvarta — সমস্যার প্রতিবেদন';

  @override
  String helpReportBody(String version, String platform) {
    return 'কী হয়েছে:\n\n\nআবার দেখার ধাপ:\n1. \n2. \n3. \n\nঅ্যাপ সংস্করণ: $version\nপ্ল্যাটফর্ম: $platform\n';
  }

  @override
  String get logout => 'লগ আউট';

  @override
  String get authSignIn => 'সাইন ইন';

  @override
  String get authSignInTitle => 'আবার স্বাগতম';

  @override
  String get authSignInSubtitle => 'আপনার পরামর্শ চালিয়ে যেতে সাইন ইন করুন।';

  @override
  String get authEmail => 'ইমেল';

  @override
  String get authEmailHint => 'doctor@clinic.com';

  @override
  String get authEmailInvalid => 'সঠিক ইমেল ঠিকানা দিন';

  @override
  String get authPassword => 'পাসওয়ার্ড';

  @override
  String get authPasswordHint => 'আপনার পাসওয়ার্ড দিন';

  @override
  String get authPasswordRequired => 'আপনার পাসওয়ার্ড দিন';

  @override
  String get authPasswordRules =>
      'কমপক্ষে ৮টি অক্ষর, তাতে একটি বড় ও একটি ছোট হাতের অক্ষর, একটি সংখ্যা ও একটি চিহ্ন থাকতে হবে';

  @override
  String get authPasswordTooShort => 'কমপক্ষে ৮টি অক্ষর দিন';

  @override
  String get authPasswordTooLong => 'খুব লম্বা — একটু ছোট করুন';

  @override
  String get authPasswordNeedsLowercase =>
      'একটি ছোট হাতের অক্ষর যোগ করুন (a–z)';

  @override
  String get authPasswordNeedsUppercase =>
      'একটি বড় হাতের অক্ষর যোগ করুন (A–Z)';

  @override
  String get authPasswordNeedsDigit => 'একটি সংখ্যা যোগ করুন (0–9)';

  @override
  String get authPasswordNeedsSymbol => 'একটি চিহ্ন যোগ করুন, যেমন ! বা @';

  @override
  String authEmailDidYouMean(String suggestion) {
    return 'আপনি কি $suggestion বোঝাতে চেয়েছেন?';
  }

  @override
  String authEmailKeepAsTyped(String button) {
    return 'যেমন লেখা আছে তেমনই রাখতে আবার “$button” চাপুন।';
  }

  @override
  String get authPasswordsDoNotMatch => 'পাসওয়ার্ড মিলছে না';

  @override
  String get authShowPassword => 'পাসওয়ার্ড দেখান';

  @override
  String get authHidePassword => 'পাসওয়ার্ড লুকান';

  @override
  String get authForgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get authNoAccount => 'Rxvarta-তে নতুন?';

  @override
  String get authCreateAccount => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get authHaveAccount => 'আগে থেকেই অ্যাকাউন্ট আছে?';

  @override
  String get authSignUpTitle => 'আপনার অ্যাকাউন্ট তৈরি করুন';

  @override
  String get authSignUpSubtitle =>
      'প্রতি ডাক্তারের জন্য একটি অ্যাকাউন্ট। আপনার রোগী ও প্রেসক্রিপশন শুধু আপনারই থাকে।';

  @override
  String get authConfirmPassword => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get authSignInInstead => 'বরং সাইন ইন করুন';

  @override
  String get authVerifyTitle => 'আপনার ইমেল দেখুন';

  @override
  String authVerifyBody(String email) {
    return 'আমরা $email-এ ৮ অঙ্কের একটি কোড পাঠিয়েছি। এগিয়ে যেতে নিচে সেটি দিন।';
  }

  @override
  String get authCode => 'যাচাইকরণ কোড';

  @override
  String get authCodeIncomplete => 'কোডের সবগুলি ৮টি অঙ্ক দিন';

  @override
  String get authVerify => 'যাচাই করুন';

  @override
  String get authResendCode => 'কোড আবার পাঠান';

  @override
  String authResendIn(int seconds) {
    return '$seconds সেকেন্ডে কোড আবার পাঠান';
  }

  @override
  String get authCodeSent => 'আপনার ইমেলে নতুন কোড পাঠানো হয়েছে।';

  @override
  String get authForgotTitle => 'আপনার পাসওয়ার্ড রিসেট করুন';

  @override
  String get authForgotSubtitle =>
      'যে ইমেল দিয়ে সাইন আপ করেছিলেন তা দিন, আমরা আপনাকে কোড পাঠাব।';

  @override
  String get authSendCode => 'কোড পাঠান';

  @override
  String get authResetTitle => 'নতুন পাসওয়ার্ড বাছুন';

  @override
  String get authResetSubtitle =>
      'Rxvarta-তে আগে ব্যবহার করেননি এমন পাসওয়ার্ড ব্যবহার করুন।';

  @override
  String get authNewPassword => 'নতুন পাসওয়ার্ড';

  @override
  String get authUpdatePassword => 'পাসওয়ার্ড আপডেট করুন';

  @override
  String get authPasswordUpdated => 'পাসওয়ার্ড আপডেট হয়েছে';

  @override
  String get authBackToSignIn => 'সাইন ইনে ফিরুন';

  @override
  String get authBack => 'পিছনে';

  @override
  String get authNotConfiguredTitle => 'অ্যাপ কনফিগার করা নেই';

  @override
  String get authNotConfiguredBody =>
      'এই বিল্ডে ব্যাকএন্ড সংযোগ নেই, তাই সাইন-ইন পাওয়া যাচ্ছে না। অ্যাপটি --dart-define-from-file=config/app_config.json সহ বিল্ড করুন (README দেখুন)।';

  @override
  String get authSplashLoading => 'আপনার কর্মক্ষেত্র প্রস্তুত হচ্ছে…';

  @override
  String get authSecureNote =>
      'এনক্রিপ্ট করা এবং শুধু আপনার অ্যাকাউন্টের জন্য।';

  @override
  String get authErrorInvalidCredentials => 'ইমেল বা পাসওয়ার্ড ভুল।';

  @override
  String get authErrorEmailNotConfirmed =>
      'অনুগ্রহ করে আগে আপনার ইমেল ঠিকানা যাচাই করুন।';

  @override
  String get authErrorUserExists => 'এই ইমেলে ইতিমধ্যে একটি অ্যাকাউন্ট আছে।';

  @override
  String get authErrorWeakPassword =>
      'আরও শক্ত পাসওয়ার্ড বাছুন: কমপক্ষে ৮টি অক্ষর এবং বর্তমানটির থেকে আলাদা।';

  @override
  String get authErrorOtpExpired => 'এই কোডের মেয়াদ শেষ। নতুন কোড চান।';

  @override
  String get authErrorOtpInvalid => 'কোডটি সঠিক নয়। দেখে আবার চেষ্টা করুন।';

  @override
  String get authErrorRateLimited =>
      'অনেকবার চেষ্টা হয়েছে। এক মিনিট অপেক্ষা করে আবার চেষ্টা করুন।';

  @override
  String get authErrorEmailSendFailed =>
      'এখন ইমেল পাঠানো গেল না। এক মিনিট পরে আবার চেষ্টা করুন।';

  @override
  String get authErrorNetwork =>
      'ইন্টারনেট সংযোগ নেই। নেটওয়ার্ক দেখে আবার চেষ্টা করুন।';

  @override
  String get authErrorSignupDisabled => 'নতুন সাইন-আপ আপাতত বন্ধ।';

  @override
  String get authErrorValidation => 'অনুগ্রহ করে দেওয়া তথ্য দেখে নিন।';

  @override
  String get authErrorNotConfigured =>
      'অ্যাপটি কোনো ব্যাকএন্ডের সঙ্গে যুক্ত নয়।';

  @override
  String get authErrorUnknown => 'কিছু একটা ভুল হয়েছে। আবার চেষ্টা করুন।';

  @override
  String get authErrorDetails => 'বিস্তারিত';

  @override
  String get regPrefix => 'নিব.';

  @override
  String get allRightsReserved => 'সর্বস্বত্ব সংরক্ষিত';

  @override
  String get editProfile => 'প্রোফাইল সম্পাদনা';

  @override
  String get editProfileSubtitle => 'প্রেসক্রিপশন লেটারহেডে প্রদর্শিত হয়।';

  @override
  String get doctorName => 'ডাক্তারের নাম';

  @override
  String get qualifications => 'যোগ্যতা';

  @override
  String get registrationNumber => 'নিবন্ধন নম্বর';

  @override
  String get clinicName => 'ক্লিনিক / হাসপাতালের নাম';

  @override
  String get clinicAddress => 'ক্লিনিকের ঠিকানা';

  @override
  String get clinicPhone => 'ক্লিনিক ফোন';

  @override
  String get profilePhone => 'আপনার মোবাইল নম্বর';

  @override
  String get profileOptional => 'ঐচ্ছিক';

  @override
  String get profileRequiredHint =>
      '* চিহ্নিত ঘরগুলি প্রতিটি প্রেসক্রিপশনে ছাপা হয় এবং আইন অনুযায়ী বাধ্যতামূলক।';

  @override
  String get profileSectionDoctor => 'ডাক্তারের তথ্য';

  @override
  String get profileSectionClinic => 'ক্লিনিকের তথ্য';

  @override
  String get profileNameHint => 'যেমন Dr. Asha Verma';

  @override
  String get profileQualificationsHint => 'যেমন MBBS, MD (Medicine)';

  @override
  String get profileRegNoHint => 'রাজ্য মেডিকেল কাউন্সিল নম্বর';

  @override
  String get profilePhoneHint => '১০ অঙ্কের মোবাইল নম্বর';

  @override
  String get profilePhoneInvalid => 'সঠিক মোবাইল নম্বর দিন';

  @override
  String get profileClinicNameHint => 'ক্লিনিক বা হাসপাতালের নাম';

  @override
  String get profileClinicAddressHint => 'এলাকা, শহর, রাজ্য, পিন';

  @override
  String get profileClinicPhoneHint => 'ল্যান্ডলাইন বা রিসেপশন নম্বর';

  @override
  String get profileSavedOffline =>
      'এই ডিভাইসে সংরক্ষিত — অনলাইনে এলে সিঙ্ক হবে';

  @override
  String get profileSaveFailed => 'প্রোফাইল সংরক্ষণ করা যায়নি';

  @override
  String get profileRetry => 'আবার চেষ্টা করুন';

  @override
  String get profileIncompleteNudgeTitle =>
      'প্রেসক্রিপশনে সই করতে প্রোফাইল সম্পূর্ণ করুন';

  @override
  String get profileIncompleteNudgeBody =>
      'আপনার নাম, নিবন্ধন নম্বর, ক্লিনিক ও স্বাক্ষর যোগ করুন।';

  @override
  String get signatureTitle => 'স্বাক্ষর';

  @override
  String get signatureSubtitle =>
      'আপনার সই করা প্রতিটি প্রেসক্রিপশনে ছাপা হয়।';

  @override
  String get signatureAdd => 'স্বাক্ষর যোগ করুন';

  @override
  String get signatureUpdate => 'স্বাক্ষর বদলান';

  @override
  String get signatureDraw => 'আঁকুন';

  @override
  String get signatureUpload => 'আপলোড করুন';

  @override
  String get signatureClear => 'মুছুন';

  @override
  String get signatureUse => 'এই স্বাক্ষর ব্যবহার করুন';

  @override
  String get signatureEmptyError => 'অনুগ্রহ করে আগে আপনার স্বাক্ষর আঁকুন।';

  @override
  String get signatureHint => 'রেখার উপরে আঙুল বা মাউস দিয়ে সই করুন';

  @override
  String get signatureUploadHint =>
      'সাদা কাগজে করা আপনার স্বাক্ষরের স্পষ্ট ছবি বা স্ক্যান বাছুন (PNG বা JPEG)।';

  @override
  String get signatureChooseImage => 'ছবি বাছুন';

  @override
  String get signatureChangeImage => 'অন্যটি বাছুন';

  @override
  String get signatureUnsupportedFormat => 'অনুগ্রহ করে PNG বা JPEG ছবি বাছুন।';

  @override
  String get signatureLoadFailed => 'ছবিটি লোড করা যায়নি';

  @override
  String get signatureNone => 'এখনও স্বাক্ষর নেই';

  @override
  String get signatureSaved => 'স্বাক্ষর সংরক্ষিত হয়েছে';

  @override
  String get signatureSaveFailed => 'স্বাক্ষর সংরক্ষণ করা যায়নি';

  @override
  String get onboardingTitle => 'আপনার প্রেসক্রিপশন সেট করুন';

  @override
  String get onboardingSubtitle =>
      'এই তথ্যগুলি আপনার সই করা প্রতিটি প্রেসক্রিপশনে দেখা যায়।';

  @override
  String get onboardingStepDoctor => 'ডাক্তার';

  @override
  String get onboardingStepClinic => 'ক্লিনিক';

  @override
  String get onboardingStepSignature => 'স্বাক্ষর';

  @override
  String get onboardingDoctorTitle => 'আপনার তথ্য';

  @override
  String get onboardingDoctorBody =>
      'লেটারহেডে ঠিক যেভাবে দেখাতে চান, সেভাবেই।';

  @override
  String get onboardingClinicTitle => 'আপনার ক্লিনিক';

  @override
  String get onboardingClinicBody =>
      'প্রেসক্রিপশনে ছাপা হওয়া প্র্যাকটিসের নাম ও ঠিকানা।';

  @override
  String get onboardingSignatureTitle => 'আপনার স্বাক্ষর';

  @override
  String get onboardingSignatureBody =>
      'একবার আঁকুন বা ছবি আপলোড করুন। এটি ব্যক্তিগতভাবে সংরক্ষিত হয় এবং শুধু আপনার সই করা প্রেসক্রিপশনে ছাপা হয়।';

  @override
  String get onboardingContinue => 'এগিয়ে যান';

  @override
  String get onboardingBack => 'পিছনে';

  @override
  String get onboardingFinish => 'সম্পন্ন করুন';

  @override
  String get onboardingSignatureRequired =>
      'সম্পন্ন করতে আপনার স্বাক্ষর যোগ করুন।';

  @override
  String get onboardingSignOut => 'সাইন আউট';

  @override
  String onboardingSignedInAs(String email) {
    return '$email হিসেবে সাইন ইন';
  }

  @override
  String get signGateTitle => 'সই করতে প্রোফাইল সম্পূর্ণ করুন';

  @override
  String get signGateBody =>
      'প্রেসক্রিপশনে ব্যবস্থাপত্র দেওয়া ডাক্তারের তথ্য থাকতে হবে। সই করার আগে এগুলি যোগ করুন:';

  @override
  String get signGateCompleteProfile => 'প্রোফাইল সম্পূর্ণ করুন';

  @override
  String get signGateOk => 'ঠিক আছে';

  @override
  String get signGatePatientNameTitle => 'রোগীর নাম নেই';

  @override
  String get signGatePatientNameBody =>
      'প্রেসক্রিপশনে সই করার আগে রোগীর নাম দিন।';

  @override
  String get signGateMedicineNameTitle => 'ওষুধের নাম নেই';

  @override
  String signGateMedicineNameBody(int n) {
    return 'ওষুধ $n-এর কোনো নাম নেই। সই করার আগে নাম দিন বা এটি সরিয়ে দিন।';
  }

  @override
  String pdfDocumentTitle(String name) {
    return 'প্রেসক্রিপশন — $name';
  }

  @override
  String get pdfPatient => 'রোগী';

  @override
  String get pdfDate => 'তারিখ';

  @override
  String get pdfAge => 'বয়স';

  @override
  String get pdfGender => 'লিঙ্গ';

  @override
  String get pdfPhone => 'ফোন';

  @override
  String pdfAgeYears(int age) {
    return '$age বছর';
  }

  @override
  String get pdfRegNo => 'রেজি. নং';

  @override
  String get pdfDiagnosis => 'রোগনির্ণয়';

  @override
  String get pdfNoMedicines => 'কোনো ওষুধ লেখা হয়নি।';

  @override
  String get pdfColMedicine => 'ওষুধ';

  @override
  String get pdfColDosage => 'মাত্রা';

  @override
  String get pdfColFrequency => 'কতবার';

  @override
  String get pdfColDuration => 'সময়কাল';

  @override
  String get pdfColTiming => 'সময়';

  @override
  String get pdfInvestigations => 'পরামর্শকৃত পরীক্ষা';

  @override
  String get pdfInstructions => 'নির্দেশনা';

  @override
  String get pdfAdvice => 'পরামর্শ';

  @override
  String get pdfFollowUp => 'ফলো-আপ';

  @override
  String pdfFollowUpAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days দিন পরে',
      one: '1 দিন পরে',
    );
    return '$_temp0';
  }

  @override
  String get pdfNextVisit => 'পরবর্তী সাক্ষাৎ';

  @override
  String get pdfPreviousReports => 'আগের রিপোর্ট';

  @override
  String pdfReportsAttachedFor(String name) {
    return '$name-এর জন্য সংযুক্ত';
  }

  @override
  String pdfReportCaption(int number) {
    return 'রিপোর্ট $number';
  }

  @override
  String get pdfComputerGenerated => 'এটি কম্পিউটারে তৈরি প্রেসক্রিপশন';

  @override
  String get pdfFooterTagline =>
      'Rxvarta AI দ্বারা তৈরি  |  সুরক্ষিত  |  ব্যক্তিগত';

  @override
  String get pdfAwaitingSignature => 'স্বাক্ষরের অপেক্ষায়';

  @override
  String get unsavedChanges => 'অসংরক্ষিত পরিবর্তন';

  @override
  String get unsavedChangesBody =>
      'আপনার অসংরক্ষিত পরিবর্তন রয়েছে। আপনি কি সেগুলি সংরক্ষণ করতে চান নাকি বাতিল করতে চান?';

  @override
  String get discard => 'বাতিল করুন';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get cancel => 'বাতিল';

  @override
  String get done => 'সম্পন্ন';

  @override
  String get required => 'আবশ্যক';

  @override
  String get navHome => 'হোম';

  @override
  String get navPatients => 'রোগী';

  @override
  String get navSettings => 'সেটিংস';

  @override
  String get notFound => 'পাওয়া যায়নি';

  @override
  String get newConsultation => 'নতুন পরামর্শ';

  @override
  String get whoIsThisFor => 'এই পরামর্শ কার জন্য?';

  @override
  String get newPatientTitle => 'নতুন রোগী';

  @override
  String get newPatientDesc =>
      'প্রথমবারের রোগীর নাম, বয়স, লিঙ্গ ও মোবাইল নম্বর যোগ করুন।';

  @override
  String get existingPatientTitle => 'বিদ্যমান রোগী';

  @override
  String get existingPatientDesc =>
      'ইতিহাস থেকে রোগী খুঁজুন, তাদের রিপোর্ট দেখুন, তারপর নতুন পরামর্শ শুরু করুন।';

  @override
  String get stepDetails => 'বিবরণ';

  @override
  String get stepRecording => 'রেকর্ডিং';

  @override
  String get stepReview => 'পর্যালোচনা';

  @override
  String get stepShare => 'শেয়ার';

  @override
  String get patientDetails => 'রোগীর বিবরণ';

  @override
  String get enterBasicInfo => 'রোগীর মৌলিক তথ্য দিন';

  @override
  String get confirmDetailsConsent => 'বিবরণ ও সম্মতি নিশ্চিত করুন';

  @override
  String get patientName => 'রোগীর নাম';

  @override
  String get patientNameHint => 'রোগীর পুরো নাম লিখুন';

  @override
  String get nameRequired => 'নাম আবশ্যক';

  @override
  String get age => 'বয়স';

  @override
  String get gender => 'লিঙ্গ';

  @override
  String get select => 'নির্বাচন করুন';

  @override
  String get whatsappNumber => 'হোয়াটসঅ্যাপ নম্বর';

  @override
  String get mobileHint => '10 সংখ্যার মোবাইল নম্বর';

  @override
  String get prescriptionShareNote => 'এই নম্বরে প্রেসক্রিপশন পাঠানো হবে';

  @override
  String get previousReports => 'পূর্ববর্তী রিপোর্ট (ঐচ্ছিক)';

  @override
  String get previousReportsDesc =>
      'আগের রিপোর্ট স্ক্যান বা সংযুক্ত করুন — সেগুলি প্রেসক্রিপশন PDFএ যোগ হয়।';

  @override
  String get addReport => 'রিপোর্ট যোগ করুন';

  @override
  String get takePhoto => 'ছবি তুলুন';

  @override
  String get chooseFromGallery => 'গ্যালারি থেকে বেছে নিন';

  @override
  String get reportLabelHint => 'লেবেল (যেমন রক্ত পরীক্ষা, ২ জানুয়ারি)';

  @override
  String get consentLine => 'রোগী রেকর্ডিংয়ে সম্মতি দিয়েছেন (DPDP আইন)';

  @override
  String get continueToRecording => 'রেকর্ডিংয়ে যান';

  @override
  String get couldNotAddReport => 'রিপোর্ট যোগ করা যায়নি';

  @override
  String get couldNotSavePatient => 'রোগী সংরক্ষণ করা যায়নি';

  @override
  String get couldNotSaveChanges => 'আপনার পরিবর্তনগুলি সংরক্ষণ করা যায়নি';

  @override
  String get nothingHeardInRecording =>
      'এই রেকর্ডিংয়ে কোনো পরামর্শ শোনা যায়নি। মাইক্রোফোন কাজ করছে কি না দেখে আবার রেকর্ড করুন।';

  @override
  String get retryProcessing => 'এই রেকর্ডিং দিয়ে আবার চেষ্টা করুন';

  @override
  String get recordAgain => 'আবার রেকর্ড করুন';

  @override
  String get consultationErrorOffline =>
      'ইন্টারনেট সংযোগ নেই। আপনার রেকর্ডিং এই ফোনে সংরক্ষিত আছে; ইন্টারনেট ফিরলে আবার চেষ্টা করুন চাপুন।';

  @override
  String get consultationErrorProcessing =>
      'রেকর্ডিং প্রসেস করা যায়নি। এটি এই ফোনে সংরক্ষিত আছে; আবার চেষ্টা করুন চাপুন।';

  @override
  String get errorSessionExpired =>
      'আপনার সেশনের মেয়াদ শেষ হয়েছে। অনুগ্রহ করে আবার সাইন ইন করুন।';

  @override
  String get consultationErrorStorage =>
      'রেকর্ডিং এই ফোনে সংরক্ষণ করা যায়নি। খালি জায়গা দেখে আবার রেকর্ড করুন।';

  @override
  String get errorUnexpected =>
      'কিছু একটা ভুল হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';

  @override
  String get errorOffline => 'ইন্টারনেট সংযোগ নেই।';

  @override
  String get errorStorage =>
      'এই ফোনের ফাইল পড়া বা সংরক্ষণ করা যায়নি। খালি জায়গা আছে কি না দেখুন।';

  @override
  String get errorPermission =>
      'অনুমতি দেওয়া হয়নি। ফোনের সেটিংসে Rxvarta-কে অনুমতি দিন।';

  @override
  String get errorInvalidBackup =>
      'এই ফাইলটি আপনার অ্যাকাউন্টের জন্য ব্যবহারযোগ্য Rxvarta ব্যাকআপ নয়।';

  @override
  String get errorBackupTooNew =>
      'এই ব্যাকআপটি Rxvarta-র নতুন সংস্করণে তৈরি। অ্যাপ আপডেট করে তারপর রিস্টোর করুন।';

  @override
  String get patientAlreadyExists => 'রোগী ইতিমধ্যে আছেন';

  @override
  String get patientExistsBody =>
      'এই নম্বরের রোগী ইতিমধ্যে আপনার রেকর্ডে আছেন:';

  @override
  String get patientExistsQuestion =>
      'এই পরামর্শ কি তাদের বিদ্যমান ইতিহাসে যোগ করবেন?';

  @override
  String get createNew => 'নতুন তৈরি করুন';

  @override
  String get useExisting => 'বিদ্যমানটি ব্যবহার করুন';

  @override
  String get consultationRecording => 'পরামর্শ রেকর্ডিং';

  @override
  String get processingAudio => 'অডিও প্রক্রিয়াকরণ হচ্ছে...';

  @override
  String get chooseRecordingOption => 'রেকর্ডিং বিকল্প বাছুন';

  @override
  String get paused => 'বিরতি';

  @override
  String get recordingConversation => 'কথোপকথন রেকর্ড হচ্ছে...';

  @override
  String get doctorPlusPatient => 'ডাক্তার + রোগী';

  @override
  String get saySomething => 'কিছু বলুন...';

  @override
  String get readyBothVoices => 'প্রস্তুত — উভয় কণ্ঠ রেকর্ড হবে';

  @override
  String get transcribingConversation => 'কথোপকথন প্রতিলিপি হচ্ছে...';

  @override
  String get extractingPrescription => 'প্রেসক্রিপশন বের করা হচ্ছে...';

  @override
  String get recordingTip =>
      'ফোনটি ডাক্তার ও রোগীর মাঝে টেবিলে রাখুন, তারপর স্টার্ট চাপুন।';

  @override
  String get addingToConsultation =>
      'পরামর্শে যোগ হচ্ছে — নতুন অডিও বিদ্যমান প্রতিলিপির সাথে মিলিত হবে।';

  @override
  String get startConsultation => 'পরামর্শ শুরু করুন';

  @override
  String get checkingConnection => 'সংযোগ পরীক্ষা করা হচ্ছে…';

  @override
  String get offlineReconnect => 'অফলাইন — রেকর্ড করতে পুনরায় সংযোগ করুন';

  @override
  String get resume => 'পুনরায় শুরু';

  @override
  String get pause => 'বিরতি দিন';

  @override
  String get minimumFiveSeconds => 'ন্যূনতম ৫ সেকেন্ড প্রয়োজন';

  @override
  String get recordingApproachingLimit => 'রেকর্ডিং সীমার কাছাকাছি';

  @override
  String get offlineNotice =>
      'ইন্টারনেট সংযোগ নেই। পরামর্শ প্রতিলিপি ও প্রক্রিয়া করতে ইন্টারনেট প্রয়োজন।';

  @override
  String get checkingConnectionRetry =>
      'আপনার সংযোগ পরীক্ষা করা হচ্ছে — অনুগ্রহ করে কিছুক্ষণ পরে আবার চেষ্টা করুন।';

  @override
  String get internetLostStillRecording =>
      'ইন্টারনেট নেই। রেকর্ডিং চলছে; ইন্টারনেট ফিরলে পরামর্শ প্রসেস হবে।';

  @override
  String get recordingNotificationTitle => 'পরামর্শ রেকর্ড হচ্ছে';

  @override
  String get recordingNotificationText =>
      'স্ক্রিন বন্ধ থাকলেও Rxvarta রেকর্ডিং চালিয়ে যায়।';

  @override
  String get micPermissionNeeded =>
      'পরামর্শ রেকর্ড করতে মাইক্রোফোন অনুমতি প্রয়োজন।';

  @override
  String get micAccessNeeded => 'মাইক্রোফোন অ্যাক্সেস প্রয়োজন';

  @override
  String get micEnableInSettings =>
      'রেকর্ড করতে সেটিংসে মাইক্রোফোন অনুমতি চালু করুন।';

  @override
  String get openSettings => 'সেটিংস খুলুন';

  @override
  String get stopRecordingGoBack => 'রেকর্ডিং বন্ধ করে ফিরে যাবেন?';

  @override
  String get recordingWillBeLost =>
      'আপনার রেকর্ডিং হারিয়ে যাবে। এটি ফেরানো যাবে না।';

  @override
  String get stopAndGoBack => 'বন্ধ করে ফিরুন';

  @override
  String get discardRecording => 'রেকর্ডিং বাতিল করবেন?';

  @override
  String get audioWillBeDiscarded =>
      'আপনার রেকর্ড করা অডিও বাতিল হবে। এটি ফেরানো যাবে না।';

  @override
  String get discardAndGoBack => 'বাতিল করে ফিরুন';

  @override
  String get startFresh => 'নতুন করে শুরু করবেন?';

  @override
  String get startFreshBody =>
      'এটি আপনার বর্তমান পরামর্শ ডেটা প্রতিস্থাপন করবে।';

  @override
  String get startFreshConfirm => 'নতুন করে শুরু';

  @override
  String get existingRecordingNotice =>
      'এই পরামর্শের জন্য আপনার ইতিমধ্যে রেকর্ডিং আছে।';

  @override
  String get duration => 'সময়কাল';

  @override
  String get addExtraConversation => 'অতিরিক্ত কথোপকথন যোগ করুন';

  @override
  String get addExtraDesc => 'আরও রেকর্ড করে বিদ্যমান ডেটার সাথে মেলান';

  @override
  String get startNewConversation => 'নতুন কথোপকথন শুরু করুন';

  @override
  String get startNewDesc => 'আগেরটি মুছে নতুন রেকর্ড করুন';

  @override
  String get patientHistory => 'রোগীর ইতিহাস';

  @override
  String get viewAllConsultations => 'সব পরামর্শ ও রেকর্ড দেখুন';

  @override
  String get statTotal => 'মোট';

  @override
  String get statThisWeek => 'এই সপ্তাহ';

  @override
  String get statToday => 'আজ';

  @override
  String get searchPatientsHint => 'রোগী খুঁজুন...';

  @override
  String get noPatientsFound => 'কোনো রোগী পাওয়া যায়নি';

  @override
  String get noConsultationsYet => 'এখনও কোনো পরামর্শ নেই';

  @override
  String get unknownPatient => 'অজানা রোগী';

  @override
  String get yesterday => 'গতকাল';

  @override
  String get consultationOne => 'পরামর্শ';

  @override
  String get consultationMany => 'পরামর্শ';

  @override
  String get findPatientTitle => 'রোগী খুঁজুন';

  @override
  String get searchByNameOrNumber => 'নাম বা নম্বর দিয়ে খুঁজুন…';

  @override
  String get noMatchingPatients => 'মিলে যাওয়া রোগী নেই';

  @override
  String get patientFallback => 'রোগী';

  @override
  String get patientNotFound => 'রোগী পাওয়া যায়নি';

  @override
  String get consultationHistory => 'পরামর্শের ইতিহাস';

  @override
  String get visitsWillAppearHere => 'এই রোগীর ভিজিটের রেকর্ড এখানে দেখা যাবে।';

  @override
  String get signed => 'স্বাক্ষরিত';

  @override
  String get diagnosisLabel => 'রোগ নির্ণয়';

  @override
  String get symptomsLabel => 'উপসর্গ';

  @override
  String get medicinesLabel => 'ওষুধ';

  @override
  String get noMedicinesRecorded => 'কোনো ওষুধ নথিভুক্ত নেই।';

  @override
  String get followUpLabel => 'ফলো-আপ';

  @override
  String get afterDaysOne => '১ দিন পর';

  @override
  String afterDaysMany(int n) {
    return '$n দিন পর';
  }

  @override
  String get opening => 'খোলা হচ্ছে…';

  @override
  String get viewPrescription => 'প্রেসক্রিপশন দেখুন';

  @override
  String get share => 'শেয়ার করুন';

  @override
  String get couldNotSharePrescription => 'প্রেসক্রিপশন শেয়ার করা যায়নি';

  @override
  String get couldNotSharePdf => 'PDF শেয়ার করা যায়নি';

  @override
  String get prescriptionFallback => 'প্রেসক্রিপশন';

  @override
  String get newConsultationTooltip =>
      'এই রোগীর ভিত্তিতে নতুন পরামর্শ তৈরি করুন';

  @override
  String get couldNotGeneratePrescription => 'প্রেসক্রিপশন তৈরি করা যায়নি';

  @override
  String get generatingPrescription => 'প্রেসক্রিপশন তৈরি হচ্ছে...';

  @override
  String get preparingPdf => 'PDF প্রস্তুত হচ্ছে…';

  @override
  String get shareOnWhatsapp => 'হোয়াটসঅ্যাপে শেয়ার করুন';

  @override
  String get shareViaOtherApps => 'অন্য অ্যাপে শেয়ার করুন';

  @override
  String get startNewConsultationCta => 'নতুন পরামর্শ শুরু করুন';

  @override
  String get reviewPrescription => 'প্রেসক্রিপশন পর্যালোচনা';

  @override
  String get verifyDetails => 'প্রতিলিপি করা বিবরণ যাচাই ও সম্পাদনা করুন';

  @override
  String get reviewTitle => 'পর্যালোচনা';

  @override
  String get visitNotFound => 'ভিজিট পাওয়া যায়নি';

  @override
  String get goBackToRecording => 'রেকর্ডিংয়ে ফিরে যাবেন?';

  @override
  String get goBackToRecordingBody =>
      'আপনি এই পরামর্শে আরও যোগ করতে বা নতুন রেকর্ডিং শুরু করতে পারেন।';

  @override
  String get stay => 'এখানেই থাকুন';

  @override
  String get goBack => 'ফিরে যান';

  @override
  String get consultationSummary => 'পরামর্শের সারাংশ';

  @override
  String get transcriptTitle => 'প্রতিলিপি';

  @override
  String get transcriptSubtitle => 'Sarvam STT দ্বারা যেমন শোনা হয়েছে';

  @override
  String get tapToAddSummary => 'সারাংশ যোগ করতে পেন্সিল চাপুন';

  @override
  String get summaryHint => 'রোগী কেন এসেছেন ও পরিকল্পনা সংক্ষেপে লিখুন';

  @override
  String get patientInformation => 'রোগীর তথ্য';

  @override
  String get nameLabel => 'নাম';

  @override
  String get yearsLabel => 'বছর';

  @override
  String get whatsappLabel => 'হোয়াটসঅ্যাপ';

  @override
  String get mobileNumber => 'মোবাইল নম্বর';

  @override
  String get tapToSet => 'সেট করতে চাপুন';

  @override
  String get diagnosisHint => 'যেমন ভাইরাল জ্বর';

  @override
  String get noDiagnosisTapPencil =>
      'কোনো রোগ নির্ণয় নেই — যোগ করতে পেন্সিল চাপুন';

  @override
  String get investigationsTitle => 'পরীক্ষা';

  @override
  String get noInvestigationsTapPencil =>
      'কোনো পরীক্ষা নেই — যোগ করতে পেন্সিল চাপুন';

  @override
  String get investigationsHint =>
      'যে পরীক্ষাগুলি করাতে হবে — প্রতি লাইনে একটি';

  @override
  String get doctorNotesTitle => 'ডাক্তারের নোট';

  @override
  String get doctorNotesNotPrinted =>
      'আপনার রেকর্ডের জন্য; প্রেসক্রিপশনে ছাপা হয় না';

  @override
  String get noDoctorNotesTapPencil => 'কোনো নোট নেই — যোগ করতে পেন্সিল চাপুন';

  @override
  String get doctorNotesHint => 'এই পরামর্শ সম্পর্কে আপনার নিজের নোট';

  @override
  String get adviceTitle => 'পরামর্শ';

  @override
  String get noAdviceTapPencil => 'এখনও পরামর্শ নেই — যোগ করতে পেন্সিল চাপুন';

  @override
  String get adviceHint => 'সাধারণ নির্দেশনা — প্রতি লাইনে একটি';

  @override
  String get instructionsTitle => 'নির্দেশাবলী';

  @override
  String get noInstructionsTapPencil =>
      'এখনও নির্দেশ নেই — যোগ করতে পেন্সিল চাপুন';

  @override
  String get instructionsHint => 'ক্লিনিক্যাল নির্দেশ — প্রতি লাইনে একটি';

  @override
  String get noFollowUpSet => 'কোনো ফলো-আপ সেট নেই';

  @override
  String get daysSuffix => 'দিন';

  @override
  String get prescribedMedicines => 'নির্ধারিত ওষুধ';

  @override
  String get noMedicationsYet => 'এখনও কোনো ওষুধ নথিভুক্ত নেই।';

  @override
  String get addMedicine => 'ওষুধ যোগ করুন';

  @override
  String get medicineLabel => 'ওষুধ';

  @override
  String get removeMedicine => 'ওষুধ সরান';

  @override
  String get dosageLabel => 'ডোজ';

  @override
  String get durationLabel => 'সময়কাল';

  @override
  String get frequencyLabel => 'ফ্রিকোয়েন্সি';

  @override
  String get timingLabel => 'সময়';

  @override
  String get timingBeforeFood => 'খাবারের আগে';

  @override
  String get timingAfterFood => 'খাবারের পরে';

  @override
  String get timingWithFood => 'খাবারের সাথে';

  @override
  String get timingEmptyStomach => 'খালি পেটে';

  @override
  String get timingBeforeBed => 'ঘুমানোর আগে';

  @override
  String get timingAsDirected => 'নির্দেশ অনুযায়ী';

  @override
  String get aiDisclaimer =>
      'AI শুধু ডাক্তার যা বলেছেন তাই নেয়। স্বাক্ষরের আগে সারাংশ ও ওষুধ পর্যালোচনা করুন।';

  @override
  String get generatePdf => 'প্রেসক্রিপশন PDF তৈরি করুন';

  @override
  String get signAndGeneratePdf => 'স্বাক্ষর করে PDF তৈরি করুন';

  @override
  String get icdCodeTitle => 'ICD-10 কোড';

  @override
  String get icdVerifyWarning => 'AI পরামর্শ — নির্ভর করার আগে কোড যাচাই করুন।';

  @override
  String get icdCodeField => 'কোড (যেমন B34.9)';

  @override
  String get descriptionField => 'বিবরণ';

  @override
  String get icdFooterNote =>
      'এই কোডটি নির্ণয়ের ভিত্তিতে AI সুপারিশ করেছে। ক্লিনিক্যাল বা বিলিং ব্যবহারের আগে যথার্থতা যাচাই করুন।';

  @override
  String get suggestedDifferentials => 'প্রস্তাবিত ডিফারেনশিয়াল';

  @override
  String get aiSuggestionVerify => 'AI পরামর্শ — যাচাই করুন';

  @override
  String get differentialsBasedOn =>
      'জানানো উপসর্গের ভিত্তিতে। ডাক্তারকে যাচাই করতে হবে।';

  @override
  String get accept => 'গ্রহণ করুন';

  @override
  String get prescriptionReady => 'প্রেসক্রিপশন প্রস্তুত';

  @override
  String get reviewAndShare => 'পর্যালোচনা করে রোগীকে পাঠান';

  @override
  String get generatingPdfLong => 'প্রেসক্রিপশন PDF তৈরি হচ্ছে…';

  @override
  String get couldNotGeneratePdf => 'PDF তৈরি করা যায়নি';
}

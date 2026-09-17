import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('bn'),
    Locale('en'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Rxvarta'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Smart Medical Documentation'**
  String get appTagline;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get checking;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @doctorFallback.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctorFallback;

  /// No description provided for @startNewConsultation.
  ///
  /// In en, this message translates to:
  /// **'Start new consultation'**
  String get startNewConsultation;

  /// No description provided for @startNewConsultationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Record and transcribe a patient visit'**
  String get startNewConsultationSubtitle;

  /// No description provided for @newPatient.
  ///
  /// In en, this message translates to:
  /// **'New patient'**
  String get newPatient;

  /// No description provided for @findPatient.
  ///
  /// In en, this message translates to:
  /// **'Find patient'**
  String get findPatient;

  /// No description provided for @allPatients.
  ///
  /// In en, this message translates to:
  /// **'All patients'**
  String get allPatients;

  /// No description provided for @recentPatients.
  ///
  /// In en, this message translates to:
  /// **'Recent patients'**
  String get recentPatients;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noPatientsYet.
  ///
  /// In en, this message translates to:
  /// **'No patients yet'**
  String get noPatientsYet;

  /// No description provided for @noPatientsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a consultation to add your first patient.'**
  String get noPatientsYetSubtitle;

  /// No description provided for @securityFooter.
  ///
  /// In en, this message translates to:
  /// **'Encrypted in transit - Hosted in India - Your records stay under your control'**
  String get securityFooter;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'yrs'**
  String get years;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your app preferences'**
  String get settingsSubtitle;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @sectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get sectionPreferences;

  /// No description provided for @sectionDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get sectionDataPrivacy;

  /// No description provided for @sectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get sectionSupport;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @profileSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, qualifications, registration & clinic details'**
  String get profileSettingsSubtitle;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @darkThemeActive.
  ///
  /// In en, this message translates to:
  /// **'Dark theme active'**
  String get darkThemeActive;

  /// No description provided for @lightThemeActive.
  ///
  /// In en, this message translates to:
  /// **'Light theme active'**
  String get lightThemeActive;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @appLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the language of the app interface'**
  String get appLanguageSubtitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & sync'**
  String get backupTitle;

  /// No description provided for @backupIntro.
  ///
  /// In en, this message translates to:
  /// **'Keeps a copy of your records in your own private cloud folder, so nothing is lost if this phone is.'**
  String get backupIntro;

  /// No description provided for @backupIncludes.
  ///
  /// In en, this message translates to:
  /// **'Included: patients, consultations, prescriptions, report photos, your profile and signature.'**
  String get backupIncludes;

  /// No description provided for @backupExcludes.
  ///
  /// In en, this message translates to:
  /// **'Not included: consultation recordings (they are deleted after processing).'**
  String get backupExcludes;

  /// No description provided for @backupLastAt.
  ///
  /// In en, this message translates to:
  /// **'Last backup {time}'**
  String backupLastAt(String time);

  /// No description provided for @backupNever.
  ///
  /// In en, this message translates to:
  /// **'Never backed up'**
  String get backupNever;

  /// No description provided for @backupNow.
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// No description provided for @backupLatestRemote.
  ///
  /// In en, this message translates to:
  /// **'Latest in cloud: {time} ({size})'**
  String backupLatestRemote(String time, String size);

  /// No description provided for @backupNoRemote.
  ///
  /// In en, this message translates to:
  /// **'No backup in the cloud yet'**
  String get backupNoRemote;

  /// No description provided for @backupRestoreLatest.
  ///
  /// In en, this message translates to:
  /// **'Restore latest backup'**
  String get backupRestoreLatest;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace data on this phone?'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your records on this phone are replaced by the backup from {time}. Other doctors who use this phone are not affected. This cannot be undone.'**
  String backupRestoreConfirmBody(String time);

  /// No description provided for @backupRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get backupRestoreConfirm;

  /// No description provided for @backupStageCollecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting your records…'**
  String get backupStageCollecting;

  /// No description provided for @backupStageZipping.
  ///
  /// In en, this message translates to:
  /// **'Packing them up…'**
  String get backupStageZipping;

  /// No description provided for @backupStageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get backupStageUploading;

  /// No description provided for @backupStageDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading backup…'**
  String get backupStageDownloading;

  /// No description provided for @backupStageRestoring.
  ///
  /// In en, this message translates to:
  /// **'Restoring…'**
  String get backupStageRestoring;

  /// No description provided for @backupDone.
  ///
  /// In en, this message translates to:
  /// **'Backup complete'**
  String get backupDone;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get backupRestored;

  /// No description provided for @backupRestartHint.
  ///
  /// In en, this message translates to:
  /// **'Close and reopen the app to see the restored records.'**
  String get backupRestartHint;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {reason}'**
  String backupFailed(String reason);

  /// No description provided for @backupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {reason}'**
  String backupRestoreFailed(String reason);

  /// No description provided for @backupNeedsInternet.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to back up.'**
  String get backupNeedsInternet;

  /// No description provided for @exportPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing your export…'**
  String get exportPreparing;

  /// No description provided for @exportShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Rxvarta data export'**
  String get exportShareSubject;

  /// No description provided for @exportShareText.
  ///
  /// In en, this message translates to:
  /// **'Export of my Rxvarta records.'**
  String get exportShareText;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not export data: {reason}'**
  String exportFailed(String reason);

  /// No description provided for @exportEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to export yet.'**
  String get exportEmpty;

  /// No description provided for @exportSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String exportSavedTo(String path);

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @termsConditionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read our terms of service'**
  String get termsConditionsSubtitle;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @helpSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help or contact us'**
  String get helpSupportSubtitle;

  /// No description provided for @settingsProfileSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up your profile'**
  String get settingsProfileSetUp;

  /// No description provided for @settingsProfileIncompleteChip.
  ///
  /// In en, this message translates to:
  /// **'Profile incomplete — prescriptions cannot be signed'**
  String get settingsProfileIncompleteChip;

  /// No description provided for @settingsSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get settingsSignature;

  /// No description provided for @settingsSignatureSubtitleAdded.
  ///
  /// In en, this message translates to:
  /// **'Added — printed on every prescription you sign'**
  String get settingsSignatureSubtitleAdded;

  /// No description provided for @settingsSignatureSubtitleMissing.
  ///
  /// In en, this message translates to:
  /// **'Not added yet'**
  String get settingsSignatureSubtitleMissing;

  /// No description provided for @settingsBackupSync.
  ///
  /// In en, this message translates to:
  /// **'Backup & sync'**
  String get settingsBackupSync;

  /// No description provided for @settingsBackupSubtitleNever.
  ///
  /// In en, this message translates to:
  /// **'Never backed up'**
  String get settingsBackupSubtitleNever;

  /// No description provided for @settingsBackupSubtitleLast.
  ///
  /// In en, this message translates to:
  /// **'Last backup {time}'**
  String settingsBackupSubtitleLast(String time);

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save or share a copy of all your records'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where your data lives and how to delete it'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsSectionLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsSectionLegal;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How your and your patients\' data is handled'**
  String get settingsPrivacyPolicySubtitle;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Rxvarta v{version} ({build})'**
  String settingsVersion(String version, String build);

  /// No description provided for @settingsTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get settingsTimeJustNow;

  /// No description provided for @settingsTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 minute ago} other{{n} minutes ago}}'**
  String settingsTimeMinutesAgo(int n);

  /// No description provided for @settingsTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{1 hour ago} other{{n} hours ago}}'**
  String settingsTimeHoursAgo(int n);

  /// No description provided for @settingsTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =1{yesterday} other{{n} days ago}}'**
  String settingsTimeDaysAgo(int n);

  /// No description provided for @settingsSigningOut.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get settingsSigningOut;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to use Rxvarta. Records saved on this device stay on it.'**
  String get logoutConfirmBody;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutConfirm;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Rxvarta is built so that patient records stay under the doctor\'s control. This page explains, in plain words, where data is kept, who processes it and how to delete it.'**
  String get privacyIntro;

  /// No description provided for @privacyWhereStoredTitle.
  ///
  /// In en, this message translates to:
  /// **'Where your data lives'**
  String get privacyWhereStoredTitle;

  /// No description provided for @privacyWhereStoredDevice.
  ///
  /// In en, this message translates to:
  /// **'This device — patients, visits, transcripts, prescriptions, report photos and recordings are kept in the app\'s private storage on this phone.'**
  String get privacyWhereStoredDevice;

  /// No description provided for @privacyWhereStoredCloud.
  ///
  /// In en, this message translates to:
  /// **'Supabase project hosted in Mumbai, India (ap-south-1) — your account, doctor profile, signature and backups.'**
  String get privacyWhereStoredCloud;

  /// No description provided for @privacyWhereStoredAudio.
  ///
  /// In en, this message translates to:
  /// **'Recordings are uploaded to a private storage bucket only for processing, never for long-term storage.'**
  String get privacyWhereStoredAudio;

  /// No description provided for @privacyProcessorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Who processes it'**
  String get privacyProcessorsTitle;

  /// No description provided for @privacyProcessorSarvam.
  ///
  /// In en, this message translates to:
  /// **'Sarvam AI — converts the recording into text (speech-to-text).'**
  String get privacyProcessorSarvam;

  /// No description provided for @privacyProcessorGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google Gemini — turns the transcript into a structured draft prescription for you to review.'**
  String get privacyProcessorGoogle;

  /// No description provided for @privacyProcessorSupabase.
  ///
  /// In en, this message translates to:
  /// **'Supabase — sign-in, file storage and the database behind your account.'**
  String get privacyProcessorSupabase;

  /// No description provided for @privacyRetentionTitle.
  ///
  /// In en, this message translates to:
  /// **'How long it is kept'**
  String get privacyRetentionTitle;

  /// No description provided for @privacyRetentionAudio.
  ///
  /// In en, this message translates to:
  /// **'Recordings: deleted from the server once processing succeeds; kept on this device until then.'**
  String get privacyRetentionAudio;

  /// No description provided for @privacyRetentionTranscript.
  ///
  /// In en, this message translates to:
  /// **'Transcripts and prescriptions: on this device and in your backups until you delete them.'**
  String get privacyRetentionTranscript;

  /// No description provided for @privacyRetentionJobs.
  ///
  /// In en, this message translates to:
  /// **'Processing cache: cleared after the result has been delivered to the app.'**
  String get privacyRetentionJobs;

  /// No description provided for @privacyRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your role and ours'**
  String get privacyRoleTitle;

  /// No description provided for @privacyRoleBody.
  ///
  /// In en, this message translates to:
  /// **'Under the Digital Personal Data Protection Act, 2023 you, the doctor, remain the data fiduciary for your patients\' records. Rxvarta processes them only on your instructions, as a data processor.'**
  String get privacyRoleBody;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Security measures'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecurityBody.
  ///
  /// In en, this message translates to:
  /// **'Data travels over encrypted connections (TLS). Records on the server are protected by per-account access rules, so only your sign-in can read them. Keep your phone locked: anyone who can unlock it can open the app.'**
  String get privacySecurityBody;

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting data'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Use the button below to remove your data from this phone. Other doctors who sign in on this phone keep theirs. Patient records cannot be deleted one by one yet. To delete your account and the data kept on our servers, write to us from the e-mail address you signed up with.'**
  String get privacyDeleteBody;

  /// No description provided for @privacyDeleteLocal.
  ///
  /// In en, this message translates to:
  /// **'Delete my data on this device'**
  String get privacyDeleteLocal;

  /// No description provided for @privacyDeleteLocalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes your patients, visits, recordings, reports, profile cache and signature from this phone and signs you out. Your account and backups on the server are not affected.'**
  String get privacyDeleteLocalSubtitle;

  /// No description provided for @privacyDeleteLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Every patient, visit, recording and report of yours stored on this phone will be removed and you will be signed out. Other doctors\' data on this phone and your backups on the server are not affected. This cannot be undone.\n\nType {word} to confirm.'**
  String privacyDeleteLocalBody(String word);

  /// No description provided for @privacyDeleteLocalWord.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get privacyDeleteLocalWord;

  /// No description provided for @privacyDeleteLocalHint.
  ///
  /// In en, this message translates to:
  /// **'Type {word}'**
  String privacyDeleteLocalHint(String word);

  /// No description provided for @privacyDeleteLocalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete everything'**
  String get privacyDeleteLocalConfirm;

  /// No description provided for @privacyDeleting.
  ///
  /// In en, this message translates to:
  /// **'Deleting local data…'**
  String get privacyDeleting;

  /// No description provided for @privacyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Local data deleted'**
  String get privacyDeleted;

  /// No description provided for @privacyDeletePartial.
  ///
  /// In en, this message translates to:
  /// **'Some items could not be deleted: {details}'**
  String privacyDeletePartial(String details);

  /// No description provided for @privacyReadPolicy.
  ///
  /// In en, this message translates to:
  /// **'Read the full Privacy Policy'**
  String get privacyReadPolicy;

  /// No description provided for @legalTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get legalTerms;

  /// No description provided for @legalPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyPolicy;

  /// No description provided for @legalLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String legalLastUpdated(String date);

  /// No description provided for @legalReviewNotice.
  ///
  /// In en, this message translates to:
  /// **'Bundled copy — available offline. If a newer version is published online, the online version applies.'**
  String get legalReviewNotice;

  /// No description provided for @legalViewOnline.
  ///
  /// In en, this message translates to:
  /// **'View online version'**
  String get legalViewOnline;

  /// No description provided for @legalLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load this document.'**
  String get legalLoadFailed;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Questions, feedback or a problem with the app? We are happy to help.'**
  String get helpSubtitle;

  /// No description provided for @helpVersion.
  ///
  /// In en, this message translates to:
  /// **'App version {version} ({build})'**
  String helpVersion(String version, String build);

  /// No description provided for @helpEmail.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get helpEmail;

  /// No description provided for @helpWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp support'**
  String get helpWhatsapp;

  /// No description provided for @helpReportProblem.
  ///
  /// In en, this message translates to:
  /// **'Report a problem'**
  String get helpReportProblem;

  /// No description provided for @helpReportProblemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened and how to reproduce it'**
  String get helpReportProblemSubtitle;

  /// No description provided for @helpNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Support contact not configured yet'**
  String get helpNotConfigured;

  /// No description provided for @helpCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open this on your device.'**
  String get helpCouldNotOpen;

  /// No description provided for @helpEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Rxvarta support'**
  String get helpEmailSubject;

  /// No description provided for @helpEmailBody.
  ///
  /// In en, this message translates to:
  /// **'App version: {version}\nPlatform: {platform}\n\n'**
  String helpEmailBody(String version, String platform);

  /// No description provided for @helpReportSubject.
  ///
  /// In en, this message translates to:
  /// **'Rxvarta — problem report'**
  String get helpReportSubject;

  /// No description provided for @helpReportBody.
  ///
  /// In en, this message translates to:
  /// **'What happened:\n\n\nSteps to reproduce:\n1. \n2. \n3. \n\nApp version: {version}\nPlatform: {platform}\n'**
  String helpReportBody(String version, String platform);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authSignInTitle;

  /// No description provided for @authSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to your consultations.'**
  String get authSignInSubtitle;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'doctor@clinic.com'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordRules.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordRules;

  /// No description provided for @authPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordsDoNotMatch;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'New to Rxvarta?'**
  String get authNoAccount;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authHaveAccount;

  /// No description provided for @authSignUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authSignUpTitle;

  /// No description provided for @authSignUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One account per doctor. Your patients and prescriptions stay private to you.'**
  String get authSignUpSubtitle;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authSignInInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign in instead'**
  String get authSignInInstead;

  /// No description provided for @authVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authVerifyTitle;

  /// No description provided for @authVerifyBody.
  ///
  /// In en, this message translates to:
  /// **'We sent an 8-digit code to {email}. Enter it below to continue.'**
  String authVerifyBody(String email);

  /// No description provided for @authCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authCode;

  /// No description provided for @authCodeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter all 8 digits of the code'**
  String get authCodeIncomplete;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// No description provided for @authResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String authResendIn(int seconds);

  /// No description provided for @authCodeSent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent to your email.'**
  String get authCodeSent;

  /// No description provided for @authForgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get authForgotTitle;

  /// No description provided for @authForgotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with and we will send you a code.'**
  String get authForgotSubtitle;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password'**
  String get authResetTitle;

  /// No description provided for @authResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a password you have not used with Rxvarta before.'**
  String get authResetSubtitle;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get authUpdatePassword;

  /// No description provided for @authPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get authPasswordUpdated;

  /// No description provided for @authBackToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get authBackToSignIn;

  /// No description provided for @authBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get authBack;

  /// No description provided for @authNotConfiguredTitle.
  ///
  /// In en, this message translates to:
  /// **'App not configured'**
  String get authNotConfiguredTitle;

  /// No description provided for @authNotConfiguredBody.
  ///
  /// In en, this message translates to:
  /// **'This build has no backend connection, so sign-in is unavailable. Build the app with --dart-define-from-file=config/app_config.json (see the README).'**
  String get authNotConfiguredBody;

  /// No description provided for @authSplashLoading.
  ///
  /// In en, this message translates to:
  /// **'Preparing your workspace…'**
  String get authSplashLoading;

  /// No description provided for @authSecureNote.
  ///
  /// In en, this message translates to:
  /// **'Encrypted and private to your account.'**
  String get authSecureNote;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address first.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorUserExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get authErrorUserExists;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password: at least 8 characters and different from your current one.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorOtpExpired.
  ///
  /// In en, this message translates to:
  /// **'This code has expired. Request a new one.'**
  String get authErrorOtpExpired;

  /// No description provided for @authErrorOtpInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct. Check it and try again.'**
  String get authErrorOtpInvalid;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a minute and try again.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorSignupDisabled.
  ///
  /// In en, this message translates to:
  /// **'New sign-ups are currently disabled.'**
  String get authErrorSignupDisabled;

  /// No description provided for @authErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the details you entered.'**
  String get authErrorValidation;

  /// No description provided for @authErrorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The app is not connected to a backend.'**
  String get authErrorNotConfigured;

  /// No description provided for @authErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorUnknown;

  /// No description provided for @authErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get authErrorDetails;

  /// No description provided for @regPrefix.
  ///
  /// In en, this message translates to:
  /// **'Reg.'**
  String get regPrefix;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'All rights reserved'**
  String get allRightsReserved;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Appears on prescription letterhead.'**
  String get editProfileSubtitle;

  /// No description provided for @doctorName.
  ///
  /// In en, this message translates to:
  /// **'Doctor name'**
  String get doctorName;

  /// No description provided for @qualifications.
  ///
  /// In en, this message translates to:
  /// **'Qualifications'**
  String get qualifications;

  /// No description provided for @registrationNumber.
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get registrationNumber;

  /// No description provided for @clinicName.
  ///
  /// In en, this message translates to:
  /// **'Clinic / Hospital name'**
  String get clinicName;

  /// No description provided for @clinicAddress.
  ///
  /// In en, this message translates to:
  /// **'Clinic address'**
  String get clinicAddress;

  /// No description provided for @clinicPhone.
  ///
  /// In en, this message translates to:
  /// **'Clinic phone'**
  String get clinicPhone;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Your mobile number'**
  String get profilePhone;

  /// No description provided for @profileOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profileOptional;

  /// No description provided for @profileRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Fields marked * are printed on every prescription and are required by law.'**
  String get profileRequiredHint;

  /// No description provided for @profileSectionDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor details'**
  String get profileSectionDoctor;

  /// No description provided for @profileSectionClinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic details'**
  String get profileSectionClinic;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Dr. Asha Verma'**
  String get profileNameHint;

  /// No description provided for @profileQualificationsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. MBBS, MD (Medicine)'**
  String get profileQualificationsHint;

  /// No description provided for @profileRegNoHint.
  ///
  /// In en, this message translates to:
  /// **'State medical council number'**
  String get profileRegNoHint;

  /// No description provided for @profilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get profilePhoneHint;

  /// No description provided for @profilePhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid mobile number'**
  String get profilePhoneInvalid;

  /// No description provided for @profileClinicNameHint.
  ///
  /// In en, this message translates to:
  /// **'Clinic or hospital name'**
  String get profileClinicNameHint;

  /// No description provided for @profileClinicAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Area, City, State PIN'**
  String get profileClinicAddressHint;

  /// No description provided for @profileClinicPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Landline or reception number'**
  String get profileClinicPhoneHint;

  /// No description provided for @profileSavedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device — will sync when online'**
  String get profileSavedOffline;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile'**
  String get profileSaveFailed;

  /// No description provided for @profileRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get profileRetry;

  /// No description provided for @profileIncompleteNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to sign prescriptions'**
  String get profileIncompleteNudgeTitle;

  /// No description provided for @profileIncompleteNudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Add your name, registration number, clinic and signature.'**
  String get profileIncompleteNudgeBody;

  /// No description provided for @signatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signatureTitle;

  /// No description provided for @signatureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Printed on every prescription you sign.'**
  String get signatureSubtitle;

  /// No description provided for @signatureAdd.
  ///
  /// In en, this message translates to:
  /// **'Add signature'**
  String get signatureAdd;

  /// No description provided for @signatureUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update signature'**
  String get signatureUpdate;

  /// No description provided for @signatureDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get signatureDraw;

  /// No description provided for @signatureUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get signatureUpload;

  /// No description provided for @signatureClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get signatureClear;

  /// No description provided for @signatureUse.
  ///
  /// In en, this message translates to:
  /// **'Use signature'**
  String get signatureUse;

  /// No description provided for @signatureEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please draw your signature first.'**
  String get signatureEmptyError;

  /// No description provided for @signatureHint.
  ///
  /// In en, this message translates to:
  /// **'Sign above the line with your finger or mouse'**
  String get signatureHint;

  /// No description provided for @signatureUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a clear photo or scan of your signature on white paper (PNG or JPEG).'**
  String get signatureUploadHint;

  /// No description provided for @signatureChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get signatureChooseImage;

  /// No description provided for @signatureChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Choose another'**
  String get signatureChangeImage;

  /// No description provided for @signatureUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'Please choose a PNG or JPEG image.'**
  String get signatureUnsupportedFormat;

  /// No description provided for @signatureLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load that image'**
  String get signatureLoadFailed;

  /// No description provided for @signatureNone.
  ///
  /// In en, this message translates to:
  /// **'No signature yet'**
  String get signatureNone;

  /// No description provided for @signatureSaved.
  ///
  /// In en, this message translates to:
  /// **'Signature saved'**
  String get signatureSaved;

  /// No description provided for @signatureSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save signature'**
  String get signatureSaveFailed;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your prescription'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These details appear on every prescription you sign.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingStepDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get onboardingStepDoctor;

  /// No description provided for @onboardingStepClinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get onboardingStepClinic;

  /// No description provided for @onboardingStepSignature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get onboardingStepSignature;

  /// No description provided for @onboardingDoctorTitle.
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get onboardingDoctorTitle;

  /// No description provided for @onboardingDoctorBody.
  ///
  /// In en, this message translates to:
  /// **'Exactly as they should appear on the letterhead.'**
  String get onboardingDoctorBody;

  /// No description provided for @onboardingClinicTitle.
  ///
  /// In en, this message translates to:
  /// **'Your clinic'**
  String get onboardingClinicTitle;

  /// No description provided for @onboardingClinicBody.
  ///
  /// In en, this message translates to:
  /// **'Practice name and address printed on the prescription.'**
  String get onboardingClinicBody;

  /// No description provided for @onboardingSignatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Your signature'**
  String get onboardingSignatureTitle;

  /// No description provided for @onboardingSignatureBody.
  ///
  /// In en, this message translates to:
  /// **'Draw it once or upload a photo. It is stored privately and printed only on prescriptions you sign.'**
  String get onboardingSignatureBody;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get onboardingFinish;

  /// No description provided for @onboardingSignatureRequired.
  ///
  /// In en, this message translates to:
  /// **'Add your signature to finish.'**
  String get onboardingSignatureRequired;

  /// No description provided for @onboardingSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get onboardingSignOut;

  /// No description provided for @onboardingSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String onboardingSignedInAs(String email);

  /// No description provided for @signGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to sign'**
  String get signGateTitle;

  /// No description provided for @signGateBody.
  ///
  /// In en, this message translates to:
  /// **'A prescription must carry the prescribing doctor\'s details. Add the following before signing:'**
  String get signGateBody;

  /// No description provided for @signGateCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get signGateCompleteProfile;

  /// No description provided for @signGateOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get signGateOk;

  /// No description provided for @signGatePatientNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient name missing'**
  String get signGatePatientNameTitle;

  /// No description provided for @signGatePatientNameBody.
  ///
  /// In en, this message translates to:
  /// **'Add the patient\'s name before signing the prescription.'**
  String get signGatePatientNameBody;

  /// No description provided for @signGateMedicineNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine name missing'**
  String get signGateMedicineNameTitle;

  /// No description provided for @signGateMedicineNameBody.
  ///
  /// In en, this message translates to:
  /// **'Medicine {n} has no name. Enter a name or remove it before signing.'**
  String signGateMedicineNameBody(int n);

  /// No description provided for @pdfAwaitingSignature.
  ///
  /// In en, this message translates to:
  /// **'Awaiting signature'**
  String get pdfAwaitingSignature;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Do you want to save them or discard?'**
  String get unsavedChangesBody;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get navPatients;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// No description provided for @newConsultation.
  ///
  /// In en, this message translates to:
  /// **'New Consultation'**
  String get newConsultation;

  /// No description provided for @whoIsThisFor.
  ///
  /// In en, this message translates to:
  /// **'Who is this consultation for?'**
  String get whoIsThisFor;

  /// No description provided for @newPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'New Patient'**
  String get newPatientTitle;

  /// No description provided for @newPatientDesc.
  ///
  /// In en, this message translates to:
  /// **'Add name, age, gender and mobile number for a first-time patient.'**
  String get newPatientDesc;

  /// No description provided for @existingPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Existing Patient'**
  String get existingPatientTitle;

  /// No description provided for @existingPatientDesc.
  ///
  /// In en, this message translates to:
  /// **'Search a patient from history, review their report, then start a new consultation.'**
  String get existingPatientDesc;

  /// No description provided for @stepDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get stepDetails;

  /// No description provided for @stepRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get stepRecording;

  /// No description provided for @stepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get stepReview;

  /// No description provided for @stepShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get stepShare;

  /// No description provided for @patientDetails.
  ///
  /// In en, this message translates to:
  /// **'Patient Details'**
  String get patientDetails;

  /// No description provided for @enterBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Enter basic patient information'**
  String get enterBasicInfo;

  /// No description provided for @confirmDetailsConsent.
  ///
  /// In en, this message translates to:
  /// **'Confirm details & consent'**
  String get confirmDetailsConsent;

  /// No description provided for @patientName.
  ///
  /// In en, this message translates to:
  /// **'Patient Name'**
  String get patientName;

  /// No description provided for @patientNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter full name of the patient'**
  String get patientNameHint;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @whatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get whatsappNumber;

  /// No description provided for @mobileHint.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get mobileHint;

  /// No description provided for @prescriptionShareNote.
  ///
  /// In en, this message translates to:
  /// **'Prescription will be shared on this number'**
  String get prescriptionShareNote;

  /// No description provided for @previousReports.
  ///
  /// In en, this message translates to:
  /// **'Previous Reports (optional)'**
  String get previousReports;

  /// No description provided for @previousReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Scan or attach earlier reports — they are added to the prescription PDF.'**
  String get previousReportsDesc;

  /// No description provided for @addReport.
  ///
  /// In en, this message translates to:
  /// **'Add report'**
  String get addReport;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @reportLabelHint.
  ///
  /// In en, this message translates to:
  /// **'Label (e.g. Blood test, 2 Jan)'**
  String get reportLabelHint;

  /// No description provided for @consentLine.
  ///
  /// In en, this message translates to:
  /// **'Patient has consented to be recorded (DPDP Act)'**
  String get consentLine;

  /// No description provided for @continueToRecording.
  ///
  /// In en, this message translates to:
  /// **'Continue to Recording'**
  String get continueToRecording;

  /// No description provided for @couldNotAddReport.
  ///
  /// In en, this message translates to:
  /// **'Could not add report'**
  String get couldNotAddReport;

  /// No description provided for @couldNotSavePatient.
  ///
  /// In en, this message translates to:
  /// **'Could not save patient'**
  String get couldNotSavePatient;

  /// No description provided for @couldNotSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Could not save your changes'**
  String get couldNotSaveChanges;

  /// No description provided for @nothingHeardInRecording.
  ///
  /// In en, this message translates to:
  /// **'No consultation was heard in this recording. Check that the microphone is working, then record again.'**
  String get nothingHeardInRecording;

  /// No description provided for @retryProcessing.
  ///
  /// In en, this message translates to:
  /// **'Retry with this recording'**
  String get retryProcessing;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record again'**
  String get recordAgain;

  /// No description provided for @consultationErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Your recording is saved on this phone; tap Retry when you are back online.'**
  String get consultationErrorOffline;

  /// No description provided for @consultationErrorProcessing.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be processed. It is saved on this phone; tap Retry.'**
  String get consultationErrorProcessing;

  /// No description provided for @errorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get errorSessionExpired;

  /// No description provided for @consultationErrorStorage.
  ///
  /// In en, this message translates to:
  /// **'The recording could not be saved on this phone. Check free storage and record again.'**
  String get consultationErrorStorage;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorOffline;

  /// No description provided for @errorStorage.
  ///
  /// In en, this message translates to:
  /// **'Files on this phone could not be read or saved. Check that there is free storage.'**
  String get errorStorage;

  /// No description provided for @errorPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission was denied. Allow it for Rxvarta in the phone settings.'**
  String get errorPermission;

  /// No description provided for @errorInvalidBackup.
  ///
  /// In en, this message translates to:
  /// **'This file is not a usable Rxvarta backup for your account.'**
  String get errorInvalidBackup;

  /// No description provided for @errorBackupTooNew.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of Rxvarta. Update the app, then restore.'**
  String get errorBackupTooNew;

  /// No description provided for @patientAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Patient already exists'**
  String get patientAlreadyExists;

  /// No description provided for @patientExistsBody.
  ///
  /// In en, this message translates to:
  /// **'A patient with this number is already in your records:'**
  String get patientExistsBody;

  /// No description provided for @patientExistsQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add this consultation to their existing history?'**
  String get patientExistsQuestion;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get createNew;

  /// No description provided for @useExisting.
  ///
  /// In en, this message translates to:
  /// **'Use existing'**
  String get useExisting;

  /// No description provided for @consultationRecording.
  ///
  /// In en, this message translates to:
  /// **'Consultation Recording'**
  String get consultationRecording;

  /// No description provided for @processingAudio.
  ///
  /// In en, this message translates to:
  /// **'Processing audio...'**
  String get processingAudio;

  /// No description provided for @chooseRecordingOption.
  ///
  /// In en, this message translates to:
  /// **'Choose recording option'**
  String get chooseRecordingOption;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @recordingConversation.
  ///
  /// In en, this message translates to:
  /// **'Recording conversation...'**
  String get recordingConversation;

  /// No description provided for @doctorPlusPatient.
  ///
  /// In en, this message translates to:
  /// **'Doctor + Patient'**
  String get doctorPlusPatient;

  /// No description provided for @saySomething.
  ///
  /// In en, this message translates to:
  /// **'Say something...'**
  String get saySomething;

  /// No description provided for @readyBothVoices.
  ///
  /// In en, this message translates to:
  /// **'Ready — both voices will be captured'**
  String get readyBothVoices;

  /// No description provided for @transcribingConversation.
  ///
  /// In en, this message translates to:
  /// **'Transcribing conversation...'**
  String get transcribingConversation;

  /// No description provided for @extractingPrescription.
  ///
  /// In en, this message translates to:
  /// **'Extracting prescription...'**
  String get extractingPrescription;

  /// No description provided for @recordingTip.
  ///
  /// In en, this message translates to:
  /// **'Place phone on the desk between doctor and patient, then tap Start.'**
  String get recordingTip;

  /// No description provided for @addingToConsultation.
  ///
  /// In en, this message translates to:
  /// **'Adding to consultation — new audio will be merged with the existing transcript.'**
  String get addingToConsultation;

  /// No description provided for @startConsultation.
  ///
  /// In en, this message translates to:
  /// **'Start Consultation'**
  String get startConsultation;

  /// No description provided for @checkingConnection.
  ///
  /// In en, this message translates to:
  /// **'Checking connection…'**
  String get checkingConnection;

  /// No description provided for @offlineReconnect.
  ///
  /// In en, this message translates to:
  /// **'Offline — reconnect to record'**
  String get offlineReconnect;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @minimumFiveSeconds.
  ///
  /// In en, this message translates to:
  /// **'Minimum 5 seconds required'**
  String get minimumFiveSeconds;

  /// No description provided for @recordingApproachingLimit.
  ///
  /// In en, this message translates to:
  /// **'Recording approaching limit'**
  String get recordingApproachingLimit;

  /// No description provided for @offlineNotice.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Recording needs internet to transcribe and process the consultation.'**
  String get offlineNotice;

  /// No description provided for @checkingConnectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Checking your connection — please try again in a moment.'**
  String get checkingConnectionRetry;

  /// No description provided for @internetLostStillRecording.
  ///
  /// In en, this message translates to:
  /// **'No internet. Recording continues; the consultation is processed once you are back online.'**
  String get internetLostStillRecording;

  /// No description provided for @recordingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording consultation'**
  String get recordingNotificationTitle;

  /// No description provided for @recordingNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Rxvarta keeps recording while the screen is off.'**
  String get recordingNotificationText;

  /// No description provided for @micPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is needed to record the consultation.'**
  String get micPermissionNeeded;

  /// No description provided for @micAccessNeeded.
  ///
  /// In en, this message translates to:
  /// **'Microphone access needed'**
  String get micAccessNeeded;

  /// No description provided for @micEnableInSettings.
  ///
  /// In en, this message translates to:
  /// **'Enable microphone permission in settings to record.'**
  String get micEnableInSettings;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @stopRecordingGoBack.
  ///
  /// In en, this message translates to:
  /// **'Stop recording and go back?'**
  String get stopRecordingGoBack;

  /// No description provided for @recordingWillBeLost.
  ///
  /// In en, this message translates to:
  /// **'Your recording will be lost. This cannot be undone.'**
  String get recordingWillBeLost;

  /// No description provided for @stopAndGoBack.
  ///
  /// In en, this message translates to:
  /// **'Stop & Go Back'**
  String get stopAndGoBack;

  /// No description provided for @discardRecording.
  ///
  /// In en, this message translates to:
  /// **'Discard recording?'**
  String get discardRecording;

  /// No description provided for @audioWillBeDiscarded.
  ///
  /// In en, this message translates to:
  /// **'Your recorded audio will be discarded. This cannot be undone.'**
  String get audioWillBeDiscarded;

  /// No description provided for @discardAndGoBack.
  ///
  /// In en, this message translates to:
  /// **'Discard & Go Back'**
  String get discardAndGoBack;

  /// No description provided for @startFresh.
  ///
  /// In en, this message translates to:
  /// **'Start fresh?'**
  String get startFresh;

  /// No description provided for @startFreshBody.
  ///
  /// In en, this message translates to:
  /// **'This will replace your current consultation data.'**
  String get startFreshBody;

  /// No description provided for @startFreshConfirm.
  ///
  /// In en, this message translates to:
  /// **'Start Fresh'**
  String get startFreshConfirm;

  /// No description provided for @existingRecordingNotice.
  ///
  /// In en, this message translates to:
  /// **'You have an existing recording for this consultation.'**
  String get existingRecordingNotice;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @addExtraConversation.
  ///
  /// In en, this message translates to:
  /// **'Add Extra Conversation'**
  String get addExtraConversation;

  /// No description provided for @addExtraDesc.
  ///
  /// In en, this message translates to:
  /// **'Record more and merge with existing data'**
  String get addExtraDesc;

  /// No description provided for @startNewConversation.
  ///
  /// In en, this message translates to:
  /// **'Start New Conversation'**
  String get startNewConversation;

  /// No description provided for @startNewDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear previous and record fresh'**
  String get startNewDesc;

  /// No description provided for @patientHistory.
  ///
  /// In en, this message translates to:
  /// **'Patient History'**
  String get patientHistory;

  /// No description provided for @viewAllConsultations.
  ///
  /// In en, this message translates to:
  /// **'View all consultations and records'**
  String get viewAllConsultations;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get statThisWeek;

  /// No description provided for @statToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statToday;

  /// No description provided for @searchPatientsHint.
  ///
  /// In en, this message translates to:
  /// **'Search patients...'**
  String get searchPatientsHint;

  /// No description provided for @noPatientsFound.
  ///
  /// In en, this message translates to:
  /// **'No patients found'**
  String get noPatientsFound;

  /// No description provided for @noConsultationsYet.
  ///
  /// In en, this message translates to:
  /// **'No consultations yet'**
  String get noConsultationsYet;

  /// No description provided for @unknownPatient.
  ///
  /// In en, this message translates to:
  /// **'Unknown Patient'**
  String get unknownPatient;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @consultationOne.
  ///
  /// In en, this message translates to:
  /// **'consultation'**
  String get consultationOne;

  /// No description provided for @consultationMany.
  ///
  /// In en, this message translates to:
  /// **'consultations'**
  String get consultationMany;

  /// No description provided for @findPatientTitle.
  ///
  /// In en, this message translates to:
  /// **'Find Patient'**
  String get findPatientTitle;

  /// No description provided for @searchByNameOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Search by name or number…'**
  String get searchByNameOrNumber;

  /// No description provided for @noMatchingPatients.
  ///
  /// In en, this message translates to:
  /// **'No matching patients'**
  String get noMatchingPatients;

  /// No description provided for @patientFallback.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientFallback;

  /// No description provided for @patientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Patient not found'**
  String get patientNotFound;

  /// No description provided for @consultationHistory.
  ///
  /// In en, this message translates to:
  /// **'Consultation History'**
  String get consultationHistory;

  /// No description provided for @visitsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Records from this patient\'s visits will appear here.'**
  String get visitsWillAppearHere;

  /// No description provided for @signed.
  ///
  /// In en, this message translates to:
  /// **'Signed'**
  String get signed;

  /// No description provided for @diagnosisLabel.
  ///
  /// In en, this message translates to:
  /// **'Diagnosis'**
  String get diagnosisLabel;

  /// No description provided for @symptomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Symptoms'**
  String get symptomsLabel;

  /// No description provided for @medicinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicinesLabel;

  /// No description provided for @noMedicinesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No medicines recorded.'**
  String get noMedicinesRecorded;

  /// No description provided for @followUpLabel.
  ///
  /// In en, this message translates to:
  /// **'Follow-up'**
  String get followUpLabel;

  /// No description provided for @afterDaysOne.
  ///
  /// In en, this message translates to:
  /// **'After 1 day'**
  String get afterDaysOne;

  /// No description provided for @afterDaysMany.
  ///
  /// In en, this message translates to:
  /// **'After {n} days'**
  String afterDaysMany(int n);

  /// No description provided for @opening.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get opening;

  /// No description provided for @viewPrescription.
  ///
  /// In en, this message translates to:
  /// **'View Prescription'**
  String get viewPrescription;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @couldNotSharePrescription.
  ///
  /// In en, this message translates to:
  /// **'Could not share prescription'**
  String get couldNotSharePrescription;

  /// No description provided for @couldNotSharePdf.
  ///
  /// In en, this message translates to:
  /// **'Could not share PDF'**
  String get couldNotSharePdf;

  /// No description provided for @prescriptionFallback.
  ///
  /// In en, this message translates to:
  /// **'Prescription'**
  String get prescriptionFallback;

  /// No description provided for @newConsultationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create new consultation based on this patient'**
  String get newConsultationTooltip;

  /// No description provided for @couldNotGeneratePrescription.
  ///
  /// In en, this message translates to:
  /// **'Could not generate prescription'**
  String get couldNotGeneratePrescription;

  /// No description provided for @generatingPrescription.
  ///
  /// In en, this message translates to:
  /// **'Generating prescription...'**
  String get generatingPrescription;

  /// No description provided for @preparingPdf.
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF…'**
  String get preparingPdf;

  /// No description provided for @shareOnWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'Share on WhatsApp'**
  String get shareOnWhatsapp;

  /// No description provided for @shareViaOtherApps.
  ///
  /// In en, this message translates to:
  /// **'Share via other apps'**
  String get shareViaOtherApps;

  /// No description provided for @startNewConsultationCta.
  ///
  /// In en, this message translates to:
  /// **'Start New Consultation'**
  String get startNewConsultationCta;

  /// No description provided for @reviewPrescription.
  ///
  /// In en, this message translates to:
  /// **'Review Prescription'**
  String get reviewPrescription;

  /// No description provided for @verifyDetails.
  ///
  /// In en, this message translates to:
  /// **'Verify and edit transcribed details'**
  String get verifyDetails;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// No description provided for @visitNotFound.
  ///
  /// In en, this message translates to:
  /// **'Visit not found'**
  String get visitNotFound;

  /// No description provided for @goBackToRecording.
  ///
  /// In en, this message translates to:
  /// **'Go back to recording?'**
  String get goBackToRecording;

  /// No description provided for @goBackToRecordingBody.
  ///
  /// In en, this message translates to:
  /// **'You can add more to this consultation or start a new recording.'**
  String get goBackToRecordingBody;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @consultationSummary.
  ///
  /// In en, this message translates to:
  /// **'Consultation Summary'**
  String get consultationSummary;

  /// No description provided for @transcriptTitle.
  ///
  /// In en, this message translates to:
  /// **'Transcript'**
  String get transcriptTitle;

  /// No description provided for @transcriptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'As heard by Sarvam STT'**
  String get transcriptSubtitle;

  /// No description provided for @tapToAddSummary.
  ///
  /// In en, this message translates to:
  /// **'Tap the pencil to add a consultation summary'**
  String get tapToAddSummary;

  /// No description provided for @summaryHint.
  ///
  /// In en, this message translates to:
  /// **'Summarise what the patient came in for and the plan'**
  String get summaryHint;

  /// No description provided for @patientInformation.
  ///
  /// In en, this message translates to:
  /// **'Patient Information'**
  String get patientInformation;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @yearsLabel.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get yearsLabel;

  /// No description provided for @whatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappLabel;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @tapToSet.
  ///
  /// In en, this message translates to:
  /// **'Tap to set'**
  String get tapToSet;

  /// No description provided for @diagnosisHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Viral fever'**
  String get diagnosisHint;

  /// No description provided for @noDiagnosisTapPencil.
  ///
  /// In en, this message translates to:
  /// **'No diagnosis — tap the pencil to add'**
  String get noDiagnosisTapPencil;

  /// No description provided for @adviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get adviceTitle;

  /// No description provided for @noAdviceTapPencil.
  ///
  /// In en, this message translates to:
  /// **'No advice yet — tap the pencil to add'**
  String get noAdviceTapPencil;

  /// No description provided for @adviceHint.
  ///
  /// In en, this message translates to:
  /// **'General guidance — one per line'**
  String get adviceHint;

  /// No description provided for @instructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructionsTitle;

  /// No description provided for @noInstructionsTapPencil.
  ///
  /// In en, this message translates to:
  /// **'No instructions yet — tap the pencil to add'**
  String get noInstructionsTapPencil;

  /// No description provided for @instructionsHint.
  ///
  /// In en, this message translates to:
  /// **'Clinical directives — one per line'**
  String get instructionsHint;

  /// No description provided for @noFollowUpSet.
  ///
  /// In en, this message translates to:
  /// **'No follow-up set'**
  String get noFollowUpSet;

  /// No description provided for @daysSuffix.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysSuffix;

  /// No description provided for @prescribedMedicines.
  ///
  /// In en, this message translates to:
  /// **'Prescribed Medicines'**
  String get prescribedMedicines;

  /// No description provided for @noMedicationsYet.
  ///
  /// In en, this message translates to:
  /// **'No medications recorded yet.'**
  String get noMedicationsYet;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @medicineLabel.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicineLabel;

  /// No description provided for @removeMedicine.
  ///
  /// In en, this message translates to:
  /// **'Remove medicine'**
  String get removeMedicine;

  /// No description provided for @dosageLabel.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosageLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @frequencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequencyLabel;

  /// No description provided for @timingLabel.
  ///
  /// In en, this message translates to:
  /// **'Timing'**
  String get timingLabel;

  /// No description provided for @timingBeforeFood.
  ///
  /// In en, this message translates to:
  /// **'Before food'**
  String get timingBeforeFood;

  /// No description provided for @timingAfterFood.
  ///
  /// In en, this message translates to:
  /// **'After food'**
  String get timingAfterFood;

  /// No description provided for @timingWithFood.
  ///
  /// In en, this message translates to:
  /// **'With food'**
  String get timingWithFood;

  /// No description provided for @timingEmptyStomach.
  ///
  /// In en, this message translates to:
  /// **'Empty stomach'**
  String get timingEmptyStomach;

  /// No description provided for @timingBeforeBed.
  ///
  /// In en, this message translates to:
  /// **'Before bed'**
  String get timingBeforeBed;

  /// No description provided for @timingAsDirected.
  ///
  /// In en, this message translates to:
  /// **'As directed'**
  String get timingAsDirected;

  /// No description provided for @aiDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'AI extracts only what the doctor said. Review the summary and medicines before signing.'**
  String get aiDisclaimer;

  /// No description provided for @generatePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate Prescription PDF'**
  String get generatePdf;

  /// No description provided for @signAndGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Sign & Generate PDF'**
  String get signAndGeneratePdf;

  /// No description provided for @icdCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'ICD-10 Code'**
  String get icdCodeTitle;

  /// No description provided for @icdVerifyWarning.
  ///
  /// In en, this message translates to:
  /// **'AI suggestion - please verify this code before relying on it.'**
  String get icdVerifyWarning;

  /// No description provided for @icdCodeField.
  ///
  /// In en, this message translates to:
  /// **'Code (e.g. B34.9)'**
  String get icdCodeField;

  /// No description provided for @descriptionField.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionField;

  /// No description provided for @icdFooterNote.
  ///
  /// In en, this message translates to:
  /// **'This code was suggested by AI based on the diagnosis text. Please verify accuracy before clinical or billing use.'**
  String get icdFooterNote;

  /// No description provided for @suggestedDifferentials.
  ///
  /// In en, this message translates to:
  /// **'Suggested Differentials'**
  String get suggestedDifferentials;

  /// No description provided for @aiSuggestionVerify.
  ///
  /// In en, this message translates to:
  /// **'AI Suggestion — Verify'**
  String get aiSuggestionVerify;

  /// No description provided for @differentialsBasedOn.
  ///
  /// In en, this message translates to:
  /// **'Based on reported symptoms. Doctor must verify.'**
  String get differentialsBasedOn;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @prescriptionReady.
  ///
  /// In en, this message translates to:
  /// **'Prescription Ready'**
  String get prescriptionReady;

  /// No description provided for @reviewAndShare.
  ///
  /// In en, this message translates to:
  /// **'Review and share with patient'**
  String get reviewAndShare;

  /// No description provided for @generatingPdfLong.
  ///
  /// In en, this message translates to:
  /// **'Generating prescription PDF…'**
  String get generatingPdfLong;

  /// No description provided for @couldNotGeneratePdf.
  ///
  /// In en, this message translates to:
  /// **'Could not generate PDF'**
  String get couldNotGeneratePdf;
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
    'bn',
    'en',
    'gu',
    'hi',
    'kn',
    'mr',
    'ta',
    'te',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'kn':
      return AppLocalizationsKn();
    case 'mr':
      return AppLocalizationsMr();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

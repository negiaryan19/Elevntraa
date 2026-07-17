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
  /// **'Secure - HIPAA Compliant - End-to-End Encrypted'**
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

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get dataBackup;

  /// No description provided for @dataBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Backup your consultation history'**
  String get dataBackupSubtitle;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @exportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download all your data'**
  String get exportDataSubtitle;

  /// No description provided for @privacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurity;

  /// No description provided for @privacySecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your privacy settings'**
  String get privacySecuritySubtitle;

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

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

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

  /// No description provided for @internetLostPaused.
  ///
  /// In en, this message translates to:
  /// **'Internet lost — recording paused. Reconnect to resume and finish the consultation.'**
  String get internetLostPaused;

  /// No description provided for @internetLostPauseManually.
  ///
  /// In en, this message translates to:
  /// **'Internet lost and the recording could not be paused automatically — please tap Pause.'**
  String get internetLostPauseManually;

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

  /// No description provided for @welcomeToRxvarta.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rxvarta'**
  String get welcomeToRxvarta;

  /// No description provided for @onboardingMessage.
  ///
  /// In en, this message translates to:
  /// **'Doctor profile and API key setup will live here.'**
  String get onboardingMessage;
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

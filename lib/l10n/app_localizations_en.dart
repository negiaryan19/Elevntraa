// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Rxvarta';

  @override
  String get appTagline => 'Smart Medical Documentation';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get checking => 'Checking';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get doctorFallback => 'Doctor';

  @override
  String get startNewConsultation => 'Start new consultation';

  @override
  String get startNewConsultationSubtitle =>
      'Record and transcribe a patient visit';

  @override
  String get newPatient => 'New patient';

  @override
  String get findPatient => 'Find patient';

  @override
  String get allPatients => 'All patients';

  @override
  String get recentPatients => 'Recent patients';

  @override
  String get seeAll => 'See all';

  @override
  String get noPatientsYet => 'No patients yet';

  @override
  String get noPatientsYetSubtitle =>
      'Start a consultation to add your first patient.';

  @override
  String get securityFooter =>
      'Encrypted in transit - Hosted in India - Your records stay under your control';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get years => 'yrs';

  @override
  String get settings => 'Settings';

  @override
  String get settingsSubtitle => 'Manage your app preferences';

  @override
  String get sectionAccount => 'Account';

  @override
  String get sectionPreferences => 'Preferences';

  @override
  String get sectionDataPrivacy => 'Data & Privacy';

  @override
  String get sectionSupport => 'Support';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get profileSettingsSubtitle =>
      'Name, qualifications, registration & clinic details';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkThemeActive => 'Dark theme active';

  @override
  String get lightThemeActive => 'Light theme active';

  @override
  String get appLanguage => 'App Language';

  @override
  String get appLanguageSubtitle => 'Choose the language of the app interface';

  @override
  String get chooseLanguage => 'Choose Language';

  @override
  String get exportData => 'Export Data';

  @override
  String get backupTitle => 'Backup & sync';

  @override
  String get backupIntro =>
      'Keeps a copy of your records in your own private cloud folder, so nothing is lost if this phone is.';

  @override
  String get backupIncludes =>
      'Included: patients, consultations, prescriptions, report photos, your profile and signature.';

  @override
  String get backupExcludes =>
      'Not included: consultation recordings (they are deleted after processing).';

  @override
  String backupLastAt(String time) {
    return 'Last backup $time';
  }

  @override
  String get backupNever => 'Never backed up';

  @override
  String get backupNow => 'Back up now';

  @override
  String backupLatestRemote(String time, String size) {
    return 'Latest in cloud: $time ($size)';
  }

  @override
  String get backupNoRemote => 'No backup in the cloud yet';

  @override
  String get backupRestoreLatest => 'Restore latest backup';

  @override
  String get backupRestoreConfirmTitle => 'Replace data on this phone?';

  @override
  String backupRestoreConfirmBody(String time) {
    return 'Your records on this phone are replaced by the backup from $time. Other doctors who use this phone are not affected. This cannot be undone.';
  }

  @override
  String get backupRestoreConfirm => 'Restore';

  @override
  String get backupStageCollecting => 'Collecting your records…';

  @override
  String get backupStageZipping => 'Packing them up…';

  @override
  String get backupStageUploading => 'Uploading…';

  @override
  String get backupStageDownloading => 'Downloading backup…';

  @override
  String get backupStageRestoring => 'Restoring…';

  @override
  String get backupDone => 'Backup complete';

  @override
  String get backupRestored => 'Backup restored';

  @override
  String get backupRestartHint =>
      'Close and reopen the app to see the restored records.';

  @override
  String backupFailed(String reason) {
    return 'Backup failed: $reason';
  }

  @override
  String backupRestoreFailed(String reason) {
    return 'Restore failed: $reason';
  }

  @override
  String get backupNeedsInternet => 'Connect to the internet to back up.';

  @override
  String get exportPreparing => 'Preparing your export…';

  @override
  String get exportShareSubject => 'Rxvarta data export';

  @override
  String get exportShareText => 'Export of my Rxvarta records.';

  @override
  String exportFailed(String reason) {
    return 'Could not export data: $reason';
  }

  @override
  String get exportEmpty => 'There is nothing to export yet.';

  @override
  String exportSavedTo(String path) {
    return 'Saved to $path';
  }

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get termsConditionsSubtitle => 'Read our terms of service';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get helpSupportSubtitle => 'Get help or contact us';

  @override
  String get settingsProfileSetUp => 'Set up your profile';

  @override
  String get settingsProfileIncompleteChip =>
      'Profile incomplete — prescriptions cannot be signed';

  @override
  String get settingsSignature => 'Signature';

  @override
  String get settingsSignatureSubtitleAdded =>
      'Added — printed on every prescription you sign';

  @override
  String get settingsSignatureSubtitleMissing => 'Not added yet';

  @override
  String get settingsBackupSync => 'Backup & sync';

  @override
  String get settingsBackupSubtitleNever => 'Never backed up';

  @override
  String settingsBackupSubtitleLast(String time) {
    return 'Last backup $time';
  }

  @override
  String get settingsExportSubtitle =>
      'Save or share a copy of all your records';

  @override
  String get settingsPrivacySubtitle =>
      'Where your data lives and how to delete it';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyPolicySubtitle =>
      'How your and your patients\' data is handled';

  @override
  String settingsVersion(String version, String build) {
    return 'Rxvarta v$version ($build)';
  }

  @override
  String get settingsTimeJustNow => 'just now';

  @override
  String settingsTimeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String settingsTimeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'yesterday',
    );
    return '$_temp0';
  }

  @override
  String get settingsSigningOut => 'Signing out…';

  @override
  String get logoutConfirmTitle => 'Sign out?';

  @override
  String get logoutConfirmBody =>
      'You will need to sign in again to use Rxvarta. Records saved on this device stay on it.';

  @override
  String get logoutConfirm => 'Sign out';

  @override
  String get privacyIntro =>
      'Rxvarta is built so that patient records stay under the doctor\'s control. This page explains, in plain words, where data is kept, who processes it and how to delete it.';

  @override
  String get privacyWhereStoredTitle => 'Where your data lives';

  @override
  String get privacyWhereStoredDevice =>
      'This device — patients, visits, transcripts, prescriptions, report photos and recordings are kept in the app\'s private storage on this phone.';

  @override
  String get privacyWhereStoredCloud =>
      'Supabase project hosted in Mumbai, India (ap-south-1) — your account, doctor profile, signature and backups.';

  @override
  String get privacyWhereStoredAudio =>
      'Recordings are uploaded to a private storage bucket only for processing, never for long-term storage.';

  @override
  String get privacyProcessorsTitle => 'Who processes it';

  @override
  String get privacyProcessorSarvam =>
      'Sarvam AI — converts the recording into text (speech-to-text).';

  @override
  String get privacyProcessorGoogle =>
      'Google Gemini — turns the transcript into a structured draft prescription for you to review.';

  @override
  String get privacyProcessorSupabase =>
      'Supabase — sign-in, file storage and the database behind your account.';

  @override
  String get privacyRetentionTitle => 'How long it is kept';

  @override
  String get privacyRetentionAudio =>
      'Recordings: deleted from the server once processing succeeds; kept on this device until then.';

  @override
  String get privacyRetentionTranscript =>
      'Transcripts and prescriptions: on this device and in your backups until you delete them.';

  @override
  String get privacyRetentionJobs =>
      'Processing cache: cleared after the result has been delivered to the app.';

  @override
  String get privacyRoleTitle => 'Your role and ours';

  @override
  String get privacyRoleBody =>
      'Under the Digital Personal Data Protection Act, 2023 you, the doctor, remain the data fiduciary for your patients\' records. Rxvarta processes them only on your instructions, as a data processor.';

  @override
  String get privacySecurityTitle => 'Security measures';

  @override
  String get privacySecurityBody =>
      'Data travels over encrypted connections (TLS). Records on the server are protected by per-account access rules, so only your sign-in can read them. Keep your phone locked: anyone who can unlock it can open the app.';

  @override
  String get privacyDeleteTitle => 'Deleting data';

  @override
  String get privacyDeleteBody =>
      'Use the button below to remove your data from this phone. Other doctors who sign in on this phone keep theirs. Patient records cannot be deleted one by one yet. To delete your account and the data kept on our servers, write to us from the e-mail address you signed up with.';

  @override
  String get privacyDeleteLocal => 'Delete my data on this device';

  @override
  String get privacyDeleteLocalSubtitle =>
      'Removes your patients, visits, recordings, reports, profile cache and signature from this phone and signs you out. Your account and backups on the server are not affected.';

  @override
  String privacyDeleteLocalBody(String word) {
    return 'Every patient, visit, recording and report of yours stored on this phone will be removed and you will be signed out. Other doctors\' data on this phone and your backups on the server are not affected. This cannot be undone.\n\nType $word to confirm.';
  }

  @override
  String get privacyDeleteLocalWord => 'DELETE';

  @override
  String privacyDeleteLocalHint(String word) {
    return 'Type $word';
  }

  @override
  String get privacyDeleteLocalConfirm => 'Delete everything';

  @override
  String get privacyDeleting => 'Deleting local data…';

  @override
  String get privacyDeleted => 'Local data deleted';

  @override
  String privacyDeletePartial(String details) {
    return 'Some items could not be deleted: $details';
  }

  @override
  String get privacyReadPolicy => 'Read the full Privacy Policy';

  @override
  String get legalTerms => 'Terms & Conditions';

  @override
  String get legalPrivacyPolicy => 'Privacy Policy';

  @override
  String legalLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get legalReviewNotice =>
      'Bundled copy — available offline. If a newer version is published online, the online version applies.';

  @override
  String get legalViewOnline => 'View online version';

  @override
  String get legalLoadFailed => 'Could not load this document.';

  @override
  String get helpTitle => 'Help & Support';

  @override
  String get helpSubtitle =>
      'Questions, feedback or a problem with the app? We are happy to help.';

  @override
  String helpVersion(String version, String build) {
    return 'App version $version ($build)';
  }

  @override
  String get helpEmail => 'Email support';

  @override
  String get helpWhatsapp => 'WhatsApp support';

  @override
  String get helpReportProblem => 'Report a problem';

  @override
  String get helpReportProblemSubtitle =>
      'Tell us what happened and how to reproduce it';

  @override
  String get helpNotConfigured => 'Support contact not configured yet';

  @override
  String get helpCouldNotOpen => 'Could not open this on your device.';

  @override
  String get helpEmailSubject => 'Rxvarta support';

  @override
  String helpEmailBody(String version, String platform) {
    return 'App version: $version\nPlatform: $platform\n\n';
  }

  @override
  String get helpReportSubject => 'Rxvarta — problem report';

  @override
  String helpReportBody(String version, String platform) {
    return 'What happened:\n\n\nSteps to reproduce:\n1. \n2. \n3. \n\nApp version: $version\nPlatform: $platform\n';
  }

  @override
  String get logout => 'Logout';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authSignInTitle => 'Welcome back';

  @override
  String get authSignInSubtitle => 'Sign in to continue to your consultations.';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'doctor@clinic.com';

  @override
  String get authEmailInvalid => 'Enter a valid email address';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordRequired => 'Enter your password';

  @override
  String get authPasswordRules =>
      'At least 8 characters, with a capital and a small letter, a number and a symbol';

  @override
  String get authPasswordTooShort => 'Use at least 8 characters';

  @override
  String get authPasswordTooLong => 'Too long — shorten it a little';

  @override
  String get authPasswordNeedsLowercase => 'Add a small letter (a–z)';

  @override
  String get authPasswordNeedsUppercase => 'Add a capital letter (A–Z)';

  @override
  String get authPasswordNeedsDigit => 'Add a number (0–9)';

  @override
  String get authPasswordNeedsSymbol => 'Add a symbol, such as ! or @';

  @override
  String authEmailDidYouMean(String suggestion) {
    return 'Did you mean $suggestion?';
  }

  @override
  String authEmailKeepAsTyped(String button) {
    return 'To keep it as typed, tap “$button” again.';
  }

  @override
  String get authPasswordsDoNotMatch => 'Passwords do not match';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authNoAccount => 'New to Rxvarta?';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authHaveAccount => 'Already have an account?';

  @override
  String get authSignUpTitle => 'Create your account';

  @override
  String get authSignUpSubtitle =>
      'One account per doctor. Your patients and prescriptions stay private to you.';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authSignInInstead => 'Sign in instead';

  @override
  String get authVerifyTitle => 'Check your email';

  @override
  String authVerifyBody(String email) {
    return 'We sent an 8-digit code to $email. Enter it below to continue.';
  }

  @override
  String get authCode => 'Verification code';

  @override
  String get authCodeIncomplete => 'Enter all 8 digits of the code';

  @override
  String get authVerify => 'Verify';

  @override
  String get authResendCode => 'Resend code';

  @override
  String authResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get authCodeSent => 'A new code has been sent to your email.';

  @override
  String get authForgotTitle => 'Reset your password';

  @override
  String get authForgotSubtitle =>
      'Enter the email you signed up with and we will send you a code.';

  @override
  String get authSendCode => 'Send code';

  @override
  String get authResetTitle => 'Choose a new password';

  @override
  String get authResetSubtitle =>
      'Use a password you have not used with Rxvarta before.';

  @override
  String get authNewPassword => 'New password';

  @override
  String get authUpdatePassword => 'Update password';

  @override
  String get authPasswordUpdated => 'Password updated';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authBack => 'Back';

  @override
  String get authNotConfiguredTitle => 'App not configured';

  @override
  String get authNotConfiguredBody =>
      'This build has no backend connection, so sign-in is unavailable. Build the app with --dart-define-from-file=config/app_config.json (see the README).';

  @override
  String get authSplashLoading => 'Preparing your workspace…';

  @override
  String get authSecureNote => 'Encrypted and private to your account.';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Please verify your email address first.';

  @override
  String get authErrorUserExists =>
      'An account with this email already exists.';

  @override
  String get authErrorWeakPassword =>
      'Choose a stronger password: at least 8 characters and different from your current one.';

  @override
  String get authErrorOtpExpired => 'This code has expired. Request a new one.';

  @override
  String get authErrorOtpInvalid =>
      'That code is not correct. Check it and try again.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Please wait a minute and try again.';

  @override
  String get authErrorEmailSendFailed =>
      'We could not send the email just now. Please try again in a minute.';

  @override
  String get authErrorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get authErrorSignupDisabled => 'New sign-ups are currently disabled.';

  @override
  String get authErrorValidation => 'Please check the details you entered.';

  @override
  String get authErrorNotConfigured => 'The app is not connected to a backend.';

  @override
  String get authErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get authErrorDetails => 'Details';

  @override
  String get regPrefix => 'Reg.';

  @override
  String get allRightsReserved => 'All rights reserved';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileSubtitle => 'Appears on prescription letterhead.';

  @override
  String get doctorName => 'Doctor name';

  @override
  String get qualifications => 'Qualifications';

  @override
  String get registrationNumber => 'Registration number';

  @override
  String get clinicName => 'Clinic / Hospital name';

  @override
  String get clinicAddress => 'Clinic address';

  @override
  String get clinicPhone => 'Clinic phone';

  @override
  String get profilePhone => 'Your mobile number';

  @override
  String get profileOptional => 'Optional';

  @override
  String get profileRequiredHint =>
      'Fields marked * are printed on every prescription and are required by law.';

  @override
  String get profileSectionDoctor => 'Doctor details';

  @override
  String get profileSectionClinic => 'Clinic details';

  @override
  String get profileNameHint => 'e.g. Dr. Asha Verma';

  @override
  String get profileQualificationsHint => 'e.g. MBBS, MD (Medicine)';

  @override
  String get profileRegNoHint => 'State medical council number';

  @override
  String get profilePhoneHint => '10-digit mobile number';

  @override
  String get profilePhoneInvalid => 'Enter a valid mobile number';

  @override
  String get profileClinicNameHint => 'Clinic or hospital name';

  @override
  String get profileClinicAddressHint => 'Area, City, State PIN';

  @override
  String get profileClinicPhoneHint => 'Landline or reception number';

  @override
  String get profileSavedOffline =>
      'Saved on this device — will sync when online';

  @override
  String get profileSaveFailed => 'Could not save profile';

  @override
  String get profileRetry => 'Retry';

  @override
  String get profileIncompleteNudgeTitle =>
      'Complete your profile to sign prescriptions';

  @override
  String get profileIncompleteNudgeBody =>
      'Add your name, registration number, clinic and signature.';

  @override
  String get signatureTitle => 'Signature';

  @override
  String get signatureSubtitle => 'Printed on every prescription you sign.';

  @override
  String get signatureAdd => 'Add signature';

  @override
  String get signatureUpdate => 'Update signature';

  @override
  String get signatureDraw => 'Draw';

  @override
  String get signatureUpload => 'Upload';

  @override
  String get signatureClear => 'Clear';

  @override
  String get signatureUse => 'Use signature';

  @override
  String get signatureEmptyError => 'Please draw your signature first.';

  @override
  String get signatureHint => 'Sign above the line with your finger or mouse';

  @override
  String get signatureUploadHint =>
      'Choose a clear photo or scan of your signature on white paper (PNG or JPEG).';

  @override
  String get signatureChooseImage => 'Choose image';

  @override
  String get signatureChangeImage => 'Choose another';

  @override
  String get signatureUnsupportedFormat => 'Please choose a PNG or JPEG image.';

  @override
  String get signatureLoadFailed => 'Could not load that image';

  @override
  String get signatureNone => 'No signature yet';

  @override
  String get signatureSaved => 'Signature saved';

  @override
  String get signatureSaveFailed => 'Could not save signature';

  @override
  String get onboardingTitle => 'Set up your prescription';

  @override
  String get onboardingSubtitle =>
      'These details appear on every prescription you sign.';

  @override
  String get onboardingStepDoctor => 'Doctor';

  @override
  String get onboardingStepClinic => 'Clinic';

  @override
  String get onboardingStepSignature => 'Signature';

  @override
  String get onboardingDoctorTitle => 'Your details';

  @override
  String get onboardingDoctorBody =>
      'Exactly as they should appear on the letterhead.';

  @override
  String get onboardingClinicTitle => 'Your clinic';

  @override
  String get onboardingClinicBody =>
      'Practice name and address printed on the prescription.';

  @override
  String get onboardingSignatureTitle => 'Your signature';

  @override
  String get onboardingSignatureBody =>
      'Draw it once or upload a photo. It is stored privately and printed only on prescriptions you sign.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingFinish => 'Finish';

  @override
  String get onboardingSignatureRequired => 'Add your signature to finish.';

  @override
  String get onboardingSignOut => 'Sign out';

  @override
  String onboardingSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signGateTitle => 'Complete your profile to sign';

  @override
  String get signGateBody =>
      'A prescription must carry the prescribing doctor\'s details. Add the following before signing:';

  @override
  String get signGateCompleteProfile => 'Complete profile';

  @override
  String get signGateOk => 'OK';

  @override
  String get signGatePatientNameTitle => 'Patient name missing';

  @override
  String get signGatePatientNameBody =>
      'Add the patient\'s name before signing the prescription.';

  @override
  String get signGateMedicineNameTitle => 'Medicine name missing';

  @override
  String signGateMedicineNameBody(int n) {
    return 'Medicine $n has no name. Enter a name or remove it before signing.';
  }

  @override
  String pdfDocumentTitle(String name) {
    return 'Prescription — $name';
  }

  @override
  String get pdfPatient => 'Patient';

  @override
  String get pdfDate => 'Date';

  @override
  String get pdfAge => 'Age';

  @override
  String get pdfGender => 'Gender';

  @override
  String get pdfPhone => 'Phone';

  @override
  String pdfAgeYears(int age) {
    return '$age yrs';
  }

  @override
  String get pdfRegNo => 'Reg. No';

  @override
  String get pdfDiagnosis => 'Diagnosis';

  @override
  String get pdfNoMedicines => 'No medicines prescribed.';

  @override
  String get pdfColMedicine => 'Medicine';

  @override
  String get pdfColDosage => 'Dosage';

  @override
  String get pdfColFrequency => 'Frequency';

  @override
  String get pdfColDuration => 'Duration';

  @override
  String get pdfColTiming => 'Timing';

  @override
  String get pdfInvestigations => 'Investigations advised';

  @override
  String get pdfInstructions => 'Instructions';

  @override
  String get pdfAdvice => 'Advice';

  @override
  String get pdfFollowUp => 'Follow-up';

  @override
  String pdfFollowUpAfter(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'After $days days',
      one: 'After 1 day',
    );
    return '$_temp0';
  }

  @override
  String get pdfNextVisit => 'Next visit';

  @override
  String get pdfPreviousReports => 'Previous reports';

  @override
  String pdfReportsAttachedFor(String name) {
    return 'Attached for $name';
  }

  @override
  String pdfReportCaption(int number) {
    return 'Report $number';
  }

  @override
  String get pdfComputerGenerated =>
      'This is a computer-generated prescription';

  @override
  String get pdfFooterTagline =>
      'Generated by Rxvarta AI  |  Secure  |  Private';

  @override
  String get pdfAwaitingSignature => 'Awaiting signature';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get unsavedChangesBody =>
      'You have unsaved changes. Do you want to save them or discard?';

  @override
  String get discard => 'Discard';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get required => 'Required';

  @override
  String get navHome => 'Home';

  @override
  String get navPatients => 'Patients';

  @override
  String get navSettings => 'Settings';

  @override
  String get notFound => 'Not found';

  @override
  String get newConsultation => 'New Consultation';

  @override
  String get whoIsThisFor => 'Who is this consultation for?';

  @override
  String get newPatientTitle => 'New Patient';

  @override
  String get newPatientDesc =>
      'Add name, age, gender and mobile number for a first-time patient.';

  @override
  String get existingPatientTitle => 'Existing Patient';

  @override
  String get existingPatientDesc =>
      'Search a patient from history, review their report, then start a new consultation.';

  @override
  String get stepDetails => 'Details';

  @override
  String get stepRecording => 'Recording';

  @override
  String get stepReview => 'Review';

  @override
  String get stepShare => 'Share';

  @override
  String get patientDetails => 'Patient Details';

  @override
  String get editPatientDetails => 'Edit patient details';

  @override
  String get enterBasicInfo => 'Enter basic patient information';

  @override
  String get confirmDetailsConsent => 'Confirm details & consent';

  @override
  String get patientName => 'Patient Name';

  @override
  String get patientNameHint => 'Enter full name of the patient';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get select => 'Select';

  @override
  String get whatsappNumber => 'WhatsApp Number';

  @override
  String get mobileHint => '10-digit mobile number';

  @override
  String get prescriptionShareNote =>
      'Prescription will be shared on this number';

  @override
  String get previousReports => 'Previous Reports (optional)';

  @override
  String get previousReportsDesc =>
      'Scan or attach earlier reports — they are added to the prescription PDF.';

  @override
  String get addReport => 'Add report';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get reportLabelHint => 'Label (e.g. Blood test, 2 Jan)';

  @override
  String get consentLine => 'Patient has consented to be recorded (DPDP Act)';

  @override
  String get continueToRecording => 'Continue to Recording';

  @override
  String get couldNotAddReport => 'Could not add report';

  @override
  String get couldNotSavePatient => 'Could not save patient';

  @override
  String get couldNotSaveChanges => 'Could not save your changes';

  @override
  String get nothingHeardInRecording =>
      'No consultation was heard in this recording. Check that the microphone is working, then record again.';

  @override
  String get retryProcessing => 'Retry with this recording';

  @override
  String get recordAgain => 'Record again';

  @override
  String get consultationErrorOffline =>
      'No internet connection. Your recording is saved on this phone; tap Retry when you are back online.';

  @override
  String get consultationErrorProcessing =>
      'The recording could not be processed. It is saved on this phone; tap Retry.';

  @override
  String get errorSessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get consultationErrorStorage =>
      'The recording could not be saved on this phone. Check free storage and record again.';

  @override
  String get errorUnexpected => 'Something went wrong. Please try again.';

  @override
  String get errorOffline => 'No internet connection.';

  @override
  String get errorStorage =>
      'Files on this phone could not be read or saved. Check that there is free storage.';

  @override
  String get errorPermission =>
      'Permission was denied. Allow it for Rxvarta in the phone settings.';

  @override
  String get errorInvalidBackup =>
      'This file is not a usable Rxvarta backup for your account.';

  @override
  String get errorBackupTooNew =>
      'This backup was made by a newer version of Rxvarta. Update the app, then restore.';

  @override
  String get patientAlreadyExists => 'Patient already exists';

  @override
  String get patientExistsBody =>
      'A patient with this number is already in your records:';

  @override
  String get patientExistsQuestion =>
      'Add this consultation to their existing history?';

  @override
  String get createNew => 'Create new';

  @override
  String get useExisting => 'Use existing';

  @override
  String get consultationRecording => 'Consultation Recording';

  @override
  String get processingAudio => 'Processing audio...';

  @override
  String get chooseRecordingOption => 'Choose recording option';

  @override
  String get paused => 'Paused';

  @override
  String get recordingConversation => 'Recording conversation...';

  @override
  String get doctorPlusPatient => 'Doctor + Patient';

  @override
  String get saySomething => 'Say something...';

  @override
  String get readyBothVoices => 'Ready — both voices will be captured';

  @override
  String get transcribingConversation => 'Transcribing conversation...';

  @override
  String get extractingPrescription => 'Extracting prescription...';

  @override
  String get recordingTip =>
      'Place phone on the desk between doctor and patient, then tap Start.';

  @override
  String get addingToConsultation =>
      'Adding to consultation — new audio will be merged with the existing transcript.';

  @override
  String get startConsultation => 'Start Consultation';

  @override
  String get checkingConnection => 'Checking connection…';

  @override
  String get offlineReconnect => 'Offline — reconnect to record';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get minimumFiveSeconds => 'Minimum 5 seconds required';

  @override
  String get recordingApproachingLimit => 'Recording approaching limit';

  @override
  String get offlineNotice =>
      'No internet connection. Recording needs internet to transcribe and process the consultation.';

  @override
  String get offlineWillQueue =>
      'You\'re offline. The recording will be saved on this phone and processed when the internet is back.';

  @override
  String get consultationQueued =>
      'Saved on this phone. It will be processed when the internet is back.';

  @override
  String get processLater => 'Process later';

  @override
  String get pendingTitle => 'Waiting to be processed';

  @override
  String get pendingQueued => 'Waiting for internet';

  @override
  String get pendingProcessing => 'Processing…';

  @override
  String get pendingReady => 'Ready to review';

  @override
  String get pendingFailed => 'Could not be processed';

  @override
  String get pendingDismiss => 'Dismiss';

  @override
  String get checkingConnectionRetry =>
      'Checking your connection — please try again in a moment.';

  @override
  String get internetLostStillRecording =>
      'No internet. Recording continues; the consultation is processed once you are back online.';

  @override
  String get recordingNotificationTitle => 'Recording consultation';

  @override
  String get recordingNotificationText =>
      'Rxvarta keeps recording while the screen is off.';

  @override
  String get micPermissionNeeded =>
      'Microphone permission is needed to record the consultation.';

  @override
  String get micAccessNeeded => 'Microphone access needed';

  @override
  String get micEnableInSettings =>
      'Enable microphone permission in settings to record.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get stopRecordingGoBack => 'Stop recording and go back?';

  @override
  String get recordingWillBeLost =>
      'Your recording will be lost. This cannot be undone.';

  @override
  String get stopAndGoBack => 'Stop & Go Back';

  @override
  String get discardRecording => 'Discard recording?';

  @override
  String get audioWillBeDiscarded =>
      'Your recorded audio will be discarded. This cannot be undone.';

  @override
  String get discardAndGoBack => 'Discard & Go Back';

  @override
  String get startFresh => 'Start fresh?';

  @override
  String get startFreshBody =>
      'This will replace your current consultation data.';

  @override
  String get startFreshConfirm => 'Start Fresh';

  @override
  String get existingRecordingNotice =>
      'You have an existing recording for this consultation.';

  @override
  String get duration => 'Duration';

  @override
  String get addExtraConversation => 'Add Extra Conversation';

  @override
  String get addExtraDesc => 'Record more and merge with existing data';

  @override
  String get startNewConversation => 'Start New Conversation';

  @override
  String get startNewDesc => 'Clear previous and record fresh';

  @override
  String get patientHistory => 'Patient History';

  @override
  String get viewAllConsultations => 'View all consultations and records';

  @override
  String get statTotal => 'Total';

  @override
  String get statThisWeek => 'This Week';

  @override
  String get statToday => 'Today';

  @override
  String get searchPatientsHint => 'Search patients...';

  @override
  String get noPatientsFound => 'No patients found';

  @override
  String get noConsultationsYet => 'No consultations yet';

  @override
  String get unknownPatient => 'Unknown Patient';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get consultationOne => 'consultation';

  @override
  String get consultationMany => 'consultations';

  @override
  String get findPatientTitle => 'Find Patient';

  @override
  String get searchByNameOrNumber => 'Search by name or number…';

  @override
  String get noMatchingPatients => 'No matching patients';

  @override
  String get patientFallback => 'Patient';

  @override
  String get patientNotFound => 'Patient not found';

  @override
  String get consultationHistory => 'Consultation History';

  @override
  String get visitsWillAppearHere =>
      'Records from this patient\'s visits will appear here.';

  @override
  String get signed => 'Signed';

  @override
  String get diagnosisLabel => 'Diagnosis';

  @override
  String get symptomsLabel => 'Symptoms';

  @override
  String get medicinesLabel => 'Medicines';

  @override
  String get noMedicinesRecorded => 'No medicines recorded.';

  @override
  String get followUpLabel => 'Follow-up';

  @override
  String get afterDaysOne => 'After 1 day';

  @override
  String afterDaysMany(int n) {
    return 'After $n days';
  }

  @override
  String get opening => 'Opening…';

  @override
  String get viewPrescription => 'View Prescription';

  @override
  String get share => 'Share';

  @override
  String get couldNotSharePrescription => 'Could not share prescription';

  @override
  String get couldNotSharePdf => 'Could not share PDF';

  @override
  String get prescriptionFallback => 'Prescription';

  @override
  String get newConsultationTooltip =>
      'Create new consultation based on this patient';

  @override
  String get couldNotGeneratePrescription => 'Could not generate prescription';

  @override
  String get generatingPrescription => 'Generating prescription...';

  @override
  String get preparingPdf => 'Preparing PDF…';

  @override
  String get shareOnWhatsapp => 'Share on WhatsApp';

  @override
  String get shareViaOtherApps => 'Share via other apps';

  @override
  String get startNewConsultationCta => 'Start New Consultation';

  @override
  String get reviewPrescription => 'Review Prescription';

  @override
  String get verifyDetails => 'Verify and edit transcribed details';

  @override
  String get reviewTitle => 'Review';

  @override
  String get visitNotFound => 'Visit not found';

  @override
  String get goBackToRecording => 'Go back to recording?';

  @override
  String get goBackToRecordingBody =>
      'You can add more to this consultation or start a new recording.';

  @override
  String get stay => 'Stay';

  @override
  String get goBack => 'Go Back';

  @override
  String get consultationSummary => 'Consultation Summary';

  @override
  String get transcriptTitle => 'Transcript';

  @override
  String get transcriptSubtitle => 'As heard by Sarvam STT';

  @override
  String get tapToAddSummary => 'Tap the pencil to add a consultation summary';

  @override
  String get summaryHint =>
      'Summarise what the patient came in for and the plan';

  @override
  String get patientInformation => 'Patient Information';

  @override
  String get nameLabel => 'Name';

  @override
  String get yearsLabel => 'Years';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get tapToSet => 'Tap to set';

  @override
  String get diagnosisHint => 'e.g. Viral fever';

  @override
  String get noDiagnosisTapPencil => 'No diagnosis — tap the pencil to add';

  @override
  String get investigationsTitle => 'Investigations';

  @override
  String get noInvestigationsTapPencil =>
      'No tests advised — tap the pencil to add';

  @override
  String get investigationsHint => 'Tests to be done — one per line';

  @override
  String get doctorNotesTitle => 'Doctor\'s notes';

  @override
  String get doctorNotesNotPrinted =>
      'Kept for your records; not printed on the prescription';

  @override
  String get noDoctorNotesTapPencil => 'No notes — tap the pencil to add';

  @override
  String get doctorNotesHint => 'Your own notes about this consultation';

  @override
  String get adviceTitle => 'Advice';

  @override
  String get noAdviceTapPencil => 'No advice yet — tap the pencil to add';

  @override
  String get adviceHint => 'General guidance — one per line';

  @override
  String get instructionsTitle => 'Instructions';

  @override
  String get noInstructionsTapPencil =>
      'No instructions yet — tap the pencil to add';

  @override
  String get instructionsHint => 'Clinical directives — one per line';

  @override
  String get noFollowUpSet => 'No follow-up set';

  @override
  String get daysSuffix => 'days';

  @override
  String get prescribedMedicines => 'Prescribed Medicines';

  @override
  String get noMedicationsYet => 'No medications recorded yet.';

  @override
  String get addMedicine => 'Add Medicine';

  @override
  String get medicineLabel => 'Medicine';

  @override
  String get removeMedicine => 'Remove medicine';

  @override
  String get dosageLabel => 'Dosage';

  @override
  String get durationLabel => 'Duration';

  @override
  String get frequencyLabel => 'Frequency';

  @override
  String get timingLabel => 'Timing';

  @override
  String get timingBeforeFood => 'Before food';

  @override
  String get timingAfterFood => 'After food';

  @override
  String get timingWithFood => 'With food';

  @override
  String get timingEmptyStomach => 'Empty stomach';

  @override
  String get timingBeforeBed => 'Before bed';

  @override
  String get timingAsDirected => 'As directed';

  @override
  String get aiDisclaimer =>
      'AI extracts only what the doctor said. Review the summary and medicines before signing.';

  @override
  String get generatePdf => 'Generate Prescription PDF';

  @override
  String get signAndGeneratePdf => 'Sign & Generate PDF';

  @override
  String get icdCodeTitle => 'ICD-10 Code';

  @override
  String get icdVerifyWarning =>
      'AI suggestion - please verify this code before relying on it.';

  @override
  String get icdCodeField => 'Code (e.g. B34.9)';

  @override
  String get descriptionField => 'Description';

  @override
  String get icdFooterNote =>
      'This code was suggested by AI based on the diagnosis text. Please verify accuracy before clinical or billing use.';

  @override
  String get suggestedDifferentials => 'Suggested Differentials';

  @override
  String get aiSuggestionVerify => 'AI Suggestion — Verify';

  @override
  String get differentialsBasedOn =>
      'Based on reported symptoms. Doctor must verify.';

  @override
  String get accept => 'Accept';

  @override
  String get prescriptionReady => 'Prescription Ready';

  @override
  String get reviewAndShare => 'Review and share with patient';

  @override
  String get generatingPdfLong => 'Generating prescription PDF…';

  @override
  String get couldNotGeneratePdf => 'Could not generate PDF';
}

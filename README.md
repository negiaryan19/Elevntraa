# Rxvarta

Rxvarta is an AI-powered prescription dictation app for Indian doctors. A doctor records a consultation, the audio gets transcribed (supporting Indian languages), and the app generates a structured prescription that can be reviewed, signed, exported as PDF, and shared via WhatsApp.

---

## What you need before starting

- Flutter SDK 3.44 or newer (includes Dart 3.12+)
- Git
- Android: Android Studio, Java 17 JDK, Android SDK
- iOS (Mac only): Xcode and CocoaPods
- A Supabase account and project
- API keys: Sarvam AI and Google Gemini

Android toolchain versions this project uses:

- Android Gradle Plugin 9.0.1
- Kotlin 2.3.20
- Gradle 9.1.0
- Java 17

---

## Step 1: Install Git

**macOS**
Run `git --version` in Terminal. If missing, macOS will prompt you to install Command Line Tools. Or use Homebrew: `brew install git`

**Linux (Ubuntu/Debian)**
```bash
sudo apt update && sudo apt install git
```

**Windows**
Download and install from https://git-scm.com/download/win

---

## Step 2: Install Flutter

1. Go to https://docs.flutter.dev/get-started/install and follow the guide for your OS. Use the stable channel.
2. Add the Flutter `bin` folder to your PATH.
3. Check your version:
   ```bash
   flutter --version
   ```
4. If older than 3.44, run:
   ```bash
   flutter upgrade
   ```

---

## Step 3: Install the Android toolchain

Skip this if you only need iOS.

### Java 17

Check what you have:
```bash
java -version
```

**macOS**: `brew install openjdk@17` or install through Android Studio.

**Linux**:
```bash
sudo apt update && sudo apt install openjdk-17-jdk
```

**Windows**: Download Temurin 17 from https://adoptium.net

### Android SDK

1. Download Android Studio from https://developer.android.com/studio
2. Open it once and complete the first-run setup. It downloads the SDK for you.
3. In SDK Manager, make sure you have an Android SDK Platform and Android SDK Command-line Tools installed.

### Accept Android licenses

```bash
flutter doctor --android-licenses
```

Type `y` for each license. If you get a permission error, run with `sudo` on Mac/Linux, or open the terminal as Administrator on Windows.

### Confirm setup

```bash
flutter doctor
```

Look for a checkmark next to "Android toolchain".

---

## Step 4: Install the iOS toolchain (Mac only)

Skip if building for Android only.

1. Install Xcode from the Mac App Store.
2. Install command line tools:
   ```bash
   sudo xcode-select --install
   ```
3. Accept the Xcode license:
   ```bash
   sudo xcodebuild -license accept
   ```
4. Install CocoaPods:
   ```bash
   sudo gem install cocoapods
   ```

---

## Step 5: Set up Supabase

### Create a Supabase account and project

1. Go to https://supabase.com and sign up for a free account.
2. After logging in, click "New Project".
3. Fill in your project name, a database password (save this), and choose a region close to you.
4. Wait for the project to finish setting up (about 1-2 minutes).

### Get your project credentials

1. In your Supabase project, go to Project Settings > API.
2. Copy your "Project URL" and "anon/public" (publishable) key. You will need these in `config/app_config.json` (Step 7).

### Install the Supabase CLI

**macOS**:
```bash
brew install supabase/tap/supabase
```

**Linux**:
```bash
brew install supabase/tap/supabase
```
(Install Homebrew first from https://brew.sh if you do not have it.)

**Windows**: Download the latest release from https://github.com/supabase/cli/releases and add it to your PATH.

### Link your project

From the project root, log in and link to your Supabase project:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Your project ref is the string in your Supabase dashboard URL: `https://supabase.com/dashboard/project/YOUR_PROJECT_REF`

### Push the database schema

Apply the migrations to your Supabase project:

```bash
supabase db push
```

### Deploy Edge Functions

The backend processing runs on Supabase Edge Functions. Deploy them with:

```bash
supabase functions deploy process-consultation
supabase functions deploy check-job-status
```

### Set secrets for Edge Functions

The Edge Functions need your API keys. Set them as secrets in Supabase:

```bash
supabase secrets set SARVAM_API_KEY=your_sarvam_key
supabase secrets set GEMINI_API_KEY=your_gemini_key
```

---

## Step 6: Clone and set up the project

```bash
git clone <repository-url>
cd project
```

Install Flutter dependencies:

```bash
flutter pub get
```

---

## Step 7: Configure the app build

The app is configured at build time with `--dart-define-from-file`. Only values that are safe to ship inside the binary go in here: the Supabase project URL and its publishable (anon) key. Provider secrets (Sarvam, Gemini) live in Supabase Edge Function secrets and never reach the app.

Create the config file from the example:

**macOS/Linux**:
```bash
cp config/app_config.example.json config/app_config.json
```

**Windows**:
```bash
copy config\app_config.example.json config\app_config.json
```

Open `config/app_config.json` and fill in your values:

```json
{
  "SUPABASE_URL": "https://YOUR-PROJECT.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_...",
  "SENTRY_DSN": "",
  "SUPPORT_EMAIL": "",
  "SUPPORT_WHATSAPP": "",
  "PRIVACY_URL": "",
  "TERMS_URL": ""
}
```

Where to get the values:

- Supabase URL and publishable key: your Supabase project under Settings > API.
- Sarvam / Gemini keys are set as Edge Function secrets (Step 5), not here.

Do not commit `config/app_config.json` (it is gitignored). Only `config/app_config.example.json` goes into version control.

Each doctor signs in with their own e-mail and password (an 8-digit code sent by e-mail confirms the address). There is no shared or automatic login.

If you run the app without this file it still starts, but the login screen shows "App not configured" and sign-in is disabled.

---

## Step 8: Run the app

List available devices:

```bash
flutter devices
```

Start an Android emulator:

```bash
flutter emulators
flutter emulators --launch <emulator-id>
```

Start the iOS Simulator (Mac only):

```bash
open -a Simulator
```

Run the app (always pass the config file, otherwise sign-in is disabled):

```bash
flutter run --dart-define-from-file=config/app_config.json
```

On a specific device, e.g. the macOS desktop build:

```bash
flutter run -d macos --dart-define-from-file=config/app_config.json
```

If multiple devices are connected:

```bash
flutter run -d <device-id> --dart-define-from-file=config/app_config.json
```

---

## Step 9: Generate code (only when needed)

The generated files are already in the repo. Only run this if you change a model or database schema:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Build a release version

Release builds take the same `--dart-define-from-file=config/app_config.json` flag as `flutter run`.

**Android APK**:
```bash
flutter build apk --release --dart-define-from-file=config/app_config.json
```

**Android App Bundle (Play Store)**:
```bash
flutter build appbundle --release --dart-define-from-file=config/app_config.json
```

**iOS (Mac + Xcode required)**:
```bash
flutter build ios --release --dart-define-from-file=config/app_config.json
```

---

## Run tests

Unit and widget tests:

```bash
flutter test
```

End-to-end test (needs a booted device, microphone permission, and API keys set):

```bash
flutter test integration_test/e2e_test.dart -d <device-id>
```

---

## Project layout

- `lib/main.dart` - app entry point
- `lib/app` - app shell, theme, routing
- `lib/core` - shared utilities, auth, build-time config
- `lib/data` - local Drift/SQLite database and repositories
- `lib/domain` - data models
- `lib/features` - screens grouped by feature (home, consultation, prescription, patient, settings, onboarding)
- `supabase/functions` - backend Edge Functions (process-consultation, check-job-status)
- `supabase/migrations` - database schema migrations
- `android`, `ios` - native platform projects
- `config/app_config.example.json` - template for the build-time app config

---

## Troubleshooting

- "Android licenses not accepted": run `flutter doctor --android-licenses`. If permission error, see Step 3.
- "Gradle version" errors: confirm you are on Java 17 and check the pinned versions at the top.
- Missing generated files: run the build_runner command in Step 9.
- Login screen says "App not configured": you ran without `--dart-define-from-file=config/app_config.json`, or the file has empty values. Fix the file and rebuild (a hot restart is not enough — dart-defines are compiled in).
- Supabase connection issues: confirm the URL and publishable key in `config/app_config.json` match your Supabase project settings.
- Edge Functions not responding: check that you deployed them and set the secrets (Step 5).
- CocoaPods errors (iOS): from the `ios` folder run `pod install`. If it still fails, run `pod repo update` first.
- General health check: `flutter doctor -v`

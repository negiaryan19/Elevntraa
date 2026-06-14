# MediScribe

MediScribe is an AI assisted prescription dictation app for Indian doctors. The doctor records a consultation, the audio is transcribed (with support for many Indian languages), and the conversation is turned into a structured prescription that can be reviewed, signed, exported as a PDF, and shared with the patient on WhatsApp.

This README is a complete, step by step setup guide. If you have never built a Flutter app before, you can follow it from top to bottom and end up with the app running on an emulator or a real phone.

## What you are building

- Platforms: Android and iOS (there is no web or desktop build in this project).
- Framework: Flutter (Dart).
- Local database: Drift (SQLite) for patients and visits.
- Speech to text: Sarvam AI, with a Google Gemini audio fallback.
- Clinical extraction: Google Gemini turns the transcript into a structured prescription.

## Requirements at a glance

You need these tools installed before you start. Exact install steps are in the sections further down.

- Flutter SDK 3.44 or newer, which bundles Dart 3.12 or newer.
- Git.
- For Android: Android Studio (or the Android command line tools), a Java 17 JDK, and an Android SDK.
- For iOS (Mac only): Xcode and CocoaPods.
- Two API keys: one from Sarvam AI and one from Google Gemini. See the "Add your API keys" section.

The project is currently pinned to these toolchain versions on the Android side, so if you hit version errors this is the reference:

- Android Gradle Plugin 9.0.1
- Kotlin 2.3.20
- Gradle 9.1.0
- Java 17

## Step 1: Install Git

Git is needed to clone the project and is also used internally by Flutter.

- macOS: run `git --version` in the Terminal. If it is missing, macOS will offer to install the Command Line Tools, which include Git. You can also install it with Homebrew using `brew install git`.
- Linux (Debian or Ubuntu): `sudo apt update && sudo apt install git`.
- Windows: download and install Git from https://git-scm.com/download/win.

## Step 2: Install Flutter

Flutter gives you the `flutter` and `dart` commands used everywhere below.

1. Follow the official install guide for your operating system at https://docs.flutter.dev/get-started/install. Use the stable channel.
2. Add the Flutter `bin` folder to your `PATH` so the `flutter` command works in any terminal.
3. Confirm the version. This project expects Flutter 3.44 or newer:

   ```bash
   flutter --version
   ```

If you already have Flutter but it is older, upgrade it:

```bash
flutter upgrade
```

## Step 3: Install the Android toolchain

Skip this section if you only want to build for iOS. You need this to run on an Android emulator or an Android phone.

### 3a. Install a Java 17 JDK

The Android build uses Java 17. Check what you have:

```bash
java -version
```

If you do not have Java 17:

- macOS: `brew install openjdk@17` and then follow the symlink instructions Homebrew prints, or install it through Android Studio which bundles a compatible JDK.
- Linux (Debian or Ubuntu): `sudo apt update && sudo apt install openjdk-17-jdk`.
- Windows: install the Temurin 17 JDK from https://adoptium.net.

### 3b. Install the Android SDK

The easiest path is Android Studio, which installs the SDK, the platform tools, and an emulator for you.

1. Download Android Studio from https://developer.android.com/studio and install it.
2. Open Android Studio once and let it finish the first run setup, which downloads the Android SDK.
3. In Android Studio, open the SDK Manager and make sure you have a recent Android SDK Platform and the Android SDK Command line Tools installed.

If you prefer not to install the full Android Studio, you can install only the command line tools from the same download page, unzip them, and place them under your Android SDK folder in a directory named `cmdline-tools/latest`.

### 3c. Accept the Android licenses

The Android SDK will not build until you accept its licenses. This is the step people often forget. On Linux you may need elevated permissions if your SDK lives in a system wide folder, which is where the `sudo` part comes in.

Normal case (SDK is in your own home folder, which is the default with Android Studio):

```bash
flutter doctor --android-licenses
```

Type `y` to accept each license.

If the SDK was installed into a protected system location and the command above fails with a permission error, run it with elevated rights so it can write the license files. On macOS or Linux:

```bash
sudo flutter doctor --android-licenses
```

On Windows, open the terminal as Administrator and run `flutter doctor --android-licenses` without `sudo`, because `sudo` is not a Windows command.

Tip: the cleaner long term fix for permission errors is to make your user the owner of the Android SDK folder so you do not need elevated rights at all. For example on Linux, if your SDK is at `/opt/android-sdk`, you can run `sudo chown -R $USER:$USER /opt/android-sdk` once, after which the plain `flutter doctor --android-licenses` will work.

### 3d. Confirm the Android setup

```bash
flutter doctor
```

Look for a check mark next to "Android toolchain". Resolve anything it flags before moving on.

## Step 4: Install the iOS toolchain (Mac only)

Skip this section if you are building for Android only.

1. Install Xcode from the Mac App Store.
2. Install the Xcode command line tools:

   ```bash
   sudo xcode-select --install
   ```

3. Accept the Xcode license:

   ```bash
   sudo xcodebuild -license accept
   ```

4. Install CocoaPods, which manages the iOS native dependencies:

   ```bash
   sudo gem install cocoapods
   ```

## Step 5: Get the project

Clone the repository and move into it:

```bash
git clone <your-repository-url>
cd project
```

Replace `<your-repository-url>` with the actual URL of this repository.

## Step 6: Install the Dart and Flutter dependencies

From the project root, download all the packages listed in `pubspec.yaml`:

```bash
flutter pub get
```

## Step 7: Add your API keys

The app reads two API keys from a file named `.env` in the project root. This file is intentionally not committed to Git, so you create your own from the provided example.

1. Copy the example file:

   ```bash
   cp .env.example .env
   ```

2. Open `.env` and fill in your real keys:

   ```
   SARVAM_API_KEY=your_real_sarvam_key
   GEMINI_API_KEY=your_real_gemini_key
   ```

Where to get the keys:

- Sarvam API key: sign up at https://www.sarvam.ai and create an API key from your dashboard. This powers speech to text for Indian languages.
- Gemini API key: create a key in Google AI Studio at https://aistudio.google.com/app/apikey. This powers the prescription extraction and the audio fallback.

Notes:

- A missing `.env` will not crash the app on first launch, but transcription and extraction will not work until both keys are present.
- The `.env` file is already bundled as an app asset in `pubspec.yaml`, so once you fill it in, no extra wiring is needed.
- Never commit your real `.env`. Only `.env.example` belongs in version control.

## Step 8: Generate the code (only if needed)

This project uses code generation for its models and database (Freezed, json_serializable, and Drift). The generated files are already checked into the repository, so a normal first build does not require this step.

You only need to run this if you change a model or the database schema, or if the build complains about missing generated files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Step 9: Pick a device

List everything Flutter can run on right now:

```bash
flutter devices
```

To start an Android emulator, you can list and launch one of your created emulators:

```bash
flutter emulators
flutter emulators --launch <emulator-id>
```

On a Mac you can also start the iOS Simulator:

```bash
open -a Simulator
```

To use a real phone, enable Developer Options and USB debugging on Android, or trust the computer on iOS, then plug it in.

## Step 10: Run the app

With a device or emulator ready, start the app in debug mode:

```bash
flutter run
```

If more than one device is connected, target a specific one:

```bash
flutter run -d <device-id>
```

The first run takes longer because it compiles the native code. Later runs are faster, and you can use hot reload while developing.

## Permissions you will be asked for

The app requests these at runtime, and it handles a denial without crashing:

- Microphone: required to record the consultation.
- Camera and photo library: optional, used only when you attach a previous report.

If you deny the microphone permission permanently, the app shows a prompt that takes you to the system settings so you can enable it.

## Building a release version

Android APK (good for sharing a test build):

```bash
flutter build apk --release
```

Android App Bundle (for the Play Store):

```bash
flutter build appbundle --release
```

iOS (Mac with Xcode required):

```bash
flutter build ios --release
```

For a real Play Store or App Store submission you will also need to set up signing, which is beyond the scope of this setup guide. See the official Flutter deployment docs for that.

## Running the tests

Unit and widget tests:

```bash
flutter test
```

There is also an end to end integration test under `integration_test`. It drives the real recording and AI flow, so it needs a booted device, a granted microphone permission, and your API keys in place:

```bash
flutter test integration_test/e2e_test.dart -d <device-id>
```

## Project layout

A quick map so you know where things live:

- `lib/main.dart`: app entry point, loads the `.env` file and starts the app.
- `lib/app`: app shell, theme, and routing.
- `lib/core`: shared utilities, theme, widgets, networking, and the `.env` reader.
- `lib/data`: the local Drift database and repositories.
- `lib/domain`: the data models.
- `lib/features`: the screens, grouped by feature (home, consultation, prescription, patient, settings, onboarding).
- `android` and `ios`: the native platform projects.
- `.env.example`: the template for your API keys.

## Troubleshooting

- "Android licenses not accepted": run `flutter doctor --android-licenses` and accept them. If you get a permission error, see Step 3c.
- "Gradle or Android Gradle Plugin version" errors: confirm you are on Java 17, and note the pinned versions listed under "Requirements at a glance".
- Build cannot find generated files: run the command in Step 8.
- Transcription or extraction does nothing: confirm your `.env` exists in the project root and both keys are filled in, then stop and rerun the app so the new values load.
- CocoaPods errors on iOS: from the `ios` folder run `pod install`, and if it still fails run `pod repo update` first.
- General health check: `flutter doctor -v` prints a detailed report of what is missing.

## License

Add your license information here.

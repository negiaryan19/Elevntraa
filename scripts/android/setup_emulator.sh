#!/usr/bin/env bash
# Sets up the Android SDK and a Pixel 8a emulator for running Rxvarta.
#
# Android Studio ships the IDE but not the SDK; this installs the SDK packages
# headlessly with sdkmanager (using the JDK bundled inside Android Studio),
# points Flutter at them, and creates a Pixel 8a AVD.
#
# Usage:  bash scripts/android/setup_emulator.sh
# Then:   flutter run -d <emulator-id> --dart-define-from-file=config/app_config.json
set -euo pipefail

STUDIO="/Applications/Android Studio.app"
SDK="$HOME/Library/Android/sdk"
API=35
IMAGE="system-images;android-${API};google_apis;arm64-v8a"
AVD_NAME="pixel_8a"

if [ ! -d "$STUDIO" ]; then
  echo "Android Studio is not installed at $STUDIO" >&2
  exit 1
fi

# Android Studio bundles a JDK; the SDK tools need it and this Mac has no
# system Java.
export JAVA_HOME="$STUDIO/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"

mkdir -p "$SDK"

# Bootstrap sdkmanager from the command-line tools if they are not there yet.
CMDLINE_BIN="$SDK/cmdline-tools/latest/bin"
if [ ! -x "$CMDLINE_BIN/sdkmanager" ]; then
  echo "==> Fetching Android command-line tools"
  TMP="$(mktemp -d)"
  curl -fsSL -o "$TMP/cmdline-tools.zip" \
    https://dl.google.com/android/repository/commandlinetools-mac-13114758_latest.zip
  unzip -q "$TMP/cmdline-tools.zip" -d "$TMP"
  mkdir -p "$SDK/cmdline-tools"
  rm -rf "$SDK/cmdline-tools/latest"
  mv "$TMP/cmdline-tools" "$SDK/cmdline-tools/latest"
  rm -rf "$TMP"
fi

export PATH="$CMDLINE_BIN:$SDK/platform-tools:$SDK/emulator:$PATH"

echo "==> Accepting licences"
yes | sdkmanager --licenses > /dev/null 2>&1 || true

echo "==> Installing SDK packages (this downloads a few GB)"
sdkmanager --install \
  "platform-tools" \
  "emulator" \
  "platforms;android-${API}" \
  "build-tools;${API}.0.0" \
  "$IMAGE"

echo "==> Pointing Flutter at the SDK"
flutter config --android-sdk "$SDK" > /dev/null

echo "==> Creating the $AVD_NAME device"
# Prefer the real Pixel 8a profile; fall back to Pixel 8 on older tool
# versions that do not ship it.
DEVICE=pixel_8a
if ! avdmanager list device 2>/dev/null | grep -q 'id: .*pixel_8a'; then
  DEVICE=pixel_8
  echo "    (pixel_8a profile unavailable, using $DEVICE)"
fi
echo no | avdmanager create avd \
  --name "$AVD_NAME" \
  --package "$IMAGE" \
  --device "$DEVICE" \
  --force

# A phone-sized heap and a real window make the app usable; without an
# explicit skin the emulator opens at a default resolution.
CONFIG="$HOME/.android/avd/${AVD_NAME}.avd/config.ini"
if [ -f "$CONFIG" ]; then
  {
    echo "hw.ramSize=2048"
    echo "vm.heapSize=256"
    echo "hw.keyboard=yes"
  } >> "$CONFIG"
fi

echo
echo "Done. Start it from Terminal.app (so macOS can grant the microphone):"
echo "  \"$SDK/emulator/emulator\" -avd $AVD_NAME -allow-host-audio &"
echo "  flutter devices"
echo
echo "Without -allow-host-audio and macOS microphone permission the emulator"
echo "records a 220 Hz test tone, and consultations come back empty."

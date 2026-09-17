# Android release signing

Release builds (`flutter build apk --release`, `flutter build appbundle`) are
signed with the upload key. The key and its passwords never go in the repo.

## One-time setup

1. Create the upload keystore somewhere outside the repo and back it up
   (losing it means you can no longer update the app on Play):

   ```sh
   mkdir -p ~/rxvarta-keys
   keytool -genkeypair -v -storetype PKCS12 \
     -keystore ~/rxvarta-keys/upload-keystore.p12 \
     -alias upload -keyalg RSA -keysize 4096 -validity 10000
   ```

2. Create `android/key.properties` (git-ignored):

   ```properties
   storeFile=/absolute/path/to/upload-keystore.p12
   storePassword=...
   keyAlias=upload
   keyPassword=...
   storeType=PKCS12
   ```

## Building

```sh
flutter build appbundle --release --dart-define-from-file=config/app_config.json
```

Without `android/key.properties` a release build stops with an error rather
than producing an APK signed with the debug key. To try a release build on
your own phone without the upload key:

```sh
RXVARTA_ALLOW_DEBUG_SIGNING=true flutter run --release \
  --dart-define-from-file=config/app_config.json
```

Never distribute a build made that way.

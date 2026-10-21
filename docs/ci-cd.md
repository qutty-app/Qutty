# CI/CD, build variants and signing

Everything lives in `.github/workflows/build.yml`. It runs on pushes to
`main`, on pull requests, and on demand (`workflow_dispatch`).

## What runs

```
checks (analyze + test) ──► build matrix ──► NotStoreBuild, iOS, macOS, Linux, Windows, Web
                     └──► signing probe ──► store (StoreBuild, skipped until secrets exist)
```

| Job | Runner | Output |
| --- | --- | --- |
| `checks` | ubuntu | `flutter analyze` + `flutter test`, gates everything else |
| `store` | ubuntu | `qutty-StoreBuild`: `app-release.aab` + `app-release.apk`, **release-signed** |
| `build` (NotStoreBuild) | ubuntu | `qutty-NotStoreBuild`: `app-release.apk`, signed (see below) |
| `build` (iOS) | macOS | `Runner.app`, **unsigned** |
| `build` (macOS) | macOS | `.app`, **unsigned** |
| `build` (Linux/Windows/Web) | native | release bundle (no signing on these platforms) |

The Flutter version is pinned in the workflow (`FLUTTER_VERSION` at the top of
`build.yml`). Bump it deliberately: `flutter upgrade`, run the tests locally,
then update the pin.

## Caching

- **Flutter SDK + pub cache**: `subosito/flutter-action` with `cache: true`.
- **Gradle**: `actions/setup-java` `cache: gradle` on both Android jobs.
- **CocoaPods**: `~/Library/Caches/CocoaPods` and `ios/Pods`, keyed on
  `ios/Podfile.lock`, on the Apple jobs.

## Linux build dependencies

The Linux job installs the native libraries the plugins need:

```bash
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libpulse-dev
```

- `libgtk-3-dev` — required by the runner and most plugins.
- `libgstreamer1.0-dev` + `libgstreamer-plugins-base1.0-dev` — required by
  `audioplayers`. Missing them fails the build with
  `The following required packages were not found: gstreamer-1.0`.
- `libpulse-dev` — optional, enables `flutter_webrtc` system audio capture.

## Android build variants

Both variants are **release-mode** and both are **signed**; they differ in
what they are for and which key signs them.

### StoreBuild — for the Play Store

- Builds `app-release.aab` (what Play Store takes) and `app-release.apk`.
- Always signed with the **release keystore**. The job sets
  `REQUIRE_RELEASE_SIGNING=true`, so a missing keystore fails the build with a
  clear error instead of quietly producing a debug-signed bundle.
- Skipped (not failed) while the keystore secrets are not configured; the run
  still produces every other artifact.
- Built with `--dart-define=STORE_BUILD=true`.

### NotStoreBuild — for sideloading and testing

- Builds one `app-release.apk`.
- Signed with the **release keystore when it is configured**, and with the
  **debug key otherwise**, so it is always installable.
- Built with `--dart-define=STORE_BUILD=false`.

App code can branch on the variant:

```dart
const bool storeBuild = bool.fromEnvironment('STORE_BUILD');
```

Note: while the keystore is not set up, NotStoreBuild is debug-signed. Once the
keystore exists, do not mix old debug-signed installs with new release-signed
ones on a device — uninstall first, the signatures do not match.

## One-time setup: the Android release keystore

You only need to do this once, and it is the single most important backup in
the project: **if this keystore is lost, you can never update the app on the
Play Store again** (users would have to uninstall and reinstall). Keep copies
somewhere safe (password manager, private backup).

### 1. Generate the keystore (any machine with a JDK)

```bash
mkdir -p ~/keys
keytool -genkey -v -keystore ~/keys/qutty-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias qutty
```

You already have one? Skip to step 2 and just use it.

### 2. Base64-encode it

```bash
# macOS
base64 -i ~/keys/qutty-release.jks | pbcopy

# Linux
base64 -w0 ~/keys/qutty-release.jks | pbcopy
```

### 3. Add four repository secrets

GitHub → your repo → **Settings → Secrets and variables → Actions → New
repository secret**:

| Secret | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | the base64 text from step 2 |
| `ANDROID_KEYSTORE_PASSWORD` | the keystore password you chose |
| `ANDROID_KEY_ALIAS` | the alias, e.g. `qutty` |
| `ANDROID_KEY_PASSWORD` | the key password (same as the keystore password if you set it so) |

The next run of CI builds `qutty-StoreBuild` automatically; until then that
job is skipped with a notice in the run summary.

## Local release signing (optional)

To build a store-signed APK on your own machine, create
`android/key.properties` (already git-ignored, never commit it):

```properties
storeFile=/absolute/path/to/qutty-release.jks
storePassword=your-keystore-password
keyAlias=qutty
keyPassword=your-key-password
```

`flutter build apk --release` / `flutter build appbundle --release` then use
the release key. Without the file, release builds fall back to the debug key.

## Apple builds: unsigned for now

There is no Apple Developer account yet, so the iOS and macOS jobs build with
`--no-codesign`. Those artifacts prove the build compiles — they **cannot be
installed on a device** (iOS refuses unsigned apps; macOS Gatekeeper blocks
unsigned apps).

Once you have an Apple Developer account ($99/year), the upgrade path:

1. In Xcode on your Mac: sign in with your Apple ID, then create an
   *Apple Distribution* certificate (Xcode → Settings → Accounts → Manage
   Certificates) and an App ID + provisioning profile for `app.qutty.client`
   (developer.apple.com → Certificates, Identifiers & Profiles).
2. Export the certificate as a `.p12` (`Keychain Access` → export, set a
   password) and base64 it the same way as the keystore; download the
   `.mobileprovision` profile and base64 that too.
3. Add secrets, e.g. `APPLE_CERTIFICATE_P12_BASE64`,
   `APPLE_CERTIFICATE_PASSWORD`, `APPLE_PROVISION_PROFILE_BASE64`,
   `APPLE_SIGNING_IDENTITY`.
4. In `build.yml`: add a step that writes the certificate into the runner's
   keychain and installs the profile (or add `fastlane sigh`/`match`), drop
   `--no-codesign` from the iOS build, and pass
   `FLUTTER_IOS_SIGNING_IDENTITY`/`DEVELOPMENT_TEAM`.
5. For App Store submission you will also want notarization for macOS and
   `fastlane deliver`/Xcode Cloud for uploading — none of that exists yet.

Apple signing only runs on the Apple jobs; it never affects Android.

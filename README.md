# Qutty Flutter Client

Cross-platform Flutter client for the Qutty messaging application.

## Features

- Real-time messaging via WebSocket
- Push notifications (FCM + APNs)
- Voice chat via LiveKit
- Multi-account support
- Deep linking for join links
- Theming (light/dark/system, accent colors, custom fonts)
- Localization (6 languages)
- Adaptive layout (two-pane on wide screens)

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run tests
flutter test

# Run on a device
flutter run

# Build for production
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
flutter build macos        # macOS
flutter build linux        # Linux
flutter build windows      # Windows
```

## Architecture

- **Singleton AppManager**: Central state management via ChangeNotifier
- **Service layer**: ApiService for HTTP, WebSocketService for real-time
- **GoRouter**: Declarative routing with redirect-based auth guards
- **Localization**: ARB-based l10n with generated AppLocalizations class

## Platform Setup

### Android

Configure Firebase in `android/app/google-services.json` and update `android/app/build.gradle.kts` with your package name.

### iOS

Configure Firebase in `ios/Runner/GoogleService-Info.plist` and enable push notifications in Xcode.

### Web

Configure Firebase in `web/firebase-config.json` and update `web/index.html`.

## CI/CD

Every push and pull request builds test-checked artifacts in GitHub Actions:
a **StoreBuild** (Play-Store-signed AAB + APK, once the signing secrets are
configured) and a **NotStoreBuild** (sideload APK), plus unsigned iOS/macOS
builds for compile verification. Setup steps, secrets and the keystore
instructions live in [docs/ci-cd.md](docs/ci-cd.md).

## Code Generation

```bash
# Generate localizations
flutter gen-l10n

# Or use just
just l10n
```

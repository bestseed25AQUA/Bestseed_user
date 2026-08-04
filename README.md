# seedsuser

A new Flutter project.

## API keys (one-time setup after cloning)

No API key is stored in this repository. Copy the two templates once and fill
in the real values — same idea as the existing `android/key.properties`:

```bash
cp lib/app/utils/secrets.example.dart lib/app/utils/secrets.dart        # Dart + Android
cp ios/Flutter/Secrets.example.xcconfig ios/Flutter/Secrets.xcconfig    # iOS
```

That's the whole setup. **No build flags are needed** — normal commands work:

```bash
flutter run
flutter build appbundle --release
flutter build ipa --release
```

Where each key comes from:

| Consumer | Source |
|---|---|
| Dart (`AppKeys`, `NetworkConfig`, Places SDK) | `lib/app/utils/secrets.dart` |
| `AndroidManifest.xml` | the same `secrets.dart`, read by `android/app/build.gradle.kts` |
| iOS `GMSServices` | `ios/Flutter/Secrets.xcconfig` → `Info.plist` → `AppDelegate.swift` |

If `secrets.dart` is missing, the build fails with "Target of URI doesn't
exist" — deliberate, so a build can never ship with an empty key. CI must
write the file before building (e.g. from a repository secret), or set a
`GOOGLE_MAPS_API_KEY` environment variable, which Gradle prefers when present.

> Keeping keys out of git stops secret scanners and casual copying. It does
> **not** make them secret at runtime: any key compiled into the app can be
> extracted from the APK/IPA. Real protection comes from Google Cloud key
> restrictions (package name + SHA-1 / bundle id, and per-API limits) plus
> routing unrestricted web-service calls through the backend.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

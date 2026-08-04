// TEMPLATE — copy this file to `secrets.dart` (same folder) and put the real
// keys in it. `secrets.dart` is gitignored and never committed.
//
//     cp lib/app/utils/secrets.example.dart lib/app/utils/secrets.dart
//
// Nothing else is needed: no build flags, no environment variables. Android's
// manifest key is read out of `secrets.dart` by android/app/build.gradle.kts,
// and iOS reads ios/Flutter/Secrets.xcconfig.
//
// If `secrets.dart` is missing the build fails with "Target of URI doesn't
// exist" — that is deliberate, so a key is never silently empty.
class Secrets {
  Secrets._();

  /// Google Maps / Places / Directions / Geocoding key (Android + web APIs).
  static const String googleMaps = 'AIza-your-key-here';
}

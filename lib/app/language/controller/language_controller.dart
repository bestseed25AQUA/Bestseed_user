import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:ui';

class LanguageController extends GetxController {
  final _box = GetStorage();
  final _key = 'locale';

  final Map<String, Locale> langMap = {
    'English': const Locale('en', 'US'),
    'తెలుగు': const Locale('te', 'IN'),
    'हिन्दी': const Locale('hi', 'IN'),
    'தமிழ்': const Locale('ta', 'IN'),
    'ಕನ್ನಡ': const Locale('kn', 'IN'),
    'മലയാളം': const Locale('ml', 'IN'),
    'मराठी': const Locale('mr', 'IN'),
    'ગુજરાતી': const Locale('gu', 'IN'),
    'ਪੰਜਾਬੀ': const Locale('pa', 'IN'),
    'বাংলা': const Locale('bn', 'IN'),
    'ଓଡିଆ': const Locale('or', 'IN'),
    'اردو': const Locale('ur', 'IN'),
  };

  var currentLocale = const Locale('en', 'US').obs;
  var currentLanguageName = 'English'.obs;

  List<String> get availableLanguages => langMap.keys.toList();

  @override
  void onInit() {
    super.onInit();
    loadLocale();
  }

  void setLanguage(String languageName) {
    if (langMap.containsKey(languageName)) {
      currentLocale.value = langMap[languageName]!;
      currentLanguageName.value = languageName;
      Get.updateLocale(currentLocale.value);

      // Save to storage
      _box.write(_key, {
        'languageCode': currentLocale.value.languageCode,
        'countryCode': currentLocale.value.countryCode,
        'languageName': languageName
      });
    }
  }

  void loadLocale() {
    final savedData = _box.read(_key);
    if (savedData != null) {
      currentLocale.value = Locale(
        savedData['languageCode'] ?? 'en',
        savedData['countryCode'] ?? 'US',
      );
      currentLanguageName.value = savedData['languageName'] ?? 'English';
      Get.updateLocale(currentLocale.value);
    }
  }

  // Get the current language display name
  String get currentLanguageDisplay => currentLanguageName.value;

  // Check if a language is currently selected
  bool isSelected(String languageName) =>
      currentLanguageName.value == languageName;
}

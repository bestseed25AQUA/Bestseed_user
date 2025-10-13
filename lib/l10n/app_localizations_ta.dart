// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'என் பயன்பாடு';

  @override
  String get welcome => 'வரவேற்கிறோம்';

  @override
  String hello(Object name) {
    return 'வணக்கம், $name!';
  }

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get language => 'மொழி';

  @override
  String get selectLanguage => 'மொழியைத் தேர்வு செய்யவும்';

  @override
  String get save => 'சேமிக்கவும்';

  @override
  String get cancel => 'ரத்து செய்';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get search => 'தேடு';

  @override
  String get notifications => 'அறிவிப்புகள்';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get login => 'உள் நுழையவும்';

  @override
  String get signup => 'பதிவு செய்யவும்';

  @override
  String get email => 'மின்னஞ்சல்';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get confirmPassword => 'கடவுச்சொல்லை உறுதிப்படுத்தவும்';

  @override
  String get forgotPassword => 'கடவுச்சொல் மறந்துவிட்டீர்களா?';

  @override
  String get submit => 'சமர்ப்பிக்கவும்';

  @override
  String get error => 'பிழை';

  @override
  String get success => 'வெற்றி';

  @override
  String get loading => 'ஏற்றுகிறது...';

  @override
  String get noInternet => 'இணைய இணைப்பு இல்லை';

  @override
  String get tryAgain => 'மீண்டும் முயற்சி செய்க';

  @override
  String get home => 'முகப்பு';

  @override
  String get price => 'விலை';

  @override
  String get broadstock => 'பிராட்ஸ்டாக்';

  @override
  String get news_ads => 'செய்திகள் & விளம்பரங்கள்';

  @override
  String get updates => 'புதுப்பிப்புகள்';

  @override
  String get send_request => 'கோரிக்கை அனுப்பவும்';
}

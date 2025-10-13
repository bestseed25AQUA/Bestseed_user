// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'मेरा ऐप';

  @override
  String get welcome => 'स्वागत है';

  @override
  String hello(Object name) {
    return 'नमस्ते, $name!';
  }

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get save => 'सेव करें';

  @override
  String get cancel => 'कैंसल';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get search => 'खोजें';

  @override
  String get notifications => 'नोटिफिकेशन';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get login => 'लॉगिन';

  @override
  String get signup => 'साइन अप';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड कन्फर्म करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get submit => 'सबमिट करें';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफलता';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get noInternet => 'इंटरनेट कनेक्शन नहीं है';

  @override
  String get tryAgain => 'फिर से कोशिश करें';

  @override
  String get home => 'హోమ్';

  @override
  String get price => 'ధర';

  @override
  String get broadstock => 'బ్రాడ్‌స్టాక్';

  @override
  String get news_ads => 'సమాచారం & ప్రకటనలు';

  @override
  String get updates => 'తాజాకరణలు';

  @override
  String get send_request => 'अनुरोध भेजें';
}

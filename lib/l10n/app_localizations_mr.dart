// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get appTitle => 'माझे अॅप';

  @override
  String get welcome => 'स्वागत आहे';

  @override
  String hello(Object name) {
    return 'नमस्कार, $name!';
  }

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा निवडा';

  @override
  String get save => 'जतन करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get search => 'शोधा';

  @override
  String get notifications => 'सूचना';

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
  String get confirmPassword => 'पासवर्ड पुष्टी करा';

  @override
  String get forgotPassword => 'पासवर्ड विसरलात?';

  @override
  String get submit => 'सादर करा';

  @override
  String get error => 'त्रुटी';

  @override
  String get success => 'यश';

  @override
  String get loading => 'लोड होत आहे...';

  @override
  String get noInternet => 'इंटरनेट कनेक्शन नाही';

  @override
  String get tryAgain => 'पुन्हा प्रयत्न करा';

  @override
  String get home => 'मुखपृष्ठ';

  @override
  String get price => 'किंमत';

  @override
  String get broadstock => 'ब्रॉडस्टॉक';

  @override
  String get news_ads => 'बातम्या & जाहिराती';

  @override
  String get updates => 'अपडेट्स';

  @override
  String get send_request => 'विनंती पाठवा';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'میری ایپ';

  @override
  String get welcome => 'خوش آمدید';

  @override
  String hello(Object name) {
    return 'ہیلو، $name!';
  }

  @override
  String get settings => 'ترتیبات';

  @override
  String get language => 'زبان';

  @override
  String get selectLanguage => 'زبان منتخب کریں';

  @override
  String get save => 'محفوظ کریں';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get profile => 'پروفائل';

  @override
  String get search => 'تلاش کریں';

  @override
  String get notifications => 'اطلاعات';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get login => 'لاگ ان';

  @override
  String get signup => 'سائن اپ';

  @override
  String get email => 'ای میل';

  @override
  String get password => 'پاس ورڈ';

  @override
  String get confirmPassword => 'پاس ورڈ کی تصدیق کریں';

  @override
  String get forgotPassword => 'پاس ورڈ بھول گئے؟';

  @override
  String get submit => 'جمع کریں';

  @override
  String get error => 'خرابی';

  @override
  String get success => 'کامیابی';

  @override
  String get loading => 'لوڈ ہو رہا ہے...';

  @override
  String get noInternet => 'انٹرنیٹ کنکشن نہیں ہے';

  @override
  String get tryAgain => 'دوبارہ کوشش کریں';

  @override
  String get home => 'ہوم';

  @override
  String get price => 'قیمت';

  @override
  String get broadstock => 'براڈ اسٹاک';

  @override
  String get news_ads => 'خبریں اور اشتہارات';

  @override
  String get updates => 'اپ ڈیٹس';

  @override
  String get send_request => 'درخواست بھیجیں';
}

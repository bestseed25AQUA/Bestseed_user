// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'আমার অ্যাপ';

  @override
  String get welcome => 'স্বাগত';

  @override
  String hello(Object name) {
    return 'হ্যালো, $name!';
  }

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get save => 'সেভ করুন';

  @override
  String get cancel => 'বাতিল করুন';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get search => 'অনুসন্ধান';

  @override
  String get notifications => 'বিজ্ঞপ্তি';

  @override
  String get logout => 'লগ আউট';

  @override
  String get login => 'লগইন';

  @override
  String get signup => 'সাইন আপ';

  @override
  String get email => 'ইমেল';

  @override
  String get password => 'পাসওয়ার্ড';

  @override
  String get confirmPassword => 'পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get forgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get submit => 'জমা দিন';

  @override
  String get error => 'ত্রুটি';

  @override
  String get success => 'সফলতা';

  @override
  String get loading => 'লোড হচ্ছে...';

  @override
  String get noInternet => 'ইন্টারনেট সংযোগ নেই';

  @override
  String get tryAgain => 'আবার চেষ্টা করুন';

  @override
  String get home => 'হোম';

  @override
  String get price => 'মূল্য';

  @override
  String get broadstock => 'ব্রডস্টক';

  @override
  String get news_ads => 'সংবাদ & বিজ্ঞাপন';

  @override
  String get updates => 'আপডেটস';

  @override
  String get send_request => 'অনুরোধ পাঠান';
}

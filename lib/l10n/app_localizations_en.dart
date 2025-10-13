// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My App';

  @override
  String get welcome => 'Welcome';

  @override
  String hello(Object name) {
    return 'Hello, $name!';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get profile => 'Profile';

  @override
  String get search => 'Search';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get submit => 'Submit';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading...';

  @override
  String get noInternet => 'No Internet Connection';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get home => 'Home';

  @override
  String get price => 'Price';

  @override
  String get broadstock => 'Broadstock';

  @override
  String get news_ads => 'News & Ads';

  @override
  String get updates => 'Updates';

  @override
  String get send_request => 'Send request';
}

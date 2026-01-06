import 'package:secure_localizations_example/l10n/secure_encryption_helper.dart';
// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => SecureEncryption.decode('OA4IHhkOSycECAoHAhEKHwIEBRg=');

  @override
  String get helloWorld => SecureEncryption.decode('Iw4HBwRLPAQZBw8=');
}

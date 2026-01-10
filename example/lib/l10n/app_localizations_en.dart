import 'package:secure_localizations_example/secure_strings/secure_encryption_gr.dart';
// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String title(String version) {
    return SecureEncryption.decode('OA4IHhkOSycECAoHAhEKHwIEBRhL') + version + SecureEncryption.decode('Sg==');
  }

  @override
  String get helloWorld => SecureEncryption.decode('Iw4HBwRLPAQZBw8=');
}

import 'package:flutter/material.dart';

import './l10n/app_localizations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // 1. Add these lines
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // 2. Use a separate Widget for the home so it has the right context
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Now context is 'under' MaterialApp, so it's NOT null
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
          title:
              Text(l10n.title("v1.1.0"))), // Assuming appTitle is in your ARB
      body: Center(
        child: Text(l10n.helloWorld), // Assuming helloWorld is in your ARB
      ),
    );
  }
}

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:secure_strings/secure_encryption.dart';
import 'package:secure_strings/secure_strings.dart';
import 'package:yaml/yaml.dart';

const String _packageName = "secure_localizations";
const String _defaultStringsOutputDir = 'lib/secure_strings';
const String _defaultL10nOutputDir = 'lib/l10n';
const String _defaultCommand = 'gen-l10n';

void main(List<String> args) async {
  try {
    print("🔒 Secure L10n Starting (Master Mode)...");

    final dynamic pubspecYaml =
        loadYaml(File('pubspec.yaml').readAsStringSync());
    final dynamic stringsCfg = pubspecYaml[SecureStrings.packageName];
    final dynamic l10nCfg = pubspecYaml[_packageName];

    // 1. Resolve the Master Key
    final String stringsOutputDir =
        (stringsCfg?['output_dir'] ?? _defaultStringsOutputDir) as String;
    final String l10nOutputDir =
        (l10nCfg?['output_dir'] ?? _defaultL10nOutputDir) as String;
    final String command = (l10nCfg?['command'] ?? _defaultCommand) as String;
    int? forcedKey;
    for (final String arg in args) {
      if (arg.startsWith('--key=')) {
        forcedKey = int.tryParse(arg.split('=')[1]);
      }
    }
    final int key = _resolveKey(forcedKey, stringsOutputDir);

    // 2. Auto generate Gitignore
    _ensureL10nGitignore(l10nOutputDir);

    // 3. Run Flutter gen-l10n
    print("⚙️  Running flutter gen-l10n...");
    final String flutterCmd = Platform.isWindows ? 'flutter.bat' : 'flutter';
    final List<String> lstCmd = command.replaceAll("flutter ", "").split(" ");

    final ProcessResult result =
        await Process.run(flutterCmd, lstCmd, runInShell: true);
    if (result.exitCode != 0) {
      print("❌ Generator Error: ${result.stderr}");
      return;
    }

    // 4. Patch L10n files using the STRINGS output directory for the import path
    _patchGeneratedFiles(l10nOutputDir, stringsOutputDir, key);

    // 5. Trigger Secure Strings with the Master Key
    print("⚙️  Synchronizing Secure Strings...");
    final ProcessResult stringsResult = await Process.run(
      'dart',
      <String>['run', SecureStrings.packageName, '--key=$key'],
      runInShell: true,
    );

    if (stringsResult.exitCode != 0) {
      print("⚠️  Secure Strings sync failed. Ensure the package is installed.");
    } else {
      print("✅ Secure Strings synchronized successfully.");
    }

    print("🚀 All systems secured and synchronized.");
  } catch (e, stack) {
    print("💥 Fatal Error: $e");
    print(stack);
  }
}

void _ensureL10nGitignore(String l10nDir) {
  final File gitignoreFile = File(p.join(l10nDir, '.gitignore'));

  const String ignoreContent = '''
# Ignore patched localization files
app_localizations_*.dart
app_localizations.dart
''';

  if (!gitignoreFile.existsSync()) {
    gitignoreFile.writeAsStringSync(ignoreContent);
    print("🛡️  Auto-created .gitignore in $l10nDir");
  }
}

int _resolveKey(int? forcedKey, String outputDir) {
  // 1. Priority: Command Line (Slave Mode)
  if (forcedKey != null) {
    print("🔗 Sync: Using Master Key provided by command argument.");
    return forcedKey;
  }

// 2. Priority: Local Secret File (.secure_key)
  final File keyFile = File(p.join(outputDir, SecureStrings.keyFileName));
  if (keyFile.existsSync()) {
    try {
      final String content = keyFile.readAsStringSync().trim();

      // Use Regex to find the digits, allowing for "key=84600683" or just "84600683"
      final RegExp keyMatch = RegExp(r'(\d+)');
      final String? found = keyMatch.firstMatch(content)?.group(1);

      if (found != null) {
        final int savedKey = int.parse(found);
        print("🔑 Encryption Key: $savedKey (Loaded from ${keyFile.path})");
        return savedKey;
      }
    } catch (e) {
      print("⚠️  Warning: Could not parse ${keyFile.path}.");
    }
  }

  // 3. Last Resort: Generate and Save
  final int newKey = Random().nextInt(899999999) + 100000000;
  keyFile.writeAsStringSync(newKey.toString());
  print("🎲 Generated new key and persisted to ${keyFile.path}");
  print("💡 Tip: Add ${keyFile.path} to your .gitignore to keep it local.");
  return newKey;
}

void _patchGeneratedFiles(
    String l10nSearchPath, String helperLocation, int key) {
  final List<File> targets = <File>[];
  final List<String> searchPaths = <String>[
    l10nSearchPath,
    '.dart_tool/flutter_gen/gen_l10n',
    'lib/generated'
  ];

  for (final String path in searchPaths) {
    final Directory dir = Directory(path);
    if (dir.existsSync()) {
      dir.listSync(recursive: true).forEach((FileSystemEntity e) {
        if (e is File &&
            e.path.endsWith('.dart') &&
            e.path.contains('app_localizations_')) {
          targets.add(e);
        }
      });
    }
  }

  if (targets.isEmpty) {
    print("❌ ERROR: Could not find l10n files to patch.");
    return;
  }

  final dynamic pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());
  final String packageName = pubspec['name'] as String;

  // We point the import to where secure_strings is generating the helper
  final String relPath =
      p.relative(helperLocation, from: 'lib').replaceAll(r'\', '/');
  final String importPath =
      'package:$packageName/$relPath/${SecureStrings.helperFileName}';

  for (final File file in targets) {
    _applyPatch(file, importPath, key);
  }
}

void _applyPatch(File file, String importPath, int key) {
  String content = file.readAsStringSync();
  if (content.contains('SecureEncryption.decode')) return;

  final String fileName = p.basename(file.path);
  final String locale =
      RegExp(r'_([a-z]{2,3})\.dart').firstMatch(fileName)?.group(1) ?? '';

  content = "import '$importPath';\n$content";

  final RegExp pattern =
      RegExp(r'(=>|return)\s+[\x27\x22]([^\x27\x22]+)[\x27\x22]');

  final String patched = content.replaceAllMapped(pattern, (Match match) {
    final String prefix = match.group(1)!;
    final String fullValue =
        match.group(2)!; // This is 'Secure Localizations $version!'

    if (fullValue == locale) return match.group(0)!;

    String resultBody;

    if (fullValue.contains(r'$')) {
      final RegExp varRegex = RegExp(r'(\$[a-zA-Z0-9_]+|\$\{[^}]+\})');
      final List<String> segments = <String>[];
      int lastMatchEnd = 0;

      for (final RegExpMatch m in varRegex.allMatches(fullValue)) {
        if (m.start > lastMatchEnd) {
          final String text = fullValue.substring(lastMatchEnd, m.start);
          segments.add(
              "SecureEncryption.decode('${SecureEncryption.encode(text, key)}')");
        }

        String varName = m.group(0)!;
        if (varName.startsWith(r'${')) {
          varName = varName.substring(2, varName.length - 1);
        } else {
          varName = varName.substring(1);
        }
        segments.add(varName);

        lastMatchEnd = m.end;
      }

      if (lastMatchEnd < fullValue.length) {
        final String text = fullValue.substring(lastMatchEnd);
        segments.add(
            "SecureEncryption.decode('${SecureEncryption.encode(text, key)}')");
      }

      resultBody = segments.join(' + ');
    } else {
      resultBody =
          "SecureEncryption.decode('${SecureEncryption.encode(fullValue, key)}')";
    }

    // Return the patched line with the original string as a comment at the end
    return "$prefix $resultBody; // '$fullValue'";
  });

  file.writeAsStringSync(patched);
  print("✨ Patched $fileName");
}

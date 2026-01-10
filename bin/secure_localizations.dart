// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:secure_strings/secure_encryption.dart';
import 'package:yaml/yaml.dart';

const String _defaultStringsOutputDir =
    'lib/secure_strings'; // Default for secure_strings
const String _defaultL10nOutputDir = 'lib/l10n';
const String _defaultCommand = 'gen-l10n';
const String _helperFileName =
    'secure_encryption_gr.dart'; // Updated to match secure_strings

void main() async {
  try {
    print("🔒 Secure L10n Starting (Master Mode)...");

    final dynamic pubspecYaml =
        loadYaml(File('pubspec.yaml').readAsStringSync());
    final dynamic stringsCfg = pubspecYaml['secure_strings'];
    final dynamic l10nCfg = pubspecYaml['secure_localizations'];

    if (l10nCfg == null) {
      print(
          "❌ Error: 'secure_localizations' section not found in pubspec.yaml.");
      return;
    }

    // 1. Resolve the Master Key
    int key;
    if (l10nCfg['key'] != null) {
      key = l10nCfg['key'] as int;
      print("🔑 Using Master Key from 'secure_localizations'.");
    } else if (stringsCfg != null && stringsCfg['key'] != null) {
      key = stringsCfg['key'] as int;
      print("🔗 Note: Using key from 'secure_strings' for consistency.");
    } else {
      key = (Random().nextInt(899999999) + 100000000);
      print("🎲 Generated temporary key: $key");
    }

    // 2. Resolve Helper Path (Where secure_strings will put the helper)
    final String stringsOutputDir =
        (stringsCfg?['output_dir'] ?? _defaultStringsOutputDir) as String;
    final String l10nOutputDir =
        (l10nCfg['output_dir'] ?? _defaultL10nOutputDir) as String;
    final String command = (l10nCfg['command'] ?? _defaultCommand) as String;

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
      <String>['run', 'secure_strings', '--key=$key'],
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
  final String importPath = 'package:$packageName/$relPath/$_helperFileName';

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
    final String fullValue = match.group(2)!;

    if (fullValue == locale) return match.group(0)!;

    if (fullValue.contains(r'$')) {
      final RegExp varRegex = RegExp(r'(\$[a-zA-Z0-9_]+|\$\{[^}]+\})');
      final List<String> segments = <String>[];
      int lastMatchEnd = 0;

      for (final RegExpMatch m in varRegex.allMatches(fullValue)) {
        // 1. Encrypt text segment BEFORE the variable
        if (m.start > lastMatchEnd) {
          final String text = fullValue.substring(lastMatchEnd, m.start);
          segments.add(
              "SecureEncryption.decode('${SecureEncryption.encode(text, key)}')");
        }

        // 2. Extract variable name and REMOVE the '$' sign
        String varName = m.group(0)!;
        if (varName.startsWith(r'${')) {
          varName = varName.substring(2, varName.length - 1); // Remove ${ and }
        } else {
          varName = varName.substring(1); // Remove $
        }
        segments.add(varName); // Add raw variable name for concatenation

        lastMatchEnd = m.end;
      }

      // 3. Encrypt text segment AFTER the last variable
      if (lastMatchEnd < fullValue.length) {
        final String text = fullValue.substring(lastMatchEnd);
        segments.add(
            "SecureEncryption.decode('${SecureEncryption.encode(text, key)}')");
      }

      // Join with + so it results in: decode('...') + version + decode('...')
      return "$prefix ${segments.join(' + ')}";
    }

    return "$prefix SecureEncryption.decode('${SecureEncryption.encode(fullValue, key)}')";
  });

  file.writeAsStringSync(patched);
  print("✨ Patched $fileName");
}

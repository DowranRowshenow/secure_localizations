# Secure Localizations

A high-performance Flutter/Dart CLI tool that secures your app's localization strings using XOR encryption and Base64 encoding. It automatically patches your generated `app_localizations` files to decrypt strings on the fly.

## 🚀 Features

- **XOR Encryption:** Obfuscates ARB values so they aren't readable in the compiled binary.
- **Auto-Patching:** Automatically injects decryption logic into the generated Dart code.
- **Customizable Generator:** Works with standard `gen-l10n` or custom forks (like `flutter_localizations_tk`).
- **Zero-Config Decryption:** Generates a helper class in your project to handle everything.
- **Randomized Security:** Can generate a unique encryption key for every build or use a fixed one.

## 📦 Installation

Add `secure_localizations` to your `dev_dependencies` in `pubspec.yaml`:

```yaml
dev_dependencies:
  secure_localizations:
    git:
      url: https://github.com/DowranRowshenow/secure_localizations.git
      ref: v1.0.1
```

## 🛠 Configuration

Add a `secure_localizations` block to your `pubspec.yaml`:

```yaml
secure_localizations:
  # Optional: A fixed integer key. If omitted, a random key is generated each run.
  key: 72929798

  # Optional: The command used to generate localizations.
  # Default is 'gen-l10n'
  command: "pub run flutter_localizations_tk:gen_l10n_tk"

  # Optional: Where your ARB files are located.
  arb_dir: "lib/l10n"

  # Optional: Where the generated Dart files and helper class should live.
  output_dir: "lib/l10n"
```

## 📖 Usage

Run the tool from your project root:

```bash
dart run secure_localizations

```

### What happens under the hood?

1. **Encrypts** your ARB files temporarily.
2. **Generates** a `secure_encryption_helper.dart` in your output directory.
3. **Runs** your specified localization command.
4. **Patches** the generated `.dart` files to wrap strings in a `decode` method.
5. **Restores** your original ARB files so your workspace stays clean.

## ⚠️ Important Note

The first time you run this tool, your IDE might show an error in the generated files saying `secure_encryption_helper.dart` does not exist. This is normal. The error will disappear once the tool finishes its first successful run and creates the file.

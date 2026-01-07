# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 07-01-2026

- **Argument Pass Fix:** Fixed where string gets encoded with its argument.

## [1.0.0] - 07-01-2026

### Added

- **Core Encryption:** Implementation of XOR-based string obfuscation for ARB files.
- **Dynamic Helper Generation:** Automatic creation of `secure_encryption_helper.dart` with integrated encryption keys.
- **Custom Command Support:** Ability to pass custom generator commands via `pubspec.yaml`.
- **Intelligent Patching:** Recursive search and Regex patching for `app_localizations_*.dart` files.
- **Auto-Backup/Restore:** Mechanism to ensure original ARB files are never lost even if the process crashes.
- **Multi-Quote Support:** Regex support for both single (`'`) and double (`"`) quotes in generated localization files.

### Fixed

- Fixed issue where patching failed if the output directory was not the standard `.dart_tool` path.
- Fixed "Unexpected null value" errors by ensuring the helper class is generated before the localization generator runs.

### Security

- Implemented random key generation (100k - 100M range) if no static key is provided in configuration.

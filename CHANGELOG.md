# Changelog

All notable changes to this project will be documented in this file.

## [1.0.7] - 11-01-2026

## Added

- **Comments on generated files**: Added comment line in generated localization showing real string

## [1.0.7] - 11-01-2026

### Fixed

- **Ghost Tag**: Fixed Ghost tag v1.0.6 after moving tag from commit

## [1.0.6] - 10-01-2026

### Added

- **Automated Workspace Protection**: `secure_localizations` now automatically generate `.gitignore` files in their respective output directories (`lib/l10n/`).
- **Source-Only Git Tracking**: Implemented a workflow where only raw data (`*.arb`) is tracked. All generated `.dart` artifacts and local `.secure_key` secrets are now automatically shielded from Git.
- **Dynamic Package Identity**: Replaced all hardcoded string references with a centralized package name constant for better maintainability across the suite.
- **Zero-Config Onboarding**: New developers only need to run the generator once to reconstruct the entire encrypted infrastructure locally.

### Changed

- **L10n Security Policy**: Generated `app_localizations_*.dart` files are now treated as temporary artifacts and are ignored by default to prevent key-mismatch conflicts in shared repositories.
- **Key Resolution Logic**: Updated to use a robust Regex-based parser that handles both raw numbers and `key=12345` assignment styles in the `.secure_key` file.

## [1.0.4] - 10-01-2026

### Added

- **Master-Slave Synchronization:** `secure_localizations` now acts as the master tool, capable of triggering `secure_strings` automatically.
- **Cross-Package Key Sync:** Implemented a hierarchy logic where the localization key overrides or synchronizes with the strings key via command-line arguments (`--key=`).
- **Shared Encoder Integration:** Support for build-time encryption using a shared encoder logic to prevent "leakage" in the production binary.

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

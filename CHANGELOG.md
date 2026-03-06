# Changelog

## 0.3.1

- Refactor `db add` to generate a separate DAO file per table with constructor-injected `DatabaseService` (clean architecture).
- DAO is auto-registered in GetIt locator (MVVM/MVI) or generated as a Riverpod provider.
- `db remove` now also cleans up DAO registration from `locator.dart`.

## 0.3.0

- Add `database` module for local SQLite database (sqflite) with auto-registration in GetIt locator.
- Add `fluttermint db add <table> --col name:Type` command — generates model class with `toMap()`/`fromMap()`, CREATE TABLE migration, and full CRUD methods (insert, getAll, getById, update, delete).
- Add `fluttermint db remove <table>` command — removes model file, CREATE TABLE SQL, import, and CRUD methods.

## 0.2.1

- Non-destructive module add — `locator.dart` and `main.dart` are updated incrementally, preserving user edits.
- Module removal regenerates shared files correctly, including structural changes (MaterialApp properties, widget class types).
- `pref add` generates getter/setter accessors instead of method-based accessors.
- Add `preferences` module for SharedPreferences with typed getter/setter generation via `fluttermint pref add`.
- Fix missing `designPattern` propagation in add/remove commands (caused wrong code generation for MVI/Riverpod projects).
- Fix Windows line-ending normalization in shared file updates.

## 0.2.0

- Add MVI (BLoC + Equatable) as second architecture pattern.
- Add MVVM + Riverpod (flutter_riverpod + AsyncNotifier) as third architecture pattern.
- Architecture pattern selection in wizard and quick create.
- Pattern-aware module filtering — locator is hidden for Riverpod, incompatible patterns are excluded.
- Config-aware dependency resolution — modules skip unnecessary packages per pattern.
- Pattern-specific screen generation (viewmodels, blocs, or notifiers + providers).
- Pattern-specific startup, theming, and testing templates.
- Show design pattern description on generated home screen.
- Update README with multi-pattern documentation.

## 0.1.1

- Add example documentation.
- Update installation instructions for pub.dev.

## 0.1.0

- Initial release of FlutterMint CLI.
- `create` command to scaffold a new Flutter project with pre-configured architecture.
- `add` / `remove` commands for managing modules (API, routing, theming, localization, etc.).
- `config` command for interactive module configuration.
- `status` command to view installed modules.
- `screen` command to generate new screens with MVVM structure.
- `run` / `build` commands with flavor and platform selection.
- `enable-http` / `disable-http` commands for HTTP connection management.
- `platform` command to manage platform targets.

# Changelog

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

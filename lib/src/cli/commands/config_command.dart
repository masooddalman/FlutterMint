import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'package:flutterforge/src/cli/prompts/prompt_utils.dart';
import 'package:flutterforge/src/config/cicd_config.dart';
import 'package:flutterforge/src/config/flavors_config.dart';
import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/generator/file_writer.dart';
import 'package:flutterforge/src/generator/module_adder.dart';
import 'package:flutterforge/src/generator/platform_configurator.dart';
import 'package:flutterforge/src/modules/module_registry.dart';
import 'package:flutterforge/src/templates/cicd/github_actions_template.dart';

class ConfigCommand extends Command<void> {
  @override
  final String name = 'config';

  @override
  final String description = 'Configure a module interactively.';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? [];

    if (rest.isEmpty) {
      stderr.writeln('Usage: flutterforge config <module>');
      stderr.writeln('Available: cicd, flavors');
      return;
    }

    final target = rest.first;
    switch (target) {
      case 'cicd':
        await _configureCicd();
      case 'flavors':
        await _configureFlavors();
      default:
        stderr.writeln('Error: Unknown configurable module "$target".');
        stderr.writeln('Available: cicd, flavors');
    }
  }

  Future<void> _configureCicd() async {
    final projectPath = Directory.current.path;

    // 1. Load existing config
    var forgeConfig = ForgeConfig.load(projectPath);
    if (forgeConfig == null) {
      stderr.writeln(
        'Error: No FlutterForge project found in the current directory.',
      );
      stderr.writeln(
        'Make sure you are inside a project created with "flutterforge create".',
      );
      return;
    }

    // 2. Auto-add cicd module if not installed
    if (!forgeConfig.modules.contains('cicd')) {
      print('CI/CD module is not installed. Adding it first...');
      print('');
      final adder = ModuleAdder();
      await adder.add(projectPath, forgeConfig, ['cicd']);
      forgeConfig = ForgeConfig.load(projectPath)!;
    }

    // 3. Load existing CI/CD config (for defaults)
    final existing = forgeConfig.cicdConfig;

    // 4. Run wizard
    PromptUtils.printHeader('CI/CD Configuration Wizard');

    final hasTesting = forgeConfig.modules.contains('testing');

    // ANSI color codes
    const green = '\x1B[32m';
    const red = '\x1B[31m';
    const blue = '\x1B[34m';
    const dim = '\x1B[2m';
    const reset = '\x1B[0m';

    // Show current config if exists
    if (existing != null) {
      print('  ${dim}Current configuration:$reset');
      print('    Branches: ${existing.branches.join(", ")}');
      print('    Format check: ${existing.formatCheck ? "yes" : "no"}');
      print('    Caching: ${existing.caching ? "yes" : "no"}');
      if (hasTesting) {
        print('    Coverage: ${existing.coverage ? "yes" : "no"}');
      }
      print('    Concurrency: ${existing.concurrency ? "yes" : "no"}');
      for (final entry in existing.branchBuilds.entries) {
        final platLabels = entry.value
            .map((p) => CicdConfig.platformLabels[p] ?? p)
            .join(', ');
        print('    Builds (${entry.key}): $platLabels');
      }
      if (existing.firebaseDistribution) {
        print('    Firebase Distribution: yes (groups: ${existing.firebaseGroups})');
      }
      if (existing.googlePlayUpload) {
        print('    Google Play: yes (${existing.packageName}, ${CicdConfig.trackLabels[existing.googlePlayTrack] ?? existing.googlePlayTrack})');
      }
      if (existing.testflightUpload) {
        print('    TestFlight: yes (bundle ID: ${existing.bundleId})');
      }
      if (existing.hasDeployment) {
        print('    Auto-publish: ${existing.autoPublish ? "yes" : "no"}');
      }
      print('');
      print('  ${dim}Modify the settings below (press Enter to keep current values).$reset');
      print('');
    }

    // Compute default step numbers from existing config
    final defaultSteps = <int>{};
    if (existing != null) {
      if (existing.formatCheck) defaultSteps.add(1);
      if (existing.caching) defaultSteps.add(2);
      if (existing.coverage) defaultSteps.add(3);
      if (existing.concurrency) defaultSteps.add(4);
      if (existing.branchBuilds.isNotEmpty) defaultSteps.add(5);
      if (existing.firebaseDistribution) defaultSteps.add(6);
      if (existing.googlePlayUpload) defaultSteps.add(7);
      if (existing.testflightUpload) defaultSteps.add(8);
    }
    final defaultStepsStr = defaultSteps.isNotEmpty
        ? (defaultSteps.toList()..sort()).join(',')
        : '1,2,4';

    // Helper to mark active steps in blue
    String stepLabel(int n, String label) {
      final active = defaultSteps.contains(n);
      return active ? '$blue  $n. $label$reset' : '  $n. $label';
    }

    // Show available CI/CD steps
    print('  Available CI/CD steps:');
    print('');
    print(stepLabel(1, 'Format Check'));
    print('  $green   Runs "dart format --set-exit-if-changed ." to enforce code style$reset');
    print('');
    print(stepLabel(2, 'Caching'));
    print('  $green   Caches Flutter SDK & pub dependencies for faster builds$reset');
    print('');
    if (hasTesting) {
      print(stepLabel(3, 'Code Coverage'));
      print('  $green   Uploads test coverage report to Codecov after running tests$reset');
    } else {
      print('  ${red}X$reset 3. Code Coverage');
      print('  $red   (Requires testing module — run "flutterforge add testing" first)$reset');
    }
    print('');
    print(stepLabel(4, 'Concurrency Control'));
    print('  $green   Cancels in-progress CI runs when new commits are pushed$reset');
    print('');
    print(stepLabel(5, 'Build Platforms'));
    print('  $green   Choose which platforms to build (APK, AAB, Web, iOS)$reset');
    print('');
    print(stepLabel(6, 'Firebase App Distribution'));
    print('  $green   Upload APK/AAB to Firebase for testers (push only)$reset');
    print('');
    print(stepLabel(7, 'Google Play Upload'));
    print('  $green   Upload AAB to Google Play Store (push only)$reset');
    print('');
    print(stepLabel(8, 'TestFlight Upload (iOS)'));
    print('  $green   Upload IPA to TestFlight via separate macOS job (push only)$reset');
    print('');

    // Ask user to select steps
    if (defaultSteps.isNotEmpty) {
      print('  ${dim}Omit a number to remove it from the config.$reset');
      print('');
    }
    final stepsInput = PromptUtils.askText(
      'Enter step numbers to enable (comma-separated)',
      defaultValue: defaultStepsStr,
    );

    final selectedSteps = stepsInput
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();

    final formatCheck = selectedSteps.contains(1);
    final caching = selectedSteps.contains(2);
    final coverage = selectedSteps.contains(3) && hasTesting;
    final concurrency = selectedSteps.contains(4);
    final wantsPlatforms = selectedSteps.contains(5);

    if (selectedSteps.contains(3) && !hasTesting) {
      print('');
      print('  ${red}Skipping Code Coverage — testing module is not installed.$reset');
    }

    // Branches
    final existingExtra = existing != null
        ? existing.branches.where((b) => b != 'main').join(', ')
        : '';
    print('');
    print('  CI runs on push/PR to: main (default)');
    final branchInput = PromptUtils.askText(
      '  Additional branches (comma-separated, or press Enter to skip)',
      defaultValue: existingExtra,
    );
    final branches = ['main'];
    if (branchInput.isNotEmpty) {
      final extra = branchInput
          .split(',')
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty && b != 'main')
          .toList();
      branches.addAll(extra);
    }

    // Platforms — per-branch if multiple branches, global if single
    final branchBuilds = <String, List<String>>{};
    if (wantsPlatforms) {
      print('');
      final platformKeys = CicdConfig.platformLabels.keys.toList();

      if (branches.length > 1) {
        print('  ${green}Multiple branches detected — you can configure builds per branch.$reset');
        print('');
      }

      print('  Build platforms:');
      for (var i = 0; i < platformKeys.length; i++) {
        final key = platformKeys[i];
        print('    ${i + 1}. ${CicdConfig.platformLabels[key]}');
      }
      print('');

      if (branches.length == 1) {
        final platforms = _askPlatforms(
          platformKeys,
          branches.first,
          existingPlatforms: existing?.platformsForBranch(branches.first),
        );
        branchBuilds[branches.first] = platforms;
      } else {
        for (final branch in branches) {
          final platforms = _askPlatforms(
            platformKeys,
            branch,
            existingPlatforms: existing?.platformsForBranch(branch),
          );
          branchBuilds[branch] = platforms;
        }
      }
    } else {
      // No build platforms step selected — default APK for all
      for (final branch in branches) {
        branchBuilds[branch] = ['apk'];
      }
    }

    // Validate deployment steps against selected platforms
    final allSelectedPlatforms =
        branchBuilds.values.expand((p) => p).toSet();
    final hasAnyApkOrAab =
        allSelectedPlatforms.contains('apk') ||
        allSelectedPlatforms.contains('aab');
    final hasAnyAab = allSelectedPlatforms.contains('aab');

    final firebaseDistribution = selectedSteps.contains(6) && hasAnyApkOrAab;
    if (selectedSteps.contains(6) && !hasAnyApkOrAab) {
      print('');
      print('  ${red}Skipping Firebase App Distribution — no APK or AAB builds configured.$reset');
    }

    final googlePlayUpload = selectedSteps.contains(7) && hasAnyAab;
    if (selectedSteps.contains(7) && !hasAnyAab) {
      print('');
      print('  ${red}Skipping Google Play Upload — AAB build is required but not configured.$reset');
    }

    final hasAnyIos = allSelectedPlatforms.contains('ios');
    final testflightUpload = selectedSteps.contains(8) && hasAnyIos;
    if (selectedSteps.contains(8) && !hasAnyIos) {
      print('');
      print('  ${red}Skipping TestFlight Upload — iOS build platform is required but not configured.$reset');
    }

    // Collect deployment parameters
    var firebaseGroups = existing?.firebaseGroups ?? 'testers';
    var packageName = existing?.packageName ?? '${forgeConfig.org}.${forgeConfig.appName}';
    var googlePlayTrack = existing?.googlePlayTrack ?? 'internal';

    if (firebaseDistribution) {
      print('');
      print('  Firebase App Distribution setup:');
      firebaseGroups = PromptUtils.askText(
        '  Tester group names (comma-separated)',
        defaultValue: firebaseGroups,
      );
    }

    if (googlePlayUpload) {
      print('');
      print('  Google Play Store setup:');
      packageName = PromptUtils.askText(
        '  Package name',
        defaultValue: packageName,
      );

      final trackKeys = CicdConfig.trackLabels.keys.toList();
      print('');
      print('  Release track:');
      for (var i = 0; i < trackKeys.length; i++) {
        print('    ${i + 1}. ${CicdConfig.trackLabels[trackKeys[i]]}');
      }
      final existingTrackIdx = trackKeys.indexOf(googlePlayTrack);
      final defaultTrackStr =
          existingTrackIdx >= 0 ? '${existingTrackIdx + 1}' : '1';
      final trackInput = PromptUtils.askText(
        '  Select track number',
        defaultValue: defaultTrackStr,
      );
      final trackIdx = int.tryParse(trackInput.trim());
      if (trackIdx != null && trackIdx >= 1 && trackIdx <= trackKeys.length) {
        googlePlayTrack = trackKeys[trackIdx - 1];
      }
    }

    // TestFlight setup
    var bundleId = existing?.bundleId.isNotEmpty == true
        ? existing!.bundleId
        : '${forgeConfig.org}.${forgeConfig.appName}';
    if (testflightUpload) {
      print('');
      print('  TestFlight setup:');
      bundleId = PromptUtils.askText(
        '  Bundle ID',
        defaultValue: bundleId,
      );
    }

    // Publish mode
    var autoPublish = existing?.autoPublish ?? false;
    if (firebaseDistribution || googlePlayUpload) {
      print('');
      print('  Publish mode:');
      print('    1. Upload only (manual publish from console)');
      print('    2. Auto-publish with release notes');
      final defaultPublishMode = autoPublish ? '2' : '1';
      final publishInput = PromptUtils.askText(
        '  Select publish mode',
        defaultValue: defaultPublishMode,
      );
      autoPublish = publishInput.trim() == '2';
    }

    // Summary
    print('');
    print('  Summary:');
    print('    Branches: ${branches.join(", ")}');
    print('    Format check: ${formatCheck ? "${green}yes$reset" : "no"}');
    print('    Caching: ${caching ? "${green}yes$reset" : "no"}');
    if (hasTesting) {
      print('    Coverage: ${coverage ? "${green}yes (Codecov)$reset" : "no"}');
    }
    print('    Concurrency: ${concurrency ? "${green}yes$reset" : "no"}');
    for (final entry in branchBuilds.entries) {
      final platLabels = entry.value
          .map((p) => CicdConfig.platformLabels[p] ?? p)
          .join(', ');
      print('    Builds (${entry.key}): $platLabels');
    }
    if (firebaseDistribution) {
      print('    Firebase Distribution: ${green}yes$reset (groups: $firebaseGroups)');
    }
    if (googlePlayUpload) {
      print('    Google Play Upload: ${green}yes$reset ($packageName, ${CicdConfig.trackLabels[googlePlayTrack] ?? googlePlayTrack})');
    }
    if (testflightUpload) {
      print('    TestFlight Upload: ${green}yes$reset (bundle ID: $bundleId)');
    }
    if (firebaseDistribution || googlePlayUpload) {
      print('    Publish mode: ${autoPublish ? "${green}Auto-publish$reset (release notes from whatsnew/)" : "Upload only (manual publish)"}');
    }
    print('');

    final confirm = PromptUtils.askYesNo('Proceed?', defaultValue: true);
    if (!confirm) {
      print('Cancelled.');
      return;
    }

    // Create whatsnew template if auto-publish enabled
    var createdWhatsnew = false;
    if (autoPublish) {
      final whatsnewFile = p.join(projectPath, 'whatsnew', 'whatsnew-en-US');
      if (!File(whatsnewFile).existsSync()) {
        final fileWriter = FileWriter();
        await fileWriter.write(
          whatsnewFile,
          'Bug fixes and performance improvements.\n',
        );
        createdWhatsnew = true;
      }
    }

    final cicdConfig = CicdConfig(
      branches: branches,
      formatCheck: formatCheck,
      caching: caching,
      coverage: coverage,
      concurrency: concurrency,
      branchBuilds: branchBuilds,
      firebaseDistribution: firebaseDistribution,
      googlePlayUpload: googlePlayUpload,
      googlePlayTrack: googlePlayTrack,
      packageName: packageName,
      firebaseGroups: firebaseGroups,
      autoPublish: autoPublish,
      testflightUpload: testflightUpload,
      bundleId: bundleId,
    );

    // 5. Save config
    final updatedConfig = forgeConfig.withCicdConfig(cicdConfig);
    await updatedConfig.save(projectPath);

    // 6. Regenerate ci.yml
    final projectConfig = ProjectConfig(
      appName: forgeConfig.appName,
      selectedModules: forgeConfig.modules.toList(),
      cicdConfig: cicdConfig,
    );
    final ciYml = GithubActionsTemplate.generate(
      projectConfig,
      cicdConfig: cicdConfig,
    );
    final fileWriter = FileWriter();
    await fileWriter.write(
      p.join(projectPath, '.github', 'workflows', 'ci.yml'),
      ciYml,
    );

    print('');
    print('CI/CD configuration saved!');
    print('  Updated: .flutterforge.yaml');
    print('  Updated: .github/workflows/ci.yml');
    if (createdWhatsnew) {
      print('  Created: whatsnew/whatsnew-en-US');
    }

    // 7. Print secrets guidance
    if (firebaseDistribution || googlePlayUpload || testflightUpload) {
      print('');
      print('  ${green}Required GitHub Secrets:$reset');
      print('  ─────────────────────────────────');
      if (firebaseDistribution) {
        print('  FIREBASE_APP_ID');
        print('    ${dim}Your Firebase App ID (e.g. 1:123456789:android:abcdef)$reset');
        print('    ${dim}Firebase Console > Project Settings > Your apps$reset');
        print('  FIREBASE_SERVICE_ACCOUNT');
        print('    ${dim}Firebase service account JSON content$reset');
        print('    ${dim}Firebase Console > Project Settings > Service Accounts$reset');
      }
      if (googlePlayUpload) {
        print('  GOOGLE_PLAY_SERVICE_ACCOUNT_JSON');
        print('    ${dim}Google Play service account JSON content$reset');
        print('    ${dim}Google Play Console > Setup > API Access$reset');
      }
      if (testflightUpload) {
        print('  APP_STORE_CONNECT_ISSUER_ID');
        print('    ${dim}App Store Connect API issuer ID$reset');
        print('    ${dim}App Store Connect > Users and Access > Keys$reset');
        print('  APP_STORE_CONNECT_KEY_ID');
        print('    ${dim}App Store Connect API key ID$reset');
        print('    ${dim}App Store Connect > Users and Access > Keys$reset');
        print('  APP_STORE_CONNECT_PRIVATE_KEY');
        print('    ${dim}App Store Connect API private key (.p8 file content)$reset');
        print('    ${dim}App Store Connect > Users and Access > Keys$reset');
        print('  IOS_P12_BASE64');
        print('    ${dim}Base64-encoded Apple distribution certificate (.p12)$reset');
        print('    ${dim}Export from Keychain Access, then: base64 -i cert.p12 | pbcopy$reset');
        print('  IOS_P12_PASSWORD');
        print('    ${dim}Password used when exporting the .p12 certificate$reset');
      }
      print('');
      print('  Set secrets at: https://github.com/<owner>/<repo>/settings/secrets/actions');
    }

    if (autoPublish) {
      print('');
      print('  ${green}Release Notes:$reset');
      print('  ─────────────────────────────────');
      print('  Update ${dim}whatsnew/whatsnew-en-US$reset before each release push.');
      print('  This file is used by both Firebase and Google Play for release notes.');
      print('  ${dim}Tip: Add additional locale files like whatsnew-de-DE for Google Play.$reset');
    }
  }

  Future<void> _configureFlavors() async {
    final projectPath = Directory.current.path;

    // 1. Load existing config
    var forgeConfig = ForgeConfig.load(projectPath);
    if (forgeConfig == null) {
      stderr.writeln(
        'Error: No FlutterForge project found in the current directory.',
      );
      stderr.writeln(
        'Make sure you are inside a project created with "flutterforge create".',
      );
      return;
    }

    // 2. Auto-add flavors module if not installed
    if (!forgeConfig.modules.contains('flavors')) {
      print('Flavors module is not installed. Adding it first...');
      print('');
      final adder = ModuleAdder();
      await adder.add(projectPath, forgeConfig, ['flavors']);
      forgeConfig = ForgeConfig.load(projectPath)!;
    }

    // 3. Load existing flavors config
    final existing = forgeConfig.flavorsConfig;

    PromptUtils.printHeader('Flavors / Environments Configuration');

    const green = '\x1B[32m';
    const dim = '\x1B[2m';
    const reset = '\x1B[0m';

    FlavorsConfig flavorsConfig;

    if (existing != null) {
      // Show current config
      _printFlavorsOverview(existing, green, dim, reset);

      // Action menu — edit one, add, remove, or reconfigure all
      flavorsConfig = _flavorsActionMenu(existing, green, dim, reset);
    } else {
      // Fresh setup
      flavorsConfig = _flavorsFullSetup(null, green, dim, reset);
    }

    // Summary
    _printFlavorsSummary(flavorsConfig, green, reset);

    final confirm = PromptUtils.askYesNo('Proceed?', defaultValue: true);
    if (!confirm) {
      print('Cancelled.');
      return;
    }

    // Save & regenerate
    await _saveFlavorsConfig(
      projectPath, forgeConfig, flavorsConfig, green, reset,
    );
  }

  void _printFlavorsOverview(
    FlavorsConfig config,
    String green,
    String dim,
    String reset,
  ) {
    print('  ${dim}Current environments:$reset');
    print('    Default: ${config.defaultEnvironment}');
    for (final env in config.environments) {
      print('    ── ${env.name} ──');
      print('      API: ${env.apiBaseUrl}');
      if (env.appNameSuffix.isNotEmpty) {
        print('      Name suffix: ${env.appNameSuffix}');
      }
      if (env.appIdSuffix.isNotEmpty) {
        print('      ID suffix: ${env.appIdSuffix}');
      }
      if (env.custom.isNotEmpty) {
        for (final kv in env.custom.entries) {
          print('      ${kv.key}: ${kv.value}');
        }
      }
    }
    print('');
  }

  FlavorsConfig _flavorsActionMenu(
    FlavorsConfig existing,
    String green,
    String dim,
    String reset,
  ) {
    print('  What would you like to do?');
    print('    1) Edit an environment');
    print('    2) Add a new environment');
    print('    3) Remove an environment');
    print('    4) Reconfigure all environments');
    print('');
    final choice = PromptUtils.askText('  Choice', defaultValue: '1');

    switch (choice) {
      case '1':
        return _flavorsEditOne(existing, dim, reset);
      case '2':
        return _flavorsAddOne(existing, dim, reset);
      case '3':
        return _flavorsRemoveOne(existing, green, reset);
      case '4':
        return _flavorsFullSetup(existing, green, dim, reset);
      default:
        print('  Invalid choice. Defaulting to edit.');
        return _flavorsEditOne(existing, dim, reset);
    }
  }

  FlavorsConfig _flavorsEditOne(
    FlavorsConfig existing,
    String dim,
    String reset,
  ) {
    final envNames = existing.environments.map((e) => e.name).toList();

    // Pick which environment to edit
    print('');
    print('  Which environment to edit?');
    for (var i = 0; i < envNames.length; i++) {
      print('    ${i + 1}) ${envNames[i]}');
    }
    print('');
    final pick = PromptUtils.askText('  Choice', defaultValue: '1');
    final idx = int.tryParse(pick);
    final selectedIdx = (idx != null && idx >= 1 && idx <= envNames.length)
        ? idx - 1
        : 0;
    final selectedName = envNames[selectedIdx];

    // Edit the selected environment, keep others unchanged
    final environments = <EnvironmentConfig>[];
    for (final env in existing.environments) {
      if (env.name == selectedName) {
        environments.add(_askEnvironmentConfig(env.name, env, dim, reset));
      } else {
        environments.add(env);
      }
    }

    return FlavorsConfig(
      environments: environments,
      defaultEnvironment: existing.defaultEnvironment,
    );
  }

  FlavorsConfig _flavorsAddOne(
    FlavorsConfig existing,
    String dim,
    String reset,
  ) {
    print('');
    final name = PromptUtils.askText('  New environment name (e.g. qa)');
    final cleanName = name.trim().toLowerCase();
    if (cleanName.isEmpty || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(cleanName)) {
      print('  Invalid name. Cancelled.');
      return existing;
    }
    if (existing.environments.any((e) => e.name == cleanName)) {
      print('  Environment "$cleanName" already exists. Use "edit" instead.');
      return existing;
    }

    final newEnv = _askEnvironmentConfig(cleanName, null, dim, reset);
    final environments = [...existing.environments, newEnv];

    return FlavorsConfig(
      environments: environments,
      defaultEnvironment: existing.defaultEnvironment,
    );
  }

  FlavorsConfig _flavorsRemoveOne(
    FlavorsConfig existing,
    String green,
    String reset,
  ) {
    final envNames = existing.environments.map((e) => e.name).toList();
    if (envNames.length <= 1) {
      print('  Cannot remove the only environment. Use "flutterforge remove flavors" instead.');
      return existing;
    }

    print('');
    print('  Which environment to remove?');
    for (var i = 0; i < envNames.length; i++) {
      print('    ${i + 1}) ${envNames[i]}');
    }
    print('');
    final pick = PromptUtils.askText('  Choice', defaultValue: '1');
    final idx = int.tryParse(pick);
    final selectedIdx = (idx != null && idx >= 1 && idx <= envNames.length)
        ? idx - 1
        : -1;
    if (selectedIdx < 0) {
      print('  Invalid choice. Cancelled.');
      return existing;
    }

    final removedName = envNames[selectedIdx];
    final environments = existing.environments
        .where((e) => e.name != removedName)
        .toList();

    // If removed env was the default, switch to the last remaining
    var defaultEnv = existing.defaultEnvironment;
    if (defaultEnv == removedName) {
      defaultEnv = environments.last.name;
      print('  ${green}Default changed to: $defaultEnv$reset');
    }

    print('  Removing environment: $removedName');
    return FlavorsConfig(
      environments: environments,
      defaultEnvironment: defaultEnv,
    );
  }

  FlavorsConfig _flavorsFullSetup(
    FlavorsConfig? existing,
    String green,
    String dim,
    String reset,
  ) {
    if (existing != null) {
      print('  ${dim}Press Enter to keep current values.$reset');
      print('');
    }

    // Ask for environment names
    final existingNames =
        existing?.environments.map((e) => e.name).join(', ') ??
            'dev, staging, production';
    final envNamesInput = PromptUtils.askText(
      'Environment names (comma-separated)',
      defaultValue: existingNames,
    );

    final envNames = envNamesInput
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where(
            (s) => s.isNotEmpty && RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(s))
        .toList();

    if (envNames.isEmpty) {
      print('No valid environment names. Using defaults.');
      return existing ?? FlavorsConfig.defaults;
    }

    // Configure each environment
    final environments = <EnvironmentConfig>[];
    for (final name in envNames) {
      final existingEnv = existing?.environments
          .where((e) => e.name == name)
          .firstOrNull;
      environments.add(_askEnvironmentConfig(name, existingEnv, dim, reset));
    }

    // Default environment
    final defaultEnv = PromptUtils.askText(
      'Default environment',
      defaultValue: existing?.defaultEnvironment ?? envNames.last,
    );

    return FlavorsConfig(
      environments: environments,
      defaultEnvironment:
          envNames.contains(defaultEnv) ? defaultEnv : envNames.last,
    );
  }

  EnvironmentConfig _askEnvironmentConfig(
    String name,
    EnvironmentConfig? existing,
    String dim,
    String reset,
  ) {
    print('');
    print('  ── $name ──');

    final apiUrl = PromptUtils.askText(
      '    API base URL',
      defaultValue: existing?.apiBaseUrl ?? 'https://$name-api.example.com',
    );

    final defaultNameSuffix = existing?.appNameSuffix ??
        ' ${name[0].toUpperCase()}${name.substring(1)}';
    final appNameSuffix = PromptUtils.askText(
      '    App name suffix (e.g. " Dev", empty for none)',
      defaultValue: defaultNameSuffix,
    );

    final defaultIdSuffix = existing?.appIdSuffix ?? '.$name';
    final appIdSuffix = PromptUtils.askText(
      '    App ID suffix (e.g. ".dev", empty for none)',
      defaultValue: defaultIdSuffix,
    );

    // Custom key-value pairs
    final custom = <String, String>{};
    if (existing != null && existing.custom.isNotEmpty) {
      print(
          '    ${dim}Current custom keys: ${existing.custom.keys.join(", ")}$reset');
    }
    final wantCustom = PromptUtils.askYesNo(
      '    Add/edit custom config keys?',
      defaultValue: existing?.custom.isNotEmpty ?? false,
    );
    if (wantCustom) {
      if (existing != null) {
        for (final kv in existing.custom.entries) {
          final val = PromptUtils.askText(
            '      ${kv.key}',
            defaultValue: kv.value,
          );
          custom[kv.key] = val;
        }
      }
      while (true) {
        final key = PromptUtils.askText(
          '      New key (or "done" to finish)',
        );
        if (key.toLowerCase() == 'done') break;
        final value = PromptUtils.askText('      Value');
        custom[key] = value;
      }
    }

    return EnvironmentConfig(
      name: name,
      apiBaseUrl: apiUrl,
      appNameSuffix: appNameSuffix,
      appIdSuffix: appIdSuffix,
      custom: custom,
    );
  }

  void _printFlavorsSummary(
    FlavorsConfig config,
    String green,
    String reset,
  ) {
    print('');
    print('  Summary:');
    for (final env in config.environments) {
      final suffix = env.name == config.defaultEnvironment
          ? ' $green(default)$reset'
          : '';
      print('    $green${env.name}$reset$suffix');
      print('      API: ${env.apiBaseUrl}');
      if (env.appNameSuffix.isNotEmpty) {
        print('      Name suffix: ${env.appNameSuffix}');
      }
      if (env.appIdSuffix.isNotEmpty) {
        print('      ID suffix: ${env.appIdSuffix}');
      }
      for (final kv in env.custom.entries) {
        print('      ${kv.key}: ${kv.value}');
      }
    }
    print('');
  }

  Future<void> _saveFlavorsConfig(
    String projectPath,
    ForgeConfig forgeConfig,
    FlavorsConfig flavorsConfig,
    String green,
    String reset,
  ) async {
    // Save config
    final updatedConfig = forgeConfig.withFlavorsConfig(flavorsConfig);
    await updatedConfig.save(projectPath);

    // Delete old config/*.json files first (env names may have changed)
    final configDir = Directory(p.join(projectPath, 'config'));
    if (await configDir.exists()) {
      await for (final entity in configDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          await entity.delete();
        }
      }
    }

    // Regenerate all files via module generateFiles
    final allModuleIds = forgeConfig.modules.toList();
    final allModules = ModuleRegistry.resolveModules(allModuleIds);
    final projectConfig = ProjectConfig(
      appName: forgeConfig.appName,
      org: forgeConfig.org,
      selectedModules: allModuleIds,
      cicdConfig: forgeConfig.cicdConfig,
      flavorsConfig: flavorsConfig,
    );

    // Regenerate env config + JSON files
    final fileWriter = FileWriter();
    final flavorsModule = allModules.where((m) => m.id == 'flavors').first;
    final files = flavorsModule.generateFiles(projectConfig);
    for (final entry in files.entries) {
      await fileWriter.write(p.join(projectPath, entry.key), entry.value);
    }

    // Ensure native platform files are configured (idempotent)
    await PlatformConfigurator.configureFlavorsAndroid(
      projectPath,
      forgeConfig.appName,
    );
    await PlatformConfigurator.configureFlavorsIos(
      projectPath,
      forgeConfig.appName,
    );

    print('');
    print('Flavors configuration saved!');
    print('  Updated: .flutterforge.yaml');
    print('  Updated: lib/core/config/env_config.dart');
    for (final env in flavorsConfig.environments) {
      print('  Updated: config/${env.name}.json');
    }
    print('');
    print('  ${green}Usage:$reset');
    for (final env in flavorsConfig.environments) {
      print('    flutter run --dart-define-from-file=config/${env.name}.json');
    }
    print('');
  }

  List<String> _askPlatforms(
    List<String> platformKeys,
    String branch, {
    List<String>? existingPlatforms,
  }) {
    // Compute default from existing platforms
    final defaultStr = existingPlatforms != null
        ? existingPlatforms
              .map((p) => platformKeys.indexOf(p) + 1)
              .where((i) => i > 0)
              .join(',')
        : '1';
    final input = PromptUtils.askText(
      '  Platforms for "$branch"',
      defaultValue: defaultStr.isNotEmpty ? defaultStr : '1',
    );
    final parsed = input
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map((s) {
          final idx = int.tryParse(s);
          if (idx != null && idx >= 1 && idx <= platformKeys.length) {
            return platformKeys[idx - 1];
          }
          return null;
        })
        .whereType<String>()
        .toSet()
        .toList();
    return parsed.isNotEmpty ? parsed : ['apk'];
  }
}

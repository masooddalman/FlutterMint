import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'package:flutterforge/src/cli/prompts/prompt_utils.dart';
import 'package:flutterforge/src/config/cicd_config.dart';
import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/generator/file_writer.dart';
import 'package:flutterforge/src/generator/module_adder.dart';
import 'package:flutterforge/src/templates/cicd/github_actions_template.dart';
import 'package:flutterforge/src/config/project_config.dart';

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
      stderr.writeln('Available: cicd');
      return;
    }

    final target = rest.first;
    if (target != 'cicd') {
      stderr.writeln('Error: Unknown configurable module "$target".');
      stderr.writeln('Available: cicd');
      return;
    }

    await _configureCicd();
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

    // Collect deployment parameters
    var firebaseGroups = existing?.firebaseGroups ?? 'testers';
    var packageName = existing?.packageName ?? 'com.example.${forgeConfig.appName}';
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
    if (firebaseDistribution || googlePlayUpload) {
      print('    ${dim}Deployment: push events only (not PRs)$reset');
    }
    print('');

    final confirm = PromptUtils.askYesNo('Proceed?', defaultValue: true);
    if (!confirm) {
      print('Cancelled.');
      return;
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

    // 7. Print secrets guidance
    if (firebaseDistribution || googlePlayUpload) {
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
      print('');
      print('  Set secrets at: https://github.com/<owner>/<repo>/settings/secrets/actions');
    }
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

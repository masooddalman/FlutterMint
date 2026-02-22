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
      // Reload config after adding
      forgeConfig = ForgeConfig.load(projectPath)!;
    }

    // 3. Run wizard
    PromptUtils.printHeader('CI/CD Configuration Wizard');

    final hasTesting = forgeConfig.modules.contains('testing');

    // ANSI color codes
    const green = '\x1B[32m';
    const red = '\x1B[31m';
    const reset = '\x1B[0m';

    // Show available CI steps
    print('  Available CI steps:');
    print('');
    print('  1. Format Check');
    print('  $green   Runs "dart format --set-exit-if-changed ." to enforce code style$reset');
    print('');
    print('  2. Caching');
    print('  $green   Caches Flutter SDK & pub dependencies for faster builds$reset');
    print('');
    if (hasTesting) {
      print('  3. Code Coverage');
      print('  $green   Uploads test coverage report to Codecov after running tests$reset');
    } else {
      print('  ${red}X$reset 3. Code Coverage');
      print('  $red   (Requires testing module — run "flutterforge add testing" first)$reset');
    }
    print('');
    print('  4. Concurrency Control');
    print('  $green   Cancels in-progress CI runs when new commits are pushed$reset');
    print('');
    print('  5. Build Platforms');
    print('  $green   Choose which platforms to build (APK, AAB, Web, iOS)$reset');
    print('');

    // Ask user to select steps
    final stepsInput = PromptUtils.askText(
      'Enter step numbers to enable (comma-separated, e.g. 1,2,4)',
      defaultValue: '1,2,4',
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
    print('');
    print('  CI runs on push/PR to: main (default)');
    final branchInput = PromptUtils.askText(
      '  Additional branches (comma-separated, or press Enter to skip)',
      defaultValue: '',
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
        // Multiple branches — offer per-branch config
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
        // Single branch — global platforms
        final platforms = _askPlatforms(platformKeys, branches.first);
        branchBuilds[branches.first] = platforms;
      } else {
        // Per-branch
        for (final branch in branches) {
          final platforms = _askPlatforms(platformKeys, branch);
          branchBuilds[branch] = platforms;
        }
      }
    } else {
      // No build platforms step selected — default APK for all
      for (final branch in branches) {
        branchBuilds[branch] = ['apk'];
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
    );

    // 4. Save config
    final updatedConfig = forgeConfig.withCicdConfig(cicdConfig);
    await updatedConfig.save(projectPath);

    // 5. Regenerate ci.yml
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
  }

  List<String> _askPlatforms(List<String> platformKeys, String branch) {
    final input = PromptUtils.askText(
      '  Platforms for "$branch"',
      defaultValue: '1',
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

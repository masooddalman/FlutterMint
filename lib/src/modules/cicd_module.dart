import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/cicd/github_actions_template.dart';

class CicdModule extends Module {
  @override
  String get id => 'cicd';

  @override
  String get displayName => 'CI/CD (GitHub Actions)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) {
    final files = {
      '.github/workflows/ci.yml':
          GithubActionsTemplate.generate(config, cicdConfig: config.cicdConfig),
    };
    if (config.cicdConfig?.autoPublish == true) {
      files['whatsnew/whatsnew-en-US'] =
          'Bug fixes and performance improvements.\n';
    }
    return files;
  }

  @override
  List<String> mainImports(ProjectConfig config) => [];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) => [];

  @override
  List<String> locatorRegistrations(ProjectConfig config) => [];

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => [];
}

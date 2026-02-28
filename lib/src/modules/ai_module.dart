import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/services/ai_service_template.dart';

class AiModule extends Module {
  @override
  String get id => 'ai';

  @override
  String get displayName => 'AI Support (Generic HTTP)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => ['api'];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/ai/ai_service.dart':
            AiServiceTemplate.generateAiService(config),
      };

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

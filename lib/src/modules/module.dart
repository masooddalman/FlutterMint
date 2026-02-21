import 'package:flutterforge/src/config/project_config.dart';

abstract class Module {
  String get id;

  String get displayName;

  bool get isDefault;

  List<String> get dependsOn;

  Map<String, String> get dependencies;

  Map<String, String> get devDependencies;

  Map<String, String> generateFiles(ProjectConfig config);

  List<String> mainImports(ProjectConfig config);

  List<String> mainSetupLines(ProjectConfig config);

  List<String> locatorImports(ProjectConfig config);

  List<String> locatorRegistrations(ProjectConfig config);

  List<String> providerDeclarations(ProjectConfig config);

  List<String> appImports(ProjectConfig config);
}

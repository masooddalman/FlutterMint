import 'package:fluttermint/src/config/project_config.dart';

abstract class Module {
  String get id;

  String get displayName;

  bool get isDefault;

  List<String> get dependsOn;

  Map<String, String> get dependencies;

  /// SDK dependencies like flutter_localizations.
  /// Key: package name, Value: sdk name (e.g. 'flutter')
  Map<String, String> get sdkDependencies => {};

  Map<String, String> get devDependencies;

  Map<String, String> generateFiles(ProjectConfig config);

  List<String> mainImports(ProjectConfig config);

  List<String> mainSetupLines(ProjectConfig config);

  List<String> locatorImports(ProjectConfig config);

  List<String> locatorRegistrations(ProjectConfig config);

  List<String> providerDeclarations(ProjectConfig config);

  List<String> appImports(ProjectConfig config);
}

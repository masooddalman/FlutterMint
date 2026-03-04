import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/modules/ai_module.dart';
import 'package:fluttermint/src/modules/api_module.dart';
import 'package:fluttermint/src/modules/cicd_module.dart';
import 'package:fluttermint/src/modules/flavors_module.dart';
import 'package:fluttermint/src/modules/localization_module.dart';
import 'package:fluttermint/src/modules/locator_module.dart';
import 'package:fluttermint/src/modules/logging_module.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/modules/mvi_module.dart';
import 'package:fluttermint/src/modules/mvvm_module.dart';
import 'package:fluttermint/src/modules/routing_module.dart';
import 'package:fluttermint/src/modules/startup_module.dart';
import 'package:fluttermint/src/modules/testing_module.dart';
import 'package:fluttermint/src/modules/theming_module.dart';
import 'package:fluttermint/src/modules/toast_module.dart';

class ModuleRegistry {
  ModuleRegistry._();

  static final List<Module> _allModules = [
    MvvmModule(),
    MviModule(),
    LoggingModule(),
    LocatorModule(),
    ThemingModule(),
    RoutingModule(),
    ApiModule(),
    AiModule(),
    LocalizationModule(),
    StartupModule(),
    ToastModule(),
    TestingModule(),
    CicdModule(),
    FlavorsModule(),
  ];

  static List<Module> get allModules => _allModules;

  /// Default module IDs (backward compat — assumes MVVM).
  static List<String> get defaultModuleIds =>
      defaultModuleIdsForPattern(DesignPattern.mvvm);

  /// Default module IDs for the given design pattern.
  static List<String> defaultModuleIdsForPattern(DesignPattern pattern) {
    final excluded = pattern == DesignPattern.mvvm ? 'mvi' : 'mvvm';
    return _allModules
        .where((m) => m.isDefault && m.id != excluded)
        .map((m) => m.id)
        .toList();
  }

  /// Optional (non-default) modules, excluding the opposite pattern.
  static List<Module> optionalModulesForPattern(DesignPattern pattern) {
    final excluded = pattern == DesignPattern.mvvm ? 'mvi' : 'mvvm';
    return _allModules
        .where((m) => !m.isDefault && m.id != excluded)
        .toList();
  }

  static List<Module> get optionalModules =>
      _allModules.where((m) => !m.isDefault).toList();

  static List<Module> resolveModules(List<String> selectedIds) {
    final selected =
        _allModules.where((m) => selectedIds.contains(m.id)).toList();
    return _topologicalSort(selected);
  }

  static List<Module> _topologicalSort(List<Module> modules) {
    final sorted = <Module>[];
    final visited = <String>{};
    final moduleMap = {for (final m in modules) m.id: m};

    void visit(Module module) {
      if (visited.contains(module.id)) return;
      visited.add(module.id);
      for (final depId in module.dependsOn) {
        final dep = moduleMap[depId];
        if (dep != null) visit(dep);
      }
      sorted.add(module);
    }

    for (final module in modules) {
      visit(module);
    }

    return sorted;
  }
}

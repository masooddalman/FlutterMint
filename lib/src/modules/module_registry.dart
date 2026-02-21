import 'package:flutterforge/src/modules/module.dart';

class ModuleRegistry {
  ModuleRegistry._();

  static final List<Module> _allModules = [];

  static List<Module> get allModules => _allModules;

  static List<String> get defaultModuleIds =>
      _allModules.where((m) => m.isDefault).map((m) => m.id).toList();

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

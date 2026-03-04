enum DesignPattern {
  mvvm('mvvm', 'MVVM (Model-View-ViewModel)',
      'MVVM (Model-View-ViewModel) — Provider + ChangeNotifier'),
  mvi('mvi', 'MVI (Model-View-Intent / BLoC)',
      'MVI (Model-View-Intent) — BLoC + Equatable'),
  riverpod('riverpod', 'MVVM + Riverpod',
      'MVVM + Riverpod — flutter_riverpod + AsyncNotifier');

  const DesignPattern(this.id, this.displayName, this.description);
  final String id;
  final String displayName;
  final String description;

  static DesignPattern fromId(String id) {
    return DesignPattern.values.firstWhere(
      (p) => p.id == id,
      orElse: () => DesignPattern.mvvm,
    );
  }
}

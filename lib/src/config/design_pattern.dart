enum DesignPattern {
  mvvm('mvvm', 'MVVM (Model-View-ViewModel)'),
  mvi('mvi', 'MVI (Model-View-Intent / BLoC)');

  const DesignPattern(this.id, this.displayName);
  final String id;
  final String displayName;

  static DesignPattern fromId(String id) {
    return DesignPattern.values.firstWhere(
      (p) => p.id == id,
      orElse: () => DesignPattern.mvvm,
    );
  }
}

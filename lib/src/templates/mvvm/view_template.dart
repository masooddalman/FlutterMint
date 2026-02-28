import 'package:fluttermint/src/config/project_config.dart';

class ViewTemplate {
  ViewTemplate._();

  static String generate(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class BaseView<T extends ChangeNotifier> extends StatelessWidget {
  const BaseView({super.key});

  T viewModel(BuildContext context) => context.read<T>();
  T watchViewModel(BuildContext context) => context.watch<T>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<T>(
      create: (_) => createViewModel(context),
      child: Consumer<T>(
        builder: (context, viewModel, child) {
          return buildView(context, viewModel);
        },
      ),
    );
  }

  T createViewModel(BuildContext context);

  Widget buildView(BuildContext context, T viewModel);
}
''';
  }
}

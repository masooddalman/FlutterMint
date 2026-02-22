import 'package:flutterforge/src/config/project_config.dart';

class UseCaseTemplate {
  UseCaseTemplate._();

  static String generateHomeRepositoryInterface(ProjectConfig config) {
    return '''import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';

abstract class HomeRepository {
  Future<HomeModel> getHomeData();
}
''';
  }

  static String generateHomeRepositoryImpl(ProjectConfig config) {
    final loggerImport = config.hasModule('logging')
        ? "import 'package:${config.appNameSnakeCase}/core/services/logger_service.dart';\n"
        : '';
    final loggerCall = config.hasModule('logging')
        ? "\n    LoggerService.info('Home data fetched from repository');"
        : '';

    return '''import 'package:${config.appNameSnakeCase}/domain/repositories/home_repository.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';
$loggerImport
class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<HomeModel> getHomeData() async {
    // TODO: Replace with actual data source (API, database, etc.)
    await Future.delayed(const Duration(seconds: 1));$loggerCall
    return const HomeModel(
      title: 'Welcome',
      description: 'Your project is set up and ready to go!',
    );
  }
}
''';
  }

  static String generateGetHomeDataUseCase(ProjectConfig config) {
    return '''import 'package:${config.appNameSnakeCase}/domain/repositories/home_repository.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';

class GetHomeDataUseCase {
  GetHomeDataUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeModel> call() {
    return _repository.getHomeData();
  }
}
''';
  }
}

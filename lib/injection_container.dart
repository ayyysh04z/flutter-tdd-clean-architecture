import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/network_info.dart';
import 'core/util/input_converter.dart';
import 'features/number_trivia/data/datasources/number_trivia_local_data_source.dart';
import 'features/number_trivia/data/datasources/number_trivia_remote_data_source.dart';
import 'features/number_trivia/data/repositories/number_trivia_repository_impl.dart';
import 'features/number_trivia/domain/repositories/number_trivia_repository.dart';
import 'features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'features/number_trivia/domain/usecases/get_random_number_trivia.dart';
import 'features/number_trivia/presentation/bloc/number_trivia_bloc.dart';

//We have all of the individual pieces of the app architecture in place. Before we can utilize them by building a UI though, we have to connect them together.
// Since every class is decoupled from its dependencies by accepting them through the constructor, we somehow have to pass them in.
// We've been doing this all along in tests with the ​mocked​ classes. Now, however, comes the time to pass in real production classes using a service locator.
final sl = GetIt.instance;

//If your app has multiple features, you might want to create smaller injection_container files with init() functions per every feature just to keep things organized.
// You'd then call these feature-specific init() functions from within the main one.
Future<void> init() async {
  //only one exception to this rule - the NumberTriviaBloc which, following the "call flow", we're going to register first.
  //Presentation logic holders such as Bloc shouldn't be registered as singletons. They are very close to the UI and if your app has multiple pages between which you navigate, you probably want to do some cleanup (like closing Streams of a Bloc) from the dispose() method of a StatefulWidget.
  // Having a singleton for classes with this kind of a disposal would lead to trying to use a presentation logic holder (such as Bloc) with closed Streams, instead of creating a new instance with opened Streams whenever you'd try to get an object of that type from GetIt.
  //! Features - Number Trivia
  // Bloc
  sl.registerFactory(
    () => NumberTriviaBloc(
      getConcreteNumberTrivia: sl(),
      inputConverter: sl(),
      getRandomNumberTrivia: sl(),
    ),
  );

  //Since we're not holding any state inside any of the classes, we're going to register everything as a ​singleton​, which means that only one instance of a class will be created per the app's lifetime.
  // Use cases
  sl.registerLazySingleton(() => GetConcreteNumberTrivia(sl()));
  sl.registerLazySingleton(() => GetRandomNumberTrivia(sl()));

  // Repository
  // While InputConverter is a stand-alone class, both of the use cases require a NumberTriviaRepository. Notice that they depend on the ​contract​​ and not on the concrete implementation. However, we cannot instantiate a ​​​contract (which is an abstract class). Instead, we have to instantiate the implementation of the repository. This is possible by specifying a type parameter on the registerLazySingleton method.
  sl.registerLazySingleton<NumberTriviaRepository>(
    () => NumberTriviaRepositoryImpl(
      localDataSource: sl(),
      networkInfo: sl(),
      remoteDataSource: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<NumberTriviaRemoteDataSource>(
    () => NumberTriviaRemoteDataSourceImpl(client: sl()),
  );

  sl.registerLazySingleton<NumberTriviaLocalDataSource>(
    () => NumberTriviaLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Core
  sl.registerLazySingleton(() => InputConverter());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  final internetConnectionChecker = InternetConnectionChecker();

  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => internetConnectionChecker);
}

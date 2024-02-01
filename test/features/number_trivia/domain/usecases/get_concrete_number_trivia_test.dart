import 'package:clean_architecture_tdd_course/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/repositories/number_trivia_repository.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import 'get_concrete_number_trivia_test.mocks.dart';

///Writing a contract of the Repository, which in the case of Dart is an abstract class,
///will allow us to write tests (TDD style) for the UseCases without having an actual Repository implementation.

@GenerateMocks([NumberTriviaRepository])
void main() {
  late GetConcreteNumberTrivia usecase;
  late MockNumberTriviaRepository mockNumberTriviaRepository;

  setUp(() {
    mockNumberTriviaRepository = MockNumberTriviaRepository();
    usecase = GetConcreteNumberTrivia(mockNumberTriviaRepository);
  });

  final tNumber = 1;
  final tNumberTrivia = NumberTrivia(number: 1, text: 'test');

  ///test first : We know that the Use Case should get its data from the NumberTriviaRepository.
  ///We'll mock it, since we only have an abstract class for it and also because mocking allows us to check, among other things,
  /// if a method has been called.
  /// usecase (domain layer) ->repo (domain layer) -> repo (data layer) -> data source (data layer)
  test(
    'should get trivia for the number from the repository',
    () async {
      // arrange
      // "On the fly" implementation of the Repository using the Mockito package.
      // When getConcreteNumberTrivia is called with any argument, always answer with
      // the Right "side" of Either containing a test NumberTrivia object.
      when(mockNumberTriviaRepository.getConcreteNumberTrivia(any))
          .thenAnswer((_) async => Right(tNumberTrivia));
      // act : The "act" phase of the test. Call the not-yet-existent method.
      final result = await usecase(Params(number: tNumber));
      //UseCase should simply return whatever was returned from the Repository
      // assert
      expect(result, Right(tNumberTrivia)); //verify result
      verify(mockNumberTriviaRepository.getConcreteNumberTrivia(
          tNumber)); //verify this methods get called via abstract class
      verifyNoMoreInteractions(
          mockNumberTriviaRepository); //verify no other interaction
    },
  );
}

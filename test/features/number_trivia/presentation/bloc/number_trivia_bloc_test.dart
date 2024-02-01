import 'package:clean_architecture_tdd_course/core/error/failures.dart';
import 'package:clean_architecture_tdd_course/core/usecases/usecase.dart';
import 'package:clean_architecture_tdd_course/core/util/input_converter.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/entities/number_trivia.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/usecases/get_concrete_number_trivia.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/domain/usecases/get_random_number_trivia.dart';
import 'package:clean_architecture_tdd_course/features/number_trivia/presentation/bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_test/flutter_test.dart';

import 'number_trivia_bloc_test.mocks.dart';
// Event-Driven Testing
// All of the Bloc's logic is executed in the mapEventToState() method. This means that to test the Bloc, we have to mimic the UI widgets by dispatching
//appropriate Events right from the test.
// In this part, we're going to start testing with the GetTriviaForConcreteNumber event, so we'll create a test group with the same name.
//Let's also set up the variables we're going to test with in this group.

//mock usecases and core logic ( no need to mock data layer,repo)
//UI -> bloc -> usecase (domain) -> data layer
@GenerateMocks([GetConcreteNumberTrivia, GetRandomNumberTrivia, InputConverter])
void main() {
  late NumberTriviaBloc bloc;
  late MockGetConcreteNumberTrivia mockGetConcreteNumberTrivia;
  late MockGetRandomNumberTrivia mockGetRandomNumberTrivia;
  late MockInputConverter mockInputConverter;

  setUp(() {
    mockGetConcreteNumberTrivia = MockGetConcreteNumberTrivia();
    mockGetRandomNumberTrivia = MockGetRandomNumberTrivia();
    mockInputConverter = MockInputConverter();

    bloc = NumberTriviaBloc(
      getConcreteNumberTrivia: mockGetConcreteNumberTrivia,
      getRandomNumberTrivia: mockGetRandomNumberTrivia,
      inputConverter: mockInputConverter,
    );
  });

  test('initialState should be Empty', () {
    // assert
    expect(bloc.state, equals(Empty()));
  });

  group('GetTriviaForConcreteNumber', () {
    final tNumberString = '1';
    final tNumberParsed = 1;
    final tNumberTrivia = NumberTrivia(number: 1, text: 'test trivia');

    void setUpMockInputConverterSuccess() =>
        when(mockInputConverter.stringToUnsignedInteger(any))
            .thenReturn(Right(tNumberParsed));
    // The Bloc state is managed using a Stream. Therefore, we use async* instead of async. This is because async* allows us to yield each state change, effectively catching and handling each one.
    // For a more detailed explanation on the difference between async and async*, you can refer to this StackOverflow post:
    // https://stackoverflow.com/questions/55397023/whats-the-difference-between-async-and-async-in-dart#:~:text=Async%20functions%20execute%20synchronously%20until,async%20function%20body%20executes%20immediately.&text=Async*%20is%20used%20to%20create,is%20wrapped%20in%20a%20Stream.

    //Ensuring Validation & Conversion
    // The most important thing to happen when a GetTriviaForConcreteNumber is dispatched, is to make sure the String gotten from the UI is a valid positive integer.
    // Through the beauty of dependencies, we already have the logic needed for this validation and conversion - it's inside the InputConverter. Because of this, we
    // can adhere to the single responsibility principle, assume that the InputConverter is (hopefully ?) successfully implemented and mock it as usual.
    // The first test will just verify that the InputConverter's method has in fact been called.
    test(
      'should call the InputConverter to validate and convert the string to an unsigned integer',
      () async* {
        // arrange
        setUpMockInputConverterSuccess();
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
        await untilCalled(mockInputConverter.stringToUnsignedInteger(any));
        // assert
        verify(mockInputConverter.stringToUnsignedInteger(tNumberString));
      },
    );
    // If the conversion is successful, the code will continue with getting data from the GetConcreteNumberTrivia use case, which will be thoroughly tested in
    // subsequent tests. First, however, let's deal with what happens when the conversion fails. In that case, it's the NumberTriviaBloc's responsibility to
    // let the UI know what went wrong by emitting an Error state
    test(
      'should emit [Error] when the input is invalid',
      () async* {
        // arrange
        when(mockInputConverter.stringToUnsignedInteger(any))
            .thenReturn(Left(InvalidInputFailure()));
        // assert later : Instead of the usual arrange -> act -> assert, we instead arrange -> assert later -> act. It is usually not be necessary to call expectLater before actually dispatching the event because it takes some time before a Stream emits its first value. I like to err on the safe side though.
        final expected = [
          Empty(),
          Error(message: INVALID_INPUT_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should get data from the concrete use case',
      () async* {
        // arrange
        setUpMockInputConverterSuccess();
        when(mockGetConcreteNumberTrivia(any))
            .thenAnswer((_) async => Right(tNumberTrivia));
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
        await untilCalled(mockGetConcreteNumberTrivia(any));
        // assert : bloc event should call this usecase with this param
        //will test states emited in next text case
        verify(mockGetConcreteNumberTrivia(Params(number: tNumberParsed)));
      },
    );

    test(
      'should emit [Loading, Loaded] when data is gotten successfully',
      () async* {
        // arrange
        setUpMockInputConverterSuccess();
        when(mockGetConcreteNumberTrivia(any))
            .thenAnswer((_) async => Right(tNumberTrivia));
        // assert later
        final expected = [
          Empty(),
          Loading(),
          Loaded(trivia: tNumberTrivia),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
      },
    );

    test(
      'should emit [Loading, Error] when getting data fails',
      () async* {
        // arrange
        setUpMockInputConverterSuccess();
        when(mockGetConcreteNumberTrivia(any))
            .thenAnswer((_) async => Left(ServerFailure()));
        // assert later
        final expected = [
          Empty(),
          Loading(),
          Error(message: SERVER_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));

        // NOTE: Simple, isn't it? ServerFailure is not the only kind of Failure returned by the use case though. A CacheFailure can also occur and we have to handle that.
        // It's very important to handle all the possible subtypes of Failure inside a Bloc. After all, we want to show a meaningful error message to the
        // user and that's possible only by emitting Error states with a customized message.
      },
    );

    test(
      'should emit [Loading, Error] with a proper message for the error when getting data fails',
      () async* {
        // arrange
        setUpMockInputConverterSuccess();
        when(mockGetConcreteNumberTrivia(any))
            .thenAnswer((_) async => Left(CacheFailure()));
        // assert later
        final expected = [
          Empty(),
          Loading(),
          Error(message: CACHE_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForConcreteNumber(tNumberString));
      },
    );
  });

  group('GetTriviaForRandomNumber', () {
    final tNumberTrivia = NumberTrivia(number: 1, text: 'test trivia');

    test(
      'should get data from the random use case',
      () async* {
        // arrange
        when(mockGetRandomNumberTrivia(any))
            .thenAnswer((_) async => Right(tNumberTrivia));
        // act
        bloc.add(GetTriviaForRandomNumber());
        await untilCalled(mockGetRandomNumberTrivia(any));
        // assert
        verify(mockGetRandomNumberTrivia(NoParams()));
      },
    );

    test(
      'should emit [Loading, Loaded] when data is gotten successfully',
      () async* {
        // arrange
        when(mockGetRandomNumberTrivia(any))
            .thenAnswer((_) async => Right(tNumberTrivia));
        // assert later
        final expected = [
          Empty(),
          Loading(),
          Loaded(trivia: tNumberTrivia),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForRandomNumber());
      },
    );

    test(
      'should emit [Loading, Error] when getting data fails',
      () async* {
        // arrange
        when(mockGetRandomNumberTrivia(any))
            .thenAnswer((_) async => Left(ServerFailure()));
        // assert later
        final expected = [
          Empty(),
          Loading(),
          Error(message: SERVER_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForRandomNumber());
      },
    );

    test(
      'should emit [Loading, Error] with a proper message for the error when getting data fails',
      () async* {
        // arrange
        when(mockGetRandomNumberTrivia(any))
            .thenAnswer((_) async => Left(CacheFailure()));
        // assert later
        final expected = [
          Empty(),
          Loading(),
          Error(message: CACHE_FAILURE_MESSAGE),
        ];
        expectLater(bloc, emitsInOrder(expected));
        // act
        bloc.add(GetTriviaForRandomNumber());
      },
    );
  });
}

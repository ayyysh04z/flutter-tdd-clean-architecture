import 'package:clean_architecture_tdd_course/core/error/failures.dart';
import 'package:dartz/dartz.dart';

///InputConverter
// We will break our tradition a bit and create a class for doing the conversion, an InputConverter, without creating its abstract class contract first.
//Personally, I feel that creating contracts for simple utility classes such as this one isn't necessary. Plus, since every class in Dart can be
//implemented as an interface, mocking the InputConverter while testing the Bloc in the next part will still be as easy as mocking an abstract class.
// It will live inside the presentation layer very much like the the NumberTriviaModel lives inside the data layer. The purpose of the converter
//will be the same as that of the model - not to let the domain layer get entangled in the outside world. Numbers aren't strings, much like
// NumberTrivia isn't JSON, after all!
class InputConverter {
  Either<Failure, int> stringToUnsignedInteger(String str) {
    try {
      final integer = int.parse(str);
      if (integer < 0) throw FormatException();
      return Right(integer);
    } on FormatException {
      return Left(InvalidInputFailure());
    }
  }
}

class InvalidInputFailure extends Failure {}

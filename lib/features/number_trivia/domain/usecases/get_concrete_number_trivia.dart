import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/number_trivia.dart';
import '../repositories/number_trivia_repository.dart';

class GetConcreteNumberTrivia implements UseCase<NumberTrivia, Params> {
  final NumberTriviaRepository repository;

  GetConcreteNumberTrivia(this.repository);

  @override
  Future<Either<Failure, NumberTrivia>> call(Params params) async {
    //In Test-Driven Development (TDD) and clean architecture, it's common to have use cases that delegate to repository classes. However,
    // it's important to note that the use case is not just a pass-through to the repository; it encapsulates business logic, validation, and
    //coordination of data flow. While simple use cases may seem like they only call the repository, they can evolve to include more business logic as the application requirements grow.
    return await repository.getConcreteNumberTrivia(params.number);
  }
}

class Params extends Equatable {
  final int number;

  Params({required this.number});

  @override
  List<Object> get props => [number];
}

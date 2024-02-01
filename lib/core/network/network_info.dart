import 'package:internet_connection_checker/internet_connection_checker.dart';

abstract class NetworkInfo {
  Future<bool> get isConnected;
}

// It may seem that such "call forwarding" is just a waste of effort. Quite the opposite!
// Imagine you wanted to swap the data_connection_checker package for something different.
// If you used it directly inside the Repositories (unless you're building a Number Trivia App,
// you'll have multiple ones), you'd need to change a LOT of connectivity-checking code.
// By hiding it behind an interface you control, there won't much code to change at all!
class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}

/// A flat failure type the UI can render directly. Repositories and services
/// translate Dio/IO/DB exceptions into one of these so widgets never see a
/// raw exception.
sealed class Failure {
  const Failure(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

class ApiFailure extends Failure {
  const ApiFailure(super.message, {this.statusCode, super.cause});
  final int? statusCode;
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message, {super.cause});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause});
}

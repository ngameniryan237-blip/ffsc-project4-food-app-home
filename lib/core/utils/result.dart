import '../error/failures.dart';

class Result<T> {
  final T? _data;
  final Failure? failure;
  final bool isSuccess;

  const Result._({T? data, this.failure, required this.isSuccess}) : _data = data;

  factory Result.success([T? data]) => Result._(data: data, isSuccess: true);
  factory Result.error(Failure failure) => Result._(failure: failure, isSuccess: false);

  T? get data => _data;
  bool get isError => !isSuccess;

  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) {
    if (isSuccess) {
      return success(_data as T);
    } else {
      return error(failure ?? const ServerFailure('Unknown error'));
    }
  }
}

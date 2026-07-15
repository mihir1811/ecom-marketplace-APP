/// A sealed Result type representing either a [Success] or a [ResultFailure].
/// Ensures safe error containment at boundaries (e.g. Repositories).
sealed class Result<T, F> {
  const Result();
  factory Result.success(T value) = Success<T, F>;
  factory Result.failure(F failure) = ResultFailure<T, F>;
}

class Success<T, F> extends Result<T, F> {
  final T value;
  const Success(this.value);
}

class ResultFailure<T, F> extends Result<T, F> {
  final F failure;
  const ResultFailure(this.failure);
}

/// Base Result class
/// @param T The type of the value
sealed class Result<T> {
  const Result();
}

/// Success Result
final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

/// Error Result
final class Error<T> extends Result<T> {
  const Error(this.error);
  final Exception error;
}
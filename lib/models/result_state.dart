/// State-driven UI logic for asynchronous operations.
/// Exposes Loading, Success, and Error states in a type-safe Dart 3 sealed structure.
sealed class ResultState<T> {
  const ResultState();
}

class ResultStateIdle<T> extends ResultState<T> {
  const ResultStateIdle();
}

class ResultStateLoading<T> extends ResultState<T> {
  const ResultStateLoading();
}

class ResultStateSuccess<T> extends ResultState<T> {
  final T data;
  const ResultStateSuccess(this.data);
}

class ResultStateError<T> extends ResultState<T> {
  final Object error;
  final String message;
  const ResultStateError(this.error, this.message);
}

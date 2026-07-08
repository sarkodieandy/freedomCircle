sealed class AsyncState<T> {
  const AsyncState();

  bool get isLoading => this is AsyncLoading<T>;
  bool get hasValue => this is AsyncData<T>;
  bool get hasError => this is AsyncError<T>;

  T? get valueOrNull {
    final state = this;
    return state is AsyncData<T> ? state.value : null;
  }
}

class AsyncIdle<T> extends AsyncState<T> {
  const AsyncIdle();
}

class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

class AsyncData<T> extends AsyncState<T> {
  const AsyncData(this.value);

  final T value;
}

class AsyncError<T> extends AsyncState<T> {
  const AsyncError(this.message, {this.error});

  final String message;
  final Object? error;
}

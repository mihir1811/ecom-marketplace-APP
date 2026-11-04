import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod 2 behaviour for `state` once a notifier is disposed.
///
/// Riverpod 3 throws [UnmountedRefException] when a disposed notifier reads
/// or writes `state`, which happens when a screen closes while one of its
/// requests is still in flight. Riverpod 2 let that finish quietly. With this
/// mixin a late write is dropped and a late read returns the last value the
/// notifier held, so the in-flight method completes as it used to.
///
/// Prefer `if (!ref.mounted) return;` after awaits; this covers methods that
/// must return a value and cannot simply bail out.
mixin DisposeTolerantNotifier<StateT> on Notifier<StateT> {
  late StateT _lastState;
  bool _hasLastState = false;

  @override
  StateT get state {
    if (!ref.mounted && _hasLastState) return _lastState;
    final value = super.state;
    _lastState = value;
    _hasLastState = true;
    return value;
  }

  @override
  set state(StateT value) {
    if (!ref.mounted) return;
    super.state = value;
    _lastState = value;
    _hasLastState = true;
  }
}

/// [DisposeTolerantNotifier] for [AsyncNotifier].
mixin DisposeTolerantAsyncNotifier<ValueT> on AsyncNotifier<ValueT> {
  late AsyncValue<ValueT> _lastState;
  bool _hasLastState = false;

  @override
  AsyncValue<ValueT> get state {
    if (!ref.mounted && _hasLastState) return _lastState;
    final value = super.state;
    _lastState = value;
    _hasLastState = true;
    return value;
  }

  @override
  set state(AsyncValue<ValueT> value) {
    if (!ref.mounted) return;
    super.state = value;
    _lastState = value;
    _hasLastState = true;
  }
}

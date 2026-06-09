import 'dart:async';

/// Puente desacoplado entre ApiClient y la UI.
/// ApiClient llama a [notifyUnauthorized] cuando recibe un 401.
/// App.dart escucha [onUnauthorized] y dispara logout.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _controller.stream;

  void notifyUnauthorized() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}

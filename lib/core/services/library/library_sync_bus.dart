import 'dart:async';

/// Lightweight reactive broadcast bus notifying library and smart playlist
/// providers whenever tracks are favorited, played, edited, or scanned.
class LibrarySyncBus {
  LibrarySyncBus();

  final StreamController<int> _controller = StreamController<int>.broadcast(sync: true);
  int _revision = 0;

  int get revision => _revision;

  Stream<int> get stream => _controller.stream;

  void notifyChanged() {
    _revision++;
    if (!_controller.isClosed) {
      _controller.add(_revision);
    }
  }

  void dispose() {
    _controller.close();
  }
}

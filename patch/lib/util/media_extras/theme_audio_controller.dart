/// Serializes player operations and rechecks intent after a slow open.
abstract class ThemeAudioBackend {
  Future<void> open(Uri uri, Map<String, String> headers);
  Future<void> play();
  Future<void> pause();
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

class ThemeAudioController {
  final ThemeAudioBackend Function() createBackend;
  ThemeAudioController(this.createBackend);

  ThemeAudioBackend? _backend;
  Future<void> _work = Future.value();
  bool _wanted = false;
  bool _disposed = false;
  Uri? _opened;
  Map<String, String> _openedHeaders = const {};

  Future<void> update({
    required bool playing,
    required Uri? uri,
    required Map<String, String> headers,
    required double volume,
  }) {
    _wanted = playing;
    return _enqueue(() async {
      if (_disposed) return;
      if (!_wanted || uri == null) {
        await _backend?.pause();
        return;
      }
      final backend = _backend ??= createBackend();
      await backend.setVolume(volume.clamp(0, 100).toDouble());
      final sameHeaders =
          headers.length == _openedHeaders.length &&
          headers.entries.every(
            (entry) => _openedHeaders[entry.key] == entry.value,
          );
      if (_opened != uri || !sameHeaders) {
        await backend.open(uri, headers);
        _opened = uri;
        _openedHeaders = Map.of(headers);
      }
      if (_wanted && !_disposed) {
        await backend.play();
      } else {
        await backend.pause();
      }
    });
  }

  void invalidate() => _opened = null;

  Future<void> _enqueue(Future<void> Function() action) {
    final operation = _work.then((_) => action());
    _work = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> dispose() {
    _wanted = false;
    _disposed = true;
    return _enqueue(() async {
      await _backend?.dispose();
      _backend = null;
    });
  }
}

Uri themeStreamUri(String serverUrl, String itemId) {
  final base = Uri.parse(serverUrl);
  return base.replace(
    pathSegments: [
      ...base.pathSegments.where((segment) => segment.isNotEmpty),
      'Audio',
      itemId,
      'stream',
    ],
    queryParameters: {'static': 'true'},
  );
}

bool shouldPlayLocalTheme({
  required bool enabled,
  required bool currentRoute,
  required bool foreground,
  required bool mainPlayerIdle,
}) => enabled && currentRoute && foreground && mainPlayerIdle;

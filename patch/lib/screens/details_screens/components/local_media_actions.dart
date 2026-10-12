import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart' as mpv;

import 'package:fladder/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:fladder/models/items/item_stream_model.dart';
import 'package:fladder/models/media_playback_model.dart';
import 'package:fladder/providers/api_provider.dart';
import 'package:fladder/providers/local_media_extras_provider.dart';
import 'package:fladder/providers/shared_provider.dart';
import 'package:fladder/providers/user_provider.dart';
import 'package:fladder/providers/video_player_provider.dart';
import 'package:fladder/screens/details_screens/components/local_trailer_button.dart';
import 'package:fladder/util/item_base_model/play_item_helpers.dart';
import 'package:fladder/util/localization_helper.dart';
import 'package:fladder/util/media_extras/theme_audio_controller.dart';

class LocalMediaActions extends ConsumerStatefulWidget {
  final String itemId;
  final bool themeMusic;
  const LocalMediaActions({
    required this.itemId,
    this.themeMusic = false,
    super.key,
  });

  @override
  ConsumerState<LocalMediaActions> createState() => _LocalMediaActionsState();
}

class _LocalMediaActionsState extends ConsumerState<LocalMediaActions>
    with WidgetsBindingObserver {
  late final ThemeAudioController _audio;
  late bool _enabled;
  late double _volume;
  bool _foreground = true;
  bool _launchingTrailer = false;
  bool _themeFailed = false;
  String? _lastIntent;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _enabled = prefs.getBool('local_theme_enabled') ?? true;
    _volume = (prefs.getDouble('local_theme_volume') ?? 20)
        .clamp(0, 100)
        .toDouble();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _audio = ThemeAudioController(
      () => _MpvThemeBackend(() {
        if (mounted) setState(() => _themeFailed = true);
      }),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant LocalMediaActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemId != widget.itemId) {
      _lastIntent = null;
      _themeFailed = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted)
      setState(() => _foreground = state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_audio.dispose().catchError((Object _) {}));
    super.dispose();
  }

  void _updateAudio(bool wanted, Uri? uri, String token) {
    final intent = '$wanted|$uri|$_volume|$token';
    if (_lastIntent == intent) return;
    _lastIntent = intent;
    // update() records stop intent immediately, even if an open is in flight.
    unawaited(
      _audio
          .update(
            playing: wanted,
            uri: uri,
            headers: {'X-Emby-Token': token},
            volume: _volume,
          )
          .catchError((Object _) {
            if (mounted) setState(() => _themeFailed = true);
          }),
    );
  }

  Future<void> _playTrailer(BaseItemDto trailer) async {
    setState(() => _launchingTrailer = true);
    await _audio
        .update(playing: false, uri: null, headers: const {}, volume: _volume)
        .catchError((Object _) {});
    if (!mounted) return;
    try {
      final item = ItemStreamModel.fromBaseDto(trailer, null);
      await item.play(context, ref, startPosition: Duration.zero);
    } finally {
      if (mounted)
        setState(() {
          _launchingTrailer = false;
          _lastIntent = null;
        });
    }
  }

  Future<void> _changeVolume() async {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: Text(context.localized.localThemeVolume),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_volume.round()}%'),
                Slider(
                  value: _volume,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${_volume.round()}%',
                  onChanged: (value) {
                    setState(() => _volume = value);
                    ref.read(localThemeVolumeProvider.notifier).state = value;
                    updateDialog(() {});
                    unawaited(
                      ref
                          .read(sharedPreferencesProvider)
                          .setDouble('local_theme_volume', value),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.localized.close),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _enabled = ref.watch(localThemeEnabledProvider);
    _volume = ref.watch(localThemeVolumeProvider);
    final trailers = ref.watch(localTrailersProvider(widget.itemId));
    final themes = widget.themeMusic
        ? ref.watch(localThemeSongsProvider(widget.itemId))
        : null;
    final songs = themes?.asData?.value ?? const <BaseItemDto>[];
    final server = ref.watch(serverUrlProvider);
    final token =
        ref.watch(userProvider.select((value) => value?.credentials.token)) ??
        '';
    final mainPlayerIdle = ref.watch(
      mediaPlaybackProvider.select(
        (value) => value.state == VideoPlayerState.disposed,
      ),
    );
    final currentRoute = ModalRoute.of(context)?.isCurrent ?? false;
    final wanted =
        widget.themeMusic &&
        songs.isNotEmpty &&
        !_themeFailed &&
        !_launchingTrailer &&
        shouldPlayLocalTheme(
          enabled: _enabled,
          currentRoute: currentRoute,
          foreground: _foreground,
          mainPlayerIdle: mainPlayerIdle,
        );
    final uri = songs.isNotEmpty && (server ?? '').isNotEmpty
        ? themeStreamUri(server!, songs.first.id!)
        : null;
    _updateAudio(wanted, uri, token);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (trailers.asData?.value.isNotEmpty == true)
          LocalTrailerButton(
            trailers: trailers.asData!.value,
            onSelected: (item) {
              if (!_launchingTrailer) unawaited(_playTrailer(item));
            },
          ),
        if (trailers.hasError)
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(context.localized.localTrailerRetry),
            onPressed: () =>
                ref.invalidate(localTrailersProvider(widget.itemId)),
          ),
        if (songs.isNotEmpty) ...[
          OutlinedButton.icon(
            icon: Icon(
              _enabled && !_themeFailed ? Icons.music_note : Icons.music_off,
            ),
            label: Text(context.localized.localThemeMusic),
            onPressed: () {
              setState(() {
                if (_themeFailed) {
                  _audio.invalidate();
                  _themeFailed = false;
                  _lastIntent = null;
                } else {
                  _enabled = !_enabled;
                }
              });
              ref.read(localThemeEnabledProvider.notifier).state = _enabled;
              unawaited(
                ref
                    .read(sharedPreferencesProvider)
                    .setBool('local_theme_enabled', _enabled),
              );
            },
          ),
          IconButton(
            tooltip: context.localized.localThemeVolume,
            icon: const Icon(Icons.volume_up_outlined),
            onPressed: _changeVolume,
          ),
        ],
        if (_themeFailed || themes?.hasError == true)
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: Text(context.localized.localThemeRetry),
            onPressed: () {
              setState(() {
                _audio.invalidate();
                _themeFailed = false;
                _lastIntent = null;
              });
              ref.invalidate(localThemeSongsProvider(widget.itemId));
            },
          ),
      ],
    );
  }
}

class _MpvThemeBackend implements ThemeAudioBackend {
  late final mpv.Player _player;
  StreamSubscription<String>? _errors;
  _MpvThemeBackend(VoidCallback onError) {
    mpv.MediaKit.ensureInitialized();
    _player = mpv.Player(
      configuration: const mpv.PlayerConfiguration(
        title: 'Fladder theme music',
      ),
    );
    _errors = _player.stream.error.listen((_) => onError());
  }
  @override
  Future<void> open(Uri uri, Map<String, String> headers) async {
    await _player.open(
      mpv.Media(uri.toString(), httpHeaders: headers),
      play: false,
    );
    await _player.setPlaylistMode(mpv.PlaylistMode.single);
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);
  @override
  Future<void> dispose() async {
    await _errors?.cancel();
    await _player.dispose();
  }
}

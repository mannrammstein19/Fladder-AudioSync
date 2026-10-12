import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:fladder/l10n/generated/app_localizations.dart';
import 'package:fladder/screens/details_screens/components/local_trailer_button.dart';
import 'package:fladder/util/media_extras/local_media_helpers.dart';
import 'package:fladder/util/media_extras/theme_audio_controller.dart';

class FakeThemeBackend implements ThemeAudioBackend {
  final opened = Completer<void>();
  final events = <String>[];
  @override
  Future<void> open(Uri uri, Map<String, String> headers) async {
    events.add('open');
    await opened.future;
  }

  @override
  Future<void> play() async => events.add('play');
  @override
  Future<void> pause() async => events.add('pause');
  @override
  Future<void> setVolume(double volume) async => events.add('volume:$volume');
  @override
  Future<void> dispose() async => events.add('dispose');
}

void main() {
  test(
    'Invalid and duplicate IDs are removed without losing four trailers',
    () {
      final items = List.generate(
        4,
        (i) => BaseItemDto(id: 'id-$i', name: 'Trailer $i'),
      );
      expect(
        usableLocalMedia([
          ...items,
          items.first,
          const BaseItemDto(),
          const BaseItemDto(id: ''),
        ]).length,
        4,
      );
    },
  );
  test('Theme URL preserves Jellyfin subpath and keeps token out of URL', () {
    final uri = themeStreamUri('https://example.test/jellyfin/', 'theme123');
    expect(uri.path, '/jellyfin/Audio/theme123/stream');
    expect(uri.queryParameters, {'static': 'true'});
    expect(
      themeStreamUri('https://example.test', 'theme123').path,
      '/Audio/theme123/stream',
    );
  });
  test(
    'Themes require current visible route, enabled setting and idle player',
    () {
      for (final disabled in [
        'enabled',
        'currentRoute',
        'foreground',
        'mainPlayerIdle',
      ]) {
        expect(
          shouldPlayLocalTheme(
            enabled: disabled != 'enabled',
            currentRoute: disabled != 'currentRoute',
            foreground: disabled != 'foreground',
            mainPlayerIdle: disabled != 'mainPlayerIdle',
          ),
          false,
        );
      }
      expect(
        shouldPlayLocalTheme(
          enabled: true,
          currentRoute: true,
          foreground: true,
          mainPlayerIdle: true,
        ),
        true,
      );
    },
  );
  test(
    'Navigating away while opening audio never starts delayed theme',
    () async {
      final backend = FakeThemeBackend();
      final controller = ThemeAudioController(() => backend);
      final start = controller.update(
        playing: true,
        uri: Uri.parse('https://example.test/a'),
        headers: {},
        volume: 20,
      );
      await Future<void>.delayed(Duration.zero);
      final stop = controller.update(
        playing: false,
        uri: null,
        headers: {},
        volume: 20,
      );
      backend.opened.complete();
      await Future.wait([start, stop]);
      expect(backend.events, isNot(contains('play')));
      expect(backend.events, contains('pause'));
      await controller.dispose();
    },
  );
  test('Dispose during opening prevents playback and disposes once', () async {
    final backend = FakeThemeBackend();
    final controller = ThemeAudioController(() => backend);
    final start = controller.update(
      playing: true,
      uri: Uri.parse('https://example.test/a'),
      headers: {},
      volume: 500,
    );
    await Future<void>.delayed(Duration.zero);
    final disposing = controller.dispose();
    backend.opened.complete();
    await Future.wait([start, disposing]);
    expect(backend.events, contains('volume:100.0'));
    expect(backend.events, isNot(contains('play')));
    expect(backend.events.where((event) => event == 'dispose').length, 1);
  });

  Future<void> mount(
    WidgetTester tester,
    List<BaseItemDto> trailers,
    ValueChanged<BaseItemDto> onSelected,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LocalTrailerButton(trailers: trailers, onSelected: onSelected),
        ),
      ),
    );
  }

  testWidgets('One trailer plays directly without a picker', (tester) async {
    BaseItemDto? selected;
    await mount(tester, [
      const BaseItemDto(id: 'one', name: 'Oficial'),
    ], (item) => selected = item);
    await tester.tap(find.byKey(const Key('local-trailer-button')));
    await tester.pumpAndSettle();
    expect(selected?.id, 'one');
    expect(find.text('Escolher trailer'), findsNothing);
  });
  testWidgets('Four trailers can be selected and closing never plays', (
    tester,
  ) async {
    BaseItemDto? selected;
    final trailers = List.generate(
      4,
      (i) => BaseItemDto(id: '$i', name: 'Temporada ${i + 1}'),
    );
    await mount(tester, trailers, (item) => selected = item);
    await tester.tap(find.byKey(const Key('local-trailer-button')));
    await tester.pumpAndSettle();
    expect(find.text('Escolher trailer'), findsOneWidget);
    for (final trailer in trailers) {
      expect(find.text(trailer.name!), findsOneWidget);
    }
    await tester.tap(find.text('Temporada 4'));
    await tester.pumpAndSettle();
    expect(selected?.id, '3');
    selected = null;
    await tester.tap(find.byKey(const Key('local-trailer-button')));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Escolher trailer'))).pop();
    await tester.pumpAndSettle();
    expect(selected, isNull);
  });
  testWidgets('No trailer means no button', (tester) async {
    await mount(tester, [], (_) => fail('No selection expected'));
    expect(find.byKey(const Key('local-trailer-button')), findsNothing);
  });
}

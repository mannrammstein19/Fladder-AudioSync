import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fladder/l10n/generated/app_localizations.dart';
import 'package:fladder/models/settings/video_player_settings.dart';
import 'package:fladder/screens/settings/widgets/audio_sync_controls.dart';

void main() {
  test('Older saved settings keep zero delay', () {
    final oldSettings = VideoPlayerSettingsModel.fromJson({'bufferSize': 32});
    expect(oldSettings.audioDelayMs, 0);
  });

  test('Signed delay survives save and reload without changing backend', () {
    for (final delay in [-1000, -200, 0, 150, 1000]) {
      final original = VideoPlayerSettingsModel(audioDelayMs: delay, playerOptions: PlayerOptions.libMPV);
      final restored = VideoPlayerSettingsModel.fromJson(original.toJson());
      expect(restored.audioDelayMs, delay);
      expect(restored.wantedPlayer, PlayerOptions.libMPV);
    }
  });

  test('Delay changes notify settings without restarting the player', () {
    final original = VideoPlayerSettingsModel();
    final modified = original.copyWith(audioDelayMs: -200);
    expect(modified, isNot(original));
    expect(modified.playerSame(original), isTrue);
  });

  testWidgets('Bluetooth preset, signed slider and reset work', (tester) async {
    int delay = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return AudioSyncControls(value: delay, onChanged: (value) => setState(() => delay = value));
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('audio-sync-bluetooth')));
    await tester.pump();
    expect(delay, -200);
    expect(find.text('-200 ms'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byKey(const Key('audio-sync-slider')));
    slider.onChanged!(-350);
    await tester.pump();
    expect(delay, -350);
    await tester.tap(find.byKey(const Key('audio-sync-reset')));
    await tester.pump();
    expect(delay, 0);
    expect(find.text('0 ms'), findsOneWidget);
  });
}

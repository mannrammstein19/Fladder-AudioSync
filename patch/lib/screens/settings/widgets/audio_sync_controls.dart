import 'package:flutter/material.dart';

import 'package:fladder/util/localization_helper.dart';

/// Adjusts MPV synchronization without recreating the player.
class AudioSyncControls extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const AudioSyncControls({required this.value, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final delay = value.clamp(-1000, 1000).toInt();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.localized.audioSyncTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(context.localized.audioSyncHelp),
          const SizedBox(height: 8),
          Text('${delay > 0 ? '+' : ''}$delay ms'),
          Slider(
            key: const Key('audio-sync-slider'),
            value: delay.toDouble(),
            min: -1000,
            max: 1000,
            divisions: 40,
            label: '$delay ms',
            semanticFormatterCallback: (value) => '${value.round()} ms',
            onChanged: (value) => onChanged(value.round()),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('audio-sync-bluetooth'),
                onPressed: () => onChanged(-200),
                child: Text(context.localized.audioSyncBluetooth),
              ),
              TextButton(
                key: const Key('audio-sync-reset'),
                onPressed: () => onChanged(0),
                child: Text(context.localized.audioSyncReset),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

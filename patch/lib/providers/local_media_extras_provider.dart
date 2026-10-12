import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fladder/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:fladder/providers/api_provider.dart';
import 'package:fladder/providers/connectivity_provider.dart';
import 'package:fladder/providers/user_provider.dart';
import 'package:fladder/providers/shared_provider.dart';
import 'package:fladder/util/media_extras/local_media_helpers.dart';

final localTrailersProvider = FutureProvider.autoDispose
    .family<List<BaseItemDto>, String>((ref, id) async {
      if (ref.watch(offlineStateProvider)) return const [];
      final userId = ref.watch(userProvider.select((value) => value?.id));
      final response = await ref
          .watch(jellyApiProvider)
          .api
          .itemsItemIdLocalTrailersGet(itemId: id, userId: userId);
      if (!response.isSuccessful)
        throw StateError('Local trailers unavailable');
      return usableLocalMedia(response.body);
    });

final localThemeSongsProvider = FutureProvider.autoDispose
    .family<List<BaseItemDto>, String>((ref, id) async {
      if (ref.watch(offlineStateProvider)) return const [];
      final userId = ref.watch(userProvider.select((value) => value?.id));
      final response = await ref
          .watch(jellyApiProvider)
          .api
          .itemsItemIdThemeSongsGet(
            itemId: id,
            userId: userId,
            inheritFromParent: false,
          );
      if (!response.isSuccessful) throw StateError('Theme songs unavailable');
      return usableLocalMedia(response.body?.items);
    });

final localThemeEnabledProvider = StateProvider<bool>(
  (ref) =>
      ref.watch(sharedPreferencesProvider).getBool('local_theme_enabled') ??
      true,
);
final localThemeVolumeProvider = StateProvider<double>(
  (ref) =>
      (ref.watch(sharedPreferencesProvider).getDouble('local_theme_volume') ??
              20)
          .clamp(0, 100)
          .toDouble(),
);

import 'package:fladder/jellyfin/jellyfin_open_api.swagger.dart';

List<BaseItemDto> usableLocalMedia(List<BaseItemDto>? items) {
  final ids = <String>{};
  return (items ?? const <BaseItemDto>[])
      .where((item) => (item.id ?? '').isNotEmpty && ids.add(item.id!))
      .toList(growable: false);
}

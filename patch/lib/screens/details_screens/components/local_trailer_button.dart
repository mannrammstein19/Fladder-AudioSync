import 'package:flutter/material.dart';

import 'package:fladder/jellyfin/jellyfin_open_api.swagger.dart';
import 'package:fladder/util/localization_helper.dart';

class LocalTrailerButton extends StatelessWidget {
  final List<BaseItemDto> trailers;
  final ValueChanged<BaseItemDto> onSelected;
  const LocalTrailerButton({
    required this.trailers,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (trailers.isEmpty) return const SizedBox.shrink();
    return OutlinedButton.icon(
      key: const Key('local-trailer-button'),
      icon: const Icon(Icons.movie_outlined),
      label: Text(context.localized.localTrailerLabel),
      onPressed: () async {
        if (trailers.length == 1) {
          onSelected(trailers.single);
          return;
        }
        final selected = await showModalBottomSheet<BaseItemDto>(
          context: context,
          isScrollControlled: true,
          builder: (sheetContext) => SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.6,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.localized.chooseLocalTrailer,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: trailers.length,
                      itemBuilder: (context, index) {
                        final trailer = trailers[index];
                        final name = trailer.name?.trim();
                        return ListTile(
                          key: ValueKey('local-trailer-${trailer.id}'),
                          leading: const Icon(Icons.play_circle_outline),
                          title: Text(
                            name?.isNotEmpty == true
                                ? name!
                                : '${context.localized.localTrailerLabel} ${index + 1}',
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(trailer),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        if (context.mounted && selected != null) onSelected(selected);
      },
    );
  }
}

import 'dart:math';

import 'package:finamp/services/queue_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';


import '../../models/jellyfin_models.dart';
import '../../models/finamp_models.dart';
import '../../services/isar_downloads.dart';
import '../../services/jellyfin_api_helper.dart';
import '../../services/audio_service_helper.dart';
import '../../services/finamp_settings_helper.dart';

class ArtistShuffleButton extends StatefulWidget {
  const ArtistShuffleButton({
    Key? key,
    required this.artist,
  }) : super(key: key);

  final BaseItemDto artist;
  

  @override
  State<ArtistShuffleButton> createState() => _ArtistShuffleButtonState();
}

class _ArtistShuffleButtonState extends State<ArtistShuffleButton> {
  static const _disabledButton = IconButton(
    onPressed: null,
    icon: Icon(Icons.play_arrow)
    );
    Future<List<BaseItemDto>?>? artistShuffleButtonFuture;

    final _jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
    final _audioServiceHelper = GetIt.instance<AudioServiceHelper>();
    final _queueService = GetIt.instance<QueueService>();

    @override
    Widget build(BuildContext context) {
      return ValueListenableBuilder<Box<FinampSettings>>(
        valueListenable: FinampSettingsHelper.finampSettingsListener,
        builder: (context, box, _) {
          final isOffline = box.get("FinampSettings")?.isOffline ?? false;

          if (isOffline) {
             final isarDownloads = GetIt.instance<IsarDownloads>();

             artistShuffleButtonFuture ??= Future.sync(() async {
               // TODO add direct artist -> downloadedsong retrieval function
               final List<DownloadStub> artistAlbums = await isarDownloads.getAllCollections(baseTypeFilter: BaseItemDtoType.album,relatedTo: widget.artist);
               final List<BaseItemDto> sortedSongs = [];
               for(var album in artistAlbums){
                 sortedSongs.addAll(await isarDownloads.getCollectionSongs(album.baseItem!));
               }
               return sortedSongs;
             });
          } else {
            artistShuffleButtonFuture ??= _jellyfinApiHelper.getItems(
              parentItem: widget.artist,
              includeItemTypes: "Audio",
              sortBy: 'PremiereDate,Album,SortName',
              isGenres: false,
            );
          }

            return FutureBuilder<List<BaseItemDto>?>(
            future: artistShuffleButtonFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData){
                final List<BaseItemDto> items = snapshot.data!;

                return IconButton(
                  onPressed: () async {
                    await _queueService.startPlayback(
                      items: items,
                      source: QueueItemSource(type: QueueItemSourceType.artist, name: QueueItemSourceName(type: QueueItemSourceNameType.preTranslated, pretranslatedName: widget.artist.name), id: widget.artist.id),
                      order: FinampPlaybackOrder.shuffled,
                    );
                  }, 
                  icon: const Icon(Icons.shuffle),
                  );
              } else {
                return _disabledButton;
              }
            },
          );
         }
      );
    }
}
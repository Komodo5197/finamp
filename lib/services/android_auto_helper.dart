import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:collection/collection.dart';
import 'package:finamp/components/MusicScreen/sort_and_filter_row.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/extensions/list.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/models/jellyfin_models.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/item_by_id_provider.dart';
import 'package:finamp/services/music_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path_helper;
import 'package:path_provider/path_provider.dart';

import '../gen/assets.gen.dart';
import '../models/music_models.dart';
import 'album_image_provider.dart';
import 'audio_service_helper.dart';
import 'finamp_settings_helper.dart';
import 'finamp_user_helper.dart';
import 'jellyfin_api_helper.dart';
import 'music_screen_provider.dart';
import 'queue_service.dart';

class AndroidAutoSearchQuery {
  String rawQuery;
  Map<String, dynamic>? extras;

  AndroidAutoSearchQuery(this.rawQuery, this.extras);
}

class AndroidAutoHelper {
  static final _androidAutoHelperLogger = Logger("AndroidAutoHelper");

  final _finampUserHelper = GetIt.instance<FinampUserHelper>();
  final _jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  final _downloadsService = GetIt.instance<DownloadsService>();
  final _container = GetIt.instance<ProviderContainer>();
  // This cannot be set up on first load, but should be available before we try to actually load anything
  // TODO investigate better ordering?
  late final _queueService = GetIt.instance<QueueService>();

  /// Maximum items returned per Android Auto browse page.
  /// Kept well under the ~1MB Binder IPC limit.
  static const int _pageSize = 300;

  // actively remembered search query because Android Auto doesn't give us the extras during a regular search (e.g. clicking the "Search Results" button on the player screen after a voice search)
  AndroidAutoSearchQuery? _lastSearchQuery;

  void setLastSearchQuery(AndroidAutoSearchQuery? searchQuery) {
    _lastSearchQuery = searchQuery;
  }

  AndroidAutoSearchQuery? get lastSearchQuery => _lastSearchQuery;

  /// Letters used for the "Browse by Letter" nodes.
  static const List<String> _alphabet = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '#',
  ];

  /// Returns the letter nodes A–Z plus a '#' bucket for the Browse-by-Letter view.
  List<MediaItem> _getLetterNodes(MediaItemId itemId) {
    return _alphabet.map((letter) {
      return MediaItem(
        id: itemId.copyWith(nameFilter: letter).toString(),
        title: letter,
        playable: false,
        extras: const {
          // Items filtered by letter should render as a list (no grid).
          AndroidContentStyle.browsableHintKey: AndroidContentStyle.listItemHintValue,
          AndroidContentStyle.playableHintKey: AndroidContentStyle.listItemHintValue,
        },
      );
    }).toList();
  }

  /// Returns up to 20 recently played albums (online only).
  /// In offline mode returns a single non-playable placeholder.
  ///
  /// Jellyfin only tracks DatePlayed on individual tracks, not on album items.
  /// So we query recently played tracks, deduplicate by albumId, then fetch
  /// those albums by ID to get full artwork + metadata.
  Future<List<MediaItem>> _getRecentlyPlayedAlbums() async {
    // TODO do we keep this func?  If so, refactor
    if (FinampSettingsHelper.finampSettings.isOffline) {
      return [
        MediaItem(
          id: 'recently_played_offline',
          title: GlobalSnackbar.requireL10n.androidAutoNotAvailableOffline,
          playable: false,
        ),
      ];
    }

    final queueService = GetIt.instance<QueueService>();
    final parentItem = _finampUserHelper.currentUser?.currentView;

    try {
      // Step 1: fetch recently played tracks — tracks reliably have DatePlayed set.
      final tracksResult = await _jellyfinApiHelper.getItemsWithTotalRecordCount(
        parentItem: parentItem,
        includeItemTypes: BaseItemDtoType.track.jellyfinName,
        sortBy: 'DatePlayed',
        sortOrder: 'Descending',
        filters: 'IsPlayed',
        limit: 300,
      );

      // Step 2: extract ordered, deduplicated album IDs from the track results.
      final seenIds = <String>{};
      final orderedIds = <BaseItemId>[];

      for (final track in tracksResult.items ?? <BaseItemDto>[]) {
        final albumId = track.albumId;
        if (albumId != null && seenIds.add(albumId.raw)) {
          orderedIds.add(albumId);
          if (orderedIds.length >= 20) break;
        }
      }

      if (orderedIds.isEmpty) return [];

      // Step 3: fetch the actual album items by ID to get full metadata + artwork.
      final itemsResult = await _jellyfinApiHelper.getItemsWithTotalRecordCount(
        itemIds: orderedIds,
        includeItemTypes: BaseItemDtoType.album.jellyfinName,
      );

      // Re-sort to match the original play order (getItems by ID returns in arbitrary order).
      final itemsById = <String, BaseItemDto>{
        for (final item in itemsResult.items ?? <BaseItemDto>[]) item.id.raw: item,
      };
      final sortedItems = orderedIds.map((id) => itemsById[id.raw]).whereType<BaseItemDto>().toList();

      final List<MediaItem> mediaItems = [];
      for (final item in sortedItems) {
        final mediaItem = await _generateMediaItem(item, isPlayable: _isPlayable);
        mediaItems.add(mediaItem);
      }
      return mediaItems;
    } catch (err, trace) {
      _androidAutoHelperLogger.severe("Error loading recently played items", err, trace);
      return [];
    }
  }

  Future<List<MediaItem>> getRecentItems() async {
    final queueService = GetIt.instance<QueueService>();
    //TODO this should ideally list recent queues (the restorable ones), or items from the home screen
    try {
      final recentItems = queueService.peekQueue(previous: 5);
      final List<MediaItem> recentMediaItems = [];
      for (final item in recentItems) {
        final mediaItem = await _generateMediaItem(item.baseItem, isPlayable: _isPlayable);
        recentMediaItems.add(mediaItem);
      }
      return recentMediaItems;
    } catch (err) {
      _androidAutoHelperLogger.severe("Error while getting recent items:", err);
      return [];
    }
  }

  Future<void> shuffleAllTracks() async {
    final audioServiceHelper = GetIt.instance<AudioServiceHelper>();

    try {
      await audioServiceHelper.shuffleAll(onlyShowFavorites: FinampSettingsHelper.finampSettings.onlyShowFavorites);
    } catch (err) {
      _androidAutoHelperLogger.severe("Error while shuffling all tracks", err);
    }
  }

  // TODO merge the logic between browsing and playing better - more playables?
  late FutureProviderFamily<FinampPlayable, MediaItemId> mediaPlayableProvider = FutureProvider.family((
    ref,
    mediaId,
  ) async {
    switch (mediaId.type) {
      case MediaItemType.root:
        throw UnsupportedError("Cant play the home screen");
      case MediaItemType.tab:
        throw UnsupportedError("Cant play tabs");
      case MediaItemType.item:
        final item = await ref.watch(itemByIdProvider(mediaId.itemId!).future);
        if (item == null) {
          // TODO fix this - rename unavailible offline? Just throw error?
          throw UnimplementedError();
        }
        return FinampPlayableDto.fromItem(item);
    }
  });

  late FutureProviderFamily<List<MediaItem>, MediaItemId> mediaItemsProvider = FutureProvider.family((
    ref,
    mediaId,
  ) async {
    print("ZZZZZZZZZZ Getting child of $mediaId");
    switch (mediaId.type) {
      case MediaItemType.root:
        return _getRootMenu(ref);
      case MediaItemType.tab:
        final tab = ref.watch(finampSettingsProvider.androidAutoTabs)[mediaId.tabIndex!];
        if (tab.browseMode == AndroidAutoBrowsingMode.letters && mediaId.nameFilter == null) {
          return _getLetterNodes(mediaId);
        }
        if (tab.tabType == AndroidAutoTabType.recentAlbums) {
          return _getRecentlyPlayedAlbums();
        }
        var playable = await ref.watch(resolveSectionProvider(tab.homeSection).future);
        if (tab.tabType == AndroidAutoTabType.tracking) {
          final sorted = playable as MusicScreenPlayable;
          final sortControl = SortAndFilterController.trackSettings(sorted.tab);
          playable = sorted.copyWith(ref.watch(resolveSortProvider(sortControl)));
        }

        if (playable case FinampSortable<FinampPlayable> sorted) {
          playable = sorted.copyWith(sorted.sortConfig.copyWithCharacterFilter(mediaId.nameFilter));
        }
        // TODO add browse by letter when appropriate - also browse by page?
        return await _mediaItemsFromPlayable(ref, playable, mediaId);
      case MediaItemType.item:
        final item = await ref.watch(itemByIdProvider(mediaId.itemId!).future);
        if (item == null) {
          return [];
        }
        // TODO allow configuring how artists/albums are handled?
        // Do something smarter regarding album vs performing artist tabs?
        // Show all types via grouping hints?
        FinampDisplayable<FinampPlayable> playable = switch (BaseItemDtoType.fromItem(item)) {
          BaseItemDtoType.artist => Artist(
            item,
            sortConfig: SortAndFilterConfiguration.defaultArtistAlbumSort,
            type: ArtistChildType.albumsFromArtist,
            library: currentLibraryPlaceholder,
          ),
          BaseItemDtoType.genre => Genre(
            item,
            sortConfig: SortAndFilterConfiguration.defaultArtistAlbumSort,
            type: GenreChildType.albums,
            library: currentLibraryPlaceholder,
          ),
          // We shouldn't ever be attempting to browse a track
          _ => FinampPlayableDto.fromItem(item) as FinampDisplayable<FinampPlayable>,
        };
        // TODO add play/shuffle when appropriate
        // - should this be inside fromPlayable?  what about play/shuffle options?
        return await _mediaItemsFromPlayable(ref, playable, mediaId);
    }
  });

  /// Returns the top-level browsable categories for use in a media browser.
  List<MediaItem> _getRootMenu(Ref ref) {
    final l10n = ref.watch(l10nProvider);

    final tabs = ref.watch(finampSettingsProvider.androidAutoTabs);
    return tabs.mapIndexed((index, tab) {
      if (tab.tabType == AndroidAutoTabType.tracking) {
        final contentType = tab.contentType;
        return MediaItem(
          id: MediaItemId(type: MediaItemType.tab, tabIndex: index).toString(),
          // Android auto has limited space, so just say artist instead of specifying performing/album.
          title: contentType.isArtist ? l10n.artists : contentType.toLocalisedString(l10n),
          playable: false,
          extras: {AndroidContentStyle.browsableHintKey: _gridHint(contentType, tab.browseMode)},
        );
      } else {
        return MediaItem(
          id: MediaItemId(type: MediaItemType.tab, tabIndex: index).toString(),
          title: tab.tabType == AndroidAutoTabType.recentAlbums
              ? l10n.recentlyPlayedAlbums
              : tab.homeSection.toLocalisedString(l10n),
          playable: false,
          extras: {AndroidContentStyle.browsableHintKey: _gridHint(tab.contentType, tab.browseMode)},
        );
      }
    }).toList();
  }

  Future<List<MediaItem>> _mediaItemsFromPlayable(
    Ref ref,
    FinampDisplayable<FinampPlayable> playable,
    MediaItemId id,
  ) async {
    final List<MediaItem> mediaItems = [];
    switch (playable) {
      case FinampDisplayable<FinampPlayableDto>():
        // (Returned items, hasNextPage);
        final Completer<(List<FinampDisplayableOrPlayable>, bool)> completer = Completer();
        ProviderSubscription<PagingState<int, FinampDisplayableOrPlayable>>? driver;
        driver = ref.listen(pagedContentProvider(playable), fireImmediately: true, (_, next) {
          if (completer.isCompleted || next.isLoading) return;
          final items = next.items ?? [];
          final missingItems = (id.pageIndex ?? 0) + _pageSize - items.length;
          if (missingItems > 0 && next.hasNextPage && next.error == null) {
            ref.read(pagedContentProvider(playable).notifier).newPage(pageSize: missingItems);
            return;
          }
          // Surface an error only when nothing is cached, so a partial page still
          // renders rather than showing an empty library.
          if (next.error != null && items.isEmpty) {
            completer.completeError(next.error!);
          } else {
            completer.complete((items.safeSliceByLength(id.pageIndex ?? 0, _pageSize), next.hasNextPage));
          }
        });
        ref.onDispose(() {
          driver?.close();
          if (!completer.isCompleted) {
            completer.completeError("Loading aborted");
          }
        });
        final completed = await completer.future;
        for (final item in completed.$1.cast<FinampPlayableDto>()) {
          final mediaItem = await _generateMediaItem(item.item, isPlayable: _isPlayable);
          mediaItems.add(mediaItem);
        }
        if (completed.$2) {
          // TODO can we retrieve remaining items somehow?
          // TODO add image for grid mode
          mediaItems.add(
            MediaItem(
              id: id.copyWith(pageIndex: (id.pageIndex ?? 0) + _pageSize).toString(),
              title: GlobalSnackbar.requireL10n.androidAutoMoreItems(99999),
              playable: false,
            ),
          );
        }
        return mediaItems;
      case UnavailableHomeSectionPlayable():
        throw UnimplementedError();
      case PlayableQueue():
      case LatestQueues():
      case Track():
      case InstantMix():
        throw UnimplementedError();
    }
  }

  Future<MediaItem> _generateMediaItem(
    BaseItemDto item, {
    bool Function({BaseItemDto? item, ContentType? contentType})? isPlayable,
  }) async {
    MediaItemId? itemId = MediaItemId(type: MediaItemType.item, itemId: item.id);

    bool isDownloaded = false;
    bool isItemPlayable = isPlayable?.call(item: item) ?? true;

    if (item.type == "Audio") {
      final downloadedTrack = _downloadsService.getTrackDownload(item: item);
      isDownloaded = downloadedTrack?.file != null;
    } else {
      final downloadedCollection = await _downloadsService.getCollectionInfo(item: item);
      if (downloadedCollection != null) {
        final downloadStatus = _downloadsService.getStatus(downloadedCollection, null);
        isDownloaded = downloadStatus != DownloadItemStatus.notNeeded;
      }
    }

    Uri? artUri = _container.read(albumImageProvider(AlbumImageRequest(item: item, maxHeight: 200, maxWidth: 200))).uri;

    // use content provider for handling media art on Android
    if (Platform.isAndroid) {
      final packageInfo = await PackageInfo.fromPlatform();
      // replace with placeholder art
      if (artUri == null) {
        final applicationSupportDirectory = await getApplicationSupportDirectory();
        artUri = Uri(
          scheme: "content",
          host: packageInfo.packageName,
          path: path_helper.join(applicationSupportDirectory.absolute.path, Assets.images.albumWhite.path),
        );
      } else {
        // store the origin in fragment since it should be unused
        artUri = Uri(
          scheme: "content",
          host: packageInfo.packageName,
          path: artUri.path,
          fragment: ["http", "https"].contains(artUri.scheme) ? artUri.origin : null,
        );
      }
    }

    return MediaItem(
      id: itemId.toString(),
      playable:
          isItemPlayable, // this dictates whether clicking on an item will try to play it or browse it in media browsers like Android Auto
      album: item.album,
      artist: item.artists?.sortedBy((e) => e).join(", ") ?? item.albumArtist,
      title: item.name ?? GlobalSnackbar.requireL10n.unknown,
      extras: {
        "android.media.extra.DOWNLOAD_STATUS": isDownloaded ? 2 : 0,
        "android.media.IS_EXPLICIT": item.isExplicit ? 1 : 0,
      },
      // Jellyfin returns microseconds * 10 for some reason
      duration: item.runTimeTicksDuration(),
      artUri: artUri,
    );
  }

  Future<List<MediaItem>> getMediaItems(MediaItemId itemId) async {
    return await _container.read(mediaItemsProvider(itemId).future);

    /*final items = await _container.read(getChildrenProvider(item: playable).future);

    // Root collections are paginated to stay within the Android Auto Binder
    // IPC limit (~1MB). Each page shows _pageSize items with a "More..." node
    // appended when further pages exist.
    if (itemId.parentType == MediaItemParentType.rootCollection) {
      final nameFilter = itemId.nameFilter;

      // --- Browse-by-Letter index: return A–Z + # nodes ---
      if (nameFilter == _letterRootNameFilter) {
        return _getLetterNodes(itemId);
      }

      // --- Letter page: items starting with nameFilter ---
      if (nameFilter != null) {
        final (items, totalCount) = await _fetchLetterPage(itemId);
        final pageStart = itemId.pageStartIndex ?? 0;

        for (final item in items) {
          final mediaItem = await queueService.generateMediaItem(
            item,
            itemType: MediaItemType.item,
            parentId: item.parentId,
            isPlayable: _isPlayable,
          );
          mediaItems.add(mediaItem);
        }

        if (pageStart + items.length < totalCount) {
          final nextStart = pageStart + _pageSize;
          final remaining = totalCount - nextStart;
          mediaItems.add(
            MediaItem(
              id: MediaItemId(
                contentType: itemId.contentType,
                parentType: MediaItemParentType.rootCollection,
                nameFilter: nameFilter,
                pageStartIndex: nextStart,
              ).toString(),
              title: GlobalSnackbar.requireL10n.androidAutoMoreItems(remaining),
              playable: false,
            ),
          );
        }

        return mediaItems;
      }

      // --- Flat paginated list (nameFilter == null) ---
      if (itemId.contentType == ContentType.tracks) {
        mediaItems.add(
          MediaItem(
            id: QueueItemSourceNameType.shuffleAll.name,
            title: GlobalSnackbar.requireL10n.shuffleAll,
            playable: true,
          ),
        );
      }

      if (itemId.contentType == ContentType.albumArtists &&
          itemId.parentType == MediaItemParentType.collection &&
          itemId.itemId != null) {
        final instantMixId = MediaItemId(
          contentType: ContentType.albumArtists,
          parentType: MediaItemParentType.instantMix,
          itemId: itemId.itemId,
        );
        mediaItems.add(
          MediaItem(id: instantMixId.toString(), title: GlobalSnackbar.requireL10n.instantMix, playable: true),
        );
      }

      // Albums, Artists, and Tracks support letter browsing.
      // If letterFirst, return the A–Z index immediately; otherwise fall through to flat list.
      final supportsLetterBrowse =
          itemId.contentType == ContentType.albums ||
          itemId.contentType == ContentType.albumArtists ||
          itemId.contentType == ContentType.tracks;
      final isLetterFirst =
          FinampSettingsHelper.finampSettings.androidAutoBrowsingMode == AndroidAutoBrowsingMode.letterFirst;
      if (supportsLetterBrowse && isLetterFirst) {
        return _getLetterNodes(itemId);
      }

      // For flat list mode: "Browse by Letter" node only on first page, if supported.
      final pageStart = itemId.pageStartIndex ?? 0;
      if (pageStart == 0 && supportsLetterBrowse && !isLetterFirst) {
        mediaItems.add(
          MediaItem(
            id: MediaItemId(
              contentType: itemId.contentType,
              parentType: MediaItemParentType.rootCollection,
              nameFilter: _letterRootNameFilter,
            ).toString(),
            title: GlobalSnackbar.requireL10n.androidAutoBrowseByLetter,
            playable: false,
          ),
        );
      }

      final (items, totalCount) = await _fetchRootPage(itemId);

      for (final item in items) {
        final mediaItem = await queueService.generateMediaItem(
          item,
          itemType: MediaItemType.item,
          parentId: item.parentId,
          isPlayable: _isPlayable,
        );
        mediaItems.add(mediaItem);
      }

      // Guard against Jellyfin returning a slightly inflated totalRecordCount
      // (observed with playlists), which would produce a negative remaining count.
      if (pageStart + items.length < totalCount) {
        final nextStart = pageStart + _pageSize;
        final remaining = totalCount - nextStart;
        if (remaining > 0) {
          mediaItems.add(
            MediaItem(
              id: MediaItemId(
                contentType: itemId.contentType,
                parentType: MediaItemParentType.rootCollection,
                pageStartIndex: nextStart,
              ).toString(),
              title: GlobalSnackbar.requireL10n.androidAutoMoreItems(remaining),
              playable: false,
            ),
          );
        }
      }

      return mediaItems;
    }

    final items = await getBaseItems(itemId);

    for (final item in items) {
      final mediaItem = await queueService.generateMediaItem(
        item,
        itemType: MediaItemType.item,
        parentId: item.parentId,
        isPlayable: _isPlayable,
      );
      mediaItems.add(mediaItem);
    }
    return mediaItems;*/
  }

  Future<void> playFromMediaId(MediaItemId itemId) async {
    final playable = await _container.read(mediaPlayableProvider(itemId).future);
    // TODO handle more complicated track work somewhere?  Better error handling for unplayable id?
    final slice = await _container.read(getPlayableSliceProvider(item: playable, startingOffset: 0).future);
    return _queueService.startSlicePlayback(slice);
  }

  Future<List<MediaItem>> searchItems(AndroidAutoSearchQuery searchQuery) async {
    try {
      final searchFuture = Future.wait([
        _searchPlaylists(searchQuery, limit: 3),
        _searchTracks(searchQuery, limit: 5),
        _searchAlbums(searchQuery, limit: 5),
        _searchArtists(searchQuery, limit: 3),
        _searchGenres(searchQuery, limit: 3),
      ]);

      final [playlistResults, trackResults, albumResults, artistResults, genreResults] = await searchFuture;

      final List<BaseItemDto> allSearchResults = playlistResults
          .followedBy(trackResults)
          .followedBy(albumResults)
          .followedBy(artistResults)
          .followedBy(genreResults)
          .toList();

      final List<MediaItem> mediaItems = [];

      for (final item in allSearchResults) {
        final mediaItem = await _generateMediaItem(item, isPlayable: _isPlayable);

        // assign a group hint based on the item type, so Android Auto can group search results by type
        switch (item.type) {
          case "Audio":
            mediaItem.extras?["android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT"] =
                GlobalSnackbar.requireL10n.tracks;
            break;
          case "MusicAlbum":
            mediaItem.extras?["android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT"] =
                GlobalSnackbar.requireL10n.albums;
            break;
          case "MusicArtist":
            mediaItem.extras?["android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT"] =
                GlobalSnackbar.requireL10n.artists;
            break;
          case "MusicGenre":
            mediaItem.extras?["android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT"] =
                GlobalSnackbar.requireL10n.genres;
            break;
          case "Playlist":
            mediaItem.extras?["android.media.browse.CONTENT_STYLE_GROUP_TITLE_HINT"] =
                GlobalSnackbar.requireL10n.playlists;
            break;
          default:
            break;
        }
        mediaItems.add(mediaItem);
      }
      return mediaItems;
    } catch (err, trace) {
      _androidAutoHelperLogger.severe("Error while searching: ${err.toString()}", err, trace);
      return [];
    }
  }

  Future<void> playFromSearch(AndroidAutoSearchQuery searchQuery) async {
    final jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
    final finampUserHelper = GetIt.instance<FinampUserHelper>();

    if (searchQuery.rawQuery.isEmpty) {
      return await shuffleAllTracks();
    }

    BaseItemDtoType? itemType = ContentType.tracks.itemType;
    String? enhancedQuery;
    bool searchForPlaylists = false;

    if (searchQuery.extras?["android.intent.extra.album"] != null &&
        searchQuery.extras?["android.intent.extra.artist"] != null &&
        searchQuery.extras?["android.intent.extra.title"] != null) {
      // if all metadata is provided, search for track
      itemType = ContentType.tracks.itemType;
      enhancedQuery = searchQuery.extras?["android.intent.extra.title"] as String?;
    } else if (searchQuery.extras?["android.intent.extra.album"] != null &&
        searchQuery.extras?["android.intent.extra.artist"] != null &&
        searchQuery.extras?["android.intent.extra.title"] == null) {
      // if only album is provided, search for album
      itemType = ContentType.albums.itemType;
      enhancedQuery = searchQuery.extras?["android.intent.extra.album"] as String?;
    } else if (searchQuery.extras?["android.intent.extra.artist"] != null &&
        searchQuery.extras?["android.intent.extra.title"] == null) {
      // if only artist is provided, search for artist
      itemType = ContentType.albumArtists.itemType;
      enhancedQuery = searchQuery.extras?["android.intent.extra.artist"] as String?;
    } else {
      // if no metadata is provided, search for tracks *and* playlists, preferring playlists
      searchForPlaylists = true;
    }

    _androidAutoHelperLogger.info(
      "Searching for: $itemType that matches query '${enhancedQuery ?? searchQuery.rawQuery}'${searchForPlaylists ? ", including (and preferring) playlists" : ""}",
    );

    final searchTerm = searchForPlaylists
        ? searchQuery.rawQuery.trim()
        : // always use the raw query for searching playlists
          enhancedQuery?.trim() ?? searchQuery.rawQuery.trim();

    if (searchForPlaylists) {
      try {
        List<BaseItemDto>? searchResult;

        if (FinampSettingsHelper.finampSettings.isOffline) {
          List<DownloadStub>? offlineItems = await _downloadsService.getAllCollections(
            nameFilter: searchTerm,
            includeItemTypes: [BaseItemDtoType.playlist],
            fullyDownloaded: false,
            viewFilter: finampUserHelper.currentUser?.currentView?.id,
            childViewFilter: null,
            nullableViewFilters: FinampSettingsHelper.finampSettings.showDownloadsWithUnknownLibrary,
            onlyFavorites: false,
          );

          searchResult = offlineItems.map((e) => e.baseItem).whereNotNull().toList();
        } else {
          searchResult = await jellyfinApiHelper.getItems(
            parentItem: null, // always use global playlists
            includeItemTypes: ContentType.playlists.itemType?.jellyfinName,
            searchTerm: searchTerm,
            startIndex: 0,
            limit: 1,
          );
        }

        if (searchResult?.isNotEmpty ?? false) {
          final playlist = searchResult![0];

          List<BaseItemDto>? items;

          if (FinampSettingsHelper.finampSettings.isOffline) {
            items = await _downloadsService.getCollectionTracks(playlist, playable: true);
          } else {
            items = await _jellyfinApiHelper.getItems(
              parentItem: playlist,
              includeItemTypes: ContentType.tracks.itemType?.jellyfinName,
              sortBy: "ParentIndexNumber,IndexNumber,SortName",
              sortOrder: "Ascending",
              limit: 200,
            );
          }

          _androidAutoHelperLogger.info("Playing playlist: ${playlist.name} (${items?.length} tracks)");

          await _queueService.startPlayback(
            items: items ?? [],
            source: QueueItemSource(
              type: QueueItemSourceType.playlist,
              name: QueueItemSourceName(type: QueueItemSourceNameType.preTranslated, pretranslatedName: playlist.name),
              id: playlist.id,
              item: playlist,
            ),
            order: FinampPlaybackOrder
                .linear, //TODO add a setting that sets the default (because Android Auto doesn't give use the prompt as an extra), or use the current order?
          );
        } else {
          _androidAutoHelperLogger.warning("No playlists found for query: ${enhancedQuery ?? searchQuery.rawQuery}");
        }
      } catch (e) {
        _androidAutoHelperLogger.warning("Couldn't search for playlists: $e");
      }
    }

    try {
      // first try with any metadata we could get (could be corrected based on metadata or localizations, or just the raw query)
      List<BaseItemDto>? searchResult = await _getResults(
        searchTerm: searchTerm,
        itemTypes: [itemType].nonNulls.toList(),
      );

      if (searchResult == null || searchResult.isEmpty) {
        _androidAutoHelperLogger.warning("No search results found for search term: $searchTerm)");

        if (enhancedQuery != null) {
          // if we got additional metadata, we already tried searching with it
          // now try searching with the raw query
          searchResult = await _getResults(
            searchTerm: searchQuery.rawQuery.trim(),
            itemTypes: [itemType].nonNulls.toList(),
          );
        }

        if (searchResult == null || searchResult.isEmpty) {
          _androidAutoHelperLogger.warning(
            "No search results found for search term (raw query): ${searchQuery.rawQuery}",
          );
          return;
        }
      }

      final selectedResult = searchResult.firstWhere((element) {
        if (itemType == ContentType.tracks.itemType && searchQuery.extras?["android.intent.extra.artist"] != null) {
          return element.albumArtists?.any(
                (artist) =>
                    (artist.name?.isNotEmpty ?? false) &&
                    (searchQuery.extras?["android.intent.extra.artist"]?.toString().toLowerCase().contains(
                          artist.name?.toLowerCase() ?? "",
                        ) ??
                        false),
              ) ??
              false;
        } else if (itemType == ContentType.tracks.itemType &&
            searchQuery.extras?["android.intent.extra.artist"] != null) {
          return element.albumArtists?.any(
                (artist) =>
                    (artist.name?.isNotEmpty ?? false) &&
                    (searchQuery.extras?["android.intent.extra.artist"]?.toString().toLowerCase().contains(
                          artist.name?.toLowerCase() ?? "",
                        ) ??
                        false),
              ) ??
              false;
        } else {
          return false;
        }
      }, orElse: () => searchResult![0]);

      _androidAutoHelperLogger.info("Playing from search: ${selectedResult.name}");

      // Todo how to handle selecting tracks - just do instant mix?  search downloads?
      final slice = await _container.read(
        getPlayableSliceProvider(item: FinampPlayableDto.fromItem(selectedResult), startingOffset: 0).future,
      );
      return _queueService.startSlicePlayback(slice);
    } catch (err) {
      _androidAutoHelperLogger.severe("Error while playing from search query: $err");
    }
  }

  Future<List<BaseItemDto>> _searchTracks(AndroidAutoSearchQuery searchQuery, {int limit = 20}) async {
    List<BaseItemDto>? searchResult;

    // search for exact query first, then search for adjusted query
    // sometimes Google's adjustment might not be what we want, but sometimes it actually helps
    List<BaseItemDto>? searchResultExactQuery;
    List<BaseItemDto>? searchResultAdjustedQuery;
    try {
      searchResultExactQuery = await _getResults(
        searchTerm: searchQuery.rawQuery.trim(),
        itemTypes: [ContentType.tracks.itemType].nonNulls.toList(),
        limit: searchQuery.extras?["android.intent.extra.title"] != null ? (limit / 2).round() : limit,
      );
    } catch (e) {
      _androidAutoHelperLogger.severe("Error while searching for exact query:", e);
    }
    if (searchQuery.extras?["android.intent.extra.title"] != null) {
      try {
        searchResultAdjustedQuery = await _getResults(
          searchTerm: (searchQuery.extras!["android.intent.extra.title"] as String).trim(),
          itemTypes: [ContentType.tracks.itemType].nonNulls.toList(),
          limit: limit - (searchResultExactQuery?.length ?? 0),
        );
      } catch (e) {
        _androidAutoHelperLogger.severe("Error while searching for adjusted query:", e);
      }
    }

    searchResult = searchResultExactQuery?.followedBy(searchResultAdjustedQuery ?? []).toList() ?? [];

    final List<BaseItemDto> filteredSearchResults = [];
    // filter out duplicates
    for (final item in searchResult) {
      if (!filteredSearchResults.any((element) => element.id == item.id)) {
        filteredSearchResults.add(item);
      }
    }

    if (searchResult.isEmpty) {
      _androidAutoHelperLogger.warning(
        "No search results found for query: ${searchQuery.rawQuery} (extras: ${searchQuery.extras})",
      );
    }

    int calculateMatchQuality(BaseItemDto item, AndroidAutoSearchQuery searchQuery) {
      final title = item.name ?? "";

      final wantedTitle = searchQuery.extras?["android.intent.extra.title"]?.toString().trim();
      final wantedArtist = searchQuery.extras?["android.intent.extra.artist"]?.toString().trim();

      if (title.toLowerCase() == searchQuery.rawQuery.toLowerCase() ||
          wantedArtist != null &&
              (item.albumArtists?.any(
                    (artist) =>
                        (artist.name?.isNotEmpty ?? false) &&
                        wantedArtist.toString().toLowerCase().contains(artist.name?.toLowerCase() ?? ""),
                  ) ??
                  false)) {
        // Title matches exactly or artist matches, highest priority
        return 1;
      } else if (title == wantedTitle) {
        // Title matches, normal priority
        return 0;
      } else {
        // No exact match, lower priority
        return -1;
      }
    }

    // sort items based on match quality with extras
    filteredSearchResults.sort((a, b) {
      final aMatchQuality = calculateMatchQuality(a, searchQuery);
      final bMatchQuality = calculateMatchQuality(b, searchQuery);
      return bMatchQuality.compareTo(aMatchQuality);
    });

    return filteredSearchResults;
  }

  Future<List<BaseItemDto>> _searchAlbums(AndroidAutoSearchQuery searchQuery, {int limit = 20}) async {
    List<BaseItemDto>? searchResult;

    bool hasAlbumMetadata = searchQuery.extras?["android.intent.extra.album"] != null;

    // search for exact query first, then search for adjusted query
    // sometimes Google's adjustment might not be what we want, but sometimes it actually helps
    List<BaseItemDto>? searchResultExactQuery;
    List<BaseItemDto>? searchResultAdjustedQuery;
    try {
      searchResultExactQuery = await _getResults(
        searchTerm: searchQuery.rawQuery.trim(),
        itemTypes: [ContentType.albums.itemType].nonNulls.toList(),
        limit: hasAlbumMetadata ? (limit / 2).round() : limit,
      );
    } catch (e) {
      _androidAutoHelperLogger.severe("Error while searching for exact query:", e);
    }
    if (hasAlbumMetadata) {
      try {
        searchResultAdjustedQuery = await _getResults(
          searchTerm: (searchQuery.extras!["android.intent.extra.album"] as String).trim(),
          itemTypes: [ContentType.albums.itemType].nonNulls.toList(),
          limit: limit - (searchResultExactQuery?.length ?? 0),
        );
      } catch (e) {
        _androidAutoHelperLogger.severe("Error while searching for adjusted query:", e);
      }
    }

    searchResult = searchResultExactQuery?.followedBy(searchResultAdjustedQuery ?? []).toList() ?? [];

    final List<BaseItemDto> filteredSearchResults = [];
    // filter out duplicates
    for (final item in searchResult) {
      if (!filteredSearchResults.any((element) => element.id == item.id)) {
        filteredSearchResults.add(item);
      }
    }

    if (searchResult.isEmpty) {
      _androidAutoHelperLogger.warning(
        "No search results found for query: ${searchQuery.rawQuery} (extras: ${searchQuery.extras})",
      );
    }

    int calculateMatchQuality(BaseItemDto item, AndroidAutoSearchQuery searchQuery) {
      final title = item.name ?? "";

      final wantedAlbum = searchQuery.extras?["android.intent.extra.album"]?.toString().trim();
      final wantedArtist = searchQuery.extras?["android.intent.extra.artist"]?.toString().trim();

      if (title.toLowerCase() == searchQuery.rawQuery.toLowerCase() ||
          wantedArtist != null &&
              (item.albumArtists?.any(
                    (artist) =>
                        (artist.name?.isNotEmpty ?? false) &&
                        wantedArtist.toString().toLowerCase().contains(artist.name?.toLowerCase() ?? ""),
                  ) ??
                  false)) {
        // Title matches exactly or artist matches, highest priority
        return 1;
      } else if (title == wantedAlbum) {
        // Title matches, normal priority
        return 0;
      } else {
        // No exact match, lower priority
        return -1;
      }
    }

    // sort items based on match quality with extras
    filteredSearchResults.sort((a, b) {
      final aMatchQuality = calculateMatchQuality(a, searchQuery);
      final bMatchQuality = calculateMatchQuality(b, searchQuery);
      return bMatchQuality.compareTo(aMatchQuality);
    });

    return filteredSearchResults;
  }

  Future<List<BaseItemDto>> _searchPlaylists(AndroidAutoSearchQuery searchQuery, {int limit = 20}) async {
    List<BaseItemDto>? searchResult;

    bool hasPlaylistMetadata = searchQuery.extras?["android.intent.extra.playlist"] != null;

    // search for exact query first, then search for adjusted query
    // sometimes Google's adjustment might not be what we want, but sometimes it actually helps
    List<BaseItemDto>? searchResultExactQuery;
    List<BaseItemDto>? searchResultAdjustedQuery;
    try {
      searchResultExactQuery = await _getResults(
        searchTerm: searchQuery.rawQuery.trim(),
        itemTypes: [ContentType.playlists.itemType].nonNulls.toList(),
        limit: hasPlaylistMetadata ? (limit / 2).round() : limit,
      );
    } catch (e) {
      _androidAutoHelperLogger.severe("Error while searching for exact query:", e);
    }
    if (hasPlaylistMetadata) {
      try {
        searchResultAdjustedQuery = await _getResults(
          searchTerm: (searchQuery.extras!["android.intent.extra.playlist"] as String).trim(),
          itemTypes: [ContentType.playlists.itemType].nonNulls.toList(),
          limit: limit - (searchResultExactQuery?.length ?? 0),
        );
      } catch (e) {
        _androidAutoHelperLogger.severe("Error while searching for adjusted query:", e);
      }
    }

    searchResult = searchResultExactQuery?.followedBy(searchResultAdjustedQuery ?? []).toList() ?? [];

    final List<BaseItemDto> filteredSearchResults = [];
    // filter out duplicates
    for (final item in searchResult) {
      if (!filteredSearchResults.any((element) => element.id == item.id)) {
        filteredSearchResults.add(item);
      }
    }

    if (searchResult.isEmpty) {
      _androidAutoHelperLogger.warning(
        "No search results found for query: ${searchQuery.rawQuery} (extras: ${searchQuery.extras})",
      );
    }

    int calculateMatchQuality(BaseItemDto item, AndroidAutoSearchQuery searchQuery) {
      final title = item.name ?? "";

      final wantedPlaylist = searchQuery.extras?["android.intent.extra.playlist"]?.toString().trim();

      if (title.toLowerCase() == searchQuery.rawQuery.toLowerCase()) {
        // Title matches exactly, highest priority
        return 1;
      } else if (title == wantedPlaylist) {
        // Title matches metadata, normal priority
        return 0;
      } else {
        // No exact match, lower priority
        return -1;
      }
    }

    // sort items based on match quality with extras
    filteredSearchResults.sort((a, b) {
      final aMatchQuality = calculateMatchQuality(a, searchQuery);
      final bMatchQuality = calculateMatchQuality(b, searchQuery);
      return bMatchQuality.compareTo(aMatchQuality);
    });

    return filteredSearchResults;
  }

  Future<List<BaseItemDto>> _searchArtists(AndroidAutoSearchQuery searchQuery, {int limit = 20}) async {
    List<BaseItemDto>? searchResult;

    bool hasArtistMetadata = searchQuery.extras?["android.intent.extra.artist"] != null;

    // search for exact query first, then search for adjusted query
    // sometimes Google's adjustment might not be what we want, but sometimes it actually helps
    List<BaseItemDto>? searchResultExactQuery;
    List<BaseItemDto>? searchResultAdjustedQuery;
    try {
      searchResultExactQuery = await _getResults(
        searchTerm: searchQuery.rawQuery.trim(),
        itemTypes: [ContentType.albumArtists.itemType].nonNulls.toList(),
        limit: hasArtistMetadata ? (limit / 2).round() : limit,
      );
    } catch (e) {
      _androidAutoHelperLogger.severe("Error while searching for exact query:", e);
    }
    if (hasArtistMetadata) {
      try {
        searchResultAdjustedQuery = await _getResults(
          searchTerm: (searchQuery.extras!["android.intent.extra.artist"] as String).trim(),
          itemTypes: [ContentType.albumArtists.itemType].nonNulls.toList(),
          limit: limit - (searchResultExactQuery?.length ?? 0),
        );
      } catch (e) {
        _androidAutoHelperLogger.severe("Error while searching for adjusted query:", e);
      }
    }

    searchResult = searchResultExactQuery?.followedBy(searchResultAdjustedQuery ?? []).toList() ?? [];

    final List<BaseItemDto> filteredSearchResults = [];
    // filter out duplicates
    for (final item in searchResult) {
      if (!filteredSearchResults.any((element) => element.id == item.id)) {
        filteredSearchResults.add(item);
      }
    }

    if (searchResult.isEmpty) {
      _androidAutoHelperLogger.warning(
        "No search results found for query: ${searchQuery.rawQuery} (extras: ${searchQuery.extras})",
      );
    }

    int calculateMatchQuality(BaseItemDto item, AndroidAutoSearchQuery searchQuery) {
      final title = item.name ?? "";

      final wantedArtist = searchQuery.extras?["android.intent.extra.artist"]?.toString().trim();

      if (title.toLowerCase() == searchQuery.rawQuery.toLowerCase()) {
        // Title matches exactly, highest priority
        return 1;
      } else if (title == wantedArtist) {
        // Title matches, normal priority
        return 0;
      } else {
        // No exact match, lower priority
        return -1;
      }
    }

    // sort items based on match quality with extras
    filteredSearchResults.sort((a, b) {
      final aMatchQuality = calculateMatchQuality(a, searchQuery);
      final bMatchQuality = calculateMatchQuality(b, searchQuery);
      return bMatchQuality.compareTo(aMatchQuality);
    });

    return filteredSearchResults;
  }

  Future<List<BaseItemDto>> _searchGenres(AndroidAutoSearchQuery searchQuery, {int limit = 20}) async {
    List<BaseItemDto>? searchResult;

    bool hasGenreMetadata = searchQuery.extras?["android.intent.extra.genre"] != null;

    // search for exact query first, then search for adjusted query
    // sometimes Google's adjustment might not be what we want, but sometimes it actually helps
    List<BaseItemDto>? searchResultExactQuery;
    List<BaseItemDto>? searchResultAdjustedQuery;
    try {
      searchResultExactQuery = await _getResults(
        searchTerm: searchQuery.rawQuery.trim(),
        itemTypes: [ContentType.genres.itemType].nonNulls.toList(),
        limit: hasGenreMetadata ? (limit / 2).round() : limit,
      );
    } catch (e) {
      _androidAutoHelperLogger.severe("Error while searching for exact query:", e);
    }
    if (hasGenreMetadata) {
      try {
        searchResultAdjustedQuery = await _getResults(
          searchTerm: (searchQuery.extras!["android.intent.extra.genre"] as String).trim(),
          itemTypes: [ContentType.genres.itemType].nonNulls.toList(),
          limit: limit - (searchResultExactQuery?.length ?? 0),
        );
      } catch (e) {
        _androidAutoHelperLogger.severe("Error while searching for adjusted query:", e);
      }
    }

    searchResult = searchResultExactQuery?.followedBy(searchResultAdjustedQuery ?? []).toList() ?? [];

    final List<BaseItemDto> filteredSearchResults = [];
    // filter out duplicates
    for (final item in searchResult) {
      if (!filteredSearchResults.any((element) => element.id == item.id)) {
        filteredSearchResults.add(item);
      }
    }

    if (searchResult.isEmpty) {
      _androidAutoHelperLogger.warning(
        "No search results found for query: ${searchQuery.rawQuery} (extras: ${searchQuery.extras})",
      );
    }

    int calculateMatchQuality(BaseItemDto item, AndroidAutoSearchQuery searchQuery) {
      final title = item.name ?? "";

      final wantedGenre = searchQuery.extras?["android.intent.extra.genre"]?.toString().trim();

      if (title.toLowerCase() == searchQuery.rawQuery.toLowerCase()) {
        // Title matches exactly, highest priority
        return 1;
      } else if (title == wantedGenre) {
        // Title matches, normal priority
        return 0;
      } else {
        // No exact match, lower priority
        return -1;
      }
    }

    // sort items based on match quality with extras
    filteredSearchResults.sort((a, b) {
      final aMatchQuality = calculateMatchQuality(a, searchQuery);
      final bMatchQuality = calculateMatchQuality(b, searchQuery);
      return bMatchQuality.compareTo(aMatchQuality);
    });

    return filteredSearchResults;
  }

  Future<List<BaseItemDto>?> _getResults({
    required String searchTerm,
    required List<BaseItemDtoType> itemTypes,
    int limit = 25,
  }) async {
    final jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
    final finampUserHelper = GetIt.instance<FinampUserHelper>();
    List<BaseItemDto>? searchResult;

    if (FinampSettingsHelper.finampSettings.isOffline) {
      List<DownloadStub> offlineItems;

      if (itemTypes.first == ContentType.tracks.itemType) {
        // If we're on the tracks tab, just get all of the downloaded items
        // We should probably try to page this, at least if we are sorting by name
        offlineItems = await _downloadsService.getAllTracks(
          nameFilter: searchTerm,
          viewFilter: finampUserHelper.currentUser?.currentView?.id,
          nullableViewFilters: FinampSettingsHelper.finampSettings.showDownloadsWithUnknownLibrary,
          onlyFavorites: false,
        );
      } else {
        offlineItems = await _downloadsService.getAllCollections(
          nameFilter: searchTerm,
          includeItemTypes: itemTypes,
          fullyDownloaded: false,
          viewFilter: itemTypes.first == ContentType.albums.itemType
              ? finampUserHelper.currentUser?.currentView?.id
              : null,
          childViewFilter:
              (itemTypes.contains(ContentType.albums.itemType) && itemTypes.contains(ContentType.playlists.itemType))
              ? finampUserHelper.currentUser?.currentView?.id
              : null,
          nullableViewFilters:
              itemTypes.first == ContentType.albums.itemType &&
              FinampSettingsHelper.finampSettings.showDownloadsWithUnknownLibrary,
          onlyFavorites: false,
        );
      }
      searchResult = offlineItems.map((e) => e.baseItem).whereNotNull().toList();
    } else {
      if (itemTypes.first == BaseItemDtoType.artist) {
        searchResult = await jellyfinApiHelper.getArtists(
          parentItem: finampUserHelper.currentUser?.currentView,
          searchTerm: searchTerm,
          startIndex: 0,
          limit: limit,
        );
      } else {
        searchResult = await jellyfinApiHelper.getItems(
          parentItem: itemTypes.contains(BaseItemDtoType.playlist) ? null : finampUserHelper.currentUser?.currentView,
          includeItemTypes: itemTypes.map((type) => type.jellyfinName).join(","),
          searchTerm: searchTerm,
          startIndex: 0,
          limit: limit, // get more than the first result so we can filter using additional metadata
        );
      }
    }

    return searchResult;
  }

  // albums, playlists, and tracks should play when clicked
  // artists and genres have subcategories, so they should be browsable but not playable
  bool _isPlayable({BaseItemDto? item, ContentType? contentType}) {
    final tabContentType = ContentType.fromItemType(item?.type ?? contentType?.itemType?.jellyfinName ?? "Audio");
    return tabContentType == ContentType.albums ||
        tabContentType == ContentType.playlists ||
        tabContentType == ContentType.tracks;
  }
}

int _gridHint(ContentType contentType, AndroidAutoBrowsingMode viewType) {
  final hasChildren =
      contentType == ContentType.albums || contentType == ContentType.playlists || contentType == ContentType.tracks;
  return switch (viewType) {
    AndroidAutoBrowsingMode.list =>
      hasChildren ? AndroidContentStyle.categoryListItemHintValue : AndroidContentStyle.listItemHintValue,
    AndroidAutoBrowsingMode.letters => AndroidContentStyle.categoryListItemHintValue,
    AndroidAutoBrowsingMode.grid =>
      hasChildren ? AndroidContentStyle.categoryGridItemHintValue : AndroidContentStyle.gridItemHintValue,
  };
}

import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as path_helper;
import 'package:uuid/uuid.dart';

import '../services/finamp_settings_helper.dart';
import '../services/get_internal_song_dir.dart';
import 'jellyfin_models.dart';

part 'finamp_models.g.dart';

@HiveType(typeId: 8)
@collection
class FinampUser {
  FinampUser({
    required this.id,
    required this.baseUrl,
    required this.accessToken,
    required this.serverId,
    this.currentViewId,
    this.views = const {},
    this.isarId = Isar.autoIncrement,
  });

  @HiveField(0)
  String id;
  @HiveField(1)
  String baseUrl;
  @HiveField(2)
  String accessToken;
  @HiveField(3)
  String serverId;
  @HiveField(4)
  String? currentViewId;
  @ignore
  @HiveField(5)
  Map<String, BaseItemDto> views;

  Id isarId;
  String get isarViews => jsonEncode(views);
  set isarViews(String json) =>
      views = (jsonDecode(json) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, BaseItemDto.fromJson(v)));

  @ignore
  BaseItemDto? get currentView => views[currentViewId];
}

// These consts are so that we can easily keep the same default for
// FinampSettings's constructor and Hive's defaultValue.
const _songShuffleItemCountDefault = 250;
const _contentViewType = ContentViewType.list;
const _contentGridViewCrossAxisCountPortrait = 2;
const _contentGridViewCrossAxisCountLandscape = 3;
const _showTextOnGridView = true;
const _sleepTimerSeconds = 1800; // 30 Minutes
const _showCoverAsPlayerBackground = true;
const _hideSongArtistsIfSameAsAlbumArtists = true;
const _disableGesture = false;
const _showFastScroller = true;
const _bufferDurationSeconds = 50;
const _tabOrder = TabContentType.values;

@HiveType(typeId: 28)
class FinampSettings {
  FinampSettings({
    this.isOffline = false,
    this.shouldTranscode = false,
    this.transcodeBitrate = 320000,
    // downloadLocations is required since the other values can be created with
    // default values. create() is used to return a FinampSettings with
    // downloadLocations.
    required this.downloadLocations,
    this.androidStopForegroundOnPause = true,
    required this.showTabs,
    this.isFavourite = false,
    this.sortBy = SortBy.sortName,
    this.sortOrder = SortOrder.ascending,
    this.songShuffleItemCount = _songShuffleItemCountDefault,
    this.contentViewType = _contentViewType,
    this.contentGridViewCrossAxisCountPortrait =
        _contentGridViewCrossAxisCountPortrait,
    this.contentGridViewCrossAxisCountLandscape =
        _contentGridViewCrossAxisCountLandscape,
    this.showTextOnGridView = _showTextOnGridView,
    this.sleepTimerSeconds = _sleepTimerSeconds,
    required this.downloadLocationsMap,
    this.showCoverAsPlayerBackground = _showCoverAsPlayerBackground,
    this.hideSongArtistsIfSameAsAlbumArtists =
        _hideSongArtistsIfSameAsAlbumArtists,
    this.bufferDurationSeconds = _bufferDurationSeconds,
    required this.tabSortBy,
    required this.tabSortOrder,
    this.tabOrder = _tabOrder,
    this.hasCompletedBlurhashImageMigration = true,
    this.hasCompletedBlurhashImageMigrationIdFix = true,
    this.hasCompletedIsarDownloadsMigration = true,
  });

  @HiveField(0)
  bool isOffline;
  @HiveField(1)
  bool shouldTranscode;
  @HiveField(2)
  int transcodeBitrate;

  @Deprecated("Use downloadedLocationsMap instead")
  @HiveField(3)
  List<DownloadLocation> downloadLocations;

  @HiveField(4)
  bool androidStopForegroundOnPause;
  @HiveField(5)
  Map<TabContentType, bool> showTabs;

  /// Used to remember if the user has set their music screen to favourites
  /// mode.
  @HiveField(6)
  bool isFavourite;

  /// Current sort by setting.
  @Deprecated("Use per-tab sort by instead")
  @HiveField(7)
  SortBy sortBy;

  /// Current sort order setting.
  @Deprecated("Use per-tab sort order instead")
  @HiveField(8)
  SortOrder sortOrder;

  /// Amount of songs to get when shuffling songs.
  @HiveField(9, defaultValue: _songShuffleItemCountDefault)
  int songShuffleItemCount;

  /// The content view type used by the music screen.
  @HiveField(10, defaultValue: _contentViewType)
  ContentViewType contentViewType;

  /// Amount of grid tiles to use per-row when portrait.
  @HiveField(11, defaultValue: _contentGridViewCrossAxisCountPortrait)
  int contentGridViewCrossAxisCountPortrait;

  /// Amount of grid tiles to use per-row when landscape.
  @HiveField(12, defaultValue: _contentGridViewCrossAxisCountLandscape)
  int contentGridViewCrossAxisCountLandscape;

  /// Whether or not to show the text (title, artist etc) on the grid music
  /// screen.
  @HiveField(13, defaultValue: _showTextOnGridView)
  bool showTextOnGridView = _showTextOnGridView;

  /// The number of seconds to wait in a sleep timer. This is so that the app
  /// can remember the last duration. I'd use a Duration type here but Hive
  /// doesn't come with an adapter for it by default.
  @HiveField(14, defaultValue: _sleepTimerSeconds)
  int sleepTimerSeconds;

  @HiveField(15, defaultValue: {})
  Map<String, DownloadLocation> downloadLocationsMap;

  /// Whether or not to use blurred cover art as background on player screen.
  @HiveField(16, defaultValue: _showCoverAsPlayerBackground)
  bool showCoverAsPlayerBackground = _showCoverAsPlayerBackground;

  @HiveField(17, defaultValue: _hideSongArtistsIfSameAsAlbumArtists)
  bool hideSongArtistsIfSameAsAlbumArtists =
      _hideSongArtistsIfSameAsAlbumArtists;

  @HiveField(18, defaultValue: _bufferDurationSeconds)
  int bufferDurationSeconds;

  @HiveField(19, defaultValue: _disableGesture)
  bool disableGesture = _disableGesture;

  @HiveField(20, defaultValue: {})
  Map<TabContentType, SortBy> tabSortBy;

  @HiveField(21, defaultValue: {})
  Map<TabContentType, SortOrder> tabSortOrder;

  @HiveField(22, defaultValue: _tabOrder)
  List<TabContentType> tabOrder;

  @HiveField(23, defaultValue: false)
  bool hasCompletedBlurhashImageMigration;

  @HiveField(24, defaultValue: false)
  bool hasCompletedBlurhashImageMigrationIdFix;

  @HiveField(25, defaultValue: _showFastScroller)
  bool showFastScroller = _showFastScroller;

  @HiveField(26, defaultValue: false)
  bool hasCompletedIsarDownloadsMigration;

  static Future<FinampSettings> create() async {
    final internalSongDir = await getInternalSongDir();
    final downloadLocation = DownloadLocation.create(
      name: "Internal Storage",
      path: internalSongDir.path,
      useHumanReadableNames: false,
      deletable: false,
    );
    return FinampSettings(
      downloadLocations: [],
      // Create a map of TabContentType from TabContentType's values.
      showTabs: Map.fromEntries(
        TabContentType.values.map(
          (e) => MapEntry(e, true),
        ),
      ),
      downloadLocationsMap: {downloadLocation.id: downloadLocation},
      tabSortBy: {},
      tabSortOrder: {},
    );
  }

  /// Returns the DownloadLocation that is the internal song dir. See the
  /// description of the "deletable" property to see how this works. This can
  /// technically throw a StateError, but that should never happen™.
  DownloadLocation get internalSongDir =>
      downloadLocationsMap.values.firstWhere((element) => !element.deletable);

  Duration get bufferDuration => Duration(seconds: bufferDurationSeconds);

  set bufferDuration(Duration duration) =>
      bufferDurationSeconds = duration.inSeconds;

  SortBy getTabSortBy(TabContentType tabType) {
    return tabSortBy[tabType] ?? SortBy.sortName;
  }

  SortOrder getSortOrder(TabContentType tabType) {
    return tabSortOrder[tabType] ?? SortOrder.ascending;
  }

  bool get shouldRunBlurhashImageMigrationIdFix =>
      hasCompletedBlurhashImageMigration &&
      !hasCompletedBlurhashImageMigrationIdFix;
}

/// Custom storage locations for storing music.
@HiveType(typeId: 31)
class DownloadLocation {
  DownloadLocation(
      {required this.name,
      required this.path,
      required this.useHumanReadableNames,
      required this.deletable,
      required this.id});

  /// Human-readable name for the path (shown in settings)
  @HiveField(0)
  String name;

  /// The path. We store this as a string since it's easier to put into Hive.
  @HiveField(1)
  String path;

  /// If true, store songs using their actual names instead of Jellyfin item IDs.
  @HiveField(2)
  bool useHumanReadableNames;

  /// If true, the user can delete this storage location. It's a bit of a hack,
  /// but the only undeletable location is the internal storage dir, so we can
  /// use this value to get the internal song dir.
  @HiveField(3)
  bool deletable;

  /// Unique ID for the DownloadLocation. If this DownloadLocation was created
  /// before 0.6, it will be "0", very temporarily until it is changed on
  /// startup.
  @HiveField(4, defaultValue: "0")
  String id;

  /// Initialises a new DownloadLocation. id will be a UUID.
  static DownloadLocation create({
    required String name,
    required String path,
    required bool useHumanReadableNames,
    required bool deletable,
  }) {
    return DownloadLocation(
      name: name,
      path: path,
      useHumanReadableNames: useHumanReadableNames,
      deletable: deletable,
      id: const Uuid().v4(),
    );
  }
}

/// Class used in AddDownloadLocationScreen. Basically just a DownloadLocation
/// with nullable values. Shouldn't be used for actually storing download
/// locations.
class NewDownloadLocation {
  NewDownloadLocation({
    this.name,
    this.path,
    this.useHumanReadableNames,
    required this.deletable,
  });

  String? name;
  String? path;
  bool? useHumanReadableNames;
  bool deletable;
}

/// Supported tab types in MusicScreenTabView.
@HiveType(typeId: 36)
enum TabContentType {
  @HiveField(0)
  albums(BaseItemDtoType.album),
  @HiveField(1)
  artists(BaseItemDtoType.artist),
  @HiveField(2)
  playlists(BaseItemDtoType.playlist),
  @HiveField(3)
  genres(BaseItemDtoType.genre),
  @HiveField(4)
  songs(BaseItemDtoType.song);

  const TabContentType(this.itemType);

  final BaseItemDtoType itemType;

  /// Human-readable version of the [TabContentType]. For example, toString() on
  /// [TabContentType.songs], toString() would return "TabContentType.songs".
  /// With this function, the same input would return "Songs".
  @override
  @Deprecated("Use toLocalisedString when possible")
  String toString() => _humanReadableName(this);

  String toLocalisedString(BuildContext context) =>
      _humanReadableLocalisedName(this, context);

  String _humanReadableName(TabContentType tabContentType) {
    switch (tabContentType) {
      case TabContentType.songs:
        return "Songs";
      case TabContentType.albums:
        return "Albums";
      case TabContentType.artists:
        return "Artists";
      case TabContentType.genres:
        return "Genres";
      case TabContentType.playlists:
        return "Playlists";
    }
  }

  String _humanReadableLocalisedName(
      TabContentType tabContentType, BuildContext context) {
    switch (tabContentType) {
      case TabContentType.songs:
        return AppLocalizations.of(context)!.songs;
      case TabContentType.albums:
        return AppLocalizations.of(context)!.albums;
      case TabContentType.artists:
        return AppLocalizations.of(context)!.artists;
      case TabContentType.genres:
        return AppLocalizations.of(context)!.genres;
      case TabContentType.playlists:
        return AppLocalizations.of(context)!.playlists;
    }
  }
}

@HiveType(typeId: 39)
enum ContentViewType {
  @HiveField(0)
  list,
  @HiveField(1)
  grid;

  /// Human-readable version of this enum. I've written longer descriptions on
  /// enums like [TabContentType], and I can't be bothered to copy and paste it
  /// again.
  @override
  @Deprecated("Use toLocalisedString when possible")
  String toString() => _humanReadableName(this);

  String toLocalisedString(BuildContext context) =>
      _humanReadableLocalisedName(this, context);

  String _humanReadableName(ContentViewType contentViewType) {
    switch (contentViewType) {
      case ContentViewType.list:
        return "List";
      case ContentViewType.grid:
        return "Grid";
    }
  }

  String _humanReadableLocalisedName(
      ContentViewType contentViewType, BuildContext context) {
    switch (contentViewType) {
      case ContentViewType.list:
        return AppLocalizations.of(context)!.list;
      case ContentViewType.grid:
        return AppLocalizations.of(context)!.grid;
    }
  }
}

@HiveType(typeId: 3)
@JsonSerializable(
  explicitToJson: true,
  anyMap: true,
)
class DownloadedSong {
  DownloadedSong({
    required this.song,
    required this.mediaSourceInfo,
    required this.downloadId,
    required this.requiredBy,
    required this.path,
    required this.useHumanReadableNames,
    required this.viewId,
    this.isPathRelative = true,
    required this.downloadLocationId,
  });

  /// The Jellyfin item for the song
  @HiveField(0)
  BaseItemDto song;

  /// The media source info for the song (used to get file format)
  @HiveField(1)
  MediaSourceInfo mediaSourceInfo;

  /// The download ID of the song (for FlutterDownloader)
  @HiveField(2)
  String downloadId;

  /// The list of parent item IDs the item is downloaded for. If this is 0, the
  /// song should be deleted.
  @HiveField(3)
  List<String> requiredBy;

  /// The path of the song file. if [isPathRelative] is true, this will be a
  /// relative path from the song's DownloadLocation.
  @HiveField(4)
  String path;

  /// Whether or not the file is stored with a human readable name. We need this
  /// when deleting downloads, as we need to check for empty folders when
  /// deleting files with human readable names.
  @HiveField(5)
  bool useHumanReadableNames;

  /// The view that this download is in. Used for sorting in offline mode.
  @HiveField(6)
  String viewId;

  /// Whether or not [path] is relative.
  @HiveField(7, defaultValue: false)
  bool isPathRelative;

  /// The ID of the DownloadLocation that holds this file. Will be null if made
  /// before 0.6.
  @HiveField(8)
  String? downloadLocationId;

  File get file {
    if (isPathRelative) {
      final downloadLocation = FinampSettingsHelper
          .finampSettings.downloadLocationsMap[downloadLocationId];

      if (downloadLocation == null) {
        throw "DownloadLocation was null in file getter for DownloadsSong!";
      }

      return File(path_helper.join(downloadLocation.path, path));
    }

    return File(path);
  }

  DownloadLocation? get downloadLocation => FinampSettingsHelper
      .finampSettings.downloadLocationsMap[downloadLocationId];

  factory DownloadedSong.fromJson(Map<String, dynamic> json) =>
      _$DownloadedSongFromJson(json);

  Map<String, dynamic> toJson() => _$DownloadedSongToJson(this);
}

@HiveType(typeId: 4)
class DownloadedParent {
  DownloadedParent({
    required this.item,
    required this.downloadedChildren,
    required this.viewId,
  });

  @HiveField(0)
  BaseItemDto item;
  @HiveField(1)
  Map<String, BaseItemDto> downloadedChildren;

  /// The view that this download is in. Used for sorting in offline mode.
  @HiveField(2)
  String viewId;
}

@HiveType(typeId: 40)
class DownloadedImage {
  DownloadedImage({
    required this.id,
    required this.downloadId,
    required this.path,
    required this.requiredBy,
    required this.downloadLocationId,
  });

  /// The image ID
  @HiveField(0)
  String id;

  /// The download ID of the song (for FlutterDownloader)
  @HiveField(1)
  String downloadId;

  /// The relative path to the image file. To get the absolute path, use the
  /// file getter.
  @HiveField(2)
  String path;

  /// The list of item IDs that use this image. If this is empty, the image
  /// should be deleted.
  /// TODO: Investigate adding set support to Hive
  @HiveField(3)
  List<String> requiredBy;

  /// The ID of the DownloadLocation that holds this file.
  @HiveField(4)
  String downloadLocationId;

  DownloadLocation? get downloadLocation => FinampSettingsHelper
      .finampSettings.downloadLocationsMap[downloadLocationId];

  File get file {
    if (downloadLocation == null) {
      throw "Download location is null for image $id, this shouldn't happen...";
    }

    return File(path_helper.join(downloadLocation!.path, path));
  }

  /// Creates a new DownloadedImage. Does not actually handle downloading or
  /// anything. This is only really a thing since having to manually specify
  /// empty lists is a bit jank.
  static DownloadedImage create({
    required String id,
    required String downloadId,
    required String path,
    List<String>? requiredBy,
    required String downloadLocationId,
  }) =>
      DownloadedImage(
        id: id,
        downloadId: downloadId,
        path: path,
        requiredBy: requiredBy ?? [],
        downloadLocationId: downloadLocationId,
      );
}

class DownloadStub {
  DownloadStub._build({
    required this.id,
    required this.type,
    required this.jsonItem,
    required this.isarId,
    required this.name,
    required this.baseItemType,
  }) {
    assert(_verifyEnums());
  }

  bool _verifyEnums() {
    switch (type) {
      case DownloadItemType.collectionDownload: // Fall down to collectionInfo
      case DownloadItemType.collectionInfo:
        return baseItem != null &&
            BaseItemDtoType.fromItem(baseItem!) == baseItemType &&
            baseItemType != BaseItemDtoType.song &&
            baseItemType != BaseItemDtoType.unknown;
      case DownloadItemType.song:
        return baseItemType == BaseItemDtoType.song &&
            baseItem != null &&
            BaseItemDtoType.fromItem(baseItem!) == baseItemType;
      case DownloadItemType.image:
        return baseItem != null;
      case DownloadItemType.anchor:
        return baseItem == null && baseItemType == BaseItemDtoType.unknown;
    }
  }

  factory DownloadStub.fromItem({
    required DownloadItemType type,
    required BaseItemDto item,
  }) {
    assert(type.requiresItem);
    assert(type != DownloadItemType.image || item.blurHash != null);
    String id = (type == DownloadItemType.image) ? item.blurHash! : item.id;
    return DownloadStub._build(
        id: id,
        isarId: getHash(id, type),
        jsonItem: jsonEncode(item.toJson()),
        type: type,
        name: (type == DownloadItemType.image)
            ? "Image for ${item.name}"
            : item.name ?? id,
        baseItemType: BaseItemDtoType.fromItem(item));
  }

  factory DownloadStub.fromId({
    required String id,
    required DownloadItemType type,
  }) {
    assert(!type.requiresItem);
    return DownloadStub._build(
        id: id,
        isarId: getHash(id, type),
        jsonItem: null,
        type: type,
        name: id,
        baseItemType: BaseItemDtoType.unknown);
  }

  final Id isarId;

  final String id;

  final String name;

  @Enumerated(EnumType.ordinal)
  final BaseItemDtoType baseItemType;

  @Enumerated(EnumType.ordinal)
  @Index()
  final DownloadItemType type;

  final String? jsonItem;

  @ignore
  BaseItemDto? get baseItem =>
      (jsonItem == null) ? null : BaseItemDto.fromJson(jsonDecode(jsonItem!));

  /// FNV-1a 64bit hash algorithm optimized for Dart Strings
  /// Provided by Isar documentation
  static int _fastHash(String string) {
    var hash = 0xcbf29ce484222325;

    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }

    return hash;
  }

  static int getHash(String id, DownloadItemType type) {
    return _fastHash(type.name + id);
  }

  @override
  bool operator ==(Object other) {
    return other is DownloadStub && other.isarId == isarId;
  }

  @override
  @ignore
  int get hashCode => isarId;

  // For use by IsarDownloads during database inserts.  Do not call directly.
  DownloadItem asItem(String? downloadLocationId) {
    return DownloadItem(
      id: id,
      type: type,
      jsonItem: jsonItem,
      isarId: isarId,
      jsonMediaSource: null,
      name: name,
      state: DownloadItemState.notDownloaded,
      downloadLocationId: downloadLocationId,
      baseItemType: baseItemType,
      baseIndexNumber: baseItem?.indexNumber,
      parentIndexNumber: baseItem?.parentIndexNumber,
      orderedChildren: null,
    );
  }
}

@collection
class DownloadItem extends DownloadStub {
  // For use by Isar.  Do not call directly.
  DownloadItem({
    required super.id,
    required super.type,
    required super.jsonItem,
    required super.isarId,
    required super.name,
    required super.baseItemType,
    required this.jsonMediaSource,
    required this.state,
    required this.downloadLocationId,
    required this.baseIndexNumber,
    required this.parentIndexNumber,
    required this.orderedChildren,
  }) : super._build();

  final requires = IsarLinks<DownloadItem>();

  @Backlink(to: "requires")
  final requiredBy = IsarLinks<DownloadItem>();

  // Do not update directly.  Use IsarDownloads _updateItemState.
  @Enumerated(EnumType.ordinal)
  DownloadItemState state;

  String? jsonMediaSource;

  final int? baseIndexNumber;
  final int? parentIndexNumber;
  List<int>? orderedChildren;

  @ignore
  MediaSourceInfo? get mediaSourceInfo => (jsonMediaSource == null)
      ? null
      : MediaSourceInfo.fromJson(jsonDecode(jsonMediaSource!));

  set mediaSourceInfo(MediaSourceInfo? info) {
    jsonMediaSource = jsonEncode(info?.toJson());
  }

  String? path;

  String? downloadLocationId;

  @ignore
  DownloadLocation? get downloadLocation => FinampSettingsHelper
      .finampSettings.downloadLocationsMap[downloadLocationId];

  @ignore
  File get file {
    if (downloadLocation == null) {
      throw "Download location is null for item $id, this shouldn't happen...";
    }

    return File(path_helper.join(downloadLocation!.path, path));
  }

  @override
  String toString() {
    return "$runtimeType ${type.name} '$name'";
  }
}

// Enumerated by Isar, do not modify existing entries
enum DownloadItemType {
  collectionDownload(true, false),
  collectionInfo(true, false),
  song(true, true),
  image(true, true),
  anchor(false, false);

  const DownloadItemType(this.requiresItem, this.hasFiles);

  final bool requiresItem;
  final bool hasFiles;
}

// Enumerated by Isar, do not modify existing entries
enum DownloadItemState {
  notDownloaded,
  downloading,
  failed,
  complete,
  enqueued;

  static DownloadItemState fromTaskStatus(TaskStatus status) {
    return switch (status) {
      TaskStatus.enqueued => DownloadItemState.enqueued,
      TaskStatus.running => DownloadItemState.downloading,
      TaskStatus.complete => DownloadItemState.complete,
      TaskStatus.failed => DownloadItemState.failed,
      TaskStatus.canceled => DownloadItemState.failed,
      TaskStatus.paused => DownloadItemState.failed, // pausing is not enabled
      TaskStatus.notFound => DownloadItemState.failed,
      TaskStatus.waitingToRetry => DownloadItemState.downloading,
    };
  }
}

// TODO merge into DownloadItemType?  Or keep separate?
// Enumerated by Isar, do not modify existing entries
enum BaseItemDtoType {
  album("MusicAlbum"),
  artist("MusicArtist"),
  playlist("Playlist"),
  genre("MusicGenre"),
  song("Audio"),
  unknown(null);

  const BaseItemDtoType(this.idString);

  final String? idString;

  static BaseItemDtoType fromItem(BaseItemDto item) {
    switch (item.type) {
      case "Audio":
        return song;
      case "MusicAlbum":
        return album;
      case "MusicArtist":
        return artist;
      case "MusicGenre":
        return genre;
      case "Playlist":
        return playlist;
      default:
        return unknown;
    }
  }
}

@collection
class DownloadStatusSummary {
  final Id id = 0;
  int downloading = 0;
  int failed = 0;
  int complete = 0;
  int enqueued = 0;
  set(DownloadItemState state, int value) => _update(state, (_) => value);
  update(DownloadItemState oldState, DownloadItemState newState,
      {int count = 1}) {
    _update(oldState, (x) => x - count);
    _update(newState, (x) => x + count);
  }

  _update(DownloadItemState state, int Function(int) func) {
    switch (state) {
      case DownloadItemState.notDownloaded:
        break;
      case DownloadItemState.downloading:
        downloading = func(downloading);
      case DownloadItemState.failed:
        failed = func(failed);
      case DownloadItemState.complete:
        complete = func(complete);
      case DownloadItemState.enqueued:
        enqueued = func(enqueued);
    }
  }

  int get total => downloading + failed + complete + enqueued;
}

@HiveType(typeId: 43)
class OfflineListen {
  OfflineListen({
    required this.timestamp,
    required this.userId,
    required this.itemId,
    required this.name,
    this.artist,
    this.album,
    this.trackMbid,
  });

  /// The stop timestamp of the listen, measured in seconds since the epoch.
  @HiveField(0)
  int timestamp;

  @HiveField(1)
  String userId;

  @HiveField(2)
  String itemId;

  @HiveField(3)
  String name;

  @HiveField(4)
  String? artist;

  @HiveField(5)
  String? album;

  // The MusicBrainz ID of the track, if available.
  @HiveField(6)
  String? trackMbid;
}

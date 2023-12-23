// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finamp_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FinampUserAdapter extends TypeAdapter<FinampUser> {
  @override
  final int typeId = 8;

  @override
  FinampUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinampUser(
      id: fields[0] as String,
      baseUrl: fields[1] as String,
      accessToken: fields[2] as String,
      serverId: fields[3] as String,
      currentViewId: fields[4] as String?,
      views: (fields[5] as Map).cast<String, BaseItemDto>(),
    );
  }

  @override
  void write(BinaryWriter writer, FinampUser obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.baseUrl)
      ..writeByte(2)
      ..write(obj.accessToken)
      ..writeByte(3)
      ..write(obj.serverId)
      ..writeByte(4)
      ..write(obj.currentViewId)
      ..writeByte(5)
      ..write(obj.views);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinampUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FinampSettingsAdapter extends TypeAdapter<FinampSettings> {
  @override
  final int typeId = 28;

  @override
  FinampSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FinampSettings(
      isOffline: fields[0] as bool,
      shouldTranscode: fields[1] as bool,
      transcodeBitrate: fields[2] as int,
      downloadLocations: (fields[3] as List).cast<DownloadLocation>(),
      androidStopForegroundOnPause: fields[4] as bool,
      showTabs: (fields[5] as Map).cast<TabContentType, bool>(),
      isFavourite: fields[6] as bool,
      sortBy: fields[7] as SortBy,
      sortOrder: fields[8] as SortOrder,
      songShuffleItemCount: fields[9] == null ? 250 : fields[9] as int,
      contentViewType: fields[10] == null
          ? ContentViewType.list
          : fields[10] as ContentViewType,
      contentGridViewCrossAxisCountPortrait:
          fields[11] == null ? 2 : fields[11] as int,
      contentGridViewCrossAxisCountLandscape:
          fields[12] == null ? 3 : fields[12] as int,
      showTextOnGridView: fields[13] == null ? true : fields[13] as bool,
      sleepTimerSeconds: fields[14] == null ? 1800 : fields[14] as int,
      downloadLocationsMap: fields[15] == null
          ? {}
          : (fields[15] as Map).cast<String, DownloadLocation>(),
      showCoverAsPlayerBackground:
          fields[16] == null ? true : fields[16] as bool,
      hideSongArtistsIfSameAsAlbumArtists:
          fields[17] == null ? true : fields[17] as bool,
      bufferDurationSeconds: fields[18] == null ? 50 : fields[18] as int,
      tabSortBy: fields[20] == null
          ? {}
          : (fields[20] as Map).cast<TabContentType, SortBy>(),
      tabSortOrder: fields[21] == null
          ? {}
          : (fields[21] as Map).cast<TabContentType, SortOrder>(),
      tabOrder: fields[22] == null
          ? [
              TabContentType.albums,
              TabContentType.artists,
              TabContentType.playlists,
              TabContentType.genres,
              TabContentType.songs
            ]
          : (fields[22] as List).cast<TabContentType>(),
      hasCompletedBlurhashImageMigration:
          fields[23] == null ? false : fields[23] as bool,
      hasCompletedBlurhashImageMigrationIdFix:
          fields[24] == null ? false : fields[24] as bool,
      hasCompletedIsarDownloadsMigration:
          fields[26] == null ? false : fields[26] as bool,
    )
      ..disableGesture = fields[19] == null ? false : fields[19] as bool
      ..showFastScroller = fields[25] == null ? true : fields[25] as bool;
  }

  @override
  void write(BinaryWriter writer, FinampSettings obj) {
    writer
      ..writeByte(27)
      ..writeByte(0)
      ..write(obj.isOffline)
      ..writeByte(1)
      ..write(obj.shouldTranscode)
      ..writeByte(2)
      ..write(obj.transcodeBitrate)
      ..writeByte(3)
      ..write(obj.downloadLocations)
      ..writeByte(4)
      ..write(obj.androidStopForegroundOnPause)
      ..writeByte(5)
      ..write(obj.showTabs)
      ..writeByte(6)
      ..write(obj.isFavourite)
      ..writeByte(7)
      ..write(obj.sortBy)
      ..writeByte(8)
      ..write(obj.sortOrder)
      ..writeByte(9)
      ..write(obj.songShuffleItemCount)
      ..writeByte(10)
      ..write(obj.contentViewType)
      ..writeByte(11)
      ..write(obj.contentGridViewCrossAxisCountPortrait)
      ..writeByte(12)
      ..write(obj.contentGridViewCrossAxisCountLandscape)
      ..writeByte(13)
      ..write(obj.showTextOnGridView)
      ..writeByte(14)
      ..write(obj.sleepTimerSeconds)
      ..writeByte(15)
      ..write(obj.downloadLocationsMap)
      ..writeByte(16)
      ..write(obj.showCoverAsPlayerBackground)
      ..writeByte(17)
      ..write(obj.hideSongArtistsIfSameAsAlbumArtists)
      ..writeByte(18)
      ..write(obj.bufferDurationSeconds)
      ..writeByte(19)
      ..write(obj.disableGesture)
      ..writeByte(20)
      ..write(obj.tabSortBy)
      ..writeByte(21)
      ..write(obj.tabSortOrder)
      ..writeByte(22)
      ..write(obj.tabOrder)
      ..writeByte(23)
      ..write(obj.hasCompletedBlurhashImageMigration)
      ..writeByte(24)
      ..write(obj.hasCompletedBlurhashImageMigrationIdFix)
      ..writeByte(25)
      ..write(obj.showFastScroller)
      ..writeByte(26)
      ..write(obj.hasCompletedIsarDownloadsMigration);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinampSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadLocationAdapter extends TypeAdapter<DownloadLocation> {
  @override
  final int typeId = 31;

  @override
  DownloadLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadLocation(
      name: fields[0] as String,
      path: fields[1] as String,
      useHumanReadableNames: fields[2] as bool,
      deletable: fields[3] as bool,
      id: fields[4] == null ? '0' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadLocation obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.path)
      ..writeByte(2)
      ..write(obj.useHumanReadableNames)
      ..writeByte(3)
      ..write(obj.deletable)
      ..writeByte(4)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadedSongAdapter extends TypeAdapter<DownloadedSong> {
  @override
  final int typeId = 3;

  @override
  DownloadedSong read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedSong(
      song: fields[0] as BaseItemDto,
      mediaSourceInfo: fields[1] as MediaSourceInfo,
      downloadId: fields[2] as String,
      requiredBy: (fields[3] as List).cast<String>(),
      path: fields[4] as String,
      useHumanReadableNames: fields[5] as bool,
      viewId: fields[6] as String,
      isPathRelative: fields[7] == null ? false : fields[7] as bool,
      downloadLocationId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedSong obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.song)
      ..writeByte(1)
      ..write(obj.mediaSourceInfo)
      ..writeByte(2)
      ..write(obj.downloadId)
      ..writeByte(3)
      ..write(obj.requiredBy)
      ..writeByte(4)
      ..write(obj.path)
      ..writeByte(5)
      ..write(obj.useHumanReadableNames)
      ..writeByte(6)
      ..write(obj.viewId)
      ..writeByte(7)
      ..write(obj.isPathRelative)
      ..writeByte(8)
      ..write(obj.downloadLocationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedSongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadedParentAdapter extends TypeAdapter<DownloadedParent> {
  @override
  final int typeId = 4;

  @override
  DownloadedParent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedParent(
      item: fields[0] as BaseItemDto,
      downloadedChildren: (fields[1] as Map).cast<String, BaseItemDto>(),
      viewId: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedParent obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.item)
      ..writeByte(1)
      ..write(obj.downloadedChildren)
      ..writeByte(2)
      ..write(obj.viewId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedParentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DownloadedImageAdapter extends TypeAdapter<DownloadedImage> {
  @override
  final int typeId = 40;

  @override
  DownloadedImage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DownloadedImage(
      id: fields[0] as String,
      downloadId: fields[1] as String,
      path: fields[2] as String,
      requiredBy: (fields[3] as List).cast<String>(),
      downloadLocationId: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DownloadedImage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.downloadId)
      ..writeByte(2)
      ..write(obj.path)
      ..writeByte(3)
      ..write(obj.requiredBy)
      ..writeByte(4)
      ..write(obj.downloadLocationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadedImageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OfflineListenAdapter extends TypeAdapter<OfflineListen> {
  @override
  final int typeId = 43;

  @override
  OfflineListen read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineListen(
      timestamp: fields[0] as int,
      userId: fields[1] as String,
      itemId: fields[2] as String,
      name: fields[3] as String,
      artist: fields[4] as String?,
      album: fields[5] as String?,
      trackMbid: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineListen obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.itemId)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.artist)
      ..writeByte(5)
      ..write(obj.album)
      ..writeByte(6)
      ..write(obj.trackMbid);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineListenAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TabContentTypeAdapter extends TypeAdapter<TabContentType> {
  @override
  final int typeId = 36;

  @override
  TabContentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TabContentType.albums;
      case 1:
        return TabContentType.artists;
      case 2:
        return TabContentType.playlists;
      case 3:
        return TabContentType.genres;
      case 4:
        return TabContentType.songs;
      default:
        return TabContentType.albums;
    }
  }

  @override
  void write(BinaryWriter writer, TabContentType obj) {
    switch (obj) {
      case TabContentType.albums:
        writer.writeByte(0);
        break;
      case TabContentType.artists:
        writer.writeByte(1);
        break;
      case TabContentType.playlists:
        writer.writeByte(2);
        break;
      case TabContentType.genres:
        writer.writeByte(3);
        break;
      case TabContentType.songs:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TabContentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentViewTypeAdapter extends TypeAdapter<ContentViewType> {
  @override
  final int typeId = 39;

  @override
  ContentViewType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ContentViewType.list;
      case 1:
        return ContentViewType.grid;
      default:
        return ContentViewType.list;
    }
  }

  @override
  void write(BinaryWriter writer, ContentViewType obj) {
    switch (obj) {
      case ContentViewType.list:
        writer.writeByte(0);
        break;
      case ContentViewType.grid:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentViewTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFinampUserCollection on Isar {
  IsarCollection<FinampUser> get finampUsers => this.collection();
}

const FinampUserSchema = CollectionSchema(
  name: r'FinampUser',
  id: -4140083613547586279,
  properties: {
    r'accessToken': PropertySchema(
      id: 0,
      name: r'accessToken',
      type: IsarType.string,
    ),
    r'baseUrl': PropertySchema(
      id: 1,
      name: r'baseUrl',
      type: IsarType.string,
    ),
    r'currentViewId': PropertySchema(
      id: 2,
      name: r'currentViewId',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'isarViews': PropertySchema(
      id: 4,
      name: r'isarViews',
      type: IsarType.string,
    ),
    r'serverId': PropertySchema(
      id: 5,
      name: r'serverId',
      type: IsarType.string,
    )
  },
  estimateSize: _finampUserEstimateSize,
  serialize: _finampUserSerialize,
  deserialize: _finampUserDeserialize,
  deserializeProp: _finampUserDeserializeProp,
  idName: r'isarId',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _finampUserGetId,
  getLinks: _finampUserGetLinks,
  attach: _finampUserAttach,
  version: '3.1.0+1',
);

int _finampUserEstimateSize(
  FinampUser object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.accessToken.length * 3;
  bytesCount += 3 + object.baseUrl.length * 3;
  {
    final value = object.currentViewId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  bytesCount += 3 + object.isarViews.length * 3;
  bytesCount += 3 + object.serverId.length * 3;
  return bytesCount;
}

void _finampUserSerialize(
  FinampUser object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.accessToken);
  writer.writeString(offsets[1], object.baseUrl);
  writer.writeString(offsets[2], object.currentViewId);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.isarViews);
  writer.writeString(offsets[5], object.serverId);
}

FinampUser _finampUserDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FinampUser(
    accessToken: reader.readString(offsets[0]),
    baseUrl: reader.readString(offsets[1]),
    currentViewId: reader.readStringOrNull(offsets[2]),
    id: reader.readString(offsets[3]),
    isarId: id,
    serverId: reader.readString(offsets[5]),
  );
  object.isarViews = reader.readString(offsets[4]);
  return object;
}

P _finampUserDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _finampUserGetId(FinampUser object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _finampUserGetLinks(FinampUser object) {
  return [];
}

void _finampUserAttach(IsarCollection<dynamic> col, Id id, FinampUser object) {
  object.isarId = id;
}

extension FinampUserQueryWhereSort
    on QueryBuilder<FinampUser, FinampUser, QWhere> {
  QueryBuilder<FinampUser, FinampUser, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FinampUserQueryWhere
    on QueryBuilder<FinampUser, FinampUser, QWhereClause> {
  QueryBuilder<FinampUser, FinampUser, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FinampUserQueryFilter
    on QueryBuilder<FinampUser, FinampUser, QFilterCondition> {
  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'accessToken',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'accessToken',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'accessToken',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'accessToken',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      accessTokenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'accessToken',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> baseUrlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      baseUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> baseUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> baseUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> baseUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'baseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> baseUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'baseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> baseUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'baseUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> baseUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'baseUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> baseUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      baseUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'baseUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'currentViewId',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'currentViewId',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentViewId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentViewId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentViewId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentViewId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'currentViewId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'currentViewId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'currentViewId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'currentViewId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentViewId',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      currentViewIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'currentViewId',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarViewsEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarViews',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      isarViewsGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarViews',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarViewsLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarViews',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarViewsBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarViews',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      isarViewsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'isarViews',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarViewsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'isarViews',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarViewsContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'isarViews',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> isarViewsMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'isarViews',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      isarViewsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarViews',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      isarViewsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'isarViews',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> serverIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      serverIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> serverIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> serverIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'serverId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      serverIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> serverIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> serverIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'serverId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition> serverIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'serverId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      serverIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'serverId',
        value: '',
      ));
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterFilterCondition>
      serverIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'serverId',
        value: '',
      ));
    });
  }
}

extension FinampUserQueryObject
    on QueryBuilder<FinampUser, FinampUser, QFilterCondition> {}

extension FinampUserQueryLinks
    on QueryBuilder<FinampUser, FinampUser, QFilterCondition> {}

extension FinampUserQuerySortBy
    on QueryBuilder<FinampUser, FinampUser, QSortBy> {
  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByAccessToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessToken', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByAccessTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessToken', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByBaseUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseUrl', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByBaseUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseUrl', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByCurrentViewId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentViewId', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByCurrentViewIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentViewId', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByIsarViews() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarViews', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByIsarViewsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarViews', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> sortByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }
}

extension FinampUserQuerySortThenBy
    on QueryBuilder<FinampUser, FinampUser, QSortThenBy> {
  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByAccessToken() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessToken', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByAccessTokenDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'accessToken', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByBaseUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseUrl', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByBaseUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseUrl', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByCurrentViewId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentViewId', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByCurrentViewIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentViewId', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByIsarViews() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarViews', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByIsarViewsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarViews', Sort.desc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByServerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.asc);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QAfterSortBy> thenByServerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverId', Sort.desc);
    });
  }
}

extension FinampUserQueryWhereDistinct
    on QueryBuilder<FinampUser, FinampUser, QDistinct> {
  QueryBuilder<FinampUser, FinampUser, QDistinct> distinctByAccessToken(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'accessToken', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QDistinct> distinctByBaseUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QDistinct> distinctByCurrentViewId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentViewId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QDistinct> distinctByIsarViews(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isarViews', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FinampUser, FinampUser, QDistinct> distinctByServerId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'serverId', caseSensitive: caseSensitive);
    });
  }
}

extension FinampUserQueryProperty
    on QueryBuilder<FinampUser, FinampUser, QQueryProperty> {
  QueryBuilder<FinampUser, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<FinampUser, String, QQueryOperations> accessTokenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'accessToken');
    });
  }

  QueryBuilder<FinampUser, String, QQueryOperations> baseUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseUrl');
    });
  }

  QueryBuilder<FinampUser, String?, QQueryOperations> currentViewIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentViewId');
    });
  }

  QueryBuilder<FinampUser, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FinampUser, String, QQueryOperations> isarViewsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarViews');
    });
  }

  QueryBuilder<FinampUser, String, QQueryOperations> serverIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverId');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDownloadItemCollection on Isar {
  IsarCollection<DownloadItem> get downloadItems => this.collection();
}

const DownloadItemSchema = CollectionSchema(
  name: r'DownloadItem',
  id: 3470061580579511306,
  properties: {
    r'baseIndexNumber': PropertySchema(
      id: 0,
      name: r'baseIndexNumber',
      type: IsarType.long,
    ),
    r'baseItemType': PropertySchema(
      id: 1,
      name: r'baseItemType',
      type: IsarType.byte,
      enumMap: _DownloadItembaseItemTypeEnumValueMap,
    ),
    r'downloadLocationId': PropertySchema(
      id: 2,
      name: r'downloadLocationId',
      type: IsarType.string,
    ),
    r'id': PropertySchema(
      id: 3,
      name: r'id',
      type: IsarType.string,
    ),
    r'jsonItem': PropertySchema(
      id: 4,
      name: r'jsonItem',
      type: IsarType.string,
    ),
    r'jsonMediaSource': PropertySchema(
      id: 5,
      name: r'jsonMediaSource',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'orderedChildren': PropertySchema(
      id: 7,
      name: r'orderedChildren',
      type: IsarType.longList,
    ),
    r'parentIndexNumber': PropertySchema(
      id: 8,
      name: r'parentIndexNumber',
      type: IsarType.long,
    ),
    r'path': PropertySchema(
      id: 9,
      name: r'path',
      type: IsarType.string,
    ),
    r'state': PropertySchema(
      id: 10,
      name: r'state',
      type: IsarType.byte,
      enumMap: _DownloadItemstateEnumValueMap,
    ),
    r'type': PropertySchema(
      id: 11,
      name: r'type',
      type: IsarType.byte,
      enumMap: _DownloadItemtypeEnumValueMap,
    )
  },
  estimateSize: _downloadItemEstimateSize,
  serialize: _downloadItemSerialize,
  deserialize: _downloadItemDeserialize,
  deserializeProp: _downloadItemDeserializeProp,
  idName: r'isarId',
  indexes: {
    r'type': IndexSchema(
      id: 5117122708147080838,
      name: r'type',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'type',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {
    r'requires': LinkSchema(
      id: 2869659933205985607,
      name: r'requires',
      target: r'DownloadItem',
      single: false,
    ),
    r'requiredBy': LinkSchema(
      id: 8162545016065706399,
      name: r'requiredBy',
      target: r'DownloadItem',
      single: false,
      linkName: r'requires',
    )
  },
  embeddedSchemas: {},
  getId: _downloadItemGetId,
  getLinks: _downloadItemGetLinks,
  attach: _downloadItemAttach,
  version: '3.1.0+1',
);

int _downloadItemEstimateSize(
  DownloadItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.downloadLocationId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.id.length * 3;
  {
    final value = object.jsonItem;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.jsonMediaSource;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.orderedChildren;
    if (value != null) {
      bytesCount += 3 + value.length * 8;
    }
  }
  {
    final value = object.path;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _downloadItemSerialize(
  DownloadItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.baseIndexNumber);
  writer.writeByte(offsets[1], object.baseItemType.index);
  writer.writeString(offsets[2], object.downloadLocationId);
  writer.writeString(offsets[3], object.id);
  writer.writeString(offsets[4], object.jsonItem);
  writer.writeString(offsets[5], object.jsonMediaSource);
  writer.writeString(offsets[6], object.name);
  writer.writeLongList(offsets[7], object.orderedChildren);
  writer.writeLong(offsets[8], object.parentIndexNumber);
  writer.writeString(offsets[9], object.path);
  writer.writeByte(offsets[10], object.state.index);
  writer.writeByte(offsets[11], object.type.index);
}

DownloadItem _downloadItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DownloadItem(
    baseIndexNumber: reader.readLongOrNull(offsets[0]),
    baseItemType: _DownloadItembaseItemTypeValueEnumMap[
            reader.readByteOrNull(offsets[1])] ??
        BaseItemDtoType.album,
    downloadLocationId: reader.readStringOrNull(offsets[2]),
    id: reader.readString(offsets[3]),
    isarId: id,
    jsonItem: reader.readStringOrNull(offsets[4]),
    jsonMediaSource: reader.readStringOrNull(offsets[5]),
    name: reader.readString(offsets[6]),
    orderedChildren: reader.readLongList(offsets[7]),
    parentIndexNumber: reader.readLongOrNull(offsets[8]),
    state: _DownloadItemstateValueEnumMap[reader.readByteOrNull(offsets[10])] ??
        DownloadItemState.notDownloaded,
    type: _DownloadItemtypeValueEnumMap[reader.readByteOrNull(offsets[11])] ??
        DownloadItemType.collectionDownload,
  );
  object.path = reader.readStringOrNull(offsets[9]);
  return object;
}

P _downloadItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (_DownloadItembaseItemTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          BaseItemDtoType.album) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLongList(offset)) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (_DownloadItemstateValueEnumMap[reader.readByteOrNull(offset)] ??
          DownloadItemState.notDownloaded) as P;
    case 11:
      return (_DownloadItemtypeValueEnumMap[reader.readByteOrNull(offset)] ??
          DownloadItemType.collectionDownload) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DownloadItembaseItemTypeEnumValueMap = {
  'album': 0,
  'artist': 1,
  'playlist': 2,
  'genre': 3,
  'song': 4,
  'unknown': 5,
};
const _DownloadItembaseItemTypeValueEnumMap = {
  0: BaseItemDtoType.album,
  1: BaseItemDtoType.artist,
  2: BaseItemDtoType.playlist,
  3: BaseItemDtoType.genre,
  4: BaseItemDtoType.song,
  5: BaseItemDtoType.unknown,
};
const _DownloadItemstateEnumValueMap = {
  'notDownloaded': 0,
  'downloading': 1,
  'failed': 2,
  'complete': 3,
  'enqueued': 4,
};
const _DownloadItemstateValueEnumMap = {
  0: DownloadItemState.notDownloaded,
  1: DownloadItemState.downloading,
  2: DownloadItemState.failed,
  3: DownloadItemState.complete,
  4: DownloadItemState.enqueued,
};
const _DownloadItemtypeEnumValueMap = {
  'collectionDownload': 0,
  'collectionInfo': 1,
  'song': 2,
  'image': 3,
  'anchor': 4,
};
const _DownloadItemtypeValueEnumMap = {
  0: DownloadItemType.collectionDownload,
  1: DownloadItemType.collectionInfo,
  2: DownloadItemType.song,
  3: DownloadItemType.image,
  4: DownloadItemType.anchor,
};

Id _downloadItemGetId(DownloadItem object) {
  return object.isarId;
}

List<IsarLinkBase<dynamic>> _downloadItemGetLinks(DownloadItem object) {
  return [object.requires, object.requiredBy];
}

void _downloadItemAttach(
    IsarCollection<dynamic> col, Id id, DownloadItem object) {
  object.requires
      .attach(col, col.isar.collection<DownloadItem>(), r'requires', id);
  object.requiredBy
      .attach(col, col.isar.collection<DownloadItem>(), r'requiredBy', id);
}

extension DownloadItemQueryWhereSort
    on QueryBuilder<DownloadItem, DownloadItem, QWhere> {
  QueryBuilder<DownloadItem, DownloadItem, QAfterWhere> anyIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhere> anyType() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'type'),
      );
    });
  }
}

extension DownloadItemQueryWhere
    on QueryBuilder<DownloadItem, DownloadItem, QWhereClause> {
  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> isarIdEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: isarId,
        upper: isarId,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> isarIdNotEqualTo(
      Id isarId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: isarId, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: isarId, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> isarIdGreaterThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: isarId, includeLower: include),
      );
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> isarIdLessThan(
      Id isarId,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: isarId, includeUpper: include),
      );
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> isarIdBetween(
    Id lowerIsarId,
    Id upperIsarId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerIsarId,
        includeLower: includeLower,
        upper: upperIsarId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> typeEqualTo(
      DownloadItemType type) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'type',
        value: [type],
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> typeNotEqualTo(
      DownloadItemType type) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [type],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'type',
              lower: [],
              upper: [type],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> typeGreaterThan(
    DownloadItemType type, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'type',
        lower: [type],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> typeLessThan(
    DownloadItemType type, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'type',
        lower: [],
        upper: [type],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterWhereClause> typeBetween(
    DownloadItemType lowerType,
    DownloadItemType upperType, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'type',
        lower: [lowerType],
        includeLower: includeLower,
        upper: [upperType],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadItemQueryFilter
    on QueryBuilder<DownloadItem, DownloadItem, QFilterCondition> {
  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseIndexNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'baseIndexNumber',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseIndexNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'baseIndexNumber',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseIndexNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseIndexNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseIndexNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseIndexNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseIndexNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseIndexNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseIndexNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseIndexNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseItemTypeEqualTo(BaseItemDtoType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'baseItemType',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseItemTypeGreaterThan(
    BaseItemDtoType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'baseItemType',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseItemTypeLessThan(
    BaseItemDtoType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'baseItemType',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      baseItemTypeBetween(
    BaseItemDtoType lower,
    BaseItemDtoType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'baseItemType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'downloadLocationId',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'downloadLocationId',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadLocationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloadLocationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloadLocationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloadLocationId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'downloadLocationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'downloadLocationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'downloadLocationId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'downloadLocationId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloadLocationId',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      downloadLocationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'downloadLocationId',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'id',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'id',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> idIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      idIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'id',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> isarIdEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      isarIdGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      isarIdLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'isarId',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> isarIdBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'isarId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'jsonItem',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'jsonItem',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jsonItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jsonItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jsonItem',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jsonItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jsonItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jsonItem',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jsonItem',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonItem',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonItemIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jsonItem',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'jsonMediaSource',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'jsonMediaSource',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonMediaSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'jsonMediaSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'jsonMediaSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'jsonMediaSource',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'jsonMediaSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'jsonMediaSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'jsonMediaSource',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'jsonMediaSource',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'jsonMediaSource',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      jsonMediaSourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'jsonMediaSource',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'orderedChildren',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'orderedChildren',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderedChildren',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenElementGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderedChildren',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenElementLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderedChildren',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderedChildren',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'orderedChildren',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'orderedChildren',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'orderedChildren',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'orderedChildren',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'orderedChildren',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      orderedChildrenLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'orderedChildren',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      parentIndexNumberIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentIndexNumber',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      parentIndexNumberIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentIndexNumber',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      parentIndexNumberEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentIndexNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      parentIndexNumberGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentIndexNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      parentIndexNumberLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentIndexNumber',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      parentIndexNumberBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentIndexNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> pathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'path',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      pathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'path',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> pathEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      pathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> pathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> pathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'path',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      pathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> pathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> pathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'path',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> pathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'path',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      pathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'path',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      pathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'path',
        value: '',
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> stateEqualTo(
      DownloadItemState value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'state',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      stateGreaterThan(
    DownloadItemState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'state',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> stateLessThan(
    DownloadItemState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'state',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> stateBetween(
    DownloadItemState lower,
    DownloadItemState upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'state',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> typeEqualTo(
      DownloadItemType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      typeGreaterThan(
    DownloadItemType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> typeLessThan(
    DownloadItemType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> typeBetween(
    DownloadItemType lower,
    DownloadItemType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadItemQueryObject
    on QueryBuilder<DownloadItem, DownloadItem, QFilterCondition> {}

extension DownloadItemQueryLinks
    on QueryBuilder<DownloadItem, DownloadItem, QFilterCondition> {
  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> requires(
      FilterQuery<DownloadItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'requires');
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiresLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requires', length, true, length, true);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiresIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requires', 0, true, 0, true);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiresIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requires', 0, false, 999999, true);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiresLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requires', 0, true, length, include);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiresLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requires', length, include, 999999, true);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiresLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'requires', lower, includeLower, upper, includeUpper);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition> requiredBy(
      FilterQuery<DownloadItem> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'requiredBy');
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiredByLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requiredBy', length, true, length, true);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiredByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requiredBy', 0, true, 0, true);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiredByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requiredBy', 0, false, 999999, true);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiredByLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requiredBy', 0, true, length, include);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiredByLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'requiredBy', length, include, 999999, true);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterFilterCondition>
      requiredByLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'requiredBy', lower, includeLower, upper, includeUpper);
    });
  }
}

extension DownloadItemQuerySortBy
    on QueryBuilder<DownloadItem, DownloadItem, QSortBy> {
  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByBaseIndexNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseIndexNumber', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByBaseIndexNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseIndexNumber', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByBaseItemType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseItemType', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByBaseItemTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseItemType', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByDownloadLocationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadLocationId', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByDownloadLocationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadLocationId', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByJsonItem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonItem', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByJsonItemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonItem', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByJsonMediaSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonMediaSource', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByJsonMediaSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonMediaSource', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByParentIndexNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentIndexNumber', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      sortByParentIndexNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentIndexNumber', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension DownloadItemQuerySortThenBy
    on QueryBuilder<DownloadItem, DownloadItem, QSortThenBy> {
  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByBaseIndexNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseIndexNumber', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByBaseIndexNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseIndexNumber', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByBaseItemType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseItemType', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByBaseItemTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'baseItemType', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByDownloadLocationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadLocationId', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByDownloadLocationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadLocationId', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByIsarId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByIsarIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isarId', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByJsonItem() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonItem', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByJsonItemDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonItem', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByJsonMediaSource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonMediaSource', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByJsonMediaSourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'jsonMediaSource', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByParentIndexNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentIndexNumber', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy>
      thenByParentIndexNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentIndexNumber', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'path', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'state', Sort.desc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }
}

extension DownloadItemQueryWhereDistinct
    on QueryBuilder<DownloadItem, DownloadItem, QDistinct> {
  QueryBuilder<DownloadItem, DownloadItem, QDistinct>
      distinctByBaseIndexNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseIndexNumber');
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct> distinctByBaseItemType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'baseItemType');
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct>
      distinctByDownloadLocationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadLocationId',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct> distinctById(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'id', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct> distinctByJsonItem(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jsonItem', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct> distinctByJsonMediaSource(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'jsonMediaSource',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct>
      distinctByOrderedChildren() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderedChildren');
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct>
      distinctByParentIndexNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentIndexNumber');
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct> distinctByPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'path', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct> distinctByState() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'state');
    });
  }

  QueryBuilder<DownloadItem, DownloadItem, QDistinct> distinctByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type');
    });
  }
}

extension DownloadItemQueryProperty
    on QueryBuilder<DownloadItem, DownloadItem, QQueryProperty> {
  QueryBuilder<DownloadItem, int, QQueryOperations> isarIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isarId');
    });
  }

  QueryBuilder<DownloadItem, int?, QQueryOperations> baseIndexNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseIndexNumber');
    });
  }

  QueryBuilder<DownloadItem, BaseItemDtoType, QQueryOperations>
      baseItemTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'baseItemType');
    });
  }

  QueryBuilder<DownloadItem, String?, QQueryOperations>
      downloadLocationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadLocationId');
    });
  }

  QueryBuilder<DownloadItem, String, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DownloadItem, String?, QQueryOperations> jsonItemProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jsonItem');
    });
  }

  QueryBuilder<DownloadItem, String?, QQueryOperations>
      jsonMediaSourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'jsonMediaSource');
    });
  }

  QueryBuilder<DownloadItem, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<DownloadItem, List<int>?, QQueryOperations>
      orderedChildrenProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderedChildren');
    });
  }

  QueryBuilder<DownloadItem, int?, QQueryOperations>
      parentIndexNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentIndexNumber');
    });
  }

  QueryBuilder<DownloadItem, String?, QQueryOperations> pathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'path');
    });
  }

  QueryBuilder<DownloadItem, DownloadItemState, QQueryOperations>
      stateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'state');
    });
  }

  QueryBuilder<DownloadItem, DownloadItemType, QQueryOperations>
      typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDownloadStatusSummaryCollection on Isar {
  IsarCollection<DownloadStatusSummary> get downloadStatusSummarys =>
      this.collection();
}

const DownloadStatusSummarySchema = CollectionSchema(
  name: r'DownloadStatusSummary',
  id: 2636317071542697149,
  properties: {
    r'complete': PropertySchema(
      id: 0,
      name: r'complete',
      type: IsarType.long,
    ),
    r'downloading': PropertySchema(
      id: 1,
      name: r'downloading',
      type: IsarType.long,
    ),
    r'enqueued': PropertySchema(
      id: 2,
      name: r'enqueued',
      type: IsarType.long,
    ),
    r'failed': PropertySchema(
      id: 3,
      name: r'failed',
      type: IsarType.long,
    ),
    r'total': PropertySchema(
      id: 4,
      name: r'total',
      type: IsarType.long,
    )
  },
  estimateSize: _downloadStatusSummaryEstimateSize,
  serialize: _downloadStatusSummarySerialize,
  deserialize: _downloadStatusSummaryDeserialize,
  deserializeProp: _downloadStatusSummaryDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _downloadStatusSummaryGetId,
  getLinks: _downloadStatusSummaryGetLinks,
  attach: _downloadStatusSummaryAttach,
  version: '3.1.0+1',
);

int _downloadStatusSummaryEstimateSize(
  DownloadStatusSummary object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _downloadStatusSummarySerialize(
  DownloadStatusSummary object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.complete);
  writer.writeLong(offsets[1], object.downloading);
  writer.writeLong(offsets[2], object.enqueued);
  writer.writeLong(offsets[3], object.failed);
  writer.writeLong(offsets[4], object.total);
}

DownloadStatusSummary _downloadStatusSummaryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DownloadStatusSummary();
  object.complete = reader.readLong(offsets[0]);
  object.downloading = reader.readLong(offsets[1]);
  object.enqueued = reader.readLong(offsets[2]);
  object.failed = reader.readLong(offsets[3]);
  return object;
}

P _downloadStatusSummaryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _downloadStatusSummaryGetId(DownloadStatusSummary object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _downloadStatusSummaryGetLinks(
    DownloadStatusSummary object) {
  return [];
}

void _downloadStatusSummaryAttach(
    IsarCollection<dynamic> col, Id id, DownloadStatusSummary object) {}

extension DownloadStatusSummaryQueryWhereSort
    on QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QWhere> {
  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DownloadStatusSummaryQueryWhere on QueryBuilder<DownloadStatusSummary,
    DownloadStatusSummary, QWhereClause> {
  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadStatusSummaryQueryFilter on QueryBuilder<
    DownloadStatusSummary, DownloadStatusSummary, QFilterCondition> {
  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> completeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'complete',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> completeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'complete',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> completeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'complete',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> completeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'complete',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> downloadingEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'downloading',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> downloadingGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'downloading',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> downloadingLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'downloading',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> downloadingBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'downloading',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> enqueuedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'enqueued',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> enqueuedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'enqueued',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> enqueuedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'enqueued',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> enqueuedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'enqueued',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> failedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'failed',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> failedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'failed',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> failedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'failed',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> failedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'failed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> totalEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> totalGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> totalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'total',
        value: value,
      ));
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary,
      QAfterFilterCondition> totalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'total',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DownloadStatusSummaryQueryObject on QueryBuilder<
    DownloadStatusSummary, DownloadStatusSummary, QFilterCondition> {}

extension DownloadStatusSummaryQueryLinks on QueryBuilder<DownloadStatusSummary,
    DownloadStatusSummary, QFilterCondition> {}

extension DownloadStatusSummaryQuerySortBy
    on QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QSortBy> {
  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'complete', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'complete', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByDownloading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloading', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByDownloadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloading', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByEnqueued() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueued', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByEnqueuedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueued', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }
}

extension DownloadStatusSummaryQuerySortThenBy
    on QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QSortThenBy> {
  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'complete', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByCompleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'complete', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByDownloading() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloading', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByDownloadingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloading', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByEnqueued() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueued', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByEnqueuedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueued', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByFailedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'failed', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QAfterSortBy>
      thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }
}

extension DownloadStatusSummaryQueryWhereDistinct
    on QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QDistinct> {
  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QDistinct>
      distinctByComplete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'complete');
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QDistinct>
      distinctByDownloading() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloading');
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QDistinct>
      distinctByEnqueued() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enqueued');
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QDistinct>
      distinctByFailed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'failed');
    });
  }

  QueryBuilder<DownloadStatusSummary, DownloadStatusSummary, QDistinct>
      distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }
}

extension DownloadStatusSummaryQueryProperty on QueryBuilder<
    DownloadStatusSummary, DownloadStatusSummary, QQueryProperty> {
  QueryBuilder<DownloadStatusSummary, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DownloadStatusSummary, int, QQueryOperations>
      completeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'complete');
    });
  }

  QueryBuilder<DownloadStatusSummary, int, QQueryOperations>
      downloadingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloading');
    });
  }

  QueryBuilder<DownloadStatusSummary, int, QQueryOperations>
      enqueuedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enqueued');
    });
  }

  QueryBuilder<DownloadStatusSummary, int, QQueryOperations> failedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'failed');
    });
  }

  QueryBuilder<DownloadStatusSummary, int, QQueryOperations> totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DownloadedSong _$DownloadedSongFromJson(Map json) => DownloadedSong(
      song:
          BaseItemDto.fromJson(Map<String, dynamic>.from(json['song'] as Map)),
      mediaSourceInfo: MediaSourceInfo.fromJson(
          Map<String, dynamic>.from(json['mediaSourceInfo'] as Map)),
      downloadId: json['downloadId'] as String,
      requiredBy: (json['requiredBy'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      path: json['path'] as String,
      useHumanReadableNames: json['useHumanReadableNames'] as bool,
      viewId: json['viewId'] as String,
      isPathRelative: json['isPathRelative'] as bool? ?? true,
      downloadLocationId: json['downloadLocationId'] as String?,
    );

Map<String, dynamic> _$DownloadedSongToJson(DownloadedSong instance) =>
    <String, dynamic>{
      'song': instance.song.toJson(),
      'mediaSourceInfo': instance.mediaSourceInfo.toJson(),
      'downloadId': instance.downloadId,
      'requiredBy': instance.requiredBy,
      'path': instance.path,
      'useHumanReadableNames': instance.useHumanReadableNames,
      'viewId': instance.viewId,
      'isPathRelative': instance.isPathRelative,
      'downloadLocationId': instance.downloadLocationId,
    };

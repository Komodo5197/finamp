// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: deprecated_member_use_from_same_package, strict_raw_type

// dart format off

part of 'music_screen_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PagedContent)
final pagedContentProvider = PagedContentFamily._();

final class PagedContentProvider<ChildType extends FinampDisplayableOrPlayable>
    extends
        $NotifierProvider<
          PagedContent<ChildType>,
          PagingState<int, ChildType>
        > {
  PagedContentProvider._({
    required PagedContentFamily super.from,
    required FinampDisplayable<ChildType> super.argument,
  }) : super(
         retry: null,
         name: r'pagedContentProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pagedContentHash();

  @override
  String toString() {
    return r'pagedContentProvider'
        '<${ChildType}>'
        '($argument)';
  }

  @$internal
  @override
  PagedContent<ChildType> create() => PagedContent<ChildType>();

  $R _captureGenerics<$R>(
    $R Function<ChildType extends FinampDisplayableOrPlayable>() cb,
  ) {
    return cb<ChildType>();
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PagingState<int, ChildType> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PagingState<int, ChildType>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PagedContentProvider &&
        other.runtimeType == runtimeType &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return Object.hash(runtimeType, argument);
  }
}

String _$pagedContentHash() => r'd7ad89dc3b1af76891de2ebc26ddc518c44a7e65';

final class PagedContentFamily extends $Family {
  PagedContentFamily._()
    : super(
        retry: null,
        name: r'pagedContentProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PagedContentProvider<ChildType>
  call<ChildType extends FinampDisplayableOrPlayable>(
    FinampDisplayable<ChildType> request,
  ) => PagedContentProvider<ChildType>._(argument: request, from: this);

  @override
  String toString() => r'pagedContentProvider';

  /// {@macro riverpod.override_with}
  Override overrideWith(
    PagedContent<ChildType>
    Function<ChildType extends FinampDisplayableOrPlayable>()
    create,
  ) => $FamilyOverride(
    from: this,
    createElement: (pointer) {
      final provider = pointer.origin as PagedContentProvider;
      return provider._captureGenerics(
        <ChildType extends FinampDisplayableOrPlayable>() {
          provider as PagedContentProvider<ChildType>;
          return provider
              .$view(create: create<ChildType>)
              .$createElement(pointer);
        },
      );
    },
  );

  /// {@macro riverpod.override_with_build}
  Override overrideWithBuild(
    PagingState<int, ChildType> Function<
      ChildType extends FinampDisplayableOrPlayable
    >(Ref ref, PagedContent<ChildType> notifier)
    build,
  ) => $FamilyOverride(
    from: this,
    createElement: (pointer) {
      final provider = pointer.origin as PagedContentProvider;
      return provider._captureGenerics(
        <ChildType extends FinampDisplayableOrPlayable>() {
          provider as PagedContentProvider<ChildType>;
          return provider
              .$view(runNotifierBuildOverride: build<ChildType>)
              .$createElement(pointer);
        },
      );
    },
  );
}

abstract class _$PagedContent<ChildType extends FinampDisplayableOrPlayable>
    extends $Notifier<PagingState<int, ChildType>> {
  late final _$args = ref.$arg as FinampDisplayable<ChildType>;
  FinampDisplayable<ChildType> get request => _$args;

  PagingState<int, ChildType> build(FinampDisplayable<ChildType> request);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<PagingState<int, ChildType>, PagingState<int, ChildType>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                PagingState<int, ChildType>,
                PagingState<int, ChildType>
              >,
              PagingState<int, ChildType>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(loadHomeSectionItems)
final loadHomeSectionItemsProvider = LoadHomeSectionItemsFamily._();

final class LoadHomeSectionItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BaseItemDto>?>,
          List<BaseItemDto>?,
          FutureOr<List<BaseItemDto>?>
        >
    with
        $FutureModifier<List<BaseItemDto>?>,
        $FutureProvider<List<BaseItemDto>?> {
  LoadHomeSectionItemsProvider._({
    required LoadHomeSectionItemsFamily super.from,
    required ({
      MusicScreenPlayable<FinampPlayableDto> request,
      int startIndex,
      int limit,
    })
    super.argument,
  }) : super(
         retry: null,
         name: r'loadHomeSectionItemsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loadHomeSectionItemsHash();

  @override
  String toString() {
    return r'loadHomeSectionItemsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BaseItemDto>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BaseItemDto>?> create(Ref ref) {
    final argument =
        this.argument
            as ({
              MusicScreenPlayable<FinampPlayableDto> request,
              int startIndex,
              int limit,
            });
    return loadHomeSectionItems(
      ref,
      request: argument.request,
      startIndex: argument.startIndex,
      limit: argument.limit,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LoadHomeSectionItemsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loadHomeSectionItemsHash() =>
    r'03d5a2113df428ecafabb89f08f4b1fa56f90de0';

final class LoadHomeSectionItemsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BaseItemDto>?>,
          ({
            MusicScreenPlayable<FinampPlayableDto> request,
            int startIndex,
            int limit,
          })
        > {
  LoadHomeSectionItemsFamily._()
    : super(
        retry: null,
        name: r'loadHomeSectionItemsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LoadHomeSectionItemsProvider call({
    required MusicScreenPlayable<FinampPlayableDto> request,
    required int startIndex,
    required int limit,
  }) => LoadHomeSectionItemsProvider._(
    argument: (request: request, startIndex: startIndex, limit: limit),
    from: this,
  );

  @override
  String toString() => r'loadHomeSectionItemsProvider';
}

@ProviderFor(getJellyfinCollection)
final getJellyfinCollectionProvider = GetJellyfinCollectionFamily._();

final class GetJellyfinCollectionProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BaseItemDto>?>,
          List<BaseItemDto>?,
          FutureOr<List<BaseItemDto>?>
        >
    with
        $FutureModifier<List<BaseItemDto>?>,
        $FutureProvider<List<BaseItemDto>?> {
  GetJellyfinCollectionProvider._({
    required GetJellyfinCollectionFamily super.from,
    required (BaseItemDto, SortAndFilterConfiguration) super.argument,
  }) : super(
         retry: null,
         name: r'getJellyfinCollectionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$getJellyfinCollectionHash();

  @override
  String toString() {
    return r'getJellyfinCollectionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<BaseItemDto>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BaseItemDto>?> create(Ref ref) {
    final argument = this.argument as (BaseItemDto, SortAndFilterConfiguration);
    return getJellyfinCollection(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is GetJellyfinCollectionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$getJellyfinCollectionHash() =>
    r'a0f53ba1d31000864d5a81b22ecc132f0bd99934';

final class GetJellyfinCollectionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<BaseItemDto>?>,
          (BaseItemDto, SortAndFilterConfiguration)
        > {
  GetJellyfinCollectionFamily._()
    : super(
        retry: null,
        name: r'getJellyfinCollectionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GetJellyfinCollectionProvider call(
    BaseItemDto collection,
    SortAndFilterConfiguration sortConfig,
  ) => GetJellyfinCollectionProvider._(
    argument: (collection, sortConfig),
    from: this,
  );

  @override
  String toString() => r'getJellyfinCollectionProvider';
}

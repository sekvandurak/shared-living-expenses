// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_activities_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupActivitiesHash() => r'df29aec367fba7edbcb62fa0468b1ea90b7c4b30';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$GroupActivities
    extends BuildlessAutoDisposeAsyncNotifier<List<ActivityModel>> {
  late final String groupId;

  FutureOr<List<ActivityModel>> build(
    String groupId,
  );
}

/// See also [GroupActivities].
@ProviderFor(GroupActivities)
const groupActivitiesProvider = GroupActivitiesFamily();

/// See also [GroupActivities].
class GroupActivitiesFamily extends Family<AsyncValue<List<ActivityModel>>> {
  /// See also [GroupActivities].
  const GroupActivitiesFamily();

  /// See also [GroupActivities].
  GroupActivitiesProvider call(
    String groupId,
  ) {
    return GroupActivitiesProvider(
      groupId,
    );
  }

  @override
  GroupActivitiesProvider getProviderOverride(
    covariant GroupActivitiesProvider provider,
  ) {
    return call(
      provider.groupId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'groupActivitiesProvider';
}

/// See also [GroupActivities].
class GroupActivitiesProvider extends AutoDisposeAsyncNotifierProviderImpl<
    GroupActivities, List<ActivityModel>> {
  /// See also [GroupActivities].
  GroupActivitiesProvider(
    String groupId,
  ) : this._internal(
          () => GroupActivities()..groupId = groupId,
          from: groupActivitiesProvider,
          name: r'groupActivitiesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupActivitiesHash,
          dependencies: GroupActivitiesFamily._dependencies,
          allTransitiveDependencies:
              GroupActivitiesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupActivitiesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  FutureOr<List<ActivityModel>> runNotifierBuild(
    covariant GroupActivities notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(GroupActivities Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupActivitiesProvider._internal(
        () => create()..groupId = groupId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<GroupActivities, List<ActivityModel>>
      createElement() {
    return _GroupActivitiesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupActivitiesProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin GroupActivitiesRef
    on AutoDisposeAsyncNotifierProviderRef<List<ActivityModel>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupActivitiesProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupActivities,
        List<ActivityModel>> with GroupActivitiesRef {
  _GroupActivitiesProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupActivitiesProvider).groupId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_balances_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupBalancesHash() => r'42130470bef10457ebec5581a710a5b52329bef4';

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

/// See also [groupBalances].
@ProviderFor(groupBalances)
const groupBalancesProvider = GroupBalancesFamily();

/// See also [groupBalances].
class GroupBalancesFamily extends Family<AsyncValue<List<DebtModel>>> {
  /// See also [groupBalances].
  const GroupBalancesFamily();

  /// See also [groupBalances].
  GroupBalancesProvider call(
    String groupId,
  ) {
    return GroupBalancesProvider(
      groupId,
    );
  }

  @override
  GroupBalancesProvider getProviderOverride(
    covariant GroupBalancesProvider provider,
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
  String? get name => r'groupBalancesProvider';
}

/// See also [groupBalances].
class GroupBalancesProvider extends AutoDisposeFutureProvider<List<DebtModel>> {
  /// See also [groupBalances].
  GroupBalancesProvider(
    String groupId,
  ) : this._internal(
          (ref) => groupBalances(
            ref as GroupBalancesRef,
            groupId,
          ),
          from: groupBalancesProvider,
          name: r'groupBalancesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupBalancesHash,
          dependencies: GroupBalancesFamily._dependencies,
          allTransitiveDependencies:
              GroupBalancesFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  GroupBalancesProvider._internal(
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
  Override overrideWith(
    FutureOr<List<DebtModel>> Function(GroupBalancesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: GroupBalancesProvider._internal(
        (ref) => create(ref as GroupBalancesRef),
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
  AutoDisposeFutureProviderElement<List<DebtModel>> createElement() {
    return _GroupBalancesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupBalancesProvider && other.groupId == groupId;
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
mixin GroupBalancesRef on AutoDisposeFutureProviderRef<List<DebtModel>> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _GroupBalancesProviderElement
    extends AutoDisposeFutureProviderElement<List<DebtModel>>
    with GroupBalancesRef {
  _GroupBalancesProviderElement(super.provider);

  @override
  String get groupId => (origin as GroupBalancesProvider).groupId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

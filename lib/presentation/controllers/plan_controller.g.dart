// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$planRepositoryHash() => r'da9b229b5c80069040c1307b232691848c38c1d7';

/// See also [planRepository].
@ProviderFor(planRepository)
final planRepositoryProvider = AutoDisposeProvider<PlanRepository>.internal(
  planRepository,
  name: r'planRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$planRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PlanRepositoryRef = AutoDisposeProviderRef<PlanRepository>;
String _$currentPlanHash() => r'd004fc75c1e3e51201f9c2689fc71267a5130103';

/// See also [currentPlan].
@ProviderFor(currentPlan)
final currentPlanProvider = AutoDisposeFutureProvider<Plan?>.internal(
  currentPlan,
  name: r'currentPlanProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentPlanHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentPlanRef = AutoDisposeFutureProviderRef<Plan?>;
String _$planByIdHash() => r'9b0c016a8e5902bfeb05da6d51469d445f6b4a1b';

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

/// See also [planById].
@ProviderFor(planById)
const planByIdProvider = PlanByIdFamily();

/// See also [planById].
class PlanByIdFamily extends Family<AsyncValue<Plan?>> {
  /// See also [planById].
  const PlanByIdFamily();

  /// See also [planById].
  PlanByIdProvider call(
    String planId,
  ) {
    return PlanByIdProvider(
      planId,
    );
  }

  @override
  PlanByIdProvider getProviderOverride(
    covariant PlanByIdProvider provider,
  ) {
    return call(
      provider.planId,
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
  String? get name => r'planByIdProvider';
}

/// See also [planById].
class PlanByIdProvider extends AutoDisposeFutureProvider<Plan?> {
  /// See also [planById].
  PlanByIdProvider(
    String planId,
  ) : this._internal(
          (ref) => planById(
            ref as PlanByIdRef,
            planId,
          ),
          from: planByIdProvider,
          name: r'planByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$planByIdHash,
          dependencies: PlanByIdFamily._dependencies,
          allTransitiveDependencies: PlanByIdFamily._allTransitiveDependencies,
          planId: planId,
        );

  PlanByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.planId,
  }) : super.internal();

  final String planId;

  @override
  Override overrideWith(
    FutureOr<Plan?> Function(PlanByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PlanByIdProvider._internal(
        (ref) => create(ref as PlanByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        planId: planId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Plan?> createElement() {
    return _PlanByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanByIdProvider && other.planId == planId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, planId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PlanByIdRef on AutoDisposeFutureProviderRef<Plan?> {
  /// The parameter `planId` of this provider.
  String get planId;
}

class _PlanByIdProviderElement extends AutoDisposeFutureProviderElement<Plan?>
    with PlanByIdRef {
  _PlanByIdProviderElement(super.provider);

  @override
  String get planId => (origin as PlanByIdProvider).planId;
}

String _$allPlansHash() => r'508442bcf6cca0ac0fb9cbf06f77db800ec3e71a';

/// See also [allPlans].
@ProviderFor(allPlans)
final allPlansProvider = AutoDisposeFutureProvider<List<Plan>>.internal(
  allPlans,
  name: r'allPlansProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allPlansHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AllPlansRef = AutoDisposeFutureProviderRef<List<Plan>>;
String _$plansByTrainerHash() => r'ea475ea31144d4b6336be80a9e656718079c5a6b';

/// See also [plansByTrainer].
@ProviderFor(plansByTrainer)
const plansByTrainerProvider = PlansByTrainerFamily();

/// See also [plansByTrainer].
class PlansByTrainerFamily extends Family<AsyncValue<List<Plan>>> {
  /// See also [plansByTrainer].
  const PlansByTrainerFamily();

  /// See also [plansByTrainer].
  PlansByTrainerProvider call(
    String trainerId,
  ) {
    return PlansByTrainerProvider(
      trainerId,
    );
  }

  @override
  PlansByTrainerProvider getProviderOverride(
    covariant PlansByTrainerProvider provider,
  ) {
    return call(
      provider.trainerId,
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
  String? get name => r'plansByTrainerProvider';
}

/// See also [plansByTrainer].
class PlansByTrainerProvider extends AutoDisposeFutureProvider<List<Plan>> {
  /// See also [plansByTrainer].
  PlansByTrainerProvider(
    String trainerId,
  ) : this._internal(
          (ref) => plansByTrainer(
            ref as PlansByTrainerRef,
            trainerId,
          ),
          from: plansByTrainerProvider,
          name: r'plansByTrainerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$plansByTrainerHash,
          dependencies: PlansByTrainerFamily._dependencies,
          allTransitiveDependencies:
              PlansByTrainerFamily._allTransitiveDependencies,
          trainerId: trainerId,
        );

  PlansByTrainerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.trainerId,
  }) : super.internal();

  final String trainerId;

  @override
  Override overrideWith(
    FutureOr<List<Plan>> Function(PlansByTrainerRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PlansByTrainerProvider._internal(
        (ref) => create(ref as PlansByTrainerRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        trainerId: trainerId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Plan>> createElement() {
    return _PlansByTrainerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PlansByTrainerProvider && other.trainerId == trainerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, trainerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PlansByTrainerRef on AutoDisposeFutureProviderRef<List<Plan>> {
  /// The parameter `trainerId` of this provider.
  String get trainerId;
}

class _PlansByTrainerProviderElement
    extends AutoDisposeFutureProviderElement<List<Plan>>
    with PlansByTrainerRef {
  _PlansByTrainerProviderElement(super.provider);

  @override
  String get trainerId => (origin as PlansByTrainerProvider).trainerId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

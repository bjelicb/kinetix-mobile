// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminRepositoryHash() => r'8b2bd63dd63c763ad2a09e248feef7fac3fe8daf';

/// See also [adminRepository].
@ProviderFor(adminRepository)
final adminRepositoryProvider = AutoDisposeProvider<AdminRepository>.internal(
  adminRepository,
  name: r'adminRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AdminRepositoryRef = AutoDisposeProviderRef<AdminRepository>;
String _$adminControllerHash() => r'2715e8ef06a4e1a019e036c04750807d638843e8';

/// See also [AdminController].
@ProviderFor(AdminController)
final adminControllerProvider = AutoDisposeAsyncNotifierProvider<
    AdminController, Map<String, dynamic>>.internal(
  AdminController.new,
  name: r'adminControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AdminController = AutoDisposeAsyncNotifier<Map<String, dynamic>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

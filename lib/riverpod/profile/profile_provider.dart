import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http_parser/http_parser.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/riverpod/general/image_cropper_provider.dart';
import 'package:kronk/riverpod/general/update_data_provider.dart';
import 'package:kronk/screens/user/profile_screen.dart';
import 'package:kronk/services/api_service/user_service.dart';
import 'package:kronk/utility/classes.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
import 'package:tuple/tuple.dart';

final profileNotifierProvider = AutoDisposeAsyncNotifierProviderFamily<ProfileNotifier, UserModel, String?>(ProfileNotifier.new);

class ProfileNotifier extends AutoDisposeFamilyAsyncNotifier<UserModel, String?> {
  late Connectivity _connectivity;
  late Storage _storage;
  late UserService _userService;

  @override
  Future<UserModel> build(String? targetUserId) async {
    _connectivity = Connectivity();
    _storage = Storage();
    _userService = UserService();

    ref.onDispose(() => myLogger.f('onDispose in profileNotifierProvider'));
    ref.onCancel(() => myLogger.f('onDispose in onCancel'));

    try {
      return await _fetchProfile(targetUserId: targetUserId);
    } catch (error) {
      myLogger.e('Error in build: $error');
      rethrow;
    }
  }

  Future<UserModel> _fetchProfile({String? targetUserId}) async {
    try {
      List<ConnectivityResult> initialResults = await _connectivity.checkConnectivity();
      bool isOnline = initialResults.any((ConnectivityResult result) => result != ConnectivityResult.none);

      if (!isOnline) {
        final UserModel? user = _storage.getUser();
        if (user == null) throw Exception('You are not authenticated');
        return user;
      }
      final UserModel user = await _userService.fetchGetProfile(targetUserId: targetUserId);

      // await _storage.setUserAsync(user: user);
      return user;
    } catch (error, stacktrace) {
      myLogger.e('Unexpected error in _fetchProfile: $error \nStacktrace: $stacktrace');
      rethrow;
    }
  }

  Future<UserModel> refresh({String? targetUserId}) async {
    state = const AsyncValue.loading();

    try {
      final UserModel user = await _fetchProfile(targetUserId: targetUserId);
      state = await AsyncValue.guard(() async => user);
      return user;
    } catch (error) {
      myLogger.e('Error in refresh: $error');
      rethrow;
    }
  }

  void updateField({required UserModel user}) {
    state = AsyncData(user);
  }

  Future<void> toggleFollow({required String userId}) async {
    final currentState = state;
    if (currentState is! AsyncData<UserModel>) return;

    final currentUser = currentState.value;
    if (currentUser.isFollowing == null) return; // Own profile

    final isNowFollowing = !(currentUser.isFollowing ?? false);
    final updatedUser = currentUser.copyWith(isFollowing: isNowFollowing, followersCount: isNowFollowing ? currentUser.followersCount + 1 : currentUser.followersCount - 1);

    state = AsyncData(updatedUser);

    try {
      final ok = isNowFollowing ? await _userService.fetchFollow(followingId: userId) : await _userService.fetchUnfollow(followingId: userId);

      if (!ok) {
        state = AsyncData(currentUser);
      }
    } catch (error, stackTrace) {
      state = AsyncData(currentUser);
      myLogger.e('Error in toggleFollow', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> updateProfile({required UserModel user, required UpdateModel updateData, required ImageCropperState imageCropperState}) async {
    myLogger.i('croppedAvatarBytes?.length: ${imageCropperState.croppedAvatarBytes?.length}');
    myLogger.i('croppedBannerBytes?.length: ${imageCropperState.croppedBannerBytes?.length}');
    myLogger.i('updateData.toJson(): ${updateData.toJson(user: user)}');

    final Map<String, dynamic> data = updateData.toJson(user: user);
    UserModel updatedUser = user;

    if (data.isNotEmpty) {
      final bool ok = await _userService.fetchUpdateProfile(data: data);
      if (ok) {
        updatedUser = user.fromMap(data: data);
        state = AsyncData(updatedUser);
        ref.read(sharedUser.notifier).state = updatedUser;
        ref.read(updateDataNotifierProvider.notifier).updateField(user: const UpdateModel());
      }
    }

    Map<String, dynamic> map = {};
    if (imageCropperState.croppedAvatarBytes != null) {
      map['avatar_file'] = MultipartFile.fromBytes(
        imageCropperState.croppedAvatarBytes!.toList(),
        filename: imageCropperState.pickedAvatarName,
        contentType: MediaType.parse(imageCropperState.pickedAvatarMimeType ?? 'image/jpeg'),
      );
    }
    if (imageCropperState.croppedBannerBytes != null) {
      map['banner_file'] = MultipartFile.fromBytes(
        imageCropperState.croppedBannerBytes!.toList(),
        filename: imageCropperState.pickedBannerName,
        contentType: MediaType.parse(imageCropperState.pickedBannerMimeType ?? 'image/jpeg'),
      );
    }

    if (map.isNotEmpty) {
      final Tuple2<String?, String?> results = await _userService.fetchUpdateProfileImage(formData: FormData.fromMap(map));

      updatedUser = updatedUser.copyWith(avatarUrl: results.item1, bannerUrl: results.item2);

      state = AsyncData(updatedUser);
      ref.read(sharedUser.notifier).state = updatedUser;
      ref.invalidate(imageCropperNotifierProvider);
    }
  }

  Future<void> deleteAccount() async {
    final bool ok = await _userService.fetchDeleteProfile();
    myLogger.d('🔨 ok: $ok');

    if (ok) {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      User? firebaseUser = firebaseAuth.currentUser;

      try {
        final GoogleSignInAccount googleSignInAccount = await googleSignIn.authenticate();

        final GoogleSignInAuthentication googleAuth = googleSignInAccount.authentication;
        AuthCredential authCredential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

        await firebaseUser?.reauthenticateWithCredential(authCredential);
      } catch (e) {
        log('💀 Error during user deletion: $e');
        return;
      }

      await firebaseUser?.delete();
    }
  }

  Future<void> logoutUser() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
    log('🔨 googleSignInAccount in logoutUser');
  }
}

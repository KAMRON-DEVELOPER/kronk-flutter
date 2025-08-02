import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:kronk/constants/enums.dart';
import 'package:kronk/constants/my_theme.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/services/api_service/user_service.dart';
import 'package:kronk/utility/classes.dart';
import 'package:tuple/tuple.dart';

class Storage {
  final Box<NavbarModel?> navbarBox;
  final Box<UserModel?> userBox;
  final Box settingsBox;

  Storage() : navbarBox = Hive.box<NavbarModel>('navbarBox'), userBox = Hive.box<UserModel>('userBox'), settingsBox = Hive.box('settingsBox');

  Future<void> initializeNavbar({bool force = false}) async {
    // route, isComingSoon, isPlanned
    final List<Tuple3<String, bool, bool>> services = [
      const Tuple3<String, bool, bool>('/feeds', false, false),
      const Tuple3<String, bool, bool>('/search', false, false),
      const Tuple3<String, bool, bool>('/chats', false, false),
      const Tuple3<String, bool, bool>('/education', false, true),
      const Tuple3<String, bool, bool>('/notes', false, false),
      const Tuple3<String, bool, bool>('/todos', false, true),
      const Tuple3<String, bool, bool>('/video_player', false, true),
      const Tuple3<String, bool, bool>('/music_player', false, true),
      const Tuple3<String, bool, bool>('/cloud_storage', false, true),
      const Tuple3<String, bool, bool>('/vocabulary', false, false),
      const Tuple3<String, bool, bool>('/translator', false, true),
      const Tuple3<String, bool, bool>('/jobs', false, false),
      const Tuple3<String, bool, bool>('/shop', false, true),
      const Tuple3<String, bool, bool>('/profile', false, false),
    ];
    final List<NavbarModel> defaultServices = services
        .map((Tuple3<String, bool, bool> service) => NavbarModel(route: service.item1, isComingSoon: service.item2, isPlanned: service.item3))
        .toList();

    if (!force && navbarBox.isNotEmpty) return;
    if (force) await navbarBox.clear();
    await navbarBox.addAll(defaultServices);
  }

  List<NavbarModel> getNavbarItems() => navbarBox.values.cast<NavbarModel>().toList();

  Future<void> updateNavbarItemOrder({required int oldIndex, required int newIndex}) async {
    List<NavbarModel> navbarItems = getNavbarItems();

    final NavbarModel reorderedItem = navbarItems.removeAt(oldIndex);
    navbarItems.insert(newIndex, reorderedItem);

    await navbarBox.clear();
    await navbarBox.addAll(navbarItems);
  }

  String getRoute() {
    final enabledServices = navbarBox.values.whereType<NavbarModel>().where((NavbarModel navbarItem) => navbarItem.isEnabled).toList();
    return enabledServices.first.route;
  }

  Future<String> getRouteAsync() async {
    final Tuple2<String?, bool> verifyTokenStatus = await getVerifyTokenAsync();
    final String? verifyToken = verifyTokenStatus.item1;
    final bool isExpiredVerifyToken = verifyTokenStatus.item2;
    if (verifyToken != null && !isExpiredVerifyToken) return '/auth/verify';

    final Tuple2<String?, bool> resetPasswordTokenStatus = await forgotPasswordTokenAsync();
    final String? forgotPasswordToken = resetPasswordTokenStatus.item1;
    final bool isExpiredForgotPasswordToken = resetPasswordTokenStatus.item2;
    if (forgotPasswordToken != null && !isExpiredForgotPasswordToken) return '/auth/forgot_password';

    final bool isDoneWelcome = settingsBox.get('isDoneWelcome', defaultValue: false);
    if (!isDoneWelcome) return '/welcome';

    final bool isDoneSettings = settingsBox.get('isDoneSettings', defaultValue: false);
    if (!isDoneSettings) return '/settings';

    return getRoute();
  }

  UserModel? getUser() => userBox.get('user');

  Future<void> setUserAsync({required UserModel user}) async => await userBox.put('user', user);

  Future<String?> getAccessTokenAsync() async {
    String? accessToken = await settingsBox.get('access_token');
    if (accessToken == null) return null;

    final bool isExpiredAccessToken = JwtDecoder.isExpired(accessToken);
    if (isExpiredAccessToken) {
      UserService service = UserService();
      final String? refreshToken = await getRefreshTokenAsync();
      if (refreshToken == null) return null;

      Duration refreshTokenRemainingTime = JwtDecoder.getRemainingTime(refreshToken);
      final int hasEnoughTime = refreshTokenRemainingTime.compareTo(const Duration(days: 10)); // if expired -1, if equal 0, if greater 1
      if (hasEnoughTime < 0) {
        Response? response = await service.fetchRefreshTokens(refreshToken: refreshToken);

        if (response != null && response.statusCode == 200) {
          await settingsBox.putAll({...response.data});
          accessToken = response.data['access_token'];
        }
      }

      Response? response = await service.fetchAccessTokens(refreshToken: refreshToken);
      if (response != null && response.statusCode == 200) {
        accessToken = response.data['access_token'];
        await settingsBox.put('access_token', accessToken);
      }
    }

    return accessToken;
  }

  Future<String?> getRefreshTokenAsync() async {
    final String? refreshToken = await settingsBox.get('refresh_token');
    if (refreshToken == null) return null;
    final bool isExpiredRefreshToken = JwtDecoder.isExpired(refreshToken);
    return isExpiredRefreshToken ? null : refreshToken;
  }

  Future<Tuple2<String?, bool>> getVerifyTokenAsync() async {
    final String? verifyToken = await settingsBox.get('verify_token');
    final bool isExpiredVerifyToken = await _isExpired('verify_token_expiration_date');
    return Tuple2(isExpiredVerifyToken ? null : verifyToken, isExpiredVerifyToken);
  }

  Future<Tuple2<String?, bool>> forgotPasswordTokenAsync() async {
    final String? verifyToken = await settingsBox.get('forgot_password_token');
    final bool isExpiredVerifyToken = await _isExpired('forgot_password_token_expiration_date');
    return Tuple2(isExpiredVerifyToken ? null : verifyToken, isExpiredVerifyToken);
  }

  Future<bool> _isExpired(String expirationKey) async {
    final String? expirationDate = await settingsBox.get(expirationKey);

    if (expirationDate == null) return true;
    final DateTime? parsedDate = DateTime.tryParse(expirationDate);
    if (parsedDate == null) return true;
    return parsedDate.isBefore(DateTime.now());
  }

  dynamic getSettings({required String key, dynamic defaultValue}) => settingsBox.get(key, defaultValue: defaultValue);

  void setSettingsAll(Map<String, dynamic> keysValues) => settingsBox.putAll(keysValues);

  void deleteSettingsAll({required List<String> keys}) => settingsBox.deleteAll(keys);

  Future<dynamic> getSettingsAsync({required String key, dynamic defaultValue}) async => await settingsBox.get(key, defaultValue: defaultValue);

  Future<void> setSettingsAllAsync(Map<String, dynamic> data) async {
    for (final entry in data.entries) {
      await settingsBox.put(entry.key, entry.value);
    }
  }

  Future<void> deleteAsyncSettingsAll({required List<String> keys}) async => await settingsBox.deleteAll(keys);

  FeedScreenDisplayState getFeedScreenDisplayStyle() {
    final String feedScreenDisplayStyleName = settingsBox.get('feedScreenDisplayStyle', defaultValue: LayoutStyle.floating.name);
    final String feedScreenBackgroundImagePath = settingsBox.get('feedScreenBackgroundImagePath', defaultValue: 'assets/images/13.jpeg');
    final double feedScreenCardOpacity = settingsBox.get('feedScreenCardOpacity', defaultValue: 1.0);
    final double feedScreenCardBorderRadius = settingsBox.get('feedScreenCardBorderRadius', defaultValue: 12.0);

    return FeedScreenDisplayState(
      screenStyle: LayoutStyle.values.firstWhere((style) => style.name == feedScreenDisplayStyleName, orElse: () => LayoutStyle.floating),
      backgroundImagePath: feedScreenBackgroundImagePath,
      cardOpacity: feedScreenCardOpacity,
      cardBorderRadius: feedScreenCardBorderRadius,
    );
  }

  Future<void> setFeedScreenDisplayStyleAsync({required FeedScreenDisplayState feedScreenDisplayState}) async {
    final entries = {
      'feedScreenDisplayStyle': feedScreenDisplayState.screenStyle.name,
      'feedScreenCardOpacity': feedScreenDisplayState.cardOpacity,
      'feedScreenCardBorderRadius': feedScreenDisplayState.cardBorderRadius,
      'feedScreenBackgroundImagePath': feedScreenDisplayState.backgroundImagePath,
    };

    await settingsBox.putAll(entries);
  }

  ChatsScreenDisplayState getChatsScreenDisplayStyle() {
    final String screenStyle = settingsBox.get('chatsScreenDisplayStyle', defaultValue: LayoutStyle.floating.name);
    final String backgroundImagePath = settingsBox.get('chatsScreenBackgroundImagePath', defaultValue: 'assets/images/7.jpeg');
    final double tileOpacity = settingsBox.get('chatsScreenTileOpacity', defaultValue: 1.0);
    final double tileBorderRadius = settingsBox.get('chatsScreeTileBorderRadius', defaultValue: 12.0);

    return ChatsScreenDisplayState(
      screenStyle: LayoutStyle.values.byName(screenStyle),
      backgroundImagePath: backgroundImagePath,
      tileOpacity: tileOpacity,
      tileBorderRadius: tileBorderRadius,
    );
  }

  Future<void> setChatsScreenDisplayStyleAsync({required ChatsScreenDisplayState chatsScreenDisplayState}) async {
    final entries = {
      'chatsScreenDisplayStyle': chatsScreenDisplayState.screenStyle.name,
      'chatsScreenTileOpacity': chatsScreenDisplayState.tileOpacity,
      'chatsScreenTileBorderRadius': chatsScreenDisplayState.tileBorderRadius,
      'chatsScreenBackgroundImagePath': chatsScreenDisplayState.backgroundImagePath,
    };

    await settingsBox.putAll(entries);
  }

  ScreenStyleState getScreenStyleState({required String screenName}) {
    final String layoutStyle = settingsBox.get('${screenName}layoutStyle', defaultValue: LayoutStyle.floating.name);
    final double opacity = settingsBox.get('${screenName}opacity', defaultValue: 12);
    final double borderRadius = settingsBox.get('${screenName}borderRadius', defaultValue: 12);
    final String backgroundImage = settingsBox.get('${screenName}backgroundImage', defaultValue: 'assets/images/7.jpeg');

    return ScreenStyleState(layoutStyle: LayoutStyle.values.byName(layoutStyle), opacity: opacity, borderRadius: borderRadius, backgroundImage: backgroundImage);
  }

  Future<void> setScreenStyleState({required String screenName, required ScreenStyleState screenStyle}) async {
    final entries = {
      '${screenName}layoutStyle': screenStyle.layoutStyle.name,
      '${screenName}opacity': screenStyle.opacity,
      '${screenName}borderRadius': screenStyle.borderRadius,
      '${screenName}backgroundImage': screenStyle.backgroundImage,
    };

    await settingsBox.putAll(entries);
  }

  Themes getTheme() {
    final String themeName = settingsBox.get('themeName', defaultValue: Themes.dark.name);
    return Themes.values.firstWhere((theme) => theme.name == themeName);
  }

  Future<void> setThemeAsync({required Themes themeName}) async => await settingsBox.put('themeName', themeName.name);

  Future<void> logOut() async {
    await initializeNavbar(force: true);
    await userBox.clear();
    await settingsBox.clear();
  }
}

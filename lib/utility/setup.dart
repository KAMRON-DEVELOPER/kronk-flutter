import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:kronk/firebase_options.dart';
import 'package:kronk/main.dart';
import 'package:kronk/models/navbar_adapter.dart';
import 'package:kronk/models/navbar_model.dart';
import 'package:kronk/models/user_adapter.dart';
import 'package:kronk/models/user_model.dart';
import 'package:kronk/utility/constants.dart';
import 'package:kronk/utility/my_logger.dart';
import 'package:kronk/utility/storage.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:visibility_detector/visibility_detector.dart';

Future<String> setup() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final status = await Permission.storage.status;
  if (status.isDenied) {
    final request = await Permission.storage.request();
    if (request.isDenied) {
      myLogger.w("User didn't give storage permission");
    }
  }

  try {
    await Hive.initFlutter();
  } catch (e, stack) {
    myLogger.w('Exception while initializing Hive, e: ${e.toString()}, stack: ${stack.toString()}');
    rethrow;
  }

  Hive.registerAdapter(UserAdapter(), override: true);
  Hive.registerAdapter(NavbarAdapter(), override: true);

  await Hive.openBox<UserModel>('userBox');
  await Hive.openBox<NavbarModel>('navbarBox');
  await Hive.openBox('settingsBox');

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e, stack) {
    myLogger.w('Exception while initializing Firebase, e: ${e.toString()}, stack: ${stack.toString()}');
    rethrow;
  }

  try {
    await googleSignIn.initialize(clientId: constants.clientId);
  } catch (e, stack) {
    myLogger.w('Exception while initializing googleSignIn, e: ${e.toString()}, stack: ${stack.toString()}');
    rethrow;
  }

  FlutterNativeSplash.remove();

  final Storage storage = Storage();
  await storage.initializeNavbar();

  VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 200);

  return await storage.getRouteAsync();
}

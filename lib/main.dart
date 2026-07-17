import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as EL;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/application/checkIn_provider.dart';
import 'package:sm_networking/application/error_string.dart';
import 'package:sm_networking/application/location.dart';
import 'package:sm_networking/application/search_providers.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/application/visit_provider.dart';
import 'package:sm_networking/application/visit_bloc/visit_bloc.dart';
import 'package:sm_networking/presentation/view/map/widget/visit_checker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:workmanager/workmanager.dart';

import 'application/retailer_provider.dart';
import 'application/draft_provider.dart';
import 'application/pending_sync_provider.dart';
import 'application/wholesaler_retailer_provider.dart';
import 'infrastructure/services/background_location.dart';
import 'infrastructure/services/session_manager.dart';
import 'infrastructure/services/work_manager.dart';
import 'presentation/view/maintenance/maintenance_gate.dart';
import 'presentation/view/splash_screen/splash_view.dart';
import 'firebase_options.dart';

import 'injection_container.dart' as di;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  createNotification(
    title: message.data['title'].toString(),
    body: message.data['body'].toString(),
  );
}

Future<void> createNotification(
    {required String title, required String body}) async {
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
        id: 1, channelKey: 'basic_channel', title: title, body: body),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();
  await EL.EasyLocalization.ensureInitialized();
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  await BackgroundLocationService.initializeService();
  log("✅ Background Location Service initialized");

  // Clears the cached session on forced logout. Confirmed against
  // presentation/view/auth/log_in/layout/body.dart, which is where the
  // token/user is originally saved on login: SharedPreferences key
  // 'USER_DATA', plus UserProvider. splash_screen/layout/body.dart also
  // caches ALLOWED_CHECKIN_TIME/ALLOWED_CHECKOUT_TIME off the same user
  // profile, so those are cleared too for consistency (harmless if unused
  // elsewhere).
  onSessionExpired = () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('USER_DATA');
    await prefs.remove('ALLOWED_CHECKIN_TIME');
    await prefs.remove('ALLOWED_CHECKOUT_TIME');

    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      Provider.of<UserProvider>(ctx, listen: false).clearSalesData();
    }
  };

  /// Hive local storage for retailers
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('retailersBox');
  await Hive.openBox('banksBox');

  AwesomeNotifications().initialize(
    'resource://drawable/res_notification_app_icon',
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        defaultColor: Colors.teal,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        channelDescription: 'Karyana',
      ),
      NotificationChannel(
        channelKey: 'location_tracking',
        channelName: 'Location Tracking',
        channelDescription:
            'Notification channel for location tracking service',
        defaultColor: Colors.teal,
        ledColor: Colors.white,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        playSound: false,
        enableVibration: false,
      ),
    ],
  ).then((value) => print(value));
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(EL.EasyLocalization(
    startLocale: const Locale("en"),
    supportedLocales: const [
      Locale('en'),
      Locale('ur'),
    ],
    path: 'assets/translation',
    fallbackLocale: const Locale('en', 'US'),
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ErrorString()),
        ChangeNotifierProvider(create: (_) => SearchProviders()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => RetailerProvider()),
        ChangeNotifierProvider(create: (_) => VisitProvider()),
        ChangeNotifierProvider(create: (_) => CheckInProvider()),
        ChangeNotifierProvider(create: (_) => WholesalerRetailerProvider()),
        ChangeNotifierProvider(create: (_) => DraftProvider()),
        ChangeNotifierProvider(create: (_) => PendingSyncProvider()),
      ],
      child: BlocProvider(
        create: (_) => di.sl<VisitBloc>(),
        child: const MyApp(),
      ),
    ),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    AwesomeNotifications().isNotificationAllowed().then(
      (isAllowed) {
        if (!isAllowed) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Allow Notifications'),
              content:
                  const Text('Our app would like to send you notifications'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Don\'t Allow',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                ),
                TextButton(
                  onPressed: () => AwesomeNotifications()
                      .requestPermissionToSendNotifications()
                      .then((_) => Navigator.pop(context)),
                  child: const Text(
                    'Allow',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.initState();
    FirebaseMessaging.onMessage.listen((message) {
      print(message);
      createNotification(
        title: message.data['title'].toString(),
        body: message.data['body'].toString(),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      createNotification(
        title: message.data['title'].toString(),
        body: message.data['body'].toString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return VisitChecker(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        locale: context.locale,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: "Raleway",
          scaffoldBackgroundColor: Colors.white,
        ),
        home: const MaintenanceGate(child: SplashView()),
      ),
    );
  }
}

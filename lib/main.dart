import '../auth/login.dart';
import '../durub/durub.dart';
import '../firebase_options.dart';
import '../screens/AreaManagement/AreaManagement.dart';
import '../screens/VehicleManagement/VehicleListScreen.dart';
import '../screens/dashboard/dashboard.dart';
import '../screens/users/UsersScreen.dart';
import '../screens/barcode/barcode_scanner_screen.dart';
import '../shared/appProvider.dart';
import '../widgets/GlobalBarcodeListener.dart';
import '../shared/ScannerProvider.dart';
import '../shared/FCMService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

const Color background = Color(0xFFF8FAFC);
const Color primary = Color(0xFF4F46E5);
const Color secprimary = Color(0xFFF59E0B);
const Color accentColor = Color(0xFF6366F1);

String $KcompanyLogo = 'logo.png';

String email = 'bx1@1.com.com';

String password = '123123';

const String KcompanyName = 'bx press';

const String whatsappKey = "1A5VW56wnXX3";

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Initialize FCM
    await FCMService().initialize();
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // You might want to show a user-friendly error message here
  }
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _initialRouteFuture;
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  void initState() {
    super.initState();
    _initialRouteFuture = _determineInitialRoute();
  }

  Future<Widget> _determineInitialRoute() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return const dashboard();
    } else {
      return LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()..init()),
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
      ],
      child: MaterialApp(
        scrollBehavior: ScrollBehavior().copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: KcompanyName,
        themeMode: _themeMode,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: FontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primary,
            primary: primary,
            secondary: secprimary,
            tertiary: accentColor,
            surface: Colors.white,
            background: background,
            error: const Color(0xFFEF4444),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: FontFamily,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade100, width: 1),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: primary,
            secondary: Color(0xFFFFA500),
            tertiary: accentColor,
            surface: background,
            background: background,
            error: Colors.red[700]!,
            onPrimary: Colors.black,
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onBackground: Colors.white,
            onError: Colors.white,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: primary,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.black,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.all(primary),
            checkColor: WidgetStateProperty.all(Colors.white),
          ),
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: GlobalBarcodeListener(
              child: child!,
            ),
          );
        },
        home: FutureBuilder<Widget>(
          future: _initialRouteFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return snapshot.data ?? LoginScreen();
            }
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          },
        ),
        routes: {
          '/login': (context) => LoginScreen(),
          //'/ordersdashbord': (context) => OrderManagementScreen(),
          '/dashbord': (context) => const dashboard(),
          '/users': (context) => const UsersScreen(),
          '/vehiclemanagement': (context) => const VehicleListScreen(),
          '/areamanagement': (context) => const AreaManagement(),
          '/barcodescanner': (context) => const BarcodeScannerScreen(),
        },
      ),
    );
  }
}

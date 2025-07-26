import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/data.dart';
import 'package:xpensia/screens/home/home_screen.dart';
import 'package:xpensia/screens/login_page.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _amplifyConfigured = false;
  Widget _initialScreen = const Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Future<void> _configureAmplify() async {
    try {
      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);
      await Amplify.configure(amplifyconfig);

      final session = await Amplify.Auth.fetchAuthSession();
      setState(() {
        _initialScreen = session.isSignedIn
            ? const HomeScreen()
            : const Login();
        _amplifyConfigured = true;
      });
    } on Exception catch (e) {
      debugPrint('Amplify setup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _amplifyConfigured
          ? _initialScreen
          : const CircularProgressIndicator(),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.coda(color: Colors.white),
          bodyLarge: GoogleFonts.coda(color: Colors.white),
        ),
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00458e),
          secondary: const Color(0xFF000328),
          tertiary: const Color(0xFF2B2B2B),
          onPrimary: Colors.white,
          surface: Colors.black,
        ),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: TextTheme(
          bodyMedium: GoogleFonts.coda(color: Colors.black),
          bodyLarge: GoogleFonts.coda(color: Colors.black),
        ),
        colorScheme: ColorScheme.light(
          surface: Colors.white,
          onSurface: Colors.black,
          primary: const Color(0xFF08203e),
          secondary: const Color(0xFF557c93),
          tertiary: const Color.fromARGB(255, 218, 243, 254),
          outline: Colors.grey,
          onPrimary: Colors.black,
        ),
      ),
      themeMode: ThemeMode.system,
    );
  }
}

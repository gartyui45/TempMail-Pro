import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF05081A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const CypherMailApp());
}

class CypherMailApp extends StatelessWidget {
  const CypherMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CypherMail Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF00D4FF),
          secondary: const Color(0xFF0044FF),
          surface: const Color(0xFF0A0E27),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pocket_llm/screens/homepage.dart';
import 'package:pocket_llm/screens/welcome.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences preferences = await SharedPreferences.getInstance();
  bool setupComplete = preferences.getBool('setupComplete') ?? false;
  runApp(MyApp(setupComplete: setupComplete));
}

class MyApp extends StatelessWidget {
  final bool setupComplete;

  const MyApp({super.key, required this.setupComplete});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.lexendDecaTextTheme(
          Theme.of(context).textTheme
        ).apply(bodyColor: Colors.white),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color.fromARGB(191, 0, 0, 0)
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 18)
      ),
      home: !setupComplete ? const WelcomePage() : const HomePage(),
    );
  }
}
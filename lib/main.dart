import 'package:flutter/material.dart';
import 'package:mobile_uas/Auth/LoginScreen.dart';
import 'package:mobile_uas/Auth/RegisterScreen.dart';
import 'package:mobile_uas/Notes/NotesIndex.dart';
import 'package:mobile_uas/Calender/CalenderIndex.dart';
import 'package:mobile_uas/Settings.dart';
import 'package:mobile_uas/SplashScreen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_uas/Notes/EditNote.dart'; // Adjust the import path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://kqvjryrpmsjxmgmyxxib.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtxdmpyeXJwbXNqeG1nbXl4eGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU5MzAyMzAsImV4cCI6MjA2MTUwNjIzMH0.RUyzIDjctFrnngi1lS2ggyK1JRqmANKfbDQcHgPsi7w',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      theme: ThemeData(
        brightness:
            themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',  
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const NotesIndex(),
        '/signup': (context) => const RegisterScreen(),
        '/edit_note': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return EditNote(noteId: args['noteId']);
        },
        // add other routes here
      },
    );
  }
}

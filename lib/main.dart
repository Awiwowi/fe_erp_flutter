import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import ini
import 'screens/login_page.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ERP Flutter',
      theme: ThemeData(
        // Pakai font 'Inter' atau 'Poppins' biar modern
        textTheme: GoogleFonts.interTextTheme(), 
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
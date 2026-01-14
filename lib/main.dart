import 'package:flutter/material.dart';
// Kita import halaman login saja
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
      title: 'ERP Login UI',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.grey,
        useMaterial3: true,
      ),
      // Langsung panggil LoginPage dari folder screens
      home: const LoginPage(),
    );
  }
}
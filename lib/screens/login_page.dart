import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart'; // Pastikan ini mengarah ke Dashboard kamu

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Controller untuk menangkap inputan user
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false; // Status Loading

  // 2. Fungsi Logika Login (API)
  void _handleLogin() async {
    // A. Validasi Input Kosong
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password tidak boleh kosong!")),
      );
      return;
    }

    // B. Mulai Loading (Tombol jadi muter-muter)
    setState(() => _isLoading = true);

    print("Mencoba login dengan: ${_emailController.text}");

    // C. Tembak API ke Ngrok
    bool success = await AuthService().login(
      _emailController.text,
      _passwordController.text,
    );

    // D. Selesai Loading
    setState(() => _isLoading = false);

    // E. Cek Hasil Login
    if (success) {
      if (!mounted) return;
      print("Login Sukses! Masuk Dashboard...");
      
      // Pindah Halaman
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Berhasil!"), backgroundColor: Colors.green),
      );
    } else {
      if (!mounted) return;
      print("Login Gagal!");
      
      // Muncul Pesan Error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Gagal. Cek Email/Password atau URL Ngrok."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text("Welcome Back!", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              // 3. Input Email (Wajib Pasang Controller)
              CustomTextField(
                label: "Email",
                hintText: "Enter email",
                icon: Icons.email_outlined,
                controller: _emailController, // <--- PENTING
              ),
              const SizedBox(height: 20),
              
              // 4. Input Password (Wajib Pasang Controller)
              CustomTextField(
                label: "Password",
                hintText: "Enter password",
                icon: Icons.lock_outline,
                isPassword: true,
                controller: _passwordController, // <--- PENTING
              ),

              const SizedBox(height: 30),

              // 5. TOMBOL SIGN IN (BAGIAN PALING KRUSIAL)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 74, 192),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  // KALAU INI LANGSUNG NAVIGATOR, PASTI INSTAN.
                  // GANTI JADI _handleLogin AGAR DIA NUNGGU API.
                  onPressed: _isLoading ? null : _handleLogin, 
                  
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) // Animasi loading
                    : const Text("Sign in", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              // ...
            ],
          ),
        ),
      ),
    );
  }
}
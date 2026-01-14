import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import 'reset_password_page.dart';
import 'login_page.dart';

class OtpVerificationPage extends StatelessWidget {
  final bool isResetPassword;

  const OtpVerificationPage({super.key, required this.isResetPassword});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Icon(Icons.security, size: 80, color: Color(0xFF5D6679)),
              const SizedBox(height: 30),
              Text(isResetPassword ? "Confirm Your Email" : "Verify Your Account", textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("We've sent a verification code to \nCihuyy@gmail.com", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 40),
              const CustomTextField(label: "Enter Verification Code", hintText: "Ex: 59382", icon: Icons.vpn_key_outlined),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B4B4B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    if (isResetPassword) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ResetPasswordPage()));
                    } else {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account created! Please Sign In."), backgroundColor: Colors.green));
                    }
                  },
                  child: Text(isResetPassword ? "Verify and Reset Password" : "Verify and Create Account", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
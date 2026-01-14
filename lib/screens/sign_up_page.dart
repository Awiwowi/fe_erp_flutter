import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import 'otp_verification_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              const Text("Create Your Account", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Create account for exploring news", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 30),
              const CustomTextField(label: "Email or Phone Number", hintText: "Cihuyy@gmail.com", icon: Icons.email_outlined),
              const SizedBox(height: 16),
              const CustomTextField(label: "First Name", hintText: "First Name", icon: Icons.person_outline),
              const SizedBox(height: 16),
              const CustomTextField(label: "Last Name", hintText: "Last Name", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildPasswordField("Password", _obscurePassword, (val) => setState(() => _obscurePassword = val)),
              const SizedBox(height: 16),
              _buildPasswordField("Confirm Password", _obscureConfirmPassword, (val) => setState(() => _obscureConfirmPassword = val)),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4B4B4B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const OtpVerificationPage(isResetPassword: false)));
                  },
                  child: const Text("Continue", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, bool isObscured, Function(bool) onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
          child: TextField(
            obscureText: isObscured,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
              suffixIcon: IconButton(icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey), onPressed: () => onToggle(!isObscured)),
              hintText: "Enter your password", hintStyle: const TextStyle(color: Colors.grey), contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
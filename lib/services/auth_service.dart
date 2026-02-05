import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Wajib Import ini

class AuthService {
//URL BASE API
  static const String baseUrl = 'https://unplaying-hedwig-beautiful.ngrok-free.dev/api/v1';
  
  static String? token; 

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        
        // 1. Inisialisasi SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // 2. Simpan Token
        token = data['token']; 
        await prefs.setString('token', token!);

        // 3. Simpan Nama User
        String name = data['user']['name'] ?? 'User';
        await prefs.setString('user_name', name);

        // 4. Simpan Role (Ambil role pertama dari list)
        List<dynamic> roles = data['user']['roles'] ?? [];
        String mainRole = roles.isNotEmpty ? roles[0] : 'Staff';
        await prefs.setString('user_role', mainRole);

        print("Login Success: Token & User Data Saved.");
        return true;
      } else {
        print("Login Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Login: $e");
      return false;
    }
  }

  // Fungsi Logout 
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    token = null;
  }
}
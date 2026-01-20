import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // GANTI URL INI DENGAN NGROK TERBARU KAMU
  static const String baseUrl = 'https://unplaying-hedwig-beautiful.ngrok-free.dev/api/v1';
  
  // Variabel untuk menyimpan token sementara (di memori)
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
        // SIMPAN TOKEN DARI SERVER
        token = data['token']; 
        print("Token disimpan: $token");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error Login: $e");
      return false;
    }
  }
  // ... fungsi register biarkan saja
}
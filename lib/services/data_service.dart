import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DataService {
  // --- PRODUCTS ---

  // GET (Read)
  Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/products'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error Get Products: $e");
      return [];
    }
  }

  // POST (Create)
  Future<bool> addProduct(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/products'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Add Product: $e");
      return false;
    }
  }

  // PUT (Update)
  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/products/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Product: $e");
      return false;
    }
  }

  // DELETE
  Future<bool> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/products/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error Delete Product: $e");
      return false;
    }
  }

  // --- UNITS ---

  Future<List<dynamic>> getUnits() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/units'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error Get Units: $e");
      return [];
    }
  }

  Future<bool> addUnit(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/units'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Add Unit: $e");
      return false;
    }
  }

  Future<bool> updateUnit(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/units/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Unit: $e");
      return false;
    }
  }

  Future<bool> deleteUnit(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/units/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error Delete Unit: $e");
      return false;
    }
  }

// --- WAREHOUSES ---

  Future<List<dynamic>> getWarehouses() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/warehouses'), // Pastikan route Laravel benar
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'] ?? [];
      }
      return [];
    } catch (e) {
      print("Error Get Warehouses: $e");
      return [];
    }
  }

  Future<bool> addWarehouse(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/warehouses'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Add Warehouse: $e");
      return false;
    }
  }

  Future<bool> updateWarehouse(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/warehouses/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Warehouse: $e");
      return false;
    }
  }

  Future<bool> deleteWarehouse(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/warehouses/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error Delete Warehouse: $e");
      return false;
    }
  }

// User Management
// Get all users
  Future<List<dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/users'),
        headers: _headers(),
      );

      print("Status User: ${response.statusCode}");
      print("Body User: ${response.body}");

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List){
        return jsonResponse;
      } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
        return jsonResponse['data'];
      } else {
        return [];}
      }
      return [];
    } catch (e) {
      print("Error Get Users: $e");
      return [];
    }
  }

  //Create User
  Future<bool> createUser(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/users'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      //201 created
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create User: $e");
      return false;
    }
  }

// Update User
  Future<bool> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/users/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update User: $e");
      return false;
    }
  }

  // Delete User
  Future<bool> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/users/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error Delete User: $e");
      return false;
    }
  }

  // Suppliers
  Future<List<dynamic>> getSuppliers() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/suppliers'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List) {
          return jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          return jsonResponse['data'];
        }
      }
      return [];
    } catch (e) {
      print("Error Get Suppliers: $e");
      return [];
    }
  }

  Future<bool> addSupplier(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/suppliers'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Add Supplier: $e");
      return false;
    }
  }

  Future<bool> updateSupplier(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/suppliers/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Supplier: $e");
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/suppliers/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error Delete Supplier: $e");
      return false;
    }
  }

  // Helper Headers
  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${AuthService.token}',
    };
  }
}
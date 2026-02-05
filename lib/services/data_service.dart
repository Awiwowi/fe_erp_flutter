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
        Uri.parse('${AuthService.baseUrl}/warehouses'),
        headers: _headers(),
      );

      if (response.statusCode != 200) {
        print("Gagal Get Warehouses: ${response.statusCode} - ${response.body}");
        return [];
      }

      var json = jsonDecode(response.body);
      
      if (json['data'] != null) {
        return List<dynamic>.from(json['data']);
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

// --- STOCK REQUESTS ---

  Future<List<dynamic>> getStockRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/stock-requests'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List) {
          return jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          return jsonResponse['data'];
        }
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get Stock Requests: $e");
      return [];
    }
  }

  Future<bool> createStockRequest(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-requests'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create Stock Request: $e");
      return false;
    }
  }

  Future<bool> deleteStockRequest(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/stock-requests/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Error Delete Stock Request: $e");
      return false;
    }
  }

  Future<bool> updateStockRequest(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/stock-requests/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Stock Request: $e");
      return false;
    }
  }

  // APPROVE
  Future<bool> approveStockRequest(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-requests-approval/$id/approve'), // Asumsi route Laravel: POST /stock-requests/{id}/approve
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Approve: $e");
      return false;
    }
  }

  // REJECT
  Future<bool> rejectStockRequest(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-requests-approval/$id/reject'), // Asumsi route Laravel: POST /stock-requests/{id}/reject
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Reject: $e");
      return false;
    }
  }

// AMBIL LIST WAREHOUSE (GUDANG)
  // 1. Ambil Stock Request yang SUDAH APPROVED saja
  Future<List<dynamic>> getApprovedStockRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/stock-requests'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        List<dynamic> allData = json['data'] ?? [];
        
        // FILTER HANYA YANG STATUS == 'approved'
        return allData.where((item) {
          String status = (item['status'] ?? '').toString().toLowerCase();
          return status == 'approved';
        }).toList();
      }
      return [];
    } catch (e) {
      print("Error Get Approved Requests: $e");
      return [];
    }
  }

  // 2. Submit Stock Out
  Future<bool> createStockOut(int stockRequestId, int warehouseId, String date, String notes) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-outs'),
        headers: _headers(),
        body: jsonEncode({
          'stock_request_id': stockRequestId,
          'warehouse_id': warehouseId,
          'out_date': date,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Gagal Stock Out: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Create Stock Out: $e");
      return false;
    }
  }

// --- STOCK INITIAL (STOK AWAL) ---

  Future<bool> createInitialStocks(int warehouseId, List<Map<String, dynamic>> items) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/initial-stocks'),
        headers: _headers(),
        body: jsonEncode({
          'warehouse_id': warehouseId,
          'items': items, // format: [{ "product_id": 1, "quantity": 100 }, ...]
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print("Gagal Input Stok Awal: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Create Initial Stock: $e");
      return false;
    }
  }

  Future<List<dynamic>> getInitialStocks() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/initial-stocks'), // Sesuaikan route di api.php
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      print("Error Get Stock Initial: $e");
      return [];
    }
  }

  Future<bool> addInitialStocks(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/initial-stocks'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error Add Stock Initial: $e");
      return false;
    }
  }

// --- STOCK TRANSFER ---

  Future<List<dynamic>> getStockTransfers() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/stock-transfers'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        // Handle jika backend return {data: []} atau [] langsung
        var json = jsonDecode(response.body);
        if (json is List) return json;
        if (json is Map && json.containsKey('data')) return List<dynamic>.from(json['data']);
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get Stock Transfer: $e");
      return [];
    }
  }

  Future<bool> createStockTransfer(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-transfers'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error Create Transfer: $e");
      return false;
    }
  }

  Future<bool> approveStockTransfer(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-transfers/$id/approve'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> executeStockTransfer(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-transfers/$id/execute'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectStockTransfer(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-transfers/$id/reject'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteStockTransfer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/stock-transfers/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

// --- STOCK ADJUSTMENT (PENYESUAIAN STOK) ---

  Future<List<dynamic>> getStockAdjustments() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/stock-adjustments'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is Map && json.containsKey('data')) return List<dynamic>.from(json['data']);
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get Adjustments: $e");
      return [];
    }
  }

  Future<bool> createStockAdjustment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-adjustments'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error Create Adjustment: $e");
      return false;
    }
  }

  Future<bool> approveStockAdjustment(int id) async {
    try {
      // Sesuai routes/api.php: stock-adjustments/{id}/approved
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/stock-adjustments/$id/approved'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Approve Adjustment: $e");
      return false;
    }
  }

  Future<bool> deleteStockAdjustment(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/stock-adjustments/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete Adjustment: $e");
      return false;
    }
  }

// --- RAW MATERIALS (BAHAN BAKU) ---

  Future<List<dynamic>> getRawMaterials() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/raw-materials'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is Map && json.containsKey('data')) {
          return List<dynamic>.from(json['data']); // Format Paginasi Laravel
        }
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get Raw Materials: $e");
      return [];
    }
  }

  Future<bool> addRawMaterial(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/raw-materials'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Add Raw Material: $e");
      return false;
    }
  }

  Future<bool> updateRawMaterial(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/raw-materials/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Raw Material: $e");
      return false;
    }
  }

  Future<bool> deleteRawMaterial(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/raw-materials/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete Raw Material: $e");
      return false;
    }
  }

// --- RAW MATERIAL STOCK IN (BARANG MASUK) ---

  Future<List<dynamic>> getRawMaterialStockIn() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-in'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        // Laravel pagination wrap data inside 'data' key
        if (json is Map && json.containsKey('data')) {
          return List<dynamic>.from(json['data']);
        }
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get RM Stock In: $e");
      return [];
    }
  }

  Future<bool> createRawMaterialStockIn(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-in'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Gagal Create RM In: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Create RM In: $e");
      return false;
    }
  }

  // Fungsi untuk POSTING (Finalisasi Stok)
  Future<bool> postRawMaterialStockIn(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-in/$id/post'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Post RM In: $e");
      return false;
    }
  }

  Future<bool> deleteRawMaterialStockIn(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-in/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete RM In: $e");
      return false;
    }
  }

// --- RAW MATERIAL STOCK OUT (PENGELUARAN BAHAN BAKU) ---

  Future<List<dynamic>> getRawMaterialStockOut() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-out'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        // Backend return list langsung atau dibungkus data?
        // Berdasarkan controller index: return response()->json($data); (Langsung List)
        if (json is List) return json;
        if (json is Map && json.containsKey('data')) return List<dynamic>.from(json['data']);
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get RM Stock Out: $e");
      return [];
    }
  }

  Future<bool> createRawMaterialStockOut(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-out'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      // 201 Created
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Gagal Create RM Out: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Create RM Out: $e");
      return false;
    }
  }

  Future<bool> postRawMaterialStockOut(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-out/$id/post'),
        headers: _headers(),
      );
      
      // Backend return 200 OK jika sukses, 500 jika stok kurang
      if (response.statusCode == 200) return true;
      
      print("Gagal Post RM Out: ${response.body}");
      return false;
    } catch (e) {
      print("Error Post RM Out: $e");
      return false;
    }
  }

  Future<bool> deleteRawMaterialStockOut(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-out/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete RM Out: $e");
      return false;
    }
  }

  // --- PURCHASE REQUESTS ---
Future<List<dynamic>> getPurchaseRequests() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/purchase-requests'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        // Backend return array langsung (berdasarkan controller index)
        if (json is List) return json; 
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get PR: $e");
      return [];
    }
  }

  Future<bool> createPurchaseRequest(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-requests'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Gagal Create PR: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Create PR: $e");
      return false;
    }
  }

  Future<bool> deletePurchaseRequest(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/purchase-requests/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete PR: $e");
      return false;
    }
  }

// --- PURCHASE REQUEST WORKFLOW ---

  Future<bool> submitPurchaseRequest(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-requests/$id/submit'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Submit PR: $e");
      return false;
    }
  }

  Future<bool> approvePurchaseRequest(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-requests/$id/approve'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Approve PR: $e");
      return false;
    }
  }

  Future<bool> rejectPurchaseRequest(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-requests/$id/reject'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Reject PR: $e");
      return false;
    }
  }

// --- PURCHASE REQUEST ITEMS ---

  // Ambil Detail PR (termasuk items) berdasarkan ID
  Future<Map<String, dynamic>?> getPurchaseRequestDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/purchase-requests/$id'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Error Get PR Detail: $e");
      return null;
    }
  }

  Future<bool> addPurchaseRequestItem(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-request-items'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error Add PR Item: $e");
      return false;
    }
  }

  Future<bool> updatePurchaseRequestItem(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/purchase-request-items/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update PR Item: $e");
      return false;
    }
  }

  Future<bool> deletePurchaseRequestItem(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/purchase-request-items/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete PR Item: $e");
      return false;
    }
  }

// --- PURCHASE ORDERS (PO) ---

  Future<List<dynamic>> getPurchaseOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/purchase-orders'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error Get PO: $e");
      return [];
    }
  }

  // 1. GENERATE PO DARI PR (Hanya untuk PR Approved)
  Future<bool> generatePOFromPR(int prId) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-orders/from-pr/$prId'),
        headers: _headers(),
      );
      // 201 Created atau 422 jika sudah ada
      return response.statusCode == 201;
    } catch (e) {
      print("Error Generate PO: $e");
      return false;
    }
  }

  // 2. UPDATE PO (Supplier, Date, Notes) - Status Draft
  Future<bool> updatePurchaseOrder(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/purchase-orders/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update PO: $e");
      return false;
    }
  }

  // 3. UPDATE HARGA ITEM PO
  Future<bool> updatePOItemPrice(int itemId, double price) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-orders/item/$itemId/price'),
        headers: _headers(),
        body: jsonEncode({"price": price}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update PO Price: $e");
      return false;
    }
  }

  // 4. SUBMIT PO (Draft -> Sent)
  Future<bool> submitPurchaseOrder(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-orders/$id/submit'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Submit PO: $e");
      return false;
    }
  }

  // 5. APPROVE/RECEIVE PO (Sent -> Received)
  Future<bool> approvePurchaseOrder(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-orders/$id/receive'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Approve PO: $e");
      return false;
    }
  }

  Future<bool> deletePurchaseOrder(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/purchase-orders/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete PO: $e");
      return false;
    }
  }

// --- GOODS RECEIPTS (PENERIMAAN BARANG) ---

  // Get List
  Future<List<dynamic>> getGoodsReceipts() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/goods-receipts'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return List<dynamic>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      print("Error Get GR: $e");
      return [];
    }
  }

  // Create GR from PO
  Future<bool> createGoodsReceipt(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/goods-receipts'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Gagal Create GR: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Create GR: $e");
      return false;
    }
  }

  // Update GR (Draft Only)
  Future<bool> updateGoodsReceipt(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/goods-receipts/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update GR: $e");
      return false;
    }
  }

  // Post/Finalize GR (Update Stock)
  Future<bool> postGoodsReceipt(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/goods-receipts/$id/post'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Post GR: $e");
      return false;
    }
  }

  // Delete GR
  Future<bool> deleteGoodsReceipt(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/goods-receipts/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete GR: $e");
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
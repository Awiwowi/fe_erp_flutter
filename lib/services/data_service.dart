import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DataService {
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
        if (jsonResponse is List) {
          return jsonResponse;
        } else if (jsonResponse is Map && jsonResponse.containsKey('data')) {
          return jsonResponse['data'];
        } else {
          return [];
        }
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

  // Data Master
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
        print(
          "Gagal Get Warehouses: ${response.statusCode} - ${response.body}",
        );
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

  // Customers
  Future<List<dynamic>> getCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/customer'), // Diubah jadi /customer
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
        return List<dynamic>.from(json);
      }
      return [];
    } catch (e) {
      print("Error Get Customers: $e");
      return [];
    }
  }

  Future<bool> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/customer'), // Diubah jadi /customer
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create Customer: $e");
      return false;
    }
  }

  Future<bool> updateCustomer(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse(
          '${AuthService.baseUrl}/customer/$id',
        ), // Diubah jadi /customer
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update Customer: $e");
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '${AuthService.baseUrl}/customer/$id',
        ), // Diubah jadi /customer
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete Customer: $e");
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

  // --- CHART OF ACCOUNTS (COA) ---

  Future<List<dynamic>> getChartOfAccounts() async {
    try {
      // Endpoint: GET /api/chart-of-accounts
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/chart-of-accounts'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        // Controller mengembalikan List langsung [...]
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("Error Get COA: $e");
      return [];
    }
  }

  Future<bool> createChartOfAccount(Map<String, dynamic> data) async {
    try {
      // Endpoint: POST /api/chart-of-accounts
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/chart-of-accounts'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      // Expected Status: 201 Created
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create COA: $e");
      return false;
    }
  }

  Future<bool> updateChartOfAccount(int id, Map<String, dynamic> data) async {
    try {
      // Endpoint: PUT /api/chart-of-accounts/{id}
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/chart-of-accounts/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update COA: $e");
      return false;
    }
  }

  Future<bool> deleteChartOfAccount(int id) async {
    try {
      // Endpoint: DELETE /api/chart-of-accounts/{id}
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/chart-of-accounts/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete COA: $e");
      return false;
    }
  }

  // Initial Balance
  Future<List<dynamic>> getInitialBalances() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/initial-balances'),
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
      print("Error Get Initial Balances: $e");
      return [];
    }
  }

  Future<bool> createInitialBalance(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/initial-balances'),
        headers: _headers(),
        body: jsonEncode(data),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create Initial Balance: $e");
      return false;
    }
  }

  Future<bool> approveInitialBalance(String year) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/initial-balances/$year/approve'),
        headers: _headers(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error Approve Initial Balance: $e");
      return false;
    }
  }

  Future<bool> deleteInitialBalance(String year) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/initial-balances/$year'),
        headers: _headers(),
      );

      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete Initial Balance: $e");
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
        Uri.parse(
          '${AuthService.baseUrl}/stock-requests-approval/$id/approve',
        ), // Asumsi route Laravel: POST /stock-requests/{id}/approve
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
        Uri.parse(
          '${AuthService.baseUrl}/stock-requests-approval/$id/reject',
        ), // Asumsi route Laravel: POST /stock-requests/{id}/reject
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
  Future<bool> createStockOut(
    int stockRequestId,
    int warehouseId,
    String date,
    String notes,
  ) async {
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

  Future<bool> createInitialStocks(
    int warehouseId,
    List<Map<String, dynamic>> items,
  ) async {
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
        Uri.parse(
          '${AuthService.baseUrl}/initial-stocks',
        ), // Sesuaikan route di api.php
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
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
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
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
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

  // --- STOCK SUMMARY (PRODUCT TRACKING) ---

  Future<List<dynamic>> getProductStockSummary() async {
    try {
      // Endpoint ini sesuai dengan routes/api.php: Route::get('/stock-summary', ...)
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/stock-summary'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);

        // Handle jika response dibungkus { success: true, data: [...] }
        if (json is Map && json.containsKey('data')) {
          return List<dynamic>.from(json['data']);
        }
        // Handle jika response langsung list [...]
        else if (json is List) {
          return json;
        }
      }
      return [];
    } catch (e) {
      print("Error Get Stock Summary: $e");
      return [];
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
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
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

  // --- RAW MATERIAL STOCK ADJUSTMENT ---

  Future<List<dynamic>> getRawMaterialStockAdjustments() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-adjustments'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Mengembalikan List [...]
      }
      return [];
    } catch (e) {
      print("Error Get RM Adjustment: $e");
      return [];
    }
  }

  Future<bool> createRawMaterialStockAdjustment(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/raw-material-stock-adjustments'),
        headers: _headers(),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        print("Fail Create RM Adjustment: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error Create RM Adjustment: $e");
      return false;
    }
  }

  // --- STOCK MOVEMENTS (HISTORY) ---

  Future<List<dynamic>> getStockMovements() async {
    try {
      // PERBAIKAN: Endpoint yang benar sesuai api.php adalah '/stock-tracking'
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/stock-tracking'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);

        // Backend mengembalikan format: { "success": true, "data": [...] }
        if (json is Map && json.containsKey('data')) {
          return List<dynamic>.from(json['data']);
        }
        // Jaga-jaga jika backend mengembalikan list langsung
        else if (json is List) {
          return List<dynamic>.from(json);
        }
      }
      return [];
    } catch (e) {
      print("Error Get Stock Movements: $e");
      return [];
    }
  }

  // --- Laporan Kartu Persediaan ---

  Future<List<dynamic>> getInventoryProducts({
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      String queryParams = '?';
      if (startDate != null && startDate.isNotEmpty)
        queryParams += 'start_date=$startDate&';
      if (endDate != null && endDate.isNotEmpty)
        queryParams += 'end_date=$endDate&';
      if (search != null && search.isNotEmpty) queryParams += 'search=$search';

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/inventory/products$queryParams'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success' && json['data'] != null) {
          return List<dynamic>.from(json['data']);
        }
      }
      return [];
    } catch (e) {
      print("Error Get Inventory Products: $e");
      return [];
    }
  }

  Future<List<dynamic>> getInventoryRawMaterials({
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      String queryParams = '?';
      if (startDate != null && startDate.isNotEmpty)
        queryParams += 'start_date=$startDate&';
      if (endDate != null && endDate.isNotEmpty)
        queryParams += 'end_date=$endDate&';
      if (search != null && search.isNotEmpty) queryParams += 'search=$search';

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/inventory/raw-materials$queryParams'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success' && json['data'] != null) {
          return List<dynamic>.from(json['data']);
        }
      }
      return [];
    } catch (e) {
      print("Error Get Inventory Raw Materials: $e");
      return [];
    }
  }

  // --- REPORTS (LAPORAN) ---
  // --- LAPORAN BARANG MASUK ---
  Future<Map<String, dynamic>?> getIncomingGoodsReport({
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      String queryParams = '?';
      if (startDate != null && startDate.isNotEmpty)
        queryParams += 'start_date=$startDate&';
      if (endDate != null && endDate.isNotEmpty)
        queryParams += 'end_date=$endDate&';
      if (search != null && search.isNotEmpty) queryParams += 'search=$search';

      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/inventory/incoming-report$queryParams',
        ),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          return json; // Return seluruh JSON karena kita butuh 'data' (Map) dan 'meta' (Grand Total)
        }
      }
      return null;
    } catch (e) {
      print("Error Get Incoming Report: $e");
      return null;
    }
  }

  // --- LAPORAN BARANG KELUAR ---
  Future<Map<String, dynamic>?> getOutgoingGoodsReport({
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    try {
      String queryParams = '?';
      if (startDate != null && startDate.isNotEmpty)
        queryParams += 'start_date=$startDate&';
      if (endDate != null && endDate.isNotEmpty)
        queryParams += 'end_date=$endDate&';
      if (search != null && search.isNotEmpty) queryParams += 'search=$search';

      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/inventory/outgoing-report$queryParams',
        ),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success') {
          return json;
        }
      }
      return null;
    } catch (e) {
      print("Error Get Outgoing Report: $e");
      return null;
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

  Future<bool> updatePurchaseRequestItem(
    int id,
    Map<String, dynamic> data,
  ) async {
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

  // --- PURCHASE RETURNS (RETUR PEMBELIAN) ---

  Future<List<dynamic>> getPurchaseReturns() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/purchase-returns'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is List) return json;
        return [];
      }
      return [];
    } catch (e) {
      print("Error Get PR: $e");
      return [];
    }
  }

  // Ambil PO yang boleh diretur (Status: received / closed)
  Future<List<dynamic>> getReturnablePOs() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/purchase-returns-helpers/returnable-pos',
        ),
        headers: _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      print("Error Get Returnable PO: $e");
      return [];
    }
  }

  Future<bool> createPurchaseReturn(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-returns'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      if (response.statusCode != 201)
        print("Gagal Create Return: ${response.body}");
      return response.statusCode == 201;
    } catch (e) {
      print("Error Create Return: $e");
      return false;
    }
  }

  // Generic Action: submit, approve, reject, realize, complete
  Future<bool> actionPurchaseReturn(int id, String action) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/purchase-returns/$id/$action'),
        headers: _headers(),
      );
      if (response.statusCode != 200)
        print("Gagal $action Return: ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      print("Error $action Return: $e");
      return false;
    }
  }

  Future<bool> deletePurchaseReturn(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/purchase-returns/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete Return: $e");
      return false;
    }
  }

  // --- INVOICE RECEIPTS (TANDA TERIMA FAKTUR) ---

  Future<List<dynamic>> getInvoiceReceipts() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/invoice-receipts'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is List) return json;
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
      }
      return [];
    } catch (e) {
      print("Error Get Invoice Receipts: $e");
      return [];
    }
  }

  // API BARU: Untuk Dropdown Form Create
  Future<List<dynamic>> getEligiblePOs() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/invoice-receipts-helpers/eligible-pos',
        ),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is List) return json;
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
      }
      return [];
    } catch (e) {
      print("Error Get Eligible POs: $e");
      return [];
    }
  }

  Future<bool> createInvoiceReceipt(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/invoice-receipts'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      // Laravel mengembalikan status 201 Created atau 200
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create Invoice Receipt: $e");
      return false;
    }
  }

  Future<bool> actionInvoiceReceipt(int id, String action) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/invoice-receipts/$id/$action'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Action Invoice Receipt: $e");
      return false;
    }
  }

  Future<bool> deleteInvoiceReceipt(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/invoice-receipts/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Mengambil data khusus untuk cetak PDF
  Future<Map<String, dynamic>?> getInvoicePrintData(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/invoice-receipts/$id/print'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Error Get Print Data: $e");
      return null;
    }
  }

  // --- LAPORAN PEMBELIAN SUPPLIER ---

  Future<Map<String, dynamic>?> getSupplierPurchaseReport({
    String? startDate,
    String? endDate,
    String? supplierId,
  }) async {
    try {
      String queryParams = '?';
      if (startDate != null && startDate.isNotEmpty)
        queryParams += 'start_date=$startDate&';
      if (endDate != null && endDate.isNotEmpty)
        queryParams += 'end_date=$endDate&';
      if (supplierId != null && supplierId.isNotEmpty)
        queryParams += 'supplier_id=$supplierId';

      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/supplier-purchase-report$queryParams',
        ),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(
          response.body,
        ); // Mengembalikan Map yang berisi 'data' dan 'meta'
      }
      return null;
    } catch (e) {
      print("Error Get Supplier Purchase Report: $e");
      return null;
    }
  }

  //Penjualan
  //Sales Quotations
  Future<List<dynamic>> getSalesQuotations() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-quotations'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);

        // Pastikan status respon success
        if (json['success'] == true || json['data'] != null) {
          var responseData = json['data'];

          // CEK: Jika data dari paginate() Laravel (berbentuk Map/Objek yang memiliki key 'data' lagi)
          if (responseData is Map && responseData.containsKey('data')) {
            return List<dynamic>.from(responseData['data']);
          }
          // CEK: Jika data dari get() biasa (langsung berbentuk List/Array)
          else if (responseData is List) {
            return List<dynamic>.from(responseData);
          }
        }
      }
      return [];
    } catch (e) {
      print("Error Get SQ: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSalesQuotationDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-quotations/$id'),
        headers: _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createSalesQuotation(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-quotations'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create SQ: $e");
      return false;
    }
  }

  // Aksi untuk Approve atau Reject
  Future<bool> actionSalesQuotation(int id, String action) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-quotations/$id/$action'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateSalesQuotationStatus(int id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/sales-quotations/$id'),
        headers: _headers(),
        body: jsonEncode({"status": status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Update SQ Status: $e");
      return false;
    }
  }

  Future<bool> deleteSalesQuotation(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/sales-quotations/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Sales Orders
  Future<List<dynamic>> getSalesOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-orders'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['success'] == true || json['data'] != null) {
          var responseData = json['data'];
          if (responseData is Map && responseData.containsKey('data')) {
            return List<dynamic>.from(responseData['data']);
          } else if (responseData is List) {
            return List<dynamic>.from(responseData);
          }
        }
      }
      return [];
    } catch (e) {
      print("Error Get SO: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSalesOrderDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-orders/$id'),
        headers: _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createSalesOrder(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-orders'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create SO: $e");
      return false;
    }
  }

  Future<bool> updateSalesOrderStatus(int id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/sales-orders/$id'),
        headers: _headers(),
        body: jsonEncode({
          "status": status,
        }), // Bisa pending, processing, completed, dsb
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSalesOrder(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/sales-orders/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Fungsi Convert SQ ke SO (SPK) ---
  Future<bool> convertSqToSo(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-quotations/$id/convert'),
        headers: _headers(),
      );
      // Backend mengembalikan status 201 Created saat sukses
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Convert SQ: $e");
      return false;
    }
  }

  // Delivery Orders
  // 1. Dapatkan daftar DO
  Future<List<dynamic>> getDeliveryOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/delivery-orders'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);

        // 🔥 PERBAIKAN PENGECEKAN TIPE DATA
        if (json['data'] is Map && json['data'].containsKey('data')) {
          // Jika pakai paginate()
          return List<dynamic>.from(json['data']['data']);
        } else if (json['data'] is List) {
          // Jika pakai get()
          return List<dynamic>.from(json['data']);
        }
      }
      return [];
    } catch (e) {
      print("Error Get DO: $e"); // Akan muncul di terminal jika masih ada error
      return [];
    }
  }

  // 2. Dapatkan detail DO
  Future<Map<String, dynamic>?> getDeliveryOrderDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/delivery-orders/$id'),
        headers: _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  // 3. Buat DO Baru
  Future<Map<String, dynamic>?> createDeliveryOrder(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/delivery-orders'),
        headers: _headers(),
        body: jsonEncode(data),
      );

      // Jika berhasil (201 Created atau 200 OK)
      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body); // Kembalikan datanya (mengandung ID)
      } else {
        print("Error Create DO API: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error Exception Create DO: $e");
      return null;
    }
  }

  // 4. Ubah status DO jadi Shipped (Dikirim) -> [PERBAIKAN ROUTE: /send]
  Future<bool> sendDeliveryOrder(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/delivery-orders/$id/send'),
        headers: _headers(),
      );

      if (response.statusCode != 200) {
        print("Gagal Send DO: ${response.body}");
      }
      return response.statusCode == 200;
    } catch (e) {
      print("Error Send DO: $e");
      return false;
    }
  }

  // 5. Ubah status DO jadi Received (Diterima)
  Future<bool> confirmReceivedDO(int id) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AuthService.baseUrl}/delivery-orders/$id/confirm-received',
        ),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Confirm Received DO: $e");
      return false;
    }
  }

  // 6. Hapus DO (Soft Delete)
  Future<bool> deleteDeliveryOrder(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/delivery-orders/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete DO: $e");
      return false;
    }
  }

  // 7. AMBIL OUTSTANDING ITEMS DARI SALES ORDER (Penting untuk Form Buat DO) -> [PERBAIKAN ROUTE: /outstanding]
  Future<Map<String, dynamic>?> getSalesOrderOutstanding(int soId) async {
    try {
      // Endpoint ini berada di SalesOrderController Laravel kamu
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-orders/$soId/outstanding'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Error Get Outstanding SO: $e");
      return null;
    }
  }

  // --- FUNGSI BYPASS OUTSTANDING (DIHITUNG OLEH FLUTTER) ---
  Future<List<Map<String, dynamic>>> getManualOutstandingItems(
    int salesOrderId,
  ) async {
    try {
      // Kita Tembak API Detail SO biasa, BUKAN API Outstanding
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-orders/$salesOrderId'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        var data = json['data'];

        if (data != null && data['items'] != null) {
          List<dynamic> items = data['items'];
          List<Map<String, dynamic>> outstandingItems = [];

          for (var item in items) {
            // Parsing nilai dengan aman
            double qtyPesanan =
                double.tryParse(item['qty_pesanan']?.toString() ?? '0') ?? 0;
            double qtyShipped =
                double.tryParse(item['qty_shipped']?.toString() ?? '0') ?? 0;

            // FLUTTER YANG MENGHITUNG SISA
            double sisa = qtyPesanan - qtyShipped;

            // Hanya masukkan ke list jika barang benar-benar masih ada sisa
            if (sisa > 0) {
              outstandingItems.add({
                'sales_order_item_id': item['id'],
                'product_id': item['product_id'],
                'product_name': item['product'] != null
                    ? item['product']['name']
                    : 'Unknown',
                'qty_pesanan': qtyPesanan,
                'qty_terkirim': qtyShipped,
                'qty_sisa': sisa, // Nilai ini yang akan jadi patokan input
              });
            }
          }
          return outstandingItems; // Kembalikan list yang sudah difilter Flutter
        }
      }
      return [];
    } catch (e) {
      print("Error Get Manual Outstanding: $e");
      return [];
    }
  }

  // Sales Invoices
  // ============================================================
  // BAGIAN SALES INVOICE — tambahkan ke dalam class DataService
  // File: lib/services/data_service.dart
  //
  // Import yang dibutuhkan (tambahkan ke bagian atas data_service.dart):
  //   import 'dart:convert';
  //   import 'package:http/http.dart' as http;
  // ============================================================

  // ----------------------------------------------------------
  // GET: Daftar semua Sales Invoice
  // Endpoint: GET /api/v1/sales-invoices
  // ----------------------------------------------------------
  Future<List<dynamic>> getSalesInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-invoices'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        // Handle Laravel paginate: { data: { data: [...] } }
        if (json['data'] is Map && json['data']['data'] != null) {
          return json['data']['data'];
        }
        return json['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSalesInvoiceDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-invoices/$id'),
        headers: _headers(),
      );

      print('=== getSalesInvoiceDetail status: ${response.statusCode}');
      print(
        '=== body preview: ${response.body.substring(0, response.body.length.clamp(0, 300))}',
      );

      if (response.body.isEmpty) return null;

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      // Laravel 500 — kemungkinan karena tabel invoice_installments belum ada
      // Fallback: ambil dari list index, cari by id
      if (response.statusCode == 500) {
        print('=== show() gagal 500, fallback ke list index...');
        return await _getSalesInvoiceFromList(id);
      }

      return null;
    } catch (e) {
      print('=== getSalesInvoiceDetail error: $e');
      return await _getSalesInvoiceFromList(id);
    }
  }

  // Fallback: ambil dari index, filter by id
  Future<Map<String, dynamic>?> _getSalesInvoiceFromList(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-invoices?per_page=999'),
        headers: _headers(),
      );
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body);
      List<dynamic> list = [];
      if (json['data'] is Map && json['data']['data'] != null) {
        list = json['data']['data'];
      } else if (json['data'] is List) {
        list = json['data'];
      }

      final found = list.firstWhere(
        (item) => item['id'] == id,
        orElse: () => null,
      );

      if (found == null) return null;
      return {'success': true, 'data': found};
    } catch (e) {
      print('=== _getSalesInvoiceFromList error: $e');
      return null;
    }
  }

  // ----------------------------------------------------------
  // POST: Buat Sales Invoice baru
  // Endpoint: POST /api/v1/sales-invoices
  // Body: { sales_order_id, payment_type: 'full'|'dp', dp_amount? }
  // Return: Map berisi { success, message, data }
  // ----------------------------------------------------------
  Future<Map<String, dynamic>?> createSalesInvoice(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-invoices'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan.'};
    }
  }

  // ----------------------------------------------------------
  // PUT: Update Invoice (hanya due_date & notes, jika belum paid)
  // Endpoint: PUT /api/v1/sales-invoices/{id}
  // ----------------------------------------------------------
  Future<Map<String, dynamic>?> updateSalesInvoice(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/sales-invoices/$id'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan.'};
    }
  }

  // ----------------------------------------------------------
  // DELETE: Soft-delete Invoice (hanya jika belum paid)
  // Endpoint: DELETE /api/v1/sales-invoices/{id}
  // ----------------------------------------------------------
  Future<bool> deleteSalesInvoice(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/sales-invoices/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // POST: Restore Invoice dari sampah
  // Endpoint: POST /api/v1/sales-invoices/{id}/restore
  // ----------------------------------------------------------
  Future<bool> restoreSalesInvoice(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-invoices/$id/restore'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // POST: Bayar cicilan
  // Endpoint: POST /api/v1/sales-invoices/{id}/installment
  // Body: { amount, notes? }
  // ----------------------------------------------------------
  Future<Map<String, dynamic>?> payInstallment(
    int id,
    double amount, {
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-invoices/$id/installment'),
        headers: _headers(),
        body: jsonEncode({
          'amount': amount,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan.'};
    }
  }

  // ----------------------------------------------------------
  // POST: Lunasi sisa tagihan sekaligus
  // Endpoint: POST /api/v1/sales-invoices/{id}/pay-remainder
  // ----------------------------------------------------------
  Future<Map<String, dynamic>?> payRemainderInvoice(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-invoices/$id/pay-remainder'),
        headers: _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan.'};
    }
  }

  // ----------------------------------------------------------
  // GET: Invoice yang belum lunas (pending payments)
  // Endpoint: GET /api/v1/sales-invoices/pending-payments
  // ----------------------------------------------------------
  Future<List<dynamic>> getPendingInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-invoices/pending-payments'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['data'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ----------------------------------------------------------
  // HELPER: updateSalesInvoiceStatus
  // Dipanggil dari _changeStatus di halaman.
  // Karena Laravel tidak punya endpoint ubah status manual,
  // method ini mengarahkan ke pay-remainder jika target = 'paid'.
  // ----------------------------------------------------------
  Future<bool> updateSalesInvoiceStatus(int id, String status) async {
    if (status == 'paid') {
      final res = await payRemainderInvoice(id);
      return res?['success'] == true;
    }
    return false;
  }

  // ==========================================
  // SALES RETURNS (RETUR PENJUALAN)
  // ==========================================

  Future<List<dynamic>> getSalesReturns() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-returns'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['data'] is List) return List<dynamic>.from(json['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSalesReturnDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/sales-returns/$id'),
        headers: _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createSalesReturn(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/sales-returns'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSalesReturn(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/sales-returns/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Sales Reports
  // ==========================================
  // SALES REPORTS (LAPORAN PENJUALAN)
  // ==========================================

  Future<Map<String, dynamic>?> getSalesResume({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };
      final uri = Uri.parse(
        '${AuthService.baseUrl}/sales-reports/resume',
      ).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        return json['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getSalesReportByProduct({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final params = {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      };
      final uri = Uri.parse(
        '${AuthService.baseUrl}/sales-reports/by-product',
      ).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['data'] is List) return List<dynamic>.from(json['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // payment_status: null | 'paid' | 'unpaid'
  Future<List<dynamic>> getSalesReportByCustomer({
    String? startDate,
    String? endDate,
    String? paymentStatus,
  }) async {
    try {
      final params = {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (paymentStatus != null) 'payment_status': paymentStatus,
      };
      final uri = Uri.parse(
        '${AuthService.baseUrl}/sales-reports/by-customer',
      ).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['data'] is List) return List<dynamic>.from(json['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getSalesMonthlyTrend({String? year}) async {
    try {
      final params = {if (year != null) 'year': year};
      final uri = Uri.parse(
        '${AuthService.baseUrl}/sales-reports/monthly-trend',
      ).replace(queryParameters: params.isNotEmpty ? params : null);
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['data'] is List) return List<dynamic>.from(json['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getSalesAgingReport() async {
    try {
      final uri = Uri.parse('${AuthService.baseUrl}/sales-reports/aging');
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['data'] is List) return List<dynamic>.from(json['data']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Produksi
  // --- BILL OF MATERIALS (BOM) ---

  Future<List<dynamic>> getBOMs() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/bill-of-materials'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
        return List<dynamic>.from(json);
      }
      return [];
    } catch (e) {
      print("Error Get BOM: $e");
      return [];
    }
  }

  Future<bool> createBOM(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/bill-of-materials'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create BOM: $e");
      return false;
    }
  }

  Future<bool> deleteBOM(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/bill-of-materials/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Delete BOM: $e");
      return false;
    }
  }

  // --- PRODUCTION ORDERS ---

  Future<List<dynamic>> getProductionOrders() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/production-orders'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is List) return json;
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
      }
      return [];
    } catch (e) {
      print("Error Get Production Orders: $e");
      return [];
    }
  }

  Future<bool> createProductionOrder(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/production-orders'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create Production Order: $e");
      return false;
    }
  }

  // Release PO (Cek Stok Bahan Baku)
  Future<Map<String, dynamic>> releaseProductionOrder(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/production-orders/$id/release'),
        headers: _headers(),
      );
      var json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': json['message'] ?? 'Berhasil di-release',
        };
      } else {
        // Menangkap error jika material tidak cukup (biasanya 422 Unprocessable Entity)
        return {
          'success': false,
          'message': json['message'] ?? 'Gagal',
          'data': json['insufficient_materials'],
        };
      }
    } catch (e) {
      print("Error Release PO: $e");
      return {'success': false, 'message': 'Terjadi kesalahan sistem'};
    }
  }

  Future<bool> deleteProductionOrder(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/production-orders/$id'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- PRODUCTION EXECUTIONS & HPP ---

  // Mengambil daftar eksekusi produksi (Released, In Progress, Completed)
  Future<List<dynamic>> getProductionExecutions({
    String? startDate,
    String? endDate,
  }) async {
    try {
      String queryParams = '?';
      if (startDate != null) queryParams += 'start_date=$startDate&';
      if (endDate != null) queryParams += 'end_date=$endDate';

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/production-executions$queryParams'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json is Map && json.containsKey('data'))
          return List<dynamic>.from(json['data']);
        return List<dynamic>.from(json);
      }
      return [];
    } catch (e) {
      print("Error Get Production Executions: $e");
      return [];
    }
  }

  // Memulai Produksi (Memotong stok bahan baku)
  Future<bool> startProduction(
    int executionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AuthService.baseUrl}/production-executions/$executionId/start',
        ),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Start Production: $e");
      return false;
    }
  }

  // Menyelesaikan Produksi (Menghitung HPP & Menambah stok produk jadi)
  Future<bool> completeProduction(
    int executionId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AuthService.baseUrl}/production-executions/$executionId/complete',
        ),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Complete Production: $e");
      return false;
    }
  }

  // Mengambil Laporan Rincian HPP
  Future<Map<String, dynamic>?> getProductionReport(int executionId) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/production-executions/$executionId/report',
        ),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print("Error Get Production Report: $e");
      return null;
    }
  }

  // Akutansi dan Keuangan
  // Mengambil daftar Hutang (Hanya yang belum lunas / unpaid untuk dropdown)
  Future<List<dynamic>> getUnpaidAccountPayables() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/account-payables?status=unpaid'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonRes = jsonDecode(response.body);
        return jsonRes is List ? jsonRes : (jsonRes['data'] ?? []);
      }
      return [];
    } catch (e) {
      print("Error Get Unpaid Account Payables: $e");
      return [];
    }
  }

  // Mengambil riwayat Pembayaran Hutang
  Future<List<dynamic>> getPayablePayments() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/payable-payments'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonRes = jsonDecode(response.body);
        return jsonRes is List ? jsonRes : (jsonRes['data'] ?? []);
      }
      return [];
    } catch (e) {
      print("Error Get Payable Payments: $e");
      return [];
    }
  }

  // Membuat Draft Pembayaran Hutang
  Future<bool> createPayablePayment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/payable-payments'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create Payable Payment: $e");
      return false;
    }
  }

  // Konfirmasi Pembayaran Hutang (Hutang Lunas & Jurnal Terbentuk)
  Future<bool> confirmPayablePayment(int id) async {
    try {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/payable-payments/$id/confirm'),
        headers: _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error Confirm Payable Payment: $e");
      return false;
    }
  }

  // Hutang Usaha (AP)
  // 1. Mengambil semua data Hutang Usaha
  Future<List<dynamic>> getAccountPayables() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/account-payables'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonRes = jsonDecode(response.body);
        return jsonRes is List ? jsonRes : (jsonRes['data'] ?? []);
      }
      return [];
    } catch (e) {
      print("Error Get Account Payables: $e");
      return [];
    }
  }

  // 2. Mengambil TTF yang statusnya Approved (Belum jadi AP)
  Future<List<dynamic>> getApprovedInvoiceReceipts() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/invoice-receipts?status=approved'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        var jsonRes = jsonDecode(response.body);
        return jsonRes is List ? jsonRes : (jsonRes['data'] ?? []);
      }
      return [];
    } catch (e) {
      print("Error Get Approved TTF: $e");
      return [];
    }
  }

  // 3. Membuat Hutang (AP) dari TTF (Update dengan COA)
  Future<bool> createAccountPayableFromTTF(
    int invoiceReceiptId,
    int payableAccountId,
    int inventoryAccountId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${AuthService.baseUrl}/account-payables/from-invoice-receipt',
        ),
        headers: _headers(),
        body: jsonEncode({
          "invoice_receipt_id": invoiceReceiptId,
          "payable_account_id": payableAccountId,
          "inventory_account_id": inventoryAccountId,
        }),
      );
      // Backend mengembalikan 201 Created saat sukses
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print("Error Create AP from TTF: $e");
      return false;
    }
  }

  // Jurnal $ Buku Besar
  // 1. Ambil Buku Besar (Sesuai fungsi detail() di PHP)
  Future<Map<String, dynamic>?> getLedgerDetail(
    int accountId,
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/ledger/detail/$accountId?start_date=$startDate&end_date=$endDate',
        ),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(
          response.body,
        ); // Mengembalikan utuh 1 object dari PHP
      }
      return null;
    } catch (e) {
      print("Error Get Ledger: $e");
      return null;
    }
  }

  // 2. Ambil Neraca Saldo (Sesuai fungsi trialBalance() di PHP)
  Future<Map<String, dynamic>?> getTrialBalance(
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/ledger/trial-balance?start_date=$startDate&end_date=$endDate',
        ),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(
          response.body,
        ); // Mengembalikan utuh 1 object dari PHP
      }
      return null;
    } catch (e) {
      print("Error Get Trial Balance: $e");
      return null;
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

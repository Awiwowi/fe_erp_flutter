import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class InitialStocksPage extends StatefulWidget {
  const InitialStocksPage({super.key});

  @override
  State<InitialStocksPage> createState() => _InitialStocksPageState();
}

class _InitialStocksPageState extends State<InitialStocksPage> {
  bool _isLoading = true;
  
  // Data Master
  List<dynamic> _warehouses = [];
  List<dynamic> _products = [];
  
  // Data Index (List Stok yang sudah ada)
  List<dynamic> _stocks = []; 

  // State Form
  int? _selectedWarehouseId;
  
  // List untuk menampung baris inputan barang
  List<Map<String, dynamic>> _inputItems = [];

  @override
  void initState() {
    super.initState();
    _addInputRow(); // Tambah 1 baris kosong di awal
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Ambil data Gudang, Produk, DAN Daftar Stok (Index)
      var wh = await DataService().getWarehouses();
      var prod = await DataService().getProducts();
      var st = await DataService().getInitialStocks(); // Pastikan fungsi ini ada di DataService

      if (!mounted) return;

      setState(() {
        _warehouses = wh;
        _products = prod;
        _stocks = st; // Simpan data stok ke state
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetch data: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  void _addInputRow() {
    setState(() {
      _inputItems.add({
        "product_id": null,
        "qty_ctrl": TextEditingController(text: "0"),
      });
    });
  }

  void _removeInputRow(int index) {
    if (_inputItems.length > 1) {
      setState(() {
        _inputItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal harus ada 1 barang"))
      );
    }
  }

  void _submit() async {
    // Validasi Dasar
    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Gudang terlebih dahulu!")));
      return;
    }

    List<Map<String, dynamic>> itemsToSend = [];

    for (var item in _inputItems) {
      int? pid = item['product_id'];
      String qtyStr = item['qty_ctrl'].text;
      int qty = int.tryParse(qtyStr) ?? 0;

      if (pid == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ada baris produk yang belum dipilih!")));
        return;
      }
      if (qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jumlah stok harus lebih dari 0!")));
        return;
      }

      itemsToSend.add({
        "product_id": pid,
        "quantity": qty
      });
    }

    // Proses Kirim
    final messenger = ScaffoldMessenger.of(context); // Simpan messenger
    setState(() => _isLoading = true);
    
    // Note: Pastikan nama fungsi di DataService sesuai ('addInitialStocks' atau 'createInitialStocks')
    // Di sini saya pakai createInitialStocks sesuai kodingan Anda sebelumnya
    bool success = await DataService().addInitialStocks({
      "warehouse_id": _selectedWarehouseId,
      "items": itemsToSend
    });
    
    if (!mounted) return;
    
    if (success) {
      _fetchData(); // Refresh Data (agar tabel stok di bawah terupdate otomatis)
      messenger.showSnackBar(const SnackBar(content: Text("Stok Awal Berhasil Diinput!"), backgroundColor: Colors.green));
      
      // Reset Form
      setState(() {
        _selectedWarehouseId = null;
        _inputItems.clear();
        _addInputRow();
      });
    } else {
      setState(() => _isLoading = false);
      messenger.showSnackBar(const SnackBar(content: Text("Gagal input stok."), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          // --- BAGIAN 1: FORM INPUT STOK AWAL ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Input Stok Awal", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)
                ),
                const Text(
                  "Masukkan saldo stok awal untuk gudang (Setup Awal)", 
                  style: TextStyle(fontSize: 12, color: Colors.grey)
                ),
                const SizedBox(height: 20),

                if (_isLoading && _warehouses.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. PILIH GUDANG
                      DropdownButtonFormField<int>(
                        value: _selectedWarehouseId,
                        decoration: const InputDecoration(
                          labelText: "Pilih Gudang",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warehouse)
                        ),
                        items: _warehouses.map((w) => DropdownMenuItem<int>(
                          value: w['id'],
                          child: Text(w['name']),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedWarehouseId = val),
                      ),
                      const SizedBox(height: 20),

                      // 2. LIST BARANG INPUT
                      const Text("Daftar Barang:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _inputItems.length,
                        itemBuilder: (ctx, index) {
                          var row = _inputItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50
                            ),
                            child: Row(
                              children: [
                                // Dropdown Product
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<int>(
                                    value: row['product_id'],
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: "Produk",
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      border: OutlineInputBorder()
                                    ),
                                    items: _products.map((p) => DropdownMenuItem<int>(
                                      value: p['id'],
                                      child: Text(p['name'], overflow: TextOverflow.ellipsis),
                                    )).toList(),
                                    onChanged: (val) => setState(() => row['product_id'] = val),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                
                                // Input Qty
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller: row['qty_ctrl'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Qty",
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      border: OutlineInputBorder()
                                    ),
                                  ),
                                ),
                                
                                // Tombol Hapus Baris
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeInputRow(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Tombol Tambah Baris
                      TextButton.icon(
                        onPressed: _addInputRow, 
                        icon: const Icon(Icons.add), 
                        label: const Text("Tambah Baris Barang")
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      // TOMBOL SUBMIT
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text("SIMPAN STOK AWAL", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- BAGIAN 2: TABEL DATA STOK YANG SUDAH ADA ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Data Stok Saat Ini", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)
                ),
                const SizedBox(height: 15),

                _stocks.isEmpty 
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada data stok.")))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text("Produk")),
                          DataColumn(label: Text("Gudang")),
                          DataColumn(label: Text("Quantity")),
                        ],
                        rows: _stocks.map((item) {
                          // Mapping sesuai controller index
                          return DataRow(cells: [
                            DataCell(Text(item['product_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(item['warehouse'] ?? '-')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4)
                                ),
                                child: Text(
                                  item['quantity'].toString(), 
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
                                ),
                              )
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
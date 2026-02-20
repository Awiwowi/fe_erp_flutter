import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class ProductStockPage extends StatefulWidget {
  const ProductStockPage({super.key});

  @override
  State<ProductStockPage> createState() => _ProductStockPageState();
}

class _ProductStockPageState extends State<ProductStockPage> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    try {
      var data = await DataService().getProductStockSummary();
      
      // Filter: Hanya ambil yang category/type-nya 'Product' (sesuai request)
      var filteredData = data.where((item) {
        final type = item['type'] ?? item['category'] ?? '';
        return type == 'Product';
      }).toList();

      setState(() {
        _products = filteredData;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching stock: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(10), 
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Tanpa Tombol Add
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Product Stock Tracking", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)
                ),
                // Bisa tambah tombol Refresh atau Filter Date jika perlu di sini
              ],
            ),
            const SizedBox(height: 20),
            
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _products.isEmpty 
                  ? const Center(child: Text("Belum ada data stok produk."))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9FC)),
                          columns: const [
                            DataColumn(label: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Category", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Unit", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Current Stock", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _products.map((item) {
                            // Ambil quantity, pastikan tipe data aman (double/int)
                            double qty = double.tryParse(item['current_stock'].toString()) ?? 0.0;

                            return DataRow(cells: [
                              DataCell(Text(item['code'] ?? item['kode'] ?? '-')),
                              DataCell(Text(item['name'] ?? '-')),
                              DataCell(Text(item['type'] ?? item['category'] ?? '-')),
                              DataCell(Text(item['unit'] ?? '-')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    // Merah jika stok <= 0, Hijau jika aman
                                    color: qty <= 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    qty.toString(), // Tampilkan Quantity
                                    style: TextStyle(
                                      color: qty <= 0 ? Colors.red : Colors.green, 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                )
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
          ],
        ),
      ),
    );
  }
}
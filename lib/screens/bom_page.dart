import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class BOMPage extends StatefulWidget {
  const BOMPage({super.key});

  @override
  State<BOMPage> createState() => _BOMPageState();
}

class _BOMPageState extends State<BOMPage> {
  List<dynamic> _boms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getBOMs();
    if (mounted) {
      setState(() {
        _boms = data;
        _isLoading = false;
      });
    }
  }

  // --- MODAL UNTUK MELIHAT DETAIL BAHAN BAKU ---
  void _showDetailModal(Map<String, dynamic> bom) {
    List<dynamic> items = bom['items'] ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detail Bahan Baku: ${bom['bom_number'] ?? 'BOM'}"),
        content: SizedBox(
          width: double.maxFinite,
          child: items.isEmpty 
            ? const Text("Tidak ada item bahan baku.")
            : ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var item = items[index];
                  // Raw Material menggunakan 'name' di model Laravel Anda
                  String materialName = item['raw_material']?['name'] ?? "Bahan #${item['raw_material_id']}";
                  String unit = item['unit']?['name'] ?? "";
                  return ListTile(
                    leading: CircleAvatar(child: Text("${index + 1}")),
                    title: Text(materialName),
                    subtitle: Text("Kebutuhan: ${item['quantity']} $unit"),
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bill of Materials (BOM)", 
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text("Daftar resep produksi produk jadi", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
                    onPressed: _fetchData,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text("Refresh Data", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // TABEL
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _boms.isEmpty
                        ? const Center(child: Text("Belum ada data BOM yang tersimpan."))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                columns: const [
                                  DataColumn(label: Text("Kode BOM")),
                                  DataColumn(label: Text("Produk Jadi (Target)")),
                                  DataColumn(label: Text("Batch Size")),
                                  DataColumn(label: Text("Status")),
                                  DataColumn(label: Text("Aksi")),
                                ],
                                rows: _boms.map((bom) {
                                  // 1. Ambil Kode BOM (Fallback ke ID jika null)
                                  String bomNumber = bom['bom_number']?.toString() ?? "BOM-${bom['id']}";

                                  // 2. LOGIKA PRODUK JADI (Sesuai permintaan Anda menggunakan ID sebagai cadangan)
                                  // Di Product.php model Anda menggunakan 'nama'
                                  String productName = "-";
                                  if (bom['product'] != null) {
                                    productName = bom['product']['nama'] ?? bom['product']['name'] ?? "ID: ${bom['product_id']}";
                                  } else {
                                    productName = "Produk ID: ${bom['product_id']}";
                                  }
                                  
                                  // 3. Batch Size / Qty Output
                                  String batchSize = "${bom['batch_size'] ?? '0'}";

                                  bool isActive = bom['is_active'] == 1 || bom['is_active'] == true;

                                  return DataRow(cells: [
                                    DataCell(Text(bomNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(productName)),
                                    DataCell(Text(batchSize)),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(color: isActive ? Colors.green : Colors.red),
                                        ),
                                        child: Text(isActive ? "AKTIF" : "NON-AKTIF", 
                                          style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.receipt_long, color: Colors.blue),
                                          tooltip: "Lihat Bahan Baku",
                                          onPressed: () => _showDetailModal(bom),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          onPressed: () {},
                                        ),
                                      ],
                                    )),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
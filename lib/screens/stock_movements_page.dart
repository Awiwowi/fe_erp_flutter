import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class StockMovementsPage extends StatefulWidget {
  const StockMovementsPage({super.key});

  @override
  State<StockMovementsPage> createState() => _StockMovementsPageState();
}

class _StockMovementsPageState extends State<StockMovementsPage> {
  List<dynamic> _movements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getStockMovements();
    setState(() {
      _movements = data;
      _isLoading = false;
    });
  }

  // Helper untuk menentukan warna badge tipe pergerakan
  Color _getMovementColor(String type) {
    String t = type.toUpperCase();
    if (t.contains('IN')) return Colors.green;
    if (t.contains('OUT')) return Colors.red;
    return Colors.blue; // Untuk Adjustment / Transfer
  }

  // Helper untuk format tanggal sederhana
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    // Mengambil "YYYY-MM-DD HH:MM" dari "YYYY-MM-DDTHH:MM:SS.000000Z"
    try {
      DateTime dt = DateTime.parse(dateString).toLocal();
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString.split('T')[0]; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Histori Pergerakan Stok (Ledger)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  tooltip: "Refresh Data",
                  onPressed: _fetchData,
                )
              ],
            ),
            const SizedBox(height: 20),

            // CONTENT / TABLE
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _movements.isEmpty
                    ? const Center(child: Text("Belum ada riwayat pergerakan stok."))
                    : SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn(label: Text("Tanggal & Waktu", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Nama Item", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Tipe Mutasi", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Kuantitas", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _movements.map((item) {
                            String movementType = (item['movement_type'] ?? '-').toString().toUpperCase();
                            Color typeColor = _getMovementColor(movementType);

                            return DataRow(cells: [
                              DataCell(Text(_formatDate(item['created_at']))),
                              DataCell(Text(item['item_name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                  child: Text(
                                    item['item_type']?.toString() ?? '-', 
                                    style: const TextStyle(fontSize: 12)
                                  ),
                                )
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: typeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                  child: Text(
                                    movementType, 
                                    style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold)
                                  ),
                                )
                              ),
                              DataCell(
                                Text(
                                  item['quantity']?.toString() ?? '0',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                )
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}
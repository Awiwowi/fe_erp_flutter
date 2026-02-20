import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class ProductionExecutionsPage extends StatefulWidget {
  const ProductionExecutionsPage({super.key});

  @override
  State<ProductionExecutionsPage> createState() => _ProductionExecutionsPageState();
}

class _ProductionExecutionsPageState extends State<ProductionExecutionsPage> {
  List<dynamic> _executions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getProductionExecutions();
    if (mounted) {
      setState(() {
        _executions = data;
        _isLoading = false;
      });
    }
  }

  // --- MODAL SELESAIKAN PRODUKSI ---
  void _showCompleteDialog(Map<String, dynamic> po) {
    final qtyActualCtrl = TextEditingController(text: po['quantity_plan']?.toString() ?? '');
    final qtyWasteCtrl = TextEditingController(text: '0');
    final laborCostCtrl = TextEditingController(text: '0');
    final overheadCostCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Selesaikan Produksi: ${po['production_number'] ?? po['order_number']}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: qtyActualCtrl, decoration: const InputDecoration(labelText: "Kuantitas Hasil Aktual *", border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              TextField(controller: qtyWasteCtrl, decoration: const InputDecoration(labelText: "Kuantitas Rusak (Waste)", border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              TextField(controller: laborCostCtrl, decoration: const InputDecoration(labelText: "Biaya Tenaga Kerja (Labor Cost)", border: OutlineInputBorder(), prefixText: "Rp "), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              TextField(controller: overheadCostCtrl, decoration: const InputDecoration(labelText: "Biaya Overhead (Listrik, dll)", border: OutlineInputBorder(), prefixText: "Rp "), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Catatan", border: OutlineInputBorder()), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (qtyActualCtrl.text.isEmpty) return;

              Map<String, dynamic> payload = {
                'quantity_actual': double.tryParse(qtyActualCtrl.text) ?? 0,
                'quantity_waste': double.tryParse(qtyWasteCtrl.text) ?? 0,
                'labor_cost': double.tryParse(laborCostCtrl.text) ?? 0,
                'overhead_cost': double.tryParse(overheadCostCtrl.text) ?? 0,
                'notes': notesCtrl.text,
                'completed_at': DateTime.now().toIso8601String(),
              };

              Navigator.pop(context);
              setState(() => _isLoading = true);
              bool success = await DataService().completeProduction(po['id'], payload);
              if (success) {
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produksi Selesai. HPP dihitung & Stok bertambah.")));
              } else {
                setState(() => _isLoading = false);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menyelesaikan produksi.")));
              }
            },
            child: const Text("Selesaikan & Hitung HPP", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- MODAL LAPORAN HPP ---
  void _showReportDialog(int poId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    var report = await DataService().getProductionReport(poId);
    Navigator.pop(context); // Tutup loading

    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memuat laporan HPP.")));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Laporan HPP: ${report['production_number']}", style: const TextStyle(color: AppColors.primary)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Produk: ${report['product']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("Efisiensi: ${double.tryParse(report['efficiency']?.toString() ?? '0')?.toStringAsFixed(2)}%"),
              const Divider(),
              const Text("Rincian Kuantitas", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("- Rencana: ${report['quantity_plan']}"),
              Text("- Aktual: ${report['quantity_actual']}"),
              Text("- Waste: ${report['quantity_waste']}"),
              const Divider(),
              const Text("Rincian Biaya (Cost Breakdown)", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("- Biaya Material: Rp ${report['material_cost']}"),
              Text("- Biaya Tenaga Kerja: Rp ${report['labor_cost']}"),
              Text("- Biaya Overhead: Rp ${report['overhead_cost']}"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.green.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Biaya Produksi: Rp ${report['total_production_cost']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("HPP Per Unit: Rp ${double.tryParse(report['hpp_per_unit']?.toString() ?? '0')?.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                  ],
                ),
              ),
              const Divider(),
              const Text("Detail Penggunaan Material:", style: TextStyle(fontWeight: FontWeight.bold)),
              if (report['material_usage'] != null)
                ...List<Widget>.from(report['material_usage'].map((m) => 
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("• ${m['material']} (${m['quantity_used']} x Rp${m['unit_cost']}) = Rp${m['total_cost']}", style: const TextStyle(fontSize: 12)),
                  )
                )),
            ],
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Eksekusi Produksi & HPP", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      Text("Penyelesaian produksi dan laporan Harga Pokok Penjualan", style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.refresh, color: AppColors.primary), onPressed: _fetchData),
                ],
              ),
              const SizedBox(height: 25),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _executions.isEmpty
                        ? const Center(child: Text("Belum ada eksekusi produksi."))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                columns: const [
                                  DataColumn(label: Text("No. Produksi")),
                                  DataColumn(label: Text("Produk Target")),
                                  DataColumn(label: Text("Qty Rencana")),
                                  DataColumn(label: Text("Status")),
                                  DataColumn(label: Text("HPP/Unit")),
                                  DataColumn(label: Text("Aksi")),
                                ],
                                rows: _executions.map((item) {
                                  String orderNumber = item['production_number'] ?? item['order_number'] ?? "-";
                                  String productName = item['product']?['nama'] ?? item['product']?['name'] ?? "-";
                                  String qty = item['quantity_plan']?.toString() ?? "0";
                                  String status = (item['status'] ?? '').toString();
                                  bool isCompleted = status.toLowerCase() == 'completed';
                                  
                                  String hpp = isCompleted ? "Rp ${double.tryParse(item['hpp_per_unit']?.toString() ?? '0')?.toStringAsFixed(0)}" : "-";

                                  return DataRow(cells: [
                                    DataCell(Text(orderNumber, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(productName)),
                                    DataCell(Text(qty)),
                                    DataCell(
                                      Chip(
                                        label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                        backgroundColor: isCompleted ? Colors.green : Colors.blue,
                                      ),
                                    ),
                                    DataCell(Text(hpp, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                                    DataCell(Row(
                                      children: [
                                        if (!isCompleted)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                            icon: const Icon(Icons.check, color: Colors.white, size: 16),
                                            label: const Text("Selesaikan", style: TextStyle(color: Colors.white, fontSize: 12)),
                                            onPressed: () => _showCompleteDialog(item),
                                          ),
                                        if (isCompleted)
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.analytics, size: 16),
                                            label: const Text("Lihat Laporan HPP", style: TextStyle(fontSize: 12)),
                                            onPressed: () => _showReportDialog(item['id']),
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
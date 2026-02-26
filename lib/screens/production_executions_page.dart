import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class ProductionExecutionsPage extends StatefulWidget {
  const ProductionExecutionsPage({super.key});

  @override
  State<ProductionExecutionsPage> createState() =>
      _ProductionExecutionsPageState();
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

    var allOrders = await DataService().getProductionOrders();

    if (mounted) {
      setState(() {
        _executions = allOrders.where((item) {
          String status = (item['status'] ?? '').toString().toLowerCase();
          return status == 'released' ||
              status == 'in_progress' ||
              status == 'completed';
        }).toList();
        _isLoading = false;
      });
    }
  }

  // --- AKSI 1: MULAI PRODUKSI ---
  void _startExecution(int id) async {
    final operatorCtrl = TextEditingController(text: "Operator 1");

    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Mulai Produksi?"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Tindakan ini akan memotong stok bahan baku di gudang.",
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: operatorCtrl,
                  decoration: const InputDecoration(
                    labelText: "Nama Operator *",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Mulai Pengerjaan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    // AMANKAN CONTEXT DI SINI
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (confirm) {
      if (operatorCtrl.text.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text("Nama Operator wajib diisi!")),
        );
        return;
      }

      setState(() => _isLoading = true);

      Map<String, dynamic> payload = {
        "started_at": DateTime.now().toIso8601String(),
        "operator": operatorCtrl.text,
      };

      bool success = await DataService().startProduction(id, payload);

      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Produksi dimulai, Stok bahan baku terpotong."),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(content: Text("Gagal memulai produksi.")),
        );
      }
    }
  }

  // --- AKSI 2: SELESAIKAN PRODUKSI ---
  void _showCompleteDialog(Map<String, dynamic> po) {
    final qtyActualCtrl = TextEditingController(
      text: po['quantity_plan']?.toString() ?? '',
    );
    final qtyWasteCtrl = TextEditingController(text: '0');
    final laborCostCtrl = TextEditingController(text: '0');
    final overheadCostCtrl = TextEditingController(text: '0');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Selesaikan: ${po['production_number'] ?? po['order_number']}",
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyActualCtrl,
                decoration: const InputDecoration(
                  labelText: "Hasil Aktual (Good Qty) *",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qtyWasteCtrl,
                decoration: const InputDecoration(
                  labelText: "Kuantitas Rusak (Waste)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: laborCostCtrl,
                decoration: const InputDecoration(
                  labelText: "Biaya Tenaga Kerja (Labor)",
                  border: OutlineInputBorder(),
                  prefixText: "Rp ",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: overheadCostCtrl,
                decoration: const InputDecoration(
                  labelText: "Biaya Overhead",
                  border: OutlineInputBorder(),
                  prefixText: "Rp ",
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: "Catatan",
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              if (qtyActualCtrl.text.isEmpty) return;

              // AMANKAN CONTEXT SEBELUM DIALOG DI-POP
              final messenger = ScaffoldMessenger.of(context);

              Map<String, dynamic> payload = {
                'quantity_actual': double.tryParse(qtyActualCtrl.text) ?? 0,
                'quantity_waste': double.tryParse(qtyWasteCtrl.text) ?? 0,
                'labor_cost': double.tryParse(laborCostCtrl.text) ?? 0,
                'overhead_cost': double.tryParse(overheadCostCtrl.text) ?? 0,
                'completed_at': DateTime.now().toIso8601String(),
                'notes': notesCtrl.text,
              };

              Navigator.pop(context);
              setState(() => _isLoading = true);

              bool success = await DataService().completeProduction(
                po['id'],
                payload,
              );

              if (!mounted) return;
              if (success) {
                _fetchData();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Produksi Selesai! Stok bertambah & HPP berhasil dihitung.",
                    ),
                  ),
                );
              } else {
                setState(() => _isLoading = false);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text("Gagal menyelesaikan produksi."),
                  ),
                );
              }
            },
            child: const Text(
              "Selesaikan",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- AKSI 3: LIHAT LAPORAN HPP ---
  void _showReportDialog(int poId) async {
    // AMANKAN CONTEXT SEBELUM LOADING MUNCUL
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    var report = await DataService().getProductionReport(poId);

    if (!mounted) return;
    Navigator.pop(context);

    if (report == null) {
      // GUNAKAN REFERENSI YANG SUDAH DIAMANKAN
      messenger.showSnackBar(
        const SnackBar(content: Text("Gagal memuat laporan HPP.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Laporan HPP: ${report['production_number']}",
          style: const TextStyle(color: AppColors.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Produk: ${report['product']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                "Efisiensi: ${double.tryParse(report['efficiency']?.toString() ?? '0')?.toStringAsFixed(2)}%",
              ),
              const Divider(),
              const Text(
                "Rincian Kuantitas",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("- Rencana: ${report['quantity_plan']}"),
              Text("- Aktual (Gudang): ${report['quantity_actual']}"),
              Text("- Waste: ${report['quantity_waste']}"),
              const Divider(),
              const Text(
                "Rincian Biaya",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("- Biaya Material: Rp ${report['material_cost']}"),
              Text("- Biaya Pekerja: Rp ${report['labor_cost']}"),
              Text("- Biaya Overhead: Rp ${report['overhead_cost']}"),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                color: Colors.green.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Biaya: Rp ${report['total_production_cost']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "HPP Per Unit: Rp ${double.tryParse(report['hpp_per_unit']?.toString() ?? '0')?.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Production Execution & HPP",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "Eksekusi lapangan, potong stok material, dan perhitungan HPP",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _fetchData,
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _executions.isEmpty
                    ? const Center(
                        child: Text("Belum ada data eksekusi produksi."),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade50,
                            ),
                            columns: const [
                              DataColumn(label: Text("No. Produksi")),
                              DataColumn(label: Text("Produk Target")),
                              DataColumn(label: Text("Qty Rencana")),
                              DataColumn(label: Text("Status Eksekusi")),
                              DataColumn(label: Text("Aksi Lapangan")),
                            ],
                            rows: _executions.map((item) {
                              String orderNumber =
                                  item['production_number'] ??
                                  item['order_number'] ??
                                  "-";
                              String productName =
                                  item['product']?['nama'] ??
                                  item['product']?['name'] ??
                                  "-";
                              String qty =
                                  item['quantity_plan']?.toString() ?? "0";

                              String status = (item['status'] ?? '')
                                  .toString()
                                  .toLowerCase();
                              bool isReleased = status == 'released';
                              bool isInProgress = status == 'in_progress';
                              bool isCompleted = status == 'completed';

                              Color statusColor = Colors.grey;
                              if (isReleased) statusColor = Colors.blue;
                              if (isInProgress) statusColor = Colors.orange;
                              if (isCompleted) statusColor = Colors.green;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      orderNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(productName)),
                                  DataCell(Text(qty)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        if (isReleased)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                            ),
                                            icon: const Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              "Mulai",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _startExecution(item['id']),
                                          ),
                                        if (isInProgress)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                            ),
                                            icon: const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              "Selesaikan",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                            onPressed: () =>
                                                _showCompleteDialog(item),
                                          ),
                                        if (isCompleted)
                                          OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.analytics,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              "Laporan HPP",
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            onPressed: () =>
                                                _showReportDialog(item['id']),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
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

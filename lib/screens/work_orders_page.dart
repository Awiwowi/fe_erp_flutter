import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class WorkOrdersPage extends StatefulWidget {
  const WorkOrdersPage({super.key});

  @override
  State<WorkOrdersPage> createState() => _WorkOrdersPageState();
}

class _WorkOrdersPageState extends State<WorkOrdersPage> {
  List<dynamic> _workOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    try {
      var data = await DataService()
          .getWorkOrders(); // Pastikan method ini ada di DataService
      if (mounted) {
        setState(() {
          _workOrders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Menentukan warna label berdasarkan status baru
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey.shade600;
      case 'processed':
        return Colors.blue.shade600;
      case 'completed':
        return Colors.green.shade600;
      case 'canceled':
        return Colors.red.shade600;
      default:
        return Colors.black;
    }
  }

  void _changeStatus(int id, String statusTarget) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Ubah Status ke ${statusTarget.toUpperCase()}?"),
            content: Text(
              "Apakah Anda yakin ingin memperbarui status work order ini?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Ya, Ubah",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() => _isLoading = true);
      bool success = await DataService().updateWorkOrderStatus(
        id,
        statusTarget,
      ); // Pastikan method ini ada di DataService
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Status berhasil diperbarui")),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal memperbarui status")),
        );
      }
    }
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
                        "Work Orders (Perintah Kerja)",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "Pengelolaan instruksi produksi dan pengerjaan",
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
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _workOrders.isEmpty
                    ? const Center(child: Text("Belum ada data Work Order."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade50,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                "No. WO",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Tanggal",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Status",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Aksi",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: _workOrders.map((item) {
                            String status = (item['status'] ?? 'draft')
                                .toString()
                                .toLowerCase();
                            Color statusColor = _getStatusColor(status);

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    item['no_wo'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataCell(Text(item['tanggal'] ?? '-')),
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
                                      // Aksi berdasarkan alur Draft -> Processed -> Completed
                                      if (status == 'draft') ...[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.play_arrow,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          tooltip: 'Proses WO',
                                          onPressed: () => _changeStatus(
                                            item['id'],
                                            'processed',
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Batalkan WO',
                                          onPressed: () => _changeStatus(
                                            item['id'],
                                            'canceled',
                                          ),
                                        ),
                                      ],
                                      if (status == 'processed')
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          tooltip: 'Selesaikan WO',
                                          onPressed: () => _changeStatus(
                                            item['id'],
                                            'completed',
                                          ),
                                        ),

                                      // Tombol hapus hanya jika draft atau canceled
                                      if (status == 'draft' ||
                                          status == 'canceled')
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Hapus',
                                          onPressed: () {
                                            // Tambahkan logika hapus jika diperlukan
                                          },
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
            ],
          ),
        ),
      ),
    );
  }
}

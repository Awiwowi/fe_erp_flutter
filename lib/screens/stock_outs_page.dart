import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Jangan lupa: flutter pub add intl
import '../constants/colors.dart';
import '../services/data_service.dart';

class StockOutsPage extends StatefulWidget {
  const StockOutsPage({super.key});

  @override
  State<StockOutsPage> createState() => _StockOutsPageState();
}

class _StockOutsPageState extends State<StockOutsPage> {
  List<dynamic> _approvedRequests = [];
  List<dynamic> _warehouses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    
    // Ambil data secara paralel biar cepat
    var requests = await DataService().getApprovedStockRequests();
    var warehouses = await DataService().getWarehouses();

    if (!mounted) return;

    setState(() {
      _approvedRequests = requests;
      _warehouses = warehouses;
      _isLoading = false;
    });
  }

  // --- FORM DIALOG STOCK OUT ---
  void _showStockOutDialog(Map<String, dynamic> requestItem) {
    // Controller
    final TextEditingController notesCtrl = TextEditingController();
    final TextEditingController dateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now())
    );

    int? selectedWarehouseId;
    // Default warehouse jika ada
    if (_warehouses.isNotEmpty) {
      selectedWarehouseId = _warehouses[0]['id'];
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Proses Pengeluaran Barang"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Request
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(5)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Request No: ${requestItem['request_number'] ?? '-'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("Requester: ${requestItem['requester']?['name'] ?? '-'}", style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 5),
                          const Text("Items:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          if (requestItem['items'] != null)
                            ...((requestItem['items'] as List).map((i) => 
                              Text("- ${i['product']['name']} (${i['quantity']})", style: const TextStyle(fontSize: 11))
                            ))
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Input Tanggal
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: "Tanggal Keluar",
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),

                    // Dropdown Warehouse
                    DropdownButtonFormField<int>(
                      value: selectedWarehouseId,
                      decoration: const InputDecoration(
                        labelText: "Pilih Gudang (Sumber)",
                        prefixIcon: Icon(Icons.warehouse),
                        border: OutlineInputBorder(),
                      ),
                      items: _warehouses.map((w) {
                        return DropdownMenuItem<int>(
                          value: w['id'],
                          child: Text(w['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() => selectedWarehouseId = val);
                      },
                    ),
                    const SizedBox(height: 15),

                    // Input Catatan
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Catatan (Opsional)",
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedWarehouseId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Gudang terlebih dahulu!")));
                      return;
                    }

                    // Loading indicator simple
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Memproses...")));
                    
                    bool success = await DataService().createStockOut(
                      requestItem['id'], 
                      selectedWarehouseId!, 
                      dateCtrl.text, 
                      notesCtrl.text
                    );

                    Navigator.pop(ctx); // Tutup dialog

                    if (success) {
                      _fetchData(); // Refresh list
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil Stock Out!"), backgroundColor: Colors.green));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal! Stok gudang mungkin tidak cukup."), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("Proses Stock Out", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
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
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Stock Out (Pengeluaran Barang)", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)
            ),
            const Text(
              "Daftar permintaan yang siap diproses", 
              style: TextStyle(fontSize: 12, color: Colors.grey)
            ),
            const SizedBox(height: 20),

            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _approvedRequests.isEmpty 
                ? const Center(child: Text("Tidak ada permintaan yang perlu diproses."))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _approvedRequests.length,
                    separatorBuilder: (ctx, i) => const Divider(),
                    itemBuilder: (ctx, i) {
                      var item = _approvedRequests[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: const Icon(Icons.output, color: Colors.blue),
                        ),
                        title: Text(item['request_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Requester: ${item['requester']?['name'] ?? '-'}"),
                            Text("Date: ${item['request_date'] ?? '-'}"),
                          ],
                        ),
                        trailing: ElevatedButton(
                          onPressed: () => _showStockOutDialog(item),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            minimumSize: const Size(0, 30) // Tombol kecil
                          ),
                          child: const Text("Proses", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
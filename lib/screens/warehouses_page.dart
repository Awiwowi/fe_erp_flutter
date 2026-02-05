import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class WarehousesPage extends StatefulWidget {
  const WarehousesPage({super.key});

  @override
  State<WarehousesPage> createState() => _WarehousesPageState();
}

class _WarehousesPageState extends State<WarehousesPage> {
  List<dynamic> _warehouses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getWarehouses();
    setState(() {
      _warehouses = data;
      _isLoading = false;
    });
  }

  void _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Warehouse"),
        content: const Text("Are you sure you want to delete this warehouse?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().deleteWarehouse(id);
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red));
      }
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final TextEditingController kodeCtrl = TextEditingController(text: item?['kode']);
    final TextEditingController nameCtrl = TextEditingController(text: item?['name']);
    final TextEditingController lokasiCtrl = TextEditingController(text: item?['lokasi']);
    final TextEditingController deskripsiCtrl = TextEditingController(text: item?['deskripsi']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit Warehouse" : "Add Warehouse"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: kodeCtrl, decoration: const InputDecoration(labelText: "Kode")),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: lokasiCtrl, decoration: const InputDecoration(labelText: "Lokasi")),
              TextField(controller: deskripsiCtrl, decoration: const InputDecoration(labelText: "Deskripsi")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Map<String, dynamic> data = {
                "kode": kodeCtrl.text,
                "name": nameCtrl.text,
                "lokasi": lokasiCtrl.text,
                "deskripsi": deskripsiCtrl.text,
              };

              bool success;
              if (isEdit) {
                success = await DataService().updateWarehouse(item['id'], data);
              } else {
                success = await DataService().addWarehouse(data);
              }

              if (success) {
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Updated!" : "Created!"), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action Failed"), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isEdit ? "Save" : "Add", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Rata kiri
              children: [
                // 1. JUDUL & SUBJUDUL
                 const Text(
                  "Data Warehouse", 
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)
               ),
                 const Text(
                   "Manage location and storage", 
                   style: TextStyle(fontSize: 12, color: Colors.grey)
              ),

                 const SizedBox(height: 15), // Beri jarak ke bawah

                // 2. TOMBOL ADD (SEKARANG DI BAWAH)
                 SizedBox(
                   width: double.infinity, // Agar tombol memanjang penuh (opsional, bisa dihapus jika ingin kecil)
                   child: ElevatedButton.icon(
                     onPressed: () => _showFormDialog(), // Pastikan nama fungsi dialog sesuai codingan Anda
                     icon: const Icon(Icons.add, color: Colors.white),
                     label: const Text("Add New Warehouse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.primary,
                       padding: const EdgeInsets.symmetric(vertical: 12), // Tinggi tombol
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                     ),
                   ),
               ),
             ],
          ),
            const SizedBox(height: 20),
            
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9FC)),
                      columns: const [
                        DataColumn(label: Text("Kode", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Lokasi", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Deskripsi", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _warehouses.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['kode']?.toString() ?? '-')),
                          DataCell(Text(item['name']?.toString() ?? '-')),
                          DataCell(Text(item['lokasi']?.toString() ?? '-')),
                          DataCell(Text(item['deskripsi']?.toString() ?? '-')),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showFormDialog(item: item)),
                              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteItem(item['id'])),
                            ],
                          )),
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
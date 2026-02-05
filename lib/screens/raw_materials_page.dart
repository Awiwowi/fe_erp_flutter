import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class RawMaterialsPage extends StatefulWidget {
  const RawMaterialsPage({super.key});

  @override
  State<RawMaterialsPage> createState() => _RawMaterialsPageState();
}

class _RawMaterialsPageState extends State<RawMaterialsPage> {
  bool _isLoading = true;
  List<dynamic> _materials = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var res = await DataService().getRawMaterials();
    
    if (!mounted) return;
    setState(() {
      _materials = res;
      _isLoading = false;
    });
  }

  // --- FORM DIALOG (ADD / EDIT) ---
  void _showFormDialog({Map<String, dynamic>? item}) {
    bool isEdit = item != null;
    final codeCtrl = TextEditingController(text: item?['code'] ?? '');
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final catCtrl = TextEditingController(text: item?['category'] ?? '');
    final unitCtrl = TextEditingController(text: item?['unit'] ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isEdit ? "Edit Raw Material" : "New Raw Material"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Kode Material (Unik)")),
                const SizedBox(height: 10),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nama Material")),
                const SizedBox(height: 10),
                TextField(controller: catCtrl, decoration: const InputDecoration(labelText: "Kategori")),
                const SizedBox(height: 10),
                TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: "Satuan (Unit)")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () async {
                // Validasi Sederhana
                if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode & Nama wajib diisi")));
                  return;
                }

                // Simpan context sebelum async
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                setState(() => _isLoading = true);

                Map<String, dynamic> data = {
                  "code": codeCtrl.text,
                  "name": nameCtrl.text,
                  "category": catCtrl.text,
                  "unit": unitCtrl.text,
                };

                bool success;
                if (isEdit) {
                  success = await DataService().updateRawMaterial(item['id'], data);
                } else {
                  success = await DataService().addRawMaterial(data);
                }

                if (!mounted) return;
                
                if (success) {
                  _fetchData();
                  scaffoldMessenger.showSnackBar(SnackBar(
                    content: Text(isEdit ? "Berhasil Diupdate!" : "Berhasil Ditambahkan!"), 
                    backgroundColor: Colors.green
                  ));
                } else {
                  setState(() => _isLoading = false);
                  scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Gagal menyimpan data"), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(isEdit ? "Update" : "Simpan", style: const TextStyle(color: Colors.white)),
            )
          ],
        );
      }
    );
  }

  void _delete(int id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Material"),
        content: const Text("Yakin ingin menghapus?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      bool success = await DataService().deleteRawMaterial(id);
      
      if (!mounted) return;
      if (success) {
        _fetchData();
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Berhasil dihapus"), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Gagal menghapus"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            const Text("Raw Materials", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Manage bahan baku produksi", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),

            // TOMBOL ADD
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Add New Material", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TABEL DATA
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _materials.isEmpty 
                ? const Center(child: Text("Belum ada data bahan baku."))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text("Kode")),
                        DataColumn(label: Text("Nama")),
                        DataColumn(label: Text("Kategori")),
                        DataColumn(label: Text("Unit")),
                        DataColumn(label: Text("Aksi")),
                      ],
                      rows: _materials.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['code'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(item['name'] ?? '-')),
                          DataCell(Text(item['category'] ?? '-')),
                          DataCell(Text(item['unit'] ?? '-')),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                onPressed: () => _showFormDialog(item: item),
                                tooltip: "Edit",
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _delete(item['id']),
                                tooltip: "Hapus",
                              ),
                            ],
                          )),
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
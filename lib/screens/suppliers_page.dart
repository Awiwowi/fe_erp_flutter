import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({super.key});

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  List<dynamic> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getSuppliers();
    setState(() {
      _suppliers = data;
      _isLoading = false;
    });
  }

  void _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Supplier"),
        content: const Text("Are you sure you want to delete this supplier?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("Cancel")
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().deleteSupplier(id);
      
      if (!mounted) return; // Cek mounted

      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final TextEditingController namaCtrl = TextEditingController(text: item?['nama']);
    final TextEditingController emailCtrl = TextEditingController(text: item?['email']);
    final TextEditingController alamatCtrl = TextEditingController(text: item?['alamat']);
    final TextEditingController teleponCtrl = TextEditingController(text: item?['telepon']);
    final TextEditingController kontakPersonCtrl = TextEditingController(text: item?['kontak_person']);

    showDialog(
      context: context, // Context Halaman Utama
      builder: (dialogContext) { // Context Dialog
        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Supplier" : "Add Supplier"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: "Nama Supplier")),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
                    TextField(controller: alamatCtrl, decoration: const InputDecoration(labelText: "Alamat")),
                    TextField(controller: teleponCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Telepon")),
                    TextField(controller: kontakPersonCtrl, decoration: const InputDecoration(labelText: "Kontak Person")),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext), 
                  child: const Text("Cancel")
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext); // Tutup dialog
                    
                    Map<String, dynamic> data = {
                      "nama": namaCtrl.text,
                      "email": emailCtrl.text,
                      "alamat": alamatCtrl.text,
                      "telepon": teleponCtrl.text,
                      "kontak_person": kontakPersonCtrl.text,
                    };

                    bool success;
                    if (isEdit) {
                      success = await DataService().updateSupplier(item['id'], data);
                    } else {
                      success = await DataService().addSupplier(data);
                    }

                    if (!mounted) return; // Cek mounted wajib

                    if (success) {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? "Updated!" : "Created!"), backgroundColor: Colors.green)
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Action Failed"), backgroundColor: Colors.red)
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(isEdit ? "Save" : "Add", style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Supplier List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text("Add Supplier", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
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
                        DataColumn(label: Text("Nama", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Alamat", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Telepon", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Kontak Person", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _suppliers.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['nama']?.toString() ?? '-')),
                          DataCell(Text(item['email']?.toString() ?? '-')),
                          DataCell(Text(item['alamat']?.toString() ?? '-')),
                          DataCell(Text(item['telepon']?.toString() ?? '-')),
                          DataCell(Text(item['kontak_person']?.toString() ?? '-')),
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
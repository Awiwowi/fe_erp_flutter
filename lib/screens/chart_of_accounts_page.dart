import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class ChartOfAccountsPage extends StatefulWidget {
  const ChartOfAccountsPage({super.key});

  @override
  State<ChartOfAccountsPage> createState() => _ChartOfAccountsPageState();
}

class _ChartOfAccountsPageState extends State<ChartOfAccountsPage> {
  List<dynamic> _accounts = [];
  bool _isLoading = true;

  // Enum Tipe Akun (Sesuai Testing Guide - Lowercase)
  final List<String> _accountTypes = [
    'asset',
    'liability',
    'equity',
    'revenue',
    'expense'
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getChartOfAccounts();
    setState(() {
      _accounts = data;
      _isLoading = false;
    });
  }

  // --- DELETE FUNCTION ---
  void _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Akun"),
        content: const Text("Apakah Anda yakin ingin menghapus akun ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().deleteChartOfAccount(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Akun berhasil dihapus"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menghapus akun"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- ADD/EDIT DIALOG ---
  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    
    // Controller Field
    final TextEditingController codeCtrl = TextEditingController(text: item?['code']);
    final TextEditingController nameCtrl = TextEditingController(text: item?['name']);
    final TextEditingController catCtrl = TextEditingController(text: item?['category']);
    
    // Default Dropdown Values
    String selectedType = item?['type'] ?? _accountTypes.first;
    if (!_accountTypes.contains(selectedType)) selectedType = _accountTypes.first;

    // Checkbox Values (Handle null/integer/boolean conversion)
    bool isCash = item?['is_cash'] == 1 || item?['is_cash'] == true;
    bool isActive = item == null ? true : (item['is_active'] == 1 || item['is_active'] == true);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Akun" : "Buat Akun Baru"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400, // Lebar dialog agar nyaman di desktop/tablet
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // CODE
                      TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: "Kode Akun",
                          hintText: "Contoh: 1.1.01",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // NAME
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nama Akun",
                          hintText: "Contoh: Kas Besar",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // TYPE DROPDOWN
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: "Tipe Akun",
                          border: OutlineInputBorder(),
                        ),
                        items: _accountTypes.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setStateDialog(() => selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      // CATEGORY
                      TextField(
                        controller: catCtrl,
                        decoration: const InputDecoration(
                          labelText: "Kategori",
                          hintText: "Contoh: persediaan",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // OPTIONS (Is Cash & Is Active)
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text("Akun Kas?"),
                              subtitle: const Text("Centang jika kas/bank"),
                              value: isCash,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) => setStateDialog(() => isCash = val!),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text("Aktif?"),
                              value: isActive,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) => setStateDialog(() => isActive = val!),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty || catCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Harap isi Kode, Nama, dan Kategori")),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);

                    // Payload sesuai Controller Laravel
                    Map<String, dynamic> payload = {
                      "code": codeCtrl.text,
                      "name": nameCtrl.text,
                      "type": selectedType,
                      "category": catCtrl.text,
                      "is_cash": isCash,
                      "is_active": isActive,
                    };

                    bool success;
                    if (isEdit) {
                      success = await DataService().updateChartOfAccount(item['id'], payload);
                    } else {
                      success = await DataService().createChartOfAccount(payload);
                    }

                    if (!mounted) return;
                    if (success) {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit ? "Akun berhasil diupdate" : "Akun berhasil dibuat"),
                          backgroundColor: Colors.green
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Operasi Gagal"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text(isEdit ? "Simpan Perubahan" : "Simpan", style: const TextStyle(color: Colors.white)),
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
                  "Chart of Accounts (COA)",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text("Tambah Akun", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CONTENT
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                    ? const Center(child: Text("Belum ada data akun."))
                    : SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn(label: Text("Kode", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Nama Akun", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Tipe", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Kas?", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Aksi", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _accounts.map((item) {
                            bool isCash = item['is_cash'] == 1 || item['is_cash'] == true;
                            bool isActive = item['is_active'] == 1 || item['is_active'] == true;

                            return DataRow(cells: [
                              DataCell(Text(item['code'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
                              DataCell(Text(item['name'] ?? '-')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                  child: Text((item['type'] ?? '').toString().toUpperCase(), 
                                    style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)
                                  ),
                                )
                              ),
                              DataCell(Text(item['category'] ?? '-')),
                              DataCell(
                                isCash 
                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 18) 
                                  : const SizedBox()
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4)
                                  ),
                                  child: Text(isActive ? "Active" : "Inactive", 
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.red, 
                                      fontSize: 11, 
                                      fontWeight: FontWeight.bold
                                    )
                                  ),
                                )
                              ),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                    tooltip: "Edit",
                                    onPressed: () => _showFormDialog(item: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    tooltip: "Hapus",
                                    onPressed: () => _deleteItem(item['id']),
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
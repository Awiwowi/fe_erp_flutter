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

  final List<String> _accountTypes = [
    'asset',
    'liability',
    'equity',
    'revenue',
    'expense',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getChartOfAccounts();
    if (mounted) {
      setState(() {
        _accounts = data;
        _isLoading = false;
      });
    }
  }

  void _deleteItem(int id) async {
    bool confirm =
        await showDialog(
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
        ) ??
        false;

    if (confirm) {
      bool success = await DataService().deleteChartOfAccount(id);
      if (!mounted) return;

      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Akun berhasil dihapus"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal menghapus akun"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;

    final codeCtrl = TextEditingController(text: item?['code']);
    final nameCtrl = TextEditingController(text: item?['name']);
    final catCtrl = TextEditingController(text: item?['category']);

    String selectedType = item?['type'] ?? _accountTypes.first;
    if (!_accountTypes.contains(selectedType)) {
      selectedType = _accountTypes.first;
    }

    bool isCash = item?['is_cash'] == 1 || item?['is_cash'] == true;
    bool isActive = item == null
        ? true
        : (item['is_active'] == 1 || item['is_active'] == true);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Akun" : "Buat Akun Baru"),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: "Kode Akun",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nama Akun",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: "Tipe Akun",
                          border: OutlineInputBorder(),
                        ),
                        items: _accountTypes
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedType = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: catCtrl,
                        decoration: const InputDecoration(
                          labelText: "Kategori",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text("Akun Kas?"),
                              value: isCash,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) =>
                                  setStateDialog(() => isCash = val!),
                            ),
                          ),
                          Expanded(
                            child: CheckboxListTile(
                              title: const Text("Aktif?"),
                              value: isActive,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (val) =>
                                  setStateDialog(() => isActive = val!),
                            ),
                          ),
                        ],
                      ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    if (codeCtrl.text.isEmpty ||
                        nameCtrl.text.isEmpty ||
                        catCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Harap isi Kode, Nama, dan Kategori"),
                        ),
                      );
                      return;
                    }

                    Map<String, dynamic> payload = {
                      "code": codeCtrl.text,
                      "name": nameCtrl.text,
                      "type": selectedType,
                      "category": catCtrl.text,
                      "is_cash": isCash,
                      "is_active": isActive,
                    };

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(dialogContext);

                    bool success;
                    if (isEdit) {
                      success = await DataService().updateChartOfAccount(
                        item['id'],
                        payload,
                      );
                    } else {
                      success = await DataService().createChartOfAccount(
                        payload,
                      );
                    }

                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? "Akun berhasil diupdate"
                                : "Akun berhasil dibuat",
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Operasi Gagal"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    isEdit ? "Simpan Perubahan" : "Simpan",
                    style: const TextStyle(color: Colors.white),
                  ),
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
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Chart of Accounts (COA)",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                ? const Center(child: Text("Belum ada data akun."))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 30,
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade100,
                      ),
                      columns: const [
                        DataColumn(label: Text("Kode")),
                        DataColumn(label: Text("Nama Akun")),
                        DataColumn(label: Text("Tipe")),
                        DataColumn(label: Text("Kategori")),
                        DataColumn(label: Text("Kas?")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Aksi")),
                      ],
                      rows: _accounts.map((item) {
                        bool isCash =
                            item['is_cash'] == 1 || item['is_cash'] == true;
                        bool isActive =
                            item['is_active'] == 1 || item['is_active'] == true;

                        return DataRow(
                          cells: [
                            DataCell(Text(item['code'] ?? '-')),
                            DataCell(Text(item['name'] ?? '-')),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  (item['type'] ?? '').toString().toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(Text(item['category'] ?? '-')),
                            DataCell(
                              isCash
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    )
                                  : const SizedBox(),
                            ),
                            DataCell(Text(isActive ? "Active" : "Inactive")),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () =>
                                        _showFormDialog(item: item),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteItem(item['id']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

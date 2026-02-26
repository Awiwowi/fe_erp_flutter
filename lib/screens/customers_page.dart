import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  List<dynamic> _customers = [];
  bool _isLoading = true;

  // Daftar pilihan Tipe Customer
  final List<String> _customerTypes = ['distributor', 'agent', 'retail'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getCustomers();
    if (mounted) {
      setState(() {
        _customers = data;
        _isLoading = false;
      });
    }
  }

  // --- DIALOG BUAT / EDIT CUSTOMER ---
  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: isEdit ? item['name'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? item['phone'] : '');
    final addressCtrl = TextEditingController(
      text: isEdit ? item['address'] : '',
    );

    // Set nilai default untuk dropdown type
    String selectedType = 'retail'; // Default
    if (isEdit && item['type'] != null) {
      String t = item['type'].toString().toLowerCase();
      if (_customerTypes.contains(t)) {
        selectedType = t;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                isEdit ? "Edit Customer" : "Tambah Customer Baru",
                style: const TextStyle(color: AppColors.primary),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Nama Customer / Perusahaan *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // --- DROPDOWN TYPE CUSTOMER ---
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: "Tipe Customer *",
                          border: OutlineInputBorder(),
                        ),
                        items: _customerTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(
                              type.toUpperCase(),
                            ), // Ditampilkan huruf besar agar rapi
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null)
                            setStateDialog(() => selectedType = val);
                        },
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: "No. Telepon",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: "Alamat Lengkap",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Nama wajib diisi!")),
                      );
                      return;
                    }

                    // Payload dikirim tanpa email, diganti dengan type
                    Map<String, dynamic> payload = {
                      "name": nameCtrl.text,
                      "type": selectedType,
                      "phone": phoneCtrl.text,
                      "address": addressCtrl.text,
                    };

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    bool success;
                    if (isEdit) {
                      success = await DataService().updateCustomer(
                        item['id'],
                        payload,
                      );
                    } else {
                      success = await DataService().createCustomer(payload);
                    }

                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? "Data diperbarui"
                                : "Customer berhasil ditambahkan",
                          ),
                        ),
                      );
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Operasi gagal")),
                      );
                    }
                  },
                  child: const Text(
                    "Simpan",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- AKSI HAPUS CUSTOMER ---
  void _deleteCustomer(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Customer?"),
            content: const Text("Data ini akan dihapus permanen. Lanjutkan?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Hapus",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().deleteCustomer(id);

      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(
          const SnackBar(content: Text("Customer berhasil dihapus")),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal menghapus data. Mungkin sedang digunakan di transaksi lain.",
            ),
          ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Data Customer",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              "Manajemen master data pelanggan/pembeli",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                        ),
                        onPressed: _fetchData,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _showFormDialog(),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      "Tambah Customer",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _customers.isEmpty
                    ? const Center(child: Text("Belum ada data customer."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade50,
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "Nama Customer",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Tipe",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "No. Telepon",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Alamat",
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
                            rows: _customers.map((item) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item['name'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (item['type'] ?? '-')
                                          .toString()
                                          .toUpperCase(),
                                    ),
                                  ), // Menampilkan type dengan huruf kapital
                                  DataCell(Text(item['phone'] ?? '-')),
                                  DataCell(
                                    SizedBox(
                                      width: 250, // Membatasi lebar alamat
                                      child: Text(
                                        item['address'] ?? '-',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.orange,
                                            size: 20,
                                          ),
                                          tooltip: 'Edit',
                                          onPressed: () =>
                                              _showFormDialog(item: item),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Hapus',
                                          onPressed: () =>
                                              _deleteCustomer(item['id']),
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

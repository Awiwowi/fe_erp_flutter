import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class SalesReturnsPage extends StatefulWidget {
  const SalesReturnsPage({super.key});

  @override
  State<SalesReturnsPage> createState() => _SalesReturnsPageState();
}

class _SalesReturnsPageState extends State<SalesReturnsPage> {
  List<dynamic> _returns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getSalesReturns();
    if (mounted) {
      setState(() {
        _returns = data;
        _isLoading = false;
      });
    }
  }

  // --- MODAL DETAIL RETUR ---
  void _showDetailModal(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    var res = await DataService().getSalesReturnDetail(id);
    if (!mounted) return;
    Navigator.pop(context);

    var detail = res?['data'] ?? res;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil detail Retur.")),
      );
      return;
    }

    List<dynamic> items = detail['items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Detail Retur: ${detail['no_retur'] ?? '-'}",
          style: const TextStyle(color: AppColors.primary),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Customer: ${detail['customer']?['name'] ?? '-'}"),
                Text("Tanggal Retur: ${detail['tanggal'] ?? '-'}"),
                Text("Catatan/Alasan: ${detail['notes'] ?? '-'}"),
                const Divider(height: 20),
                const Text(
                  "Barang yang Dikembalikan:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text("Produk")),
                      DataColumn(label: Text("Qty Dikembalikan")),
                    ],
                    rows: items.map((item) {
                      String prodName =
                          item['product']?['nama'] ??
                          item['product']?['name'] ??
                          '-';
                      String qty = item['qty']?.toString() ?? '0';

                      return DataRow(
                        cells: [
                          DataCell(Text(prodName)),
                          DataCell(
                            Text(
                              qty,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
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

  // --- MODAL BUAT RETUR BARU ---
  void _showCreateDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    var customers = await DataService().getCustomers();
    var products = await DataService().getProducts();

    if (!mounted) return;
    Navigator.pop(context);

    int? selectedCustomerId;
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final notesCtrl = TextEditingController();
    List<Map<String, dynamic>> returnItems = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Buat Retur Penjualan",
                style: TextStyle(color: AppColors.primary),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.red.shade50,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Proses ini akan mencatat pengembalian barang dari pelanggan ke gudang.",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Pilih Customer *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedCustomerId,
                        isExpanded: true,
                        items: customers
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c['id'],
                                child: Text(c['name'] ?? '-'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedCustomerId = val),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tanggal Retur *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: "Alasan Retur / Catatan",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const Divider(height: 30, thickness: 2),
                      const Text(
                        "Item Retur:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ...returnItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> item = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: "Produk",
                                    isDense: true,
                                  ),
                                  value: item['product_id'],
                                  isExpanded: true,
                                  items: products
                                      .map(
                                        (prod) => DropdownMenuItem<int>(
                                          value: prod['id'],
                                          child: Text(
                                            prod['nama'] ?? prod['name'] ?? '-',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => setStateDialog(
                                    () => item['product_id'] = val,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: item['qtyCtrl'],
                                  decoration: const InputDecoration(
                                    labelText: "Qty",
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  item['qtyCtrl'].dispose();
                                  setStateDialog(
                                    () => returnItems.removeAt(index),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setStateDialog(() {
                            returnItems.add({
                              'product_id': null,
                              'qtyCtrl': TextEditingController(text: "1"),
                            });
                          }),
                          icon: const Icon(Icons.add_circle),
                          label: const Text("Tambah Item"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    if (selectedCustomerId == null ||
                        dateCtrl.text.isEmpty ||
                        returnItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Lengkapi form & minimal 1 item produk!",
                          ),
                        ),
                      );
                      return;
                    }

                    Map<String, dynamic> payload = {
                      "customer_id": selectedCustomerId,
                      "tanggal": dateCtrl.text,
                      "notes": notesCtrl.text,
                      "items": returnItems
                          .map(
                            (i) => {
                              "product_id": i['product_id'],
                              "qty": double.tryParse(i['qtyCtrl'].text) ?? 1,
                            },
                          )
                          .toList(),
                    };

                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    bool success = await DataService().createSalesReturn(
                      payload,
                    );
                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Retur Penjualan berhasil dibuat!"),
                        ),
                      );
                    } else {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gagal membuat Retur.")),
                      );
                    }
                  },
                  child: const Text(
                    "Simpan Retur",
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

  // --- AKSI PERUBAHAN STATUS ---
  void _changeStatus(int id, String statusTarget) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Ubah Status menjadi ${statusTarget.toUpperCase()}?"),
            content: Text(
              "Aksi ini ${statusTarget == 'approved' ? 'akan menyetujui retur dan menambahkan stok kembali ke gudang' : 'akan menolak pengajuan retur'}. Lanjutkan?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusTarget == 'approved'
                      ? Colors.green
                      : Colors.red,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Ya, Lanjutkan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() => _isLoading = true);
      bool success = await DataService().updateSalesReturnStatus(
        id,
        statusTarget,
      );
      if (!mounted) return;
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status Retur diubah menjadi $statusTarget")),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal mengubah status")));
      }
    }
  }

  // --- AKSI HAPUS ---
  void _deleteReturn(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Data Retur?"),
            content: const Text(
              "Data ini akan dihapus secara permanen. Lanjutkan?",
            ),
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
      setState(() => _isLoading = true);
      bool success = await DataService().deleteSalesReturn(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Retur berhasil dihapus")));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gagal menghapus retur")));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade600;
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
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
                        "Sales Returns (Retur Penjualan)",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "Pencatatan pengembalian barang dari pelanggan",
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
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _showCreateDialog,
                icon: const Icon(
                  Icons.assignment_return,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Buat Retur Baru",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _returns.isEmpty
                    ? const Center(
                        child: Text("Belum ada data Retur Penjualan."),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade100,
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "No. Retur",
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
                                  "Customer",
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
                            rows: _returns.map((item) {
                              String status = (item['status'] ?? 'pending')
                                  .toString()
                                  .toLowerCase();
                              Color statusColor = _getStatusColor(status);

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item['no_retur'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(item['tanggal'] ?? '-')),
                                  DataCell(
                                    Text(item['customer']?['name'] ?? '-'),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor,
                                          width: 1.5,
                                        ),
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_red_eye,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          tooltip: 'Lihat Detail',
                                          onPressed: () =>
                                              _showDetailModal(item['id']),
                                        ),
                                        if (status == 'pending') ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            tooltip: 'Setujui Retur',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'approved',
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Tolak Retur',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'rejected',
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                            tooltip: 'Hapus',
                                            onPressed: () =>
                                                _deleteReturn(item['id']),
                                          ),
                                        ],
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

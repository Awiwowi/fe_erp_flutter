import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class SalesOrdersPage extends StatefulWidget {
  const SalesOrdersPage({super.key});

  @override
  State<SalesOrdersPage> createState() => _SalesOrdersPageState();
}

class _SalesOrdersPageState extends State<SalesOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getSalesOrders();
    if (mounted) {
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    }
  }

  // --- MODAL DETAIL SO ---
  void _showDetailModal(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    var res = await DataService().getSalesOrderDetail(id);
    if (!mounted) return;
    Navigator.pop(context);

    var detail = res?['data'] ?? res;

    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil detail pesanan.")),
      );
      return;
    }

    List<dynamic> items = detail['items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Detail Pesanan: ${detail['no_spk'] ?? '-'}",
          style: const TextStyle(color: AppColors.primary),
        ),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Customer: ${detail['customer']?['name'] ?? '-'}"),
                Text("Tanggal Order: ${detail['tanggal'] ?? '-'}"),
                Text("Catatan: ${detail['notes'] ?? '-'}"),
                if (detail['sales_quotation_id'] != null)
                  Text(
                    "Referensi SQ: ID #${detail['sales_quotation_id']}",
                    style: const TextStyle(color: Colors.blue),
                  ),

                const Divider(height: 20),
                const Text(
                  "Daftar Barang Pesanan:",
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
                      DataColumn(label: Text("Qty Pesanan")),
                      DataColumn(label: Text("Harga Satuan")),
                      DataColumn(label: Text("Subtotal")),
                    ],
                    rows: items.map((item) {
                      String prodName =
                          item['product']?['nama'] ??
                          item['product']?['name'] ??
                          '-';
                      double price =
                          double.tryParse(item['price']?.toString() ?? '0') ??
                          0;
                      double sub =
                          double.tryParse(
                            item['subtotal']?.toString() ?? '0',
                          ) ??
                          0;
                      String qty =
                          item['qty_pesanan']?.toString() ??
                          item['qty']?.toString() ??
                          '0';

                      return DataRow(
                        cells: [
                          DataCell(Text(prodName)),
                          DataCell(
                            Text(
                              qty,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(_currencyFormat.format(price))),
                          DataCell(
                            Text(
                              _currencyFormat.format(sub),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Grand Total: ${_currencyFormat.format(double.tryParse(detail['total_price']?.toString() ?? '0') ?? 0)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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

  // --- MODAL BUAT SO DIRECT ---
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

    List<Map<String, dynamic>> soItems = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double calculateTotal() {
              double total = 0;
              for (var item in soItems) {
                double q = double.tryParse(item['qtyCtrl'].text) ?? 0;
                double p = double.tryParse(item['priceCtrl'].text) ?? 0;
                total += (q * p);
              }
              return total;
            }

            return AlertDialog(
              title: const Text(
                "Buat Sales Order (Direct)",
                style: TextStyle(color: AppColors.primary),
              ),
              content: SizedBox(
                width: 750,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.blue.shade50,
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Gunakan form ini untuk pesanan langsung tanpa melewati proses Penawaran (Quotation).",
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
                        items: customers.map((c) {
                          return DropdownMenuItem<int>(
                            value: c['id'],
                            child: Text(c['name'] ?? '-'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedCustomerId = val),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tanggal Pesanan (YYYY-MM-DD) *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: "Catatan (Opsional)",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),

                      const Divider(height: 30, thickness: 2),
                      const Text(
                        "Daftar Barang Pesanan:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ...soItems.asMap().entries.map((entry) {
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
                                  items: products.map((prod) {
                                    String pName =
                                        prod['nama'] ?? prod['name'] ?? '-';
                                    return DropdownMenuItem<int>(
                                      value: prod['id'],
                                      child: Text(
                                        pName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
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
                                  onChanged: (v) => setStateDialog(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: item['priceCtrl'],
                                  decoration: const InputDecoration(
                                    labelText: "Harga Satuan",
                                    isDense: true,
                                    prefixText: "Rp ",
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => setStateDialog(() {}),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => setStateDialog(
                                  () => soItems.removeAt(index),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () => setStateDialog(() {
                              soItems.add({
                                'product_id': null,
                                'qtyCtrl': TextEditingController(),
                                'priceCtrl': TextEditingController(),
                              });
                            }),
                            icon: const Icon(Icons.add_circle),
                            label: const Text("Tambah Barang"),
                          ),
                          Text(
                            "Grand Total: ${_currencyFormat.format(calculateTotal())}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 16,
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    // Filter item yang valid dan lakukan mapping nilai
                    List<Map<String, dynamic>> finalItems = soItems
                        .where((i) => i['product_id'] != null)
                        .map((i) {
                          return {
                            "product_id": i['product_id'],
                            "qty": double.tryParse(i['qtyCtrl'].text) ?? 0,
                            "price": double.tryParse(i['priceCtrl'].text) ?? 0,
                          };
                        })
                        .toList();

                    // Validasi kelengkapan form
                    if (selectedCustomerId == null ||
                        dateCtrl.text.isEmpty ||
                        finalItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Lengkapi form dan minimal 1 barang!"),
                        ),
                      );
                      return;
                    }

                    // Validasi khusus QTY agar tidak bernilai 0
                    bool hasInvalidQty = finalItems.any(
                      (item) => item['qty'] < 1,
                    );
                    if (hasInvalidQty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Jumlah (Qty) tidak boleh kosong atau 0!",
                          ),
                        ),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);

                    Map<String, dynamic> payload = {
                      "customer_id": selectedCustomerId,
                      "tanggal": dateCtrl.text,
                      "notes": notesCtrl.text,
                      "items": finalItems,
                    };

                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    bool success = await DataService().createSalesOrder(
                      payload,
                    );
                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Sales Order berhasil dibuat!"),
                        ),
                      );
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Gagal membuat SO. Pastikan format sesuai.",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Simpan SO",
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

  // --- AKSI UBAH STATUS ---
  void _changeStatus(int id, String statusTarget) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Ubah Status menjadi $statusTarget?"),
            content: Text(
              "Yakin ingin mengubah status pesanan ini menjadi ${statusTarget.toUpperCase()}?",
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
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().updateSalesOrderStatus(
        id,
        statusTarget,
      );
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(
          SnackBar(content: Text("Status berhasil diubah")),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(content: Text("Gagal mengubah status")),
        );
      }
    }
  }

  // --- AKSI HAPUS ---
  void _deleteSO(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Pesanan?"),
            content: const Text(
              "Pesanan ini akan dihapus permanen. Lanjutkan?",
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
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().deleteSalesOrder(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(
          const SnackBar(content: Text("Pesanan dihapus")),
        );
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  // Menentukan warna berdasarkan status baru
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade600;
      case 'approved':
        return Colors.blue.shade600;
      case 'partial':
        return Colors.purple.shade600;
      case 'completed':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.black;
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
                              "Sales Orders (Pesanan)",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              "Daftar SPK / pesanan dari pelanggan",
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
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _orders.isEmpty
                    ? const Center(child: Text("Belum ada data Sales Order."))
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
                                  "No. SPK (Order)",
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
                                  "Total Harga",
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
                            rows: _orders.map((item) {
                              String status = (item['status'] ?? 'pending')
                                  .toString()
                                  .toLowerCase();
                              Color statusColor = _getStatusColor(status);

                              String noOrder = item['no_spk'] ?? '-';
                              String tanggal = item['tanggal'] ?? '-';
                              double total =
                                  double.tryParse(
                                    item['total_price']?.toString() ?? '0',
                                  ) ??
                                  0;
                              String customer =
                                  item['customer']?['name'] ?? '-';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      noOrder,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(tanggal)),
                                  DataCell(Text(customer)),
                                  DataCell(
                                    Text(
                                      _currencyFormat.format(total),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
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

                                        // Alur Aksi Berdasarkan Status
                                        if (status == 'pending') ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            tooltip: 'Approve',
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
                                            tooltip: 'Batalkan (Cancelled)',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'cancelled',
                                            ),
                                          ),
                                        ],
                                        if (status == 'approved')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.play_circle_fill,
                                              color: Colors.purple,
                                              size: 20,
                                            ),
                                            tooltip: 'Mulai Kirim (Partial)',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'partial',
                                            ),
                                          ),
                                        if (status == 'partial')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.done_all,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            tooltip: 'Selesaikan (Completed)',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'completed',
                                            ),
                                          ),

                                        if (status == 'pending' ||
                                            status == 'cancelled')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Hapus',
                                            onPressed: () =>
                                                _deleteSO(item['id']),
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

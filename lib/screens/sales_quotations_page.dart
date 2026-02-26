import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class SalesQuotationsPage extends StatefulWidget {
  const SalesQuotationsPage({super.key});

  @override
  State<SalesQuotationsPage> createState() => _SalesQuotationsPageState();
}

class _SalesQuotationsPageState extends State<SalesQuotationsPage> {
  List<dynamic> _quotations = [];
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
    var data = await DataService().getSalesQuotations();
    if (mounted) {
      setState(() {
        if (data.isNotEmpty && data[0] is Map && data[0].containsKey('data')) {
          _quotations = data[0]['data'];
        } else {
          _quotations = data;
        }
        _isLoading = false;
      });
    }
  }

  // --- MODAL DETAIL SQ ---
  void _showDetailModal(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    var res = await DataService().getSalesQuotationDetail(id);
    if (!mounted) return;
    Navigator.pop(context);

    var detail = res?['data'] ?? res;

    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil detail penawaran.")),
      );
      return;
    }

    List<dynamic> items = detail['items'] ?? [];
    double dpAmount =
        double.tryParse(detail['dp_amount']?.toString() ?? '0') ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Detail Penawaran: ${detail['no_quotation'] ?? '-'}",
          style: const TextStyle(color: AppColors.primary),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Customer: ${detail['customer']?['name'] ?? '-'}"),
                Text("Tanggal Penawaran: ${detail['tanggal'] ?? '-'}"),
                Text(
                  "Cara Bayar: ${detail['cara_bayar'] ?? '-'} ${detail['cara_bayar'] == 'DP' ? '(${_currencyFormat.format(dpAmount)})' : ''}",
                ),
                const Divider(height: 20),
                const Text(
                  "Daftar Barang:",
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
                      DataColumn(label: Text("Qty")),
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
                      return DataRow(
                        cells: [
                          DataCell(Text(prodName)),
                          DataCell(Text(item['qty']?.toString() ?? '0')),
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

  // --- MODAL BUAT SQ BARU ---
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

    String selectedCaraBayar = 'Full/Lunas';
    final dpAmountCtrl = TextEditingController(text: "0");

    List<Map<String, dynamic>> sqItems = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            double calculateTotal() {
              double total = 0;
              for (var item in sqItems) {
                double q = double.tryParse(item['qtyCtrl'].text) ?? 0;
                double p = double.tryParse(item['priceCtrl'].text) ?? 0;
                total += (q * p);
              }
              return total;
            }

            return AlertDialog(
              title: const Text(
                "Buat Sales Quotation",
                style: TextStyle(color: AppColors.primary),
              ),
              content: SizedBox(
                width: 750,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: dateCtrl,
                              decoration: const InputDecoration(
                                labelText: "Tanggal (YYYY-MM-DD) *",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Cara Bayar *",
                                border: OutlineInputBorder(),
                              ),
                              value: selectedCaraBayar,
                              items: ['Full/Lunas', 'DP'].map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(val),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setStateDialog(() => selectedCaraBayar = val);
                                }
                              },
                            ),
                          ),
                          if (selectedCaraBayar == 'DP') ...[
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: dpAmountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Nominal DP",
                                  prefixText: "Rp ",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 30, thickness: 2),

                      const Text(
                        "Daftar Penawaran Barang:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ...sqItems.asMap().entries.map((entry) {
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
                                  () => sqItems.removeAt(index),
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
                              sqItems.add({
                                'product_id': null,
                                'qtyCtrl': TextEditingController(),
                                'priceCtrl': TextEditingController(),
                              });
                            }),
                            icon: const Icon(Icons.add_circle),
                            label: const Text("Tambah Barang"),
                          ),
                          Text(
                            "Total Estimasi: ${_currencyFormat.format(calculateTotal())}",
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
                    if (selectedCustomerId == null ||
                        dateCtrl.text.isEmpty ||
                        sqItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Lengkapi form dan minimal 1 barang!"),
                        ),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);

                    Map<String, dynamic> payload = {
                      "customer_id": selectedCustomerId,
                      "tanggal": dateCtrl.text,
                      "cara_bayar": selectedCaraBayar,
                      "dp_amount": selectedCaraBayar == 'DP'
                          ? (double.tryParse(dpAmountCtrl.text) ?? 0)
                          : 0,
                      "items": sqItems
                          .where((i) => i['product_id'] != null)
                          .map((i) {
                            return {
                              "product_id": i['product_id'],
                              "qty": double.tryParse(i['qtyCtrl'].text) ?? 0,
                              "price":
                                  double.tryParse(i['priceCtrl'].text) ?? 0,
                            };
                          })
                          .toList(),
                    };

                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    bool success = await DataService().createSalesQuotation(
                      payload,
                    );
                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text("Sales Quotation berhasil dibuat!"),
                        ),
                      );
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Gagal membuat Quotation. Cek kembali form.",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Simpan Draft",
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
            title: Text("Konfirmasi $statusTarget"),
            content: Text(
              "Apakah Anda yakin ingin mengubah dokumen ini menjadi ${statusTarget.toUpperCase()}?",
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
                      : Colors.orange,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Ya, Proses",
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

      bool success = await DataService().updateSalesQuotationStatus(
        id,
        statusTarget,
      );

      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(
          SnackBar(content: Text("Status diubah menjadi $statusTarget")),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(content: Text("Gagal mengubah status!")),
        );
      }
    }
  }

  // --- AKSI KONVERSI SQ KE SO ---
  void _convertToSO(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Konversi ke SPK?"),
            content: const Text(
              "Penawaran yang disetujui ini akan diteruskan dan dicetak menjadi Sales Order (SPK). Lanjutkan?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Konversi",
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

      bool success = await DataService().convertSqToSo(id);

      if (!mounted) return;
      if (success) {
        _fetchData(); // Refresh data SQ
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Berhasil dikonversi! Silakan cek menu Sales Orders.",
            ),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal mengkonversi atau data sudah pernah dikonversi.",
            ),
          ),
        );
      }
    }
  }

  // --- AKSI HAPUS ---
  void _deleteSQ(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Dokumen?"),
            content: const Text(
              "Penawaran ini akan dihapus permanen. Lanjutkan?",
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
      bool success = await DataService().deleteSalesQuotation(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(
          const SnackBar(content: Text("Dokumen berhasil dihapus")),
        );
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey.shade600;
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
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
                              "Sales Quotations",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              "Manajemen dokumen penawaran harga (Draft -> Approved/Rejected)",
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
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      "Buat Penawaran Baru",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _quotations.isEmpty
                    ? const Center(
                        child: Text("Belum ada dokumen Sales Quotation."),
                      )
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
                                  "No. Penawaran",
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
                                  "Cara Bayar",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Total Nilai",
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
                            rows: _quotations.map((item) {
                              String status = (item['status'] ?? 'draft')
                                  .toString()
                                  .toLowerCase();
                              Color statusColor = _getStatusColor(status);

                              String noQuotation = item['no_quotation'] ?? '-';
                              String tanggal = item['tanggal'] ?? '-';
                              double total =
                                  double.tryParse(
                                    item['total_price']?.toString() ?? '0',
                                  ) ??
                                  0;
                              String customer =
                                  item['customer']?['name'] ?? '-';
                              String caraBayar = item['cara_bayar'] ?? '-';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      noQuotation,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(tanggal)),
                                  DataCell(Text(customer)),
                                  DataCell(Text(caraBayar)),
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

                                        // AKSI JIKA MASIH DRAFT
                                        if (status == 'draft') ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            tooltip: 'Setujui (Approve)',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'approved',
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                            tooltip: 'Tolak (Reject)',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'rejected',
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Hapus',
                                            onPressed: () =>
                                                _deleteSQ(item['id']),
                                          ),
                                        ],

                                        // AKSI JIKA SUDAH APPROVED
                                        if (status == 'approved')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.transform,
                                              color: Colors.purple,
                                              size: 20,
                                            ),
                                            tooltip:
                                                'Konversi ke SPK (Sales Order)',
                                            onPressed: () =>
                                                _convertToSO(item['id']),
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

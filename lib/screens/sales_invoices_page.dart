import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Tambahkan package url_launcher di pubspec.yaml
import '../constants/colors.dart';
import '../services/data_service.dart';
import '../services/auth_service.dart';

class SalesInvoicesPage extends StatefulWidget {
  const SalesInvoicesPage({super.key});

  @override
  State<SalesInvoicesPage> createState() => _SalesInvoicesPageState();
}

class _SalesInvoicesPageState extends State<SalesInvoicesPage> {
  List<dynamic> _invoices = [];
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
    var data = await DataService().getSalesInvoices();
    if (mounted) {
      setState(() {
        _invoices = data;
        _isLoading = false;
      });
    }
  }

  // --- MODAL DETAIL INVOICE ---
  void _showDetailModal(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    var res = await DataService().getSalesInvoiceDetail(id);
    if (!mounted) return;
    Navigator.pop(context);

    var detail = res?['data'] ?? res;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil detail Invoice.")),
      );
      return;
    }

    List<dynamic> items = detail['items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Detail Sales Invoice: ${detail['no_invoice'] ?? '-'}",
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Customer: ${detail['customer']?['name'] ?? '-'}",
                          ),
                          Text(
                            "Referensi SPK: ${detail['sales_order']?['no_spk'] ?? '-'}",
                          ),
                          Text("Tanggal Dibuat: ${detail['tanggal'] ?? '-'}"),
                          Text(
                            "Jatuh Tempo: ${detail['due_date'] ?? '-'}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Tipe Pembayaran: ${(detail['payment_type'] ?? '-').toString().toUpperCase()}",
                          ),
                          Text(
                            "Status: ${(detail['status'] ?? '-').toString().toUpperCase()}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: detail['status'] == 'paid'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Subtotal Asli: ${_currencyFormat.format(double.tryParse(detail['total_amount']?.toString() ?? '0'))}",
                          ),
                          Text(
                            "Diskon Otomatis: ${_currencyFormat.format(double.tryParse(detail['discount_amount']?.toString() ?? '0'))}",
                          ),
                          Text(
                            "PPN (11%): ${_currencyFormat.format(double.tryParse(detail['ppn_amount']?.toString() ?? '0'))}",
                          ),
                          Text(
                            "PPh (2%): - ${_currencyFormat.format(double.tryParse(detail['pph_amount']?.toString() ?? '0'))}",
                          ),
                          const Divider(),
                          Text(
                            "GRAND TOTAL: ${_currencyFormat.format(double.tryParse(detail['final_amount']?.toString() ?? '0'))}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                          if (detail['payment_type'] == 'dp') ...[
                            const SizedBox(height: 5),
                            Text(
                              "Uang Muka (DP): ${_currencyFormat.format(double.tryParse(detail['dp_amount']?.toString() ?? '0'))}",
                            ),
                            Text(
                              "Sisa Tagihan: ${_currencyFormat.format(double.tryParse(detail['balance_due']?.toString() ?? '0'))}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 30, thickness: 2),
                const Text(
                  "Daftar Barang:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.grey.shade100,
                  ),
                  columns: const [
                    DataColumn(label: Text("Produk")),
                    DataColumn(label: Text("Qty")),
                    DataColumn(label: Text("Harga")),
                    DataColumn(label: Text("Subtotal")),
                  ],
                  rows: items.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(Text(item['product']?['name'] ?? '-')),
                        DataCell(Text(item['qty'].toString())),
                        DataCell(
                          Text(
                            _currencyFormat.format(
                              double.tryParse(item['price']?.toString() ?? '0'),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _currencyFormat.format(
                              double.tryParse(
                                item['subtotal']?.toString() ?? '0',
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.print, color: Colors.white, size: 18),
            label: const Text(
              "Print Invoice",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              // Eksekusi fungsi print
              _printInvoice(id);
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  // --- MODAL BUAT SALES INVOICE ---
  void _showCreateDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    var allSOs = await DataService().getSalesOrders();
    // Berdasarkan logic baru, ambil SPK yang belum dibatalkan/pending
    var validSOs = allSOs.where((so) {
      String status = (so['status'] ?? '').toString().toLowerCase();
      return status != 'pending' && status != 'cancelled';
    }).toList();

    if (!mounted) return;
    Navigator.pop(context);

    int? selectedSoId;
    String paymentType = 'full';
    final dpCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Generate Sales Invoice",
                style: TextStyle(color: AppColors.primary),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.blue.shade50,
                        child: const Text(
                          "Info: Invoice ini akan menghitung PPN 11% dan diskon secara otomatis berdasarkan data produk.",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Pilih Referensi SPK *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedSoId,
                        isExpanded: true,
                        items: validSOs.map((so) {
                          return DropdownMenuItem<int>(
                            value: so['id'],
                            child: Text(
                              "${so['no_spk']} - ${so['customer']?['name'] ?? ''}",
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedSoId = val),
                      ),
                      const SizedBox(height: 15),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Metode Pembayaran",
                          border: OutlineInputBorder(),
                        ),
                        value: paymentType,
                        items: const [
                          DropdownMenuItem(
                            value: 'full',
                            child: Text("Bayar Lunas (Otomatis)"),
                          ),
                          DropdownMenuItem(
                            value: 'dp',
                            child: Text("Bayar Uang Muka (DP)"),
                          ),
                        ],
                        onChanged: (val) {
                          setStateDialog(() {
                            paymentType = val!;
                            if (val == 'full') dpCtrl.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 15),

                      if (paymentType == 'dp')
                        TextField(
                          controller: dpCtrl,
                          decoration: const InputDecoration(
                            labelText: "Nominal Uang Muka (Rp) *",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
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
                    if (selectedSoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pilih SPK terlebih dahulu!"),
                        ),
                      );
                      return;
                    }
                    if (paymentType == 'dp' && dpCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Nominal DP wajib diisi!"),
                        ),
                      );
                      return;
                    }

                    Map<String, dynamic> payload = {
                      "sales_order_id": selectedSoId,
                      "payment_type": paymentType,
                    };

                    if (paymentType == 'dp') {
                      payload["dp_amount"] = double.tryParse(dpCtrl.text) ?? 0;
                    }

                    Navigator.pop(context);
                    setState(() => _isLoading = true);

                    final response = await DataService().createSalesInvoice(
                      payload,
                    );
                    if (!mounted) return;

                    // Menggunakan logic pengecekan success dari respons JSON
                    if (response != null &&
                        (response['success'] == true ||
                            response.containsKey('data'))) {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Sales Invoice berhasil dibuat"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      setState(() => _isLoading = false);
                      String errorMsg =
                          response != null && response['message'] != null
                          ? response['message']
                          : "Gagal membuat invoice (SPK mungkin belum Shipped).";
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMsg),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Simpan Invoice",
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

  // --- AKSI PRINT INVOICE ---
  Future<void> _printInvoice(int id) async {
    // Karena route Laravel kamu menggunakan: Route::get('sales-invoices/{id}/print', [SalesInvoiceController::class, 'print']);
    final url = Uri.parse('${AuthService.baseUrl}/sales-invoices/$id/print');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka file PDF.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- AKSI HAPUS INVOICE ---
  void _deleteInvoice(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Invoice?"),
            content: const Text(
              "Data faktur ini akan dihapus. Yakin melanjutkan?",
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
      bool success = await DataService().deleteSalesInvoice(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Faktur berhasil dihapus.")),
        );
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal Hapus Invoice."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'unpaid':
        return Colors.orange.shade600;
      case 'paid':
        return Colors.green.shade600;
      case 'cancelled':
        return Colors.red.shade600;
      default:
        return Colors.grey;
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
                        "Sales Invoices (Faktur)",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Manajemen tagihan dan cetak bukti penjualan (PDF)",
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
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.post_add, color: Colors.white, size: 18),
                label: const Text(
                  "Buat Invoice Baru",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _invoices.isEmpty
                    ? const Center(child: Text("Belum ada data Faktur."))
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
                                  "No. Invoice",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Ref. SPK",
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
                                  "Grand Total",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Tipe Bayar",
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
                            rows: _invoices.map((item) {
                              String status = (item['status'] ?? 'unpaid')
                                  .toString()
                                  .toLowerCase();
                              Color statusColor = _getStatusColor(status);

                              double finalAmount =
                                  double.tryParse(
                                    item['final_amount']?.toString() ?? '0',
                                  ) ??
                                  0;
                              String payType = item['payment_type'] ?? '-';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item['no_invoice'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(item['sales_order']?['no_spk'] ?? '-'),
                                  ),
                                  DataCell(
                                    Text(item['customer']?['name'] ?? '-'),
                                  ),
                                  DataCell(
                                    Text(
                                      _currencyFormat.format(finalAmount),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(payType.toUpperCase())),
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
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Detail Modal
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

                                        // Tombol Print PDF
                                        IconButton(
                                          icon: const Icon(
                                            Icons.print,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          tooltip: 'Cetak PDF',
                                          onPressed: () =>
                                              _printInvoice(item['id']),
                                        ),

                                        // Tombol Hapus
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Hapus Faktur',
                                          onPressed: () =>
                                              _deleteInvoice(item['id']),
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

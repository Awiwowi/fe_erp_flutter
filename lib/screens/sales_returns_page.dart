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
          "Detail Retur: ${detail['return_no'] ?? '-'}",
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
                Text(
                  "Referensi Faktur: ${detail['invoice']?['no_invoice'] ?? '-'}",
                ),
                Text(
                  "Customer: ${detail['invoice']?['customer']?['name'] ?? '-'}",
                ),
                Text("Tanggal Retur: ${detail['return_date'] ?? '-'}"),
                Text("Catatan/Alasan: ${detail['reason'] ?? '-'}"),
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
                      DataColumn(label: Text("Kondisi Fisik")),
                    ],
                    rows: items.map((item) {
                      String prodName =
                          item['product']?['nama'] ??
                          item['product']?['name'] ??
                          '-';
                      String qty = item['qty']?.toString() ?? '0';
                      String cond;
                      switch (item['condition']) {
                        case 'good':
                          cond = 'Bagus (Good)';
                          break;
                        case 'damaged':
                          cond = 'Rusak (Damaged)';
                          break;
                        case 'reject':
                          cond = 'Reject';
                          break;
                        default:
                          cond = item['condition'] ?? '-';
                      }
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
                          DataCell(Text(cond)),
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

  // --- MODAL BUAT RETUR DARI INVOICE ---
  void _showCreateDialog() async {
    // ✅ Simpan dari page context di sini — SEBELUM dialog apapun dibuka
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    var invoices = await DataService().getSalesInvoices();

    var validInvoices = invoices.where((inv) {
      String status = (inv['status'] ?? '').toString().toLowerCase();
      return status != 'canceled' && status != 'draft';
    }).toList();

    if (!mounted) return;
    Navigator.pop(context);

    int? selectedInvoiceId;
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final notesCtrl = TextEditingController();
    List<Map<String, dynamic>> returnItems = [];
    bool isLoadingItems = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            void fetchInvoiceItems(int invoiceId) async {
              setStateDialog(() {
                isLoadingItems = true;
                returnItems = [];
              });

              var res = await DataService().getSalesInvoiceDetail(invoiceId);
              var detail = res?['data'] ?? res;

              if (detail != null) {
                List<dynamic> invItems = detail['items'] ?? [];
                setStateDialog(() {
                  returnItems = invItems.map((item) {
                    return {
                      'product_id': item['product_id'],
                      'product_name':
                          item['product']?['nama'] ??
                          item['product']?['name'] ??
                          'Produk',
                      'qty_invoice':
                          double.tryParse(item['qty']?.toString() ?? '0') ?? 0,
                      'price':
                          double.tryParse(item['price']?.toString() ?? '0') ??
                          0,
                      'qtyCtrl': TextEditingController(text: '0'),
                      'condition': 'good',
                    };
                  }).toList();
                  isLoadingItems = false;
                });
              } else {
                setStateDialog(() => isLoadingItems = false);
              }
            }

            return AlertDialog(
              title: const Text(
                "Buat Retur Penjualan",
                style: TextStyle(color: AppColors.primary),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(dialogContext).size.width * 0.8,
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        color: Colors.red.shade50,
                        child: const Text(
                          "Pilih Faktur (Invoice) pelanggan. Lalu isi Qty pada barang yang ingin dikembalikan. Biarkan '0' jika barang tersebut tidak diretur.",
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Pilih Faktur Penjualan *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedInvoiceId,
                        isExpanded: true,
                        items: validInvoices
                            .map(
                              (inv) => DropdownMenuItem<int>(
                                value: inv['id'],
                                child: Text(
                                  "${inv['no_invoice']} - ${inv['customer']?['name'] ?? ''}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedInvoiceId = val);
                            fetchInvoiceItems(val);
                          }
                        },
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
                        "Barang di dalam Faktur:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      if (isLoadingItems)
                        const Center(child: CircularProgressIndicator())
                      else if (selectedInvoiceId == null)
                        const Center(
                          child: Text(
                            "Silakan pilih Faktur terlebih dahulu.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else if (returnItems.isEmpty)
                        const Center(
                          child: Text(
                            "Faktur ini tidak memiliki data barang.",
                            style: TextStyle(color: Colors.red),
                          ),
                        )
                      else
                        // FIX OVERFLOW #2: Ganti ke Column per item agar tidak
                        // semua field berjejal dalam satu Row
                        ...returnItems.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama produk & maks qty
                                Text(
                                  item['product_name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "Maks. Qty: ${item['qty_invoice'].toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Qty & Kondisi dalam Row — sekarang lebih lebar
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: item['qtyCtrl'],
                                        decoration: const InputDecoration(
                                          labelText: "Qty Diretur",
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      flex: 3,
                                      child: DropdownButtonFormField<String>(
                                        value: item['condition'],
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: "Kondisi",
                                          border: OutlineInputBorder(),
                                          isDense: true,
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'good',
                                            child: Text("Bagus (Good)"),
                                          ),
                                          DropdownMenuItem(
                                            value: 'damaged',
                                            child: Text("Rusak (Damaged)"),
                                          ),
                                          DropdownMenuItem(
                                            value: 'reject',
                                            child: Text("Reject"),
                                          ),
                                        ],
                                        onChanged: (val) => setStateDialog(
                                          () => item['condition'] = val,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
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
                    backgroundColor: Colors.red.shade600,
                  ),
                  onPressed: returnItems.isEmpty
                      ? null
                      : () async {
                          if (selectedInvoiceId == null ||
                              dateCtrl.text.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text("Lengkapi Faktur dan Tanggal!"),
                              ),
                            );
                            return;
                          }

                          List<Map<String, dynamic>> payloadItems = [];
                          for (var i in returnItems) {
                            double qtyRetur =
                                double.tryParse(i['qtyCtrl'].text) ?? 0;
                            if (qtyRetur > 0) {
                              if (qtyRetur > i['qty_invoice']) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Qty retur ${i['product_name']} tidak boleh melebihi qty pembelian!",
                                    ),
                                  ),
                                );
                                return;
                              }
                              payloadItems.add({
                                "product_id": i['product_id'],
                                "qty": qtyRetur.toInt(),
                                "condition": i['condition'],
                                "price": i['price'],
                              });
                            }
                          }

                          if (payloadItems.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Isi 'Qty' pada minimal 1 barang!",
                                ),
                              ),
                            );
                            return;
                          }

                          Map<String, dynamic> payload = {
                            "sales_invoice_id": selectedInvoiceId,
                            "return_date": dateCtrl.text,
                            "reason": notesCtrl.text,
                            "items": payloadItems,
                          };

                          Navigator.pop(dialogContext);
                          setState(() => _isLoading = true);

                          bool success = await DataService().createSalesReturn(
                            payload,
                          );
                          if (!mounted) return;

                          if (success) {
                            _fetchData();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Pengajuan Retur berhasil dibuat!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            setState(() => _isLoading = false);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Gagal membuat Retur. Cek koneksi & validasi.",
                                ),
                                backgroundColor: Colors.red,
                              ),
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

  // --- AKSI HAPUS ---
  void _deleteReturn(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus Data Retur?"),
            content: const Text(
              "Data retur ini akan dihapus. Stok & piutang akan dikembalikan ke kondisi sebelum retur. Lanjutkan?",
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
              // FIX OVERFLOW #1: Wrap Column dengan Expanded agar tidak
              // melampaui batas Row ketika teks judul panjang
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Sales Returns (Retur Penjualan)",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "Pencatatan pengembalian barang dari Invoice",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
                  "Ajukan Retur Baru",
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
                                  "Terkait Faktur",
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
                                  "Total Retur",
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
                              String invoiceNo =
                                  item['invoice']?['no_invoice'] ?? '-';
                              String totalRetur =
                                  item['total_return_amount']?.toString() ??
                                  '0';
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item['return_no'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      invoiceNo,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(item['return_date'] ?? '-')),
                                  DataCell(
                                    Text(
                                      totalRetur,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
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
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Hapus',
                                          onPressed: () =>
                                              _deleteReturn(item['id']),
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

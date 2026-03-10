import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class InvoiceReceiptsPage extends StatefulWidget {
  const InvoiceReceiptsPage({super.key});

  @override
  State<InvoiceReceiptsPage> createState() => _InvoiceReceiptsPageState();
}

class _InvoiceReceiptsPageState extends State<InvoiceReceiptsPage> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getInvoiceReceipts();
    if (mounted) {
      setState(() {
        _invoices = data;
        _isLoading = false;
      });
    }
  }

  // --- FORM CREATE TANDA TERIMA ---
  void _showCreateDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    var allGRs = await DataService().getGoodsReceipts();
    var allUsers = await DataService().getUsers();

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading

    var postedGRs = allGRs.where((gr) => gr['status'] == 'posted').toList();

    if (postedGRs.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Tidak ada Penerimaan Barang (Goods Receipt) yang valid/posted",
            ),
          ),
        );
      return;
    }

    String? selectedGRId;
    String? selectedPoId;
    String? selectedRequesterId;

    final invoiceNoCtrl = TextEditingController();
    final trxDateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final invDateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final dueDateCtrl = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 30))
          .toIso8601String()
          .split('T')[0],
    );
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Buat Tanda Terima Faktur",
                style: TextStyle(color: AppColors.primary),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Pilih Penerimaan Barang (GR) *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedGRId,
                        isExpanded: true,
                        items: postedGRs.map((gr) {
                          String grNo = gr['receipt_number'] ?? '-';
                          String poNo = gr['po_reference'] ?? '-';

                          String supp = '-';
                          var po = gr['purchase_order'];
                          if (po != null && po['supplier'] != null) {
                            supp =
                                po['supplier']['nama'] ??
                                po['supplier']['name'] ??
                                '-';
                          }

                          return DropdownMenuItem<String>(
                            value: gr['id'].toString(),
                            child: Text(
                              "$grNo (PO: $poNo) - $supp",
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              if (gr['purchase_order_id'] != null) {
                                selectedPoId = gr['purchase_order_id']
                                    .toString();
                              }
                            },
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedGRId = val),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Pemohon (Requester) *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedRequesterId,
                        isExpanded: true,
                        items: allUsers.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['id'].toString(),
                            child: Text(
                              user['name'] ?? 'User ID: ${user['id']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedRequesterId = val),
                      ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: invoiceNoCtrl,
                        decoration: const InputDecoration(
                          labelText: "No. Faktur (Dari Supplier) *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: trxDateCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tanggal Transaksi (YYYY-MM-DD)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: invDateCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tanggal Faktur (YYYY-MM-DD)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dueDateCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tanggal Jatuh Tempo (YYYY-MM-DD)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: "Catatan",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    if (selectedPoId == null ||
                        selectedRequesterId == null ||
                        invoiceNoCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Lengkapi Pilihan GR, Pemohon, dan No Faktur!",
                          ),
                        ),
                      );
                      return;
                    }

                    Map<String, dynamic> payload = {
                      "purchase_order_id": int.parse(selectedPoId!),
                      "transaction_date": trxDateCtrl.text,
                      "invoice_number": invoiceNoCtrl.text,
                      "invoice_date": invDateCtrl.text,
                      "due_date": dueDateCtrl.text,
                      "requester_id": int.parse(selectedRequesterId!),
                      "notes": notesCtrl.text,
                    };

                    final messenger = ScaffoldMessenger.of(context);

                    Navigator.pop(dialogContext);
                    setState(() => _isLoading = true);

                    bool success = await DataService().createInvoiceReceipt(
                      payload,
                    );

                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Berhasil membuat Tanda Terima (Draft)",
                          ),
                        ),
                      );
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Gagal membuat data. Cek format tanggal/input",
                          ),
                        ),
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

  // --- HELPER WARNA STATUS ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey.shade600;
      case 'submitted':
        return Colors.orange.shade600;
      case 'approved':
        return Colors.green.shade600;
      case 'rejected':
        return Colors.red.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  // --- AKSI STATUS ---
  void _changeStatus(int id, String action, String actionName) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text("Konfirmasi $actionName"),
            content: Text(
              "Apakah Anda yakin ingin memproses data ini menjadi $actionName?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
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
      bool success = await DataService().actionInvoiceReceipt(id, action);

      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(
          SnackBar(content: Text("Status berhasil diubah menjadi $actionName")),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("Gagal mengubah status!")),
        );
      }
    }
  }

  // --- AKSI HAPUS ---
  void _deleteInvoice(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text("Hapus Data?"),
            content: const Text(
              "Tanda terima faktur yang dihapus tidak dapat dikembalikan.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(dialogContext, true),
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
      bool success = await DataService().deleteInvoiceReceipt(id);

      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(const SnackBar(content: Text("Data dihapus")));
      }
    }
  }

  // --- AKSI CETAK PDF ---
  void _printPdf(int id) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    var printData = await DataService().getInvoicePrintData(id);

    if (!mounted) return;
    Navigator.pop(context);

    if (printData == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Gagal mengambil data cetak dari server."),
        ),
      );
      return;
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    final now = DateTime.now();
    final printTime = DateFormat('d/M/yyyy, HH.mm.ss').format(now);
    final printTimeShort = DateFormat('d/M/yyyy, HH.mm').format(now);

    // Helper: format tanggal dari ISO string → "2026-03-04"
    String fmtDate(dynamic raw) {
      if (raw == null) return '-';
      return raw.toString().split('T')[0];
    }

    final supplier = printData['supplier'] ?? {};
    final receipt = printData['receipt'] ?? {};
    final invoice = printData['invoice'] ?? {};
    final po = printData['purchase_order'] ?? {};
    final items = (printData['items'] as List?) ?? [];
    final grandTotal = printData['grand_total'] ?? 0;

    final supplierName = supplier['name'] ?? supplier['nama'] ?? '-';
    final supplierAlamat = supplier['address'] ?? supplier['alamat'] ?? '-';
    final supplierTelepon = supplier['phone'] ?? supplier['telepon'] ?? '-';
    final supplierEmail = supplier['email'] ?? '-';

    final pdf = pw.Document();

    // ── Warna tema ──
    const headerColor = PdfColors.grey800;
    const labelColor = PdfColors.grey700;

    pw.Widget _labelValue(String label, String value, {bool bold = false}) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 85,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: labelColor,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 20),
        build: (pw.Context ctx) {
          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── HEADER: timestamp + url ──
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      printTimeShort,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      "localhost:3000/print/invoice-receipt/$id",
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),

                // ── JUDUL + KANAN: NAMA PERUSAHAAN ──
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          "TANDA TERIMA FAKTUR",
                          style: pw.TextStyle(
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          "NO. ${receipt['receipt_number'] ?? '-'}",
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          "PT. DKM MANUFAKTUR",
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          "Jl. Raya Industri No. 123, Cikarang",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.Text(
                          "Telp: (021) 89012345",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 8),

                // ── INFO: SUPPLIER (kiri) + TANGGAL/PO/REQUESTER (kanan) ──
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Kiri: Supplier
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _labelValue(
                            "DARI SUPPLIER",
                            supplierName,
                            bold: true,
                          ),
                          pw.SizedBox(height: 4),
                          _labelValue("TELEPON", supplierTelepon),
                          pw.SizedBox(height: 4),
                          _labelValue("ALAMAT", supplierAlamat),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    // Kanan: Tanggal TTF, PO Ref, Requester
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _labelValue(
                            "TANGGAL TTF",
                            fmtDate(receipt['transaction_date']),
                          ),
                          pw.SizedBox(height: 4),
                          _labelValue(
                            "PO REF",
                            po['kode']?.toString() ?? '-',
                            bold: true,
                          ),
                          pw.SizedBox(height: 4),
                          _labelValue("REQUESTER", receipt['requester'] ?? '-'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // ── SEKSI I: RINCIAN FAKTUR ──
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    "I. RINCIAN FAKTUR / INVOICE",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.5),
                    1: const pw.FlexColumnWidth(2.5),
                    2: const pw.FlexColumnWidth(2.5),
                    3: const pw.FlexColumnWidth(2.5),
                  },
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "NO. FAKTUR",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "TANGGAL",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "JATUH TEMPO",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "JUMLAH (RP)",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Data row
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            invoice['invoice_number']?.toString() ?? '-',
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            fmtDate(invoice['invoice_date']),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            fmtDate(invoice['due_date']),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            currencyFormatter.format(invoice['amount'] ?? 0),
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Total row di luar tabel
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                      right: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                      bottom: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        "TOTAL TERFAKTUR",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          currencyFormatter.format(invoice['amount'] ?? 0),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // ── SEKSI II: RINCIAN BARANG ──
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    "II. RINCIAN BARANG / JASA (REF: ${po['kode'] ?? '-'})",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey400,
                    width: 0.5,
                  ),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(24),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FixedColumnWidth(30),
                    3: const pw.FixedColumnWidth(48),
                    4: const pw.FixedColumnWidth(80),
                    5: const pw.FixedColumnWidth(80),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "No",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "Nama Produk/Material",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "Qty",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "Satuan",
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "Harga",
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 5,
                          ),
                          child: pw.Text(
                            "Subtotal",
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...items.asMap().entries.map((entry) {
                      final i = entry.key;
                      final item = entry.value;
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: pw.Text(
                              "${i + 1}",
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: pw.Text(
                              item['name']?.toString() ?? '-',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: pw.Text(
                              item['quantity']?.toString() ?? '0',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: pw.Text(
                              item['unit']?.toString() ?? '-',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: pw.Text(
                              currencyFormatter.format(item['price'] ?? 0),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 5,
                            ),
                            child: pw.Text(
                              currencyFormatter.format(item['subtotal'] ?? 0),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                // Total row di luar tabel agar label tidak terpotong
                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    border: pw.Border(
                      left: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                      right: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                      bottom: pw.BorderSide(
                        color: PdfColors.grey400,
                        width: 0.5,
                      ),
                    ),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 5,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        "TOTAL NILAI BARANG",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.SizedBox(
                        width: 88,
                        child: pw.Text(
                          currencyFormatter.format(grandTotal),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // ── SEKSI III: DATA SUPPLIER ──
                pw.Container(
                  color: PdfColors.grey200,
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    "III. DATA SUPPLIER",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.SizedBox(
                                  width: 80,
                                  child: pw.Text(
                                    "NAMA SUPPLIER",
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.Text(
                                  ": $supplierName",
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              children: [
                                pw.SizedBox(
                                  width: 80,
                                  child: pw.Text(
                                    "ALAMAT",
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.Text(
                                  ": $supplierAlamat",
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.SizedBox(
                                  width: 80,
                                  child: pw.Text(
                                    "NO. TELEPON",
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.Text(
                                  ": $supplierTelepon",
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                            pw.SizedBox(height: 5),
                            pw.Row(
                              children: [
                                pw.SizedBox(
                                  width: 80,
                                  child: pw.Text(
                                    "EMAIL",
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.Text(
                                  ": $supplierEmail",
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // ── CATATAN ──
                pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "CATATAN:",
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        receipt['notes']?.toString().isNotEmpty == true
                            ? '"${receipt['notes']}"'
                            : '-',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 14),

                // ── TTD ──
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          "DIBUAT OLEH",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 36),
                        pw.Text(
                          receipt['requester'] ?? receipt['created_by'] ?? '-',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          "DITERIMA OLEH",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 36),
                        pw.Text(
                          receipt['created_by'] ?? '-',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          "DISETUJUI OLEH",
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 36),
                        pw.Text(
                          receipt['approved_by'] != null
                              ? receipt['approved_by'].toString()
                              : "(.............................)",
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          "Manager Purchasing",
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),
              ],
            ),
          ];
        },
        footer: (pw.Context ctx) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Center(
                child: pw.Text(
                  "Dicetak pada $printTime",
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: "TTF_${receipt['receipt_number'] ?? id}.pdf",
    );
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
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Tanda Terima Faktur (Invoice Receipt)",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: AppColors.primary,
                        ),
                        onPressed: _fetchData,
                        tooltip: "Refresh Data",
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                      "Buat Baru",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _invoices.isEmpty
                    ? const Center(
                        child: Text("Belum ada data Tanda Terima Faktur."),
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
                                  "No. Dokumen",
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
                                  "Supplier",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Pemohon",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Total Amount",
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
                              String status = (item['status'] ?? 'draft')
                                  .toString()
                                  .toLowerCase();
                              Color statusColor = _getStatusColor(status);
                              String tgl =
                                  item['transaction_date']?.toString().split(
                                    'T',
                                  )[0] ??
                                  '-';

                              String supplierName = '-';
                              var po =
                                  item['purchase_order'] ??
                                  item['purchaseOrder'];
                              if (po != null && po is Map) {
                                var supp = po['supplier'];
                                if (supp != null && supp is Map) {
                                  supplierName =
                                      supp['nama'] ??
                                      supp['name']?.toString() ??
                                      '-';
                                }
                              }

                              String requesterName = '-';
                              if (item['requester'] != null &&
                                  item['requester'] is Map) {
                                requesterName =
                                    item['requester']['name']?.toString() ??
                                    '-';
                              }

                              double totalAmount = 0;
                              if (item['invoices'] != null &&
                                  item['invoices'] is List) {
                                for (var inv in item['invoices']) {
                                  totalAmount +=
                                      double.tryParse(
                                        inv['amount']?.toString() ?? '0',
                                      ) ??
                                      0;
                                }
                              }

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item['receipt_number']?.toString() ?? '-',
                                    ),
                                  ),
                                  DataCell(Text(tgl)),
                                  DataCell(
                                    Text(
                                      supplierName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(requesterName)),
                                  DataCell(
                                    Text(
                                      "Rp ${totalAmount.toStringAsFixed(0)}",
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
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        if (status == 'draft')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.send,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            tooltip: 'Submit',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'submit',
                                              'Submitted',
                                            ),
                                          ),
                                        if (status == 'submitted') ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            tooltip: 'Approve',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'approve',
                                              'Approved',
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                            tooltip: 'Reject',
                                            onPressed: () => _changeStatus(
                                              item['id'],
                                              'reject',
                                              'Rejected',
                                            ),
                                          ),
                                        ],
                                        // TOMBOL PDF (Akan muncul apabila status bukan draft)
                                        if (status != 'draft')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Cetak PDF',
                                            onPressed: () =>
                                                _printPdf(item['id']),
                                          ),

                                        if (status == 'draft' ||
                                            status == 'rejected')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Hapus',
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

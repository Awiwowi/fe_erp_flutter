import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class SalesInvoicesPage extends StatefulWidget {
  const SalesInvoicesPage({super.key});

  @override
  State<SalesInvoicesPage> createState() => _SalesInvoicesPageState();
}

class _SalesInvoicesPageState extends State<SalesInvoicesPage> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;

  final _fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _fmtPdf = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    final data = await DataService().getSalesInvoices();
    if (mounted)
      setState(() {
        _invoices = data;
        _isLoading = false;
      });
  }

  // ═══════════════════════════════════════════════════════════════
  // PDF HELPERS — class-level methods, bukan nested functions
  // ═══════════════════════════════════════════════════════════════

  pw.Widget _pdfLabelVal(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              ': $value',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(
    String text, {
    bool header = false,
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: (header || bold)
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _pdfSummaryRow(
    String label,
    String value, {
    bool bold = false,
    double fs = 9,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            '$label  ',
            style: pw.TextStyle(
              fontSize: fs,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(
            width: 115,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: fs,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTtd(String title, String name, {String? subtitle}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 36),
        pw.Text(
          name.isNotEmpty ? name : '(............................)',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline,
          ),
        ),
        if (subtitle != null)
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // GENERATE PDF IN-APP
  // ═══════════════════════════════════════════════════════════════
  void _printPdf(int id) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final res = await DataService().getSalesInvoiceDetail(id);
    if (!mounted) return;
    Navigator.pop(context);

    if (res == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal mengambil data invoice dari server.'),
        ),
      );
      return;
    }

    // Ambil detail — bisa dari { success, data: {...} } atau langsung map
    final detail = _extractDetail(res);

    debugPrint('=== INVOICE DETAIL KEYS: ${detail.keys.toList()}');
    debugPrint('=== no_invoice: ${detail['no_invoice']}');
    debugPrint('=== items count: ${(detail['items'] as List?)?.length}');

    final customer = (detail['customer'] as Map<String, dynamic>?) ?? {};
    final so = (detail['sales_order'] as Map<String, dynamic>?) ?? {};
    final items = (detail['items'] as List?) ?? [];

    final noInvoice = detail['no_invoice']?.toString() ?? '-';
    final tanggal = _fmtDate(detail['tanggal']);
    final dueDate = _fmtDate(detail['due_date']);
    final paymentType = detail['payment_type']?.toString() ?? 'full';
    final statusInv = (detail['status']?.toString() ?? '-').toUpperCase();
    final notes = detail['notes']?.toString() ?? '';

    final custName = customer['name']?.toString() ?? '-';
    final custAddr =
        customer['address']?.toString() ??
        customer['alamat']?.toString() ??
        '-';
    final custPhone =
        customer['phone']?.toString() ?? customer['telepon']?.toString() ?? '-';
    final noSpk = so['no_spk']?.toString() ?? so['nomor']?.toString() ?? '-';

    final totalOri = _toDouble(detail['total_amount']);
    final disc = _toDouble(detail['discount_amount']);
    final ppn = _toDouble(detail['ppn_amount']);
    final pph = _toDouble(detail['pph_amount']);
    final finalAmt = _toDouble(detail['final_amount']);
    final paid = _toDouble(detail['amount_paid']);
    final balance = _toDouble(detail['balance_due']);

    final now = DateTime.now();
    final printTime = DateFormat('d/M/yyyy, HH.mm.ss').format(now);
    final printTimeShort = DateFormat('d/M/yyyy, HH.mm').format(now);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 24, 32, 20),
        build: (ctx) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── timestamp + nomor ──
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
                    'Invoice #$noInvoice',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // ── Judul + perusahaan ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FAKTUR PENJUALAN',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'NO. $noInvoice',
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
                        'PT. DKM MANUFAKTUR',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Jl. Raya Industri No. 123, Cikarang',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'Telp: (021) 89012345',
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

              // ── Customer (kiri) + Info faktur (kanan) ──
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfLabelVal('KEPADA', custName, bold: true),
                        _pdfLabelVal('TELEPON', custPhone),
                        _pdfLabelVal('ALAMAT', custAddr),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfLabelVal('TANGGAL', tanggal),
                        _pdfLabelVal('JATUH TEMPO', dueDate),
                        _pdfLabelVal('REF SPK', noSpk, bold: true),
                        _pdfLabelVal(
                          'TIPE BAYAR',
                          paymentType == 'full'
                              ? 'LUNAS PENUH'
                              : 'DOWN PAYMENT',
                        ),
                        _pdfLabelVal('STATUS', statusInv, bold: true),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // ── Section header ──
              pw.Container(
                color: PdfColors.grey200,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                child: pw.Text(
                  'RINCIAN BARANG / JASA',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),

              // ── Tabel items ──
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(32),
                  3: const pw.FixedColumnWidth(85),
                  4: const pw.FixedColumnWidth(90),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      _pdfCell('No', header: true),
                      _pdfCell('Nama Produk', header: true),
                      _pdfCell('Qty', header: true),
                      _pdfCell(
                        'Harga (Rp)',
                        header: true,
                        align: pw.TextAlign.right,
                      ),
                      _pdfCell(
                        'Subtotal (Rp)',
                        header: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  ...items.asMap().entries.map((e) {
                    final i = e.key;
                    final item = e.value as Map<String, dynamic>;
                    final name =
                        item['product']?['nama']?.toString() ??
                        item['product']?['name']?.toString() ??
                        '-';
                    final qty = item['qty']?.toString() ?? '0';
                    final price = _toDouble(item['price']);
                    final sub = _toDouble(item['subtotal']);
                    return pw.TableRow(
                      children: [
                        _pdfCell('${i + 1}'),
                        _pdfCell(name),
                        _pdfCell(qty),
                        _pdfCell(
                          _fmtPdf.format(price),
                          align: pw.TextAlign.right,
                        ),
                        _pdfCell(
                          _fmtPdf.format(sub),
                          bold: true,
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              // ── Ringkasan harga ──
              pw.Container(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                    right: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                    bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                  ),
                ),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: pw.Column(
                  children: [
                    _pdfSummaryRow(
                      'SUBTOTAL',
                      'Rp ${_fmtPdf.format(totalOri)}',
                    ),
                    if (disc > 0)
                      _pdfSummaryRow('DISKON', '- Rp ${_fmtPdf.format(disc)}'),
                    _pdfSummaryRow('PPN 11%', '+ Rp ${_fmtPdf.format(ppn)}'),
                    _pdfSummaryRow('PPh 2%', '- Rp ${_fmtPdf.format(pph)}'),
                    pw.Divider(thickness: 0.5, color: PdfColors.grey500),
                    _pdfSummaryRow(
                      'TOTAL TAGIHAN',
                      'Rp ${_fmtPdf.format(finalAmt)}',
                      bold: true,
                      fs: 10,
                    ),
                    _pdfSummaryRow(
                      'SUDAH DIBAYAR',
                      'Rp ${_fmtPdf.format(paid)}',
                    ),
                    _pdfSummaryRow(
                      'SISA TAGIHAN',
                      'Rp ${_fmtPdf.format(balance)}',
                      bold: true,
                      color: balance > 0
                          ? PdfColors.red700
                          : PdfColors.green700,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 8),

              // ── Catatan ──
              if (notes.isNotEmpty) ...[
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
                        'CATATAN:',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '"$notes"',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
              ],

              // ── TTD ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _pdfTtd('DISIAPKAN OLEH', ''),
                  _pdfTtd('DITERIMA OLEH', custName),
                  _pdfTtd('DISETUJUI OLEH', '', subtitle: 'Manager Penjualan'),
                ],
              ),
            ],
          ),
        ],
        footer: (ctx) => pw.Column(
          children: [
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Center(
              child: pw.Text(
                'Dicetak pada $printTime',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey500,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Invoice_$noInvoice.pdf',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DETAIL MODAL
  // ═══════════════════════════════════════════════════════════════
  void _showDetailModal(int id) async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final res = await DataService().getSalesInvoiceDetail(id);
    if (!mounted) return;
    Navigator.pop(context);

    if (res == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal mengambil detail Faktur.')),
      );
      return;
    }

    final detail = _extractDetail(res);

    debugPrint('=== DETAIL MODAL KEYS: ${detail.keys.toList()}');

    final items = (detail['items'] as List?) ?? [];
    final totalOri = _toDouble(detail['total_amount']);
    final disc = _toDouble(detail['discount_amount']);
    final ppn = _toDouble(detail['ppn_amount']);
    final pph = _toDouble(detail['pph_amount']);
    final finalAmt = _toDouble(detail['final_amount']);
    final paid = _toDouble(detail['amount_paid']);
    final balance = _toDouble(detail['balance_due']);
    final payType = detail['payment_type']?.toString() ?? '-';
    final status = (detail['status']?.toString() ?? '-').toLowerCase();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail['no_invoice']?.toString() ?? '-',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    detail['customer']?['name']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 16,
              ),
              label: const Text(
                'PDF',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _printPdf(id);
              },
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 16),
                _row('Tanggal Faktur', _fmtDate(detail['tanggal'])),
                _row('Jatuh Tempo', _fmtDate(detail['due_date'])),
                _row('Tipe Bayar', payType.toUpperCase()),
                _row('Status', status.toUpperCase()),
                const Divider(height: 20),
                const Text(
                  'Daftar Item:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text(
                    'Tidak ada item.',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        Colors.grey.shade100,
                      ),
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('Produk')),
                        DataColumn(label: Text('Qty')),
                        DataColumn(label: Text('Harga')),
                        DataColumn(label: Text('Subtotal')),
                      ],
                      rows: items.map((item) {
                        final m = item as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                m['product']?['nama']?.toString() ??
                                    m['product']?['name']?.toString() ??
                                    '-',
                              ),
                            ),
                            DataCell(
                              Text(
                                m['qty']?.toString() ?? '0',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataCell(Text(_fmt.format(_toDouble(m['price'])))),
                            DataCell(
                              Text(
                                _fmt.format(_toDouble(m['subtotal'])),
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
                const Divider(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _sum('Subtotal', _fmt.format(totalOri)),
                      if (disc > 0)
                        _sum(
                          'Diskon',
                          '- ${_fmt.format(disc)}',
                          color: Colors.orange,
                        ),
                      _sum('PPN 11%', '+ ${_fmt.format(ppn)}'),
                      _sum('PPh 2%', '- ${_fmt.format(pph)}'),
                      const Divider(height: 12),
                      _sum(
                        'Total Tagihan',
                        _fmt.format(finalAmt),
                        bold: true,
                        color: Colors.green.shade700,
                        fs: 15,
                      ),
                      const SizedBox(height: 4),
                      _sum(
                        'Sudah Dibayar',
                        _fmt.format(paid),
                        color: Colors.blue.shade700,
                      ),
                      _sum(
                        'Sisa Tagihan',
                        _fmt.format(balance),
                        bold: true,
                        color: balance > 0
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            icon: const Icon(
              Icons.picture_as_pdf,
              color: Colors.white,
              size: 16,
            ),
            label: const Text(
              'Cetak PDF',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _printPdf(id);
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE DIALOG
  // ═══════════════════════════════════════════════════════════════
  void _showCreateDialog() async {
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    final allDOs = await DataService().getDeliveryOrders();
    if (!mounted) return;
    Navigator.pop(context);

    final validDOs = allDOs.where((d) {
      final s = (d['status'] ?? '').toString().toLowerCase();
      return s == 'shipped' || s == 'delivered';
    }).toList();

    if (validDOs.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak ada Surat Jalan yang sudah dikirim. Buat DO terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    int? selectedDoId;
    Map<String, dynamic>? doDetail;
    bool loadingDetail = false;
    String paymentType = 'full';
    final dpCtrl = TextEditingController();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          void loadDoDetail(int doId) async {
            setD(() {
              loadingDetail = true;
              doDetail = null;
            });
            final res = await DataService().getDeliveryOrderDetail(doId);
            setD(() {
              doDetail = (res?['data'] is Map)
                  ? res!['data'] as Map<String, dynamic>
                  : res as Map<String, dynamic>?;
              loadingDetail = false;
            });
          }

          List<Map<String, dynamic>> previewItems() {
            if (doDetail == null) return [];
            final doItems = (doDetail!['items'] as List?) ?? [];
            final soItems = (doDetail!['sales_order']?['items'] as List?) ?? [];
            return doItems.map((di) {
              final m = di as Map<String, dynamic>;
              final prodId = m['product_id'];
              final qty = _toDouble(m['qty_realisasi']);
              final soItem = soItems.firstWhere(
                (s) => (s as Map)['product_id'] == prodId,
                orElse: () => <String, dynamic>{},
              );
              final harga = _toDouble(
                (soItem as Map<String, dynamic>)['price'],
              );
              return {
                'name': m['product']?['nama'] ?? m['product']?['name'] ?? '-',
                'qty': qty,
                'price': harga,
                'subtotal': qty * harga,
              };
            }).toList();
          }

          double total() =>
              previewItems().fold(0.0, (s, i) => s + (i['subtotal'] as double));

          int? soId() =>
              doDetail?['sales_order_id'] ?? doDetail?['sales_order']?['id'];

          String soRef() =>
              doDetail?['sales_order']?['no_spk']?.toString() ??
              doDetail?['sales_order']?['nomor']?.toString() ??
              '-';

          String custName() =>
              doDetail?['sales_order']?['customer']?['name']?.toString() ??
              doDetail?['customer']?['name']?.toString() ??
              '-';

          return AlertDialog(
            title: const Text(
              'Buat Faktur Penjualan',
              style: TextStyle(color: AppColors.primary),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pilih Surat Jalan yang sudah dikirim. '
                              'Harga diambil otomatis dari Sales Order.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown DO
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: '1. Pilih Surat Jalan (DO) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_shipping),
                      ),
                      value: selectedDoId,
                      isExpanded: true,
                      hint: const Text('Pilih Surat Jalan'),
                      items: validDOs.map((d) {
                        final noSj = d['no_sj']?.toString() ?? 'DO-${d['id']}';
                        final tgl = _fmtDate(d['tanggal']);
                        final cust =
                            d['customer']?['name']?.toString() ??
                            d['sales_order']?['customer']?['name']
                                ?.toString() ??
                            '-';
                        return DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(
                            '$noSj  —  $cust  ($tgl)',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setD(() => selectedDoId = val);
                          loadDoDetail(val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Tipe bayar
                    const Text(
                      '2. Tipe Pembayaran *',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'Lunas (Full)',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: 'full',
                            groupValue: paymentType,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) =>
                                setD(() => paymentType = v ?? 'full'),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'DP (Cicilan)',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: 'dp',
                            groupValue: paymentType,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) =>
                                setD(() => paymentType = v ?? 'full'),
                          ),
                        ),
                      ],
                    ),

                    if (paymentType == 'dp') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: dpCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '3. Jumlah DP *',
                          hintText: 'Contoh: 500000',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                          prefixText: 'Rp ',
                        ),
                      ),
                    ],

                    const Divider(height: 24, thickness: 1.5),

                    // Preview
                    if (loadingDetail)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (doDetail != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            size: 15,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ref SPK: ${soRef()}  •  ${custName()}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade100,
                          ),
                          columnSpacing: 20,
                          columns: const [
                            DataColumn(label: Text('Produk')),
                            DataColumn(label: Text('Qty Kirim')),
                            DataColumn(label: Text('Harga SPK')),
                            DataColumn(label: Text('Subtotal')),
                          ],
                          rows: previewItems().map((item) {
                            return DataRow(
                              cells: [
                                DataCell(Text(item['name'].toString())),
                                DataCell(Text(item['qty'].toString())),
                                DataCell(Text(_fmt.format(item['price']))),
                                DataCell(
                                  Text(
                                    _fmt.format(item['subtotal']),
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            _prev('Total Harga SO', _fmt.format(total())),
                            _prev(
                              'PPN 11% (est.)',
                              _fmt.format(total() * 0.11),
                              sub: true,
                            ),
                            _prev(
                              'PPh 2% (est.)',
                              '- ${_fmt.format(total() * 0.02)}',
                              sub: true,
                            ),
                            const Divider(height: 10),
                            _prev(
                              'Estimasi Final',
                              _fmt.format(
                                total() + (total() * 0.11) - (total() * 0.02),
                              ),
                              bold: true,
                              color: Colors.green.shade800,
                            ),
                            _prev(
                              'Tipe Bayar',
                              paymentType == 'full'
                                  ? 'LUNAS PENUH'
                                  : 'DOWN PAYMENT',
                              bold: true,
                              color: paymentType == 'full'
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ],
                        ),
                      ),
                    ] else if (selectedDoId == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Pilih Surat Jalan untuk preview tagihan.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.save, color: Colors.white, size: 18),
                onPressed:
                    (selectedDoId == null || doDetail == null || loadingDetail)
                    ? null
                    : () async {
                        // Simpan messenger SEBELUM pop
                        final msg = ScaffoldMessenger.of(ctx);

                        if (paymentType == 'dp') {
                          final dp = double.tryParse(dpCtrl.text.trim()) ?? 0;
                          if (dp <= 0) {
                            msg.showSnackBar(
                              const SnackBar(
                                content: Text('Masukkan jumlah DP yang valid!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }

                        final sid = soId();
                        if (sid == null) {
                          msg.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Gagal membaca Sales Order dari DO ini.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final payload = <String, dynamic>{
                          'sales_order_id': sid,
                          'payment_type': paymentType,
                          if (paymentType == 'dp')
                            'dp_amount':
                                double.tryParse(dpCtrl.text.trim()) ?? 0,
                        };

                        Navigator.pop(ctx); // pop dulu
                        setState(() => _isLoading = true);

                        final result = await DataService().createSalesInvoice(
                          payload,
                        );
                        if (!mounted) return;

                        final ok = result?['success'] == true;
                        final message =
                            result?['message']?.toString() ??
                            (ok
                                ? 'Invoice berhasil dibuat!'
                                : 'Gagal membuat Invoice.');

                        if (ok) {
                          _fetchData();
                        } else {
                          setState(() => _isLoading = false);
                        }
                        msg.showSnackBar(
                          SnackBar(
                            content: Text(message),
                            backgroundColor: ok ? Colors.green : Colors.red,
                          ),
                        );
                      },
                label: const Text(
                  'Buat & Simpan Faktur',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TANDAI LUNAS
  // ═══════════════════════════════════════════════════════════════
  void _changeStatus(int id, String target) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Tandai Lunas?'),
            content: const Text(
              'Tindakan ini akan melunasi seluruh sisa tagihan invoice.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Ya, Lunasi',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    final ok = await DataService().updateSalesInvoiceStatus(id, target);
    if (!mounted) return;

    if (ok) {
      _fetchData();
      messenger.showSnackBar(
        const SnackBar(content: Text('Invoice berhasil dilunasi.')),
      );
    } else {
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Gagal melunasi invoice.')),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WIDGET HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Ekstrak data invoice dari berbagai bentuk response Laravel:
  /// - { success: true, data: {...} }  ← dari show()
  /// - { data: {...} }                 ← variasi lain
  /// - {...}                           ← langsung object invoice
  Map<String, dynamic> _extractDetail(Map<String, dynamic> res) {
    if (res['data'] is Map) return res['data'] as Map<String, dynamic>;
    return res;
  }

  /// Format tanggal dari ISO string atau Date object
  String _fmtDate(dynamic raw) {
    if (raw == null) return '-';
    return raw.toString().split('T')[0];
  }

  /// Parse double aman dari dynamic
  double _toDouble(dynamic v) => double.tryParse(v?.toString() ?? '0') ?? 0;

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        const Text(': ', style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _sum(
    String label,
    String value, {
    bool bold = false,
    Color? color,
    double fs = 13,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fs,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: fs,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _prev(
    String label,
    String value, {
    bool bold = false,
    bool sub = false,
    Color? color,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: sub ? 11 : 13,
            color: sub ? Colors.grey : null,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: sub ? 11 : 13,
            color: color ?? (sub ? Colors.grey : null),
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'draft':
        return Colors.orange.shade600;
      case 'partial':
        return Colors.blue.shade600;
      case 'paid':
        return Colors.green.shade600;
      case 'canceled':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Invoices (Faktur Penjualan)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Daftar faktur penjualan ke pelanggan',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _fetchData,
                    tooltip: 'Refresh',
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                  'Buat Faktur dari Surat Jalan',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _invoices.isEmpty
                    ? const Center(child: Text('Belum ada data Faktur.'))
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
                                  'No. Faktur',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Tanggal',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Customer',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Total Tagihan',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  'Aksi',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: _invoices.map((item) {
                              final m = item as Map<String, dynamic>;
                              final status = (m['status'] ?? 'draft')
                                  .toString()
                                  .toLowerCase();
                              final sc = _statusColor(status);
                              final total = _toDouble(
                                m['final_amount'] ?? m['total_price'],
                              );

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      m['no_invoice']?.toString() ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_fmtDate(m['tanggal']))),
                                  DataCell(
                                    Text(
                                      m['customer']?['name']?.toString() ?? '-',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _fmt.format(total),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: sc.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: sc),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: sc,
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
                                            Icons.picture_as_pdf,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          tooltip: 'Cetak PDF',
                                          onPressed: () =>
                                              _printPdf(m['id'] as int),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_red_eye,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          tooltip: 'Lihat Detail',
                                          onPressed: () =>
                                              _showDetailModal(m['id'] as int),
                                        ),
                                        if (status == 'draft' ||
                                            status == 'partial')
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            tooltip: 'Tandai Lunas',
                                            onPressed: () => _changeStatus(
                                              m['id'] as int,
                                              'paid',
                                            ),
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

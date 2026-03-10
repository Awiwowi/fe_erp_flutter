import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class PayablePaymentsPage extends StatefulWidget {
  const PayablePaymentsPage({super.key});

  @override
  State<PayablePaymentsPage> createState() => _PayablePaymentsPageState();
}

class _PayablePaymentsPageState extends State<PayablePaymentsPage> {
  List<dynamic> _payments = [];
  bool _isLoading = true;

  final currencyFormatter = NumberFormat.currency(
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
    var data = await DataService().getPayablePayments();
    if (mounted) {
      setState(() {
        _payments = data;
        _isLoading = false;
      });
    }
  }

  void _showAddDialog() async {
    setState(() => _isLoading = true);
    // Ambil data Hutang yang belum lunas dan Daftar COA
    List<dynamic> payables = await DataService().getUnpaidAccountPayables();
    List<dynamic> allCoas = await DataService().getChartOfAccounts();

    // Filter COA hanya yang tipe Asset (Kas / Bank) sesuai syarat backend
    List<dynamic> assetCoas = allCoas
        .where((coa) => coa['type'] == 'asset')
        .toList();

    if (!mounted) return;
    setState(() => _isLoading = false);

    showDialog(
      context: context,
      builder: (context) {
        return _PaymentFormDialog(
          payables: payables,
          assetCoas: assetCoas,
          onSuccess: _fetchData,
        );
      },
    );
  }

  void _confirmPayment(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Konfirmasi Pembayaran?"),
            content: const Text(
              "Aksi ini akan membuat jurnal otomatis dan merubah status hutang menjadi lunas. Yakin ingin melanjutkan?",
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
                  "Ya, Konfirmasi",
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
      bool success = await DataService().confirmPayablePayment(id);

      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Pembayaran Dikonfirmasi! Hutang Lunas."),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Gagal mengkonfirmasi pembayaran."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      "Riwayat Pembayaran Hutang",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _showAddDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text(
                      "Bayar Hutang",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _payments.isEmpty
                  ? const Center(child: Text("Belum ada riwayat pembayaran."))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey.shade100,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              "No. Pembayaran",
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
                              "Nominal",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Akun Kas/Bank",
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
                        rows: _payments.map((item) {
                          double amount =
                              double.tryParse(
                                item['amount']?.toString() ?? '0',
                              ) ??
                              0;
                          String status = item['status']?.toString() ?? 'draft';
                          bool isDraft = status == 'draft';

                          return DataRow(
                            cells: [
                              DataCell(Text(item['payment_number'] ?? '-')),
                              DataCell(
                                Text(
                                  item['payment_date']?.toString().split(
                                        ' ',
                                      )[0] ??
                                      '-',
                                ),
                              ),
                              DataCell(
                                Text(
                                  item['account_payable']?['supplier']?['nama'] ??
                                      '-',
                                ),
                              ), // Penyesuaian path supplier
                              DataCell(
                                Text(
                                  currencyFormatter.format(amount),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(item['payment_account']?['name'] ?? '-'),
                              ),
                              DataCell(
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: isDraft
                                        ? Colors.orange
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                isDraft
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _confirmPayment(item['id']),
                                        child: const Text(
                                          "Konfirmasi",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
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
    );
  }
}

// --- WIDGET DIALOG FORM PEMBAYARAN ---
class _PaymentFormDialog extends StatefulWidget {
  final List<dynamic> payables;
  final List<dynamic> assetCoas;
  final VoidCallback onSuccess;

  const _PaymentFormDialog({
    required this.payables,
    required this.assetCoas,
    required this.onSuccess,
  });

  @override
  State<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<_PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedPayableId;
  String? _selectedMethod = 'bank_transfer';
  int? _selectedAccountId;

  final TextEditingController _dateCtrl = TextEditingController(
    text: DateTime.now().toString().split(' ')[0],
  );
  final TextEditingController _refCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  // Controller Baru sesuai dokumen API
  final TextEditingController _bankNameCtrl = TextEditingController();
  final TextEditingController _accNumberCtrl = TextEditingController();

  bool _isSaving = false;

  final List<Map<String, String>> _methods = [
    {"val": "cash", "label": "Kas / Tunai"},
    {"val": "bank_transfer", "label": "Transfer Bank"},
    {"val": "credit_card", "label": "Kartu Kredit"},
    {"val": "giro_cek", "label": "Giro / Cek"},
  ];

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      Map<String, dynamic> payload = {
        "account_payable_id": _selectedPayableId,
        "payment_method": _selectedMethod,
        "payment_account_id": _selectedAccountId,
        "payment_date": _dateCtrl.text,
        "reference_number": _refCtrl.text,
        "notes": _notesCtrl.text,
      };

      // Tambahkan bank_name dan account_number jika metode BUKAN tunai
      if (_selectedMethod != 'cash') {
        payload["bank_name"] = _bankNameCtrl.text;
        payload["account_number"] = _accNumberCtrl.text;
      }

      final messenger = ScaffoldMessenger.of(context);
      bool success = await DataService().createPayablePayment(payload);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Draft Pembayaran Dibuat!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Gagal menyimpan pembayaran"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    // Cek apakah form butuh input detail bank
    bool requiresBankInfo = _selectedMethod != 'cash';

    return AlertDialog(
      title: const Text("Buat Pembayaran Hutang"),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Pilih Hutang (AP)
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Pilih Hutang (AP)",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedPayableId,
                  items: widget.payables.map((item) {
                    double amt =
                        double.tryParse(
                          item['remaining_amount']?.toString() ?? '0',
                        ) ??
                        0;
                    String supplier = item['supplier']?['nama'] ?? 'Unknown';
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text(
                        "${item['payable_number']} - $supplier (${currencyFormatter.format(amt)})",
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedPayableId = val),
                  validator: (val) => val == null ? "Wajib dipilih" : null,
                ),
                const SizedBox(height: 15),

                // 2. Pilih Akun Pembayar (Kas/Bank)
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "Bayar Dari Akun (Kas/Bank)",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedAccountId,
                  items: widget.assetCoas.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text("${item['code']} - ${item['name']}"),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedAccountId = val),
                  validator: (val) => val == null ? "Wajib dipilih" : null,
                ),
                const SizedBox(height: 15),

                // 3. Metode Pembayaran & Tanggal
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Metode Pembayaran",
                          border: OutlineInputBorder(),
                        ),
                        value: _selectedMethod,
                        items: _methods
                            .map(
                              (m) => DropdownMenuItem(
                                value: m['val'],
                                child: Text(m['label']!),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedMethod = val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _dateCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tanggal",
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            setState(
                              () => _dateCtrl.text = picked.toString().split(
                                ' ',
                              )[0],
                            );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // 4. Input Dinamis (Muncul jika metode BUKAN tunai)
                if (requiresBankInfo) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bankNameCtrl,
                          decoration: const InputDecoration(
                            labelText: "Nama Bank (BCA, Mandiri, dll)",
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) =>
                              val == null || val.isEmpty ? "Wajib diisi" : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _accNumberCtrl,
                          decoration: const InputDecoration(
                            labelText: "No. Rekening / CC",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],

                TextFormField(
                  controller: _refCtrl,
                  decoration: const InputDecoration(
                    labelText: "No. Referensi / Bukti Trf (Opsional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: "Catatan (Opsional)",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  "Simpan Draft",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

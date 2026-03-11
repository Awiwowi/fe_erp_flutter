import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class AccountPayablesPage extends StatefulWidget {
  const AccountPayablesPage({super.key});

  @override
  State<AccountPayablesPage> createState() => _AccountPayablesPageState();
}

class _AccountPayablesPageState extends State<AccountPayablesPage> {
  List<dynamic> _accountPayables = [];
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
    var data = await DataService().getAccountPayables();
    if (mounted) {
      setState(() {
        _accountPayables = data;
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'unpaid':
        return Colors.red.shade600;
      case 'partial':
        return Colors.blue.shade600;
      case 'paid':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  void _showCreateDialog() async {
    setState(() => _isLoading = true);

    // Ambil Data TTF dan COA secara bersamaan
    List<dynamic> approvedTTFs = await DataService()
        .getApprovedInvoiceReceipts();
    List<dynamic> allCOA = await DataService().getChartOfAccounts();

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Filter COA berdasarkan tipenya
    List<dynamic> liabilityAccounts = allCOA
        .where((acc) => acc['type'] == 'liability')
        .toList();
    // Asset biasanya untuk inventory/persediaan, atau bisa juga expense
    List<dynamic> assetAccounts = allCOA
        .where((acc) => acc['type'] == 'asset' || acc['type'] == 'expense')
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _CreateAPDialog(
          approvedTTFs: approvedTTFs,
          liabilityAccounts: liabilityAccounts,
          assetAccounts: assetAccounts,
          onSuccess: _fetchData,
        );
      },
    );
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daftar Hutang Usaha (Account Payable)",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "Catatan hutang pembelian ke supplier berdasarkan TTF",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _fetchData,
                    tooltip: 'Refresh Data',
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _showCreateDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  "Catat Hutang (Dari TTF)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _accountPayables.isEmpty
                  ? const Center(child: Text("Belum ada data hutang usaha."))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey.shade100,
                        ),
                        columns: const [
                          DataColumn(
                            label: Text(
                              "No. AP",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Jatuh Tempo",
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
                              "Total Hutang",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Sisa Bayar",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              "Status",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        rows: _accountPayables.map((item) {
                          double total =
                              double.tryParse(
                                item['total_amount']?.toString() ??
                                    item['amount']?.toString() ??
                                    '0',
                              ) ??
                              0;
                          double remaining =
                              double.tryParse(
                                item['remaining_amount']?.toString() ?? '0',
                              ) ??
                              0;
                          String status =
                              item['status']?.toString() ?? 'unpaid';
                          Color statusColor = _getStatusColor(status);

                          return DataRow(
                            cells: [
                              DataCell(Text(item['payable_number'] ?? '-')),
                              DataCell(
                                Text(
                                  item['due_date']?.toString().split(' ')[0] ??
                                      '-',
                                ),
                              ),
                              DataCell(Text(item['supplier']?['nama'] ?? '-')),
                              DataCell(Text(currencyFormatter.format(total))),
                              DataCell(
                                Text(
                                  currencyFormatter.format(remaining),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
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

// --- WIDGET DIALOG FORM PEMBUATAN AP ---
class _CreateAPDialog extends StatefulWidget {
  final List<dynamic> approvedTTFs;
  final List<dynamic> liabilityAccounts; // COA Tipe Hutang
  final List<dynamic> assetAccounts; // COA Tipe Aset/Persediaan
  final VoidCallback onSuccess;

  const _CreateAPDialog({
    required this.approvedTTFs,
    required this.liabilityAccounts,
    required this.assetAccounts,
    required this.onSuccess,
  });

  @override
  State<_CreateAPDialog> createState() => _CreateAPDialogState();
}

class _CreateAPDialogState extends State<_CreateAPDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedTtfId;
  int? _selectedLiabilityAccountId;
  int? _selectedAssetAccountId;
  bool _isSaving = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final messenger = ScaffoldMessenger.of(context);

      // Memanggil fungsi baru di DataService dengan 3 parameter
      bool success = await DataService().createAccountPayableFromTTF(
        _selectedTtfId!,
        _selectedLiabilityAccountId!,
        _selectedAssetAccountId!,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context); // Tutup dialog
        widget.onSuccess(); // Refresh tabel
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Hutang Usaha berhasil dicatat & Jurnal terbentuk!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Gagal mencatat hutang. Pastikan TTF belum dibuatkan AP.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Catat Hutang dari TTF",
        style: TextStyle(color: AppColors.primary),
      ),
      content: SizedBox(
        width: 500, // Sedikit dilebarkan karena ada tambahan input COA
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sistem akan otomatis membuat Jurnal Umum saat Hutang ini dicatat.",
                style: TextStyle(fontSize: 13, color: Colors.blue),
              ),
              const SizedBox(height: 20),

              if (widget.approvedTTFs.isEmpty)
                const Text(
                  "Tidak ada TTF berstatus Approved saat ini.",
                  style: TextStyle(color: Colors.red),
                )
              else
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "1. Pilih Tanda Terima Faktur (TTF)",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTtfId,
                  items: widget.approvedTTFs.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text(
                        "${item['receipt_number']} - ${item['purchase_order']?['supplier']?['nama'] ?? 'Supplier'}",
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedTtfId = val),
                  validator: (val) => val == null ? "Wajib dipilih" : null,
                ),

              const SizedBox(height: 15),

              if (widget.assetAccounts.isEmpty)
                const Text(
                  "Peringatan: Tidak ada COA Asset/Expense ditemukan. Harap buat di menu COA.",
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                )
              else
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "2. Akun Debit (Aset / Persediaan)",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedAssetAccountId,
                  items: widget.assetAccounts.map((coa) {
                    return DropdownMenuItem<int>(
                      value: coa['id'],
                      child: Text("${coa['code']} - ${coa['name']}"),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedAssetAccountId = val),
                  validator: (val) =>
                      val == null ? "Akun Debit wajib dipilih" : null,
                ),

              const SizedBox(height: 15),

              if (widget.liabilityAccounts.isEmpty)
                const Text(
                  "Peringatan: Tidak ada COA Liability (Hutang) ditemukan. Harap buat di menu COA.",
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                )
              else
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: "3. Akun Kredit (Utang Usaha / Kewajiban)",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedLiabilityAccountId,
                  items: widget.liabilityAccounts.map((coa) {
                    return DropdownMenuItem<int>(
                      value: coa['id'],
                      child: Text("${coa['code']} - ${coa['name']}"),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedLiabilityAccountId = val),
                  validator: (val) =>
                      val == null ? "Akun Kredit wajib dipilih" : null,
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: (_isSaving || widget.approvedTTFs.isEmpty)
              ? null
              : _submit,
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
                  "Catat Hutang & Jurnal",
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class AccountingReportsPage extends StatefulWidget {
  const AccountingReportsPage({super.key});

  @override
  State<AccountingReportsPage> createState() => _AccountingReportsPageState();
}

class _AccountingReportsPageState extends State<AccountingReportsPage> {
  // State Jurnal Umum
  List<dynamic> _journals = [];
  bool _isLoadingJournals = true;

  // State Buku Besar
  List<dynamic> _coas = [];
  List<dynamic> _ledgerData = [];
  bool _isLoadingLedgerForm = true;
  bool _isSearchingLedger = false;
  int? _selectedAccountId;

  final TextEditingController _startCtrl = TextEditingController(
    text: DateTime(
      DateTime.now().year,
      DateTime.now().month,
      1,
    ).toString().split(' ')[0],
  );
  final TextEditingController _endCtrl = TextEditingController(
    text: DateTime.now().toString().split(' ')[0],
  );

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchJournals();
    _fetchCoasForLedger();
  }

  // --- FUNGSI JURNAL UMUM ---
  void _fetchJournals() async {
    setState(() => _isLoadingJournals = true);
    var data = await DataService().getJournalEntries();
    if (mounted) {
      setState(() {
        _journals = data;
        _isLoadingJournals = false;
      });
    }
  }

  void _showJournalDetail(Map<String, dynamic> journal) {
    List<dynamic> lines = journal['lines'] ?? [];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Detail Jurnal: ${journal['reference_number'] ?? '-'}"),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Tanggal: ${journal['date']?.toString().split(' ')[0] ?? '-'}",
                  ),
                  Text("Keterangan: ${journal['description'] ?? '-'}"),
                  const SizedBox(height: 15),
                  DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text("Akun")),
                      DataColumn(label: Text("Debit")),
                      DataColumn(label: Text("Kredit")),
                    ],
                    rows: lines.map((line) {
                      double debit =
                          double.tryParse(line['debit']?.toString() ?? '0') ??
                          0;
                      double credit =
                          double.tryParse(line['credit']?.toString() ?? '0') ??
                          0;
                      String accName = line['account']?['name'] ?? '-';
                      String accCode = line['account']?['code'] ?? '';
                      return DataRow(
                        cells: [
                          DataCell(Text("$accCode - $accName")),
                          DataCell(
                            Text(
                              debit > 0 ? currencyFormatter.format(debit) : '-',
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                          DataCell(
                            Text(
                              credit > 0
                                  ? currencyFormatter.format(credit)
                                  : '-',
                              style: const TextStyle(color: Colors.green),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }

  // --- FUNGSI BUKU BESAR ---
  void _fetchCoasForLedger() async {
    var coas = await DataService().getChartOfAccounts();
    if (mounted) {
      setState(() {
        _coas = coas;
        _isLoadingLedgerForm = false;
      });
    }
  }

  void _filterLedger() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Akun terlebih dahulu!")),
      );
      return;
    }
    setState(() => _isSearchingLedger = true);
    var data = await DataService().getLedgerReport(
      _selectedAccountId!,
      _startCtrl.text,
      _endCtrl.text,
    );
    if (mounted) {
      setState(() {
        _ledgerData = data;
        _isSearchingLedger = false;
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null)
      setState(() => controller.text = picked.toString().split(' ')[0]);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 Tabs
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            "Laporan Akuntansi",
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColors.primary),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(icon: Icon(Icons.book), text: "Jurnal Umum"),
              Tab(icon: Icon(Icons.account_balance), text: "Buku Besar"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // =========================
            // TAB 1: JURNAL UMUM
            // =========================
            SingleChildScrollView(
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
                        const Text(
                          "Riwayat Jurnal Umum",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primary,
                          ),
                          onPressed: _fetchJournals,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _isLoadingJournals
                        ? const Center(child: CircularProgressIndicator())
                        : _journals.isEmpty
                        ? const Center(child: Text("Belum ada data jurnal."))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey.shade50,
                              ),
                              columns: const [
                                DataColumn(label: Text("Tanggal")),
                                DataColumn(label: Text("No. Referensi")),
                                DataColumn(label: Text("Keterangan")),
                                DataColumn(label: Text("Aksi")),
                              ],
                              rows: _journals.map((item) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        item['date']?.toString().split(
                                              ' ',
                                            )[0] ??
                                            '-',
                                      ),
                                    ),
                                    DataCell(
                                      Text(item['reference_number'] ?? '-'),
                                    ),
                                    DataCell(Text(item['description'] ?? '-')),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Colors.blue,
                                        ),
                                        tooltip: "Lihat Baris Jurnal",
                                        onPressed: () =>
                                            _showJournalDetail(item),
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

            // =========================
            // TAB 2: BUKU BESAR
            // =========================
            SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Filter Buku Besar",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (_isLoadingLedgerForm)
                          const CircularProgressIndicator()
                        else
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: "Pilih Akun",
                                    border: OutlineInputBorder(),
                                  ),
                                  value: _selectedAccountId,
                                  items: _coas
                                      .map(
                                        (item) => DropdownMenuItem<int>(
                                          value: item['id'],
                                          child: Text(
                                            "${item['code']} - ${item['name']}",
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedAccountId = val),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _startCtrl,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: "Dari",
                                    border: OutlineInputBorder(),
                                  ),
                                  onTap: () => _selectDate(_startCtrl),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _endCtrl,
                                  readOnly: true,
                                  decoration: const InputDecoration(
                                    labelText: "Sampai",
                                    border: OutlineInputBorder(),
                                  ),
                                  onTap: () => _selectDate(_endCtrl),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 55,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                  ),
                                  onPressed: _isSearchingLedger
                                      ? null
                                      : _filterLedger,
                                  child: _isSearchingLedger
                                      ? const SizedBox(
                                          width: 15,
                                          height: 15,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          "Cari",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Rincian Transaksi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _isSearchingLedger
                            ? const Center(child: CircularProgressIndicator())
                            : _ledgerData.isEmpty
                            ? const Center(
                                child: Text(
                                  "Tidak ada transaksi / Silakan filter akun.",
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                    Colors.grey.shade50,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text("Tanggal")),
                                    DataColumn(label: Text("No Referensi")),
                                    DataColumn(label: Text("Keterangan")),
                                    DataColumn(label: Text("Debit (+)")),
                                    DataColumn(label: Text("Kredit (-)")),
                                  ],
                                  rows: _ledgerData.map((item) {
                                    final journal = item['journal_entry'] ?? {};
                                    double debit =
                                        double.tryParse(
                                          item['debit']?.toString() ?? '0',
                                        ) ??
                                        0;
                                    double credit =
                                        double.tryParse(
                                          item['credit']?.toString() ?? '0',
                                        ) ??
                                        0;
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            journal['date']?.toString().split(
                                                  ' ',
                                                )[0] ??
                                                '-',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            journal['reference_number'] ?? '-',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            item['description'] ??
                                                journal['description'] ??
                                                '-',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            debit > 0
                                                ? currencyFormatter.format(
                                                    debit,
                                                  )
                                                : '-',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            credit > 0
                                                ? currencyFormatter.format(
                                                    credit,
                                                  )
                                                : '-',
                                            style: const TextStyle(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

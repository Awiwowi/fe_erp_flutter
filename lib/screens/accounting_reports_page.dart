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
  // State Master
  List<dynamic> _coas = [];
  bool _isLoadingCoa = true;

  // Filter Tanggal (Digunakan bersama oleh kedua tab)
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

  // State Buku Besar (Tab 1)
  int? _selectedAccountId;
  bool _isSearchingLedger = false;
  Map<String, dynamic>? _ledgerResult; // Menampung 1 object full dari PHP

  // State Neraca Saldo (Tab 2)
  bool _isSearchingTrialBalance = false;
  Map<String, dynamic>? _trialBalanceResult; // Menampung 1 object full dari PHP

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _fetchCoas();
  }

  void _fetchCoas() async {
    var coas = await DataService().getChartOfAccounts();
    if (mounted) {
      setState(() {
        _coas = coas;
        _isLoadingCoa = false;
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
    if (picked != null) {
      setState(() => controller.text = picked.toString().split(' ')[0]);
    }
  }

  // --- AKSI GET BUKU BESAR ---
  void _filterLedger() async {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Akun COA terlebih dahulu!")),
      );
      return;
    }
    setState(() => _isSearchingLedger = true);
    var res = await DataService().getLedgerDetail(
      _selectedAccountId!,
      _startCtrl.text,
      _endCtrl.text,
    );
    if (mounted) {
      setState(() {
        _ledgerResult = res;
        _isSearchingLedger = false;
      });
    }
  }

  // --- AKSI GET NERACA SALDO ---
  void _filterTrialBalance() async {
    setState(() => _isSearchingTrialBalance = true);
    var res = await DataService().getTrialBalance(
      _startCtrl.text,
      _endCtrl.text,
    );
    if (mounted) {
      setState(() {
        _trialBalanceResult = res;
        _isSearchingTrialBalance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
              Tab(icon: Icon(Icons.book), text: "Buku Besar (Ledger)"),
              Tab(
                icon: Icon(Icons.account_balance),
                text: "Neraca Saldo (Trial Balance)",
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildLedgerTab(), _buildTrialBalanceTab()],
        ),
      ),
    );
  }

  // ==============================================================
  // WIDGET TAB 1: BUKU BESAR
  // ==============================================================
  Widget _buildLedgerTab() {
    List<dynamic> transactions = _ledgerResult?['transactions'] ?? [];
    Map<String, dynamic>? summary = _ledgerResult?['summary'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KOTAK FILTER (DIPERBAIKI) ---
          Container(
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
                const Text(
                  "Tarik Data Buku Besar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Pilih akun dan periode tanggal untuk melihat rincian transaksi.",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 25),

                if (_isLoadingCoa)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    // UBAH ROW MENJADI COLUMN AGAR BESAR
                    children: [
                      // 1. DROPDOWN PILIH AKUN
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<int>(
                          isExpanded: true,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ), // Ukuran teks dropdown
                          decoration: const InputDecoration(
                            labelText: "Pilih Akun",
                            labelStyle: TextStyle(fontSize: 16), // Ukuran label
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.account_balance),
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
                      const SizedBox(height: 20), // Spasi vertikal antar input
                      // 2. DARI TANGGAL
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _startCtrl,
                          readOnly: true,
                          style: const TextStyle(
                            fontSize: 16,
                          ), // Ukuran teks input
                          decoration: const InputDecoration(
                            labelText: "Dari Tanggal",
                            labelStyle: TextStyle(fontSize: 16), // Ukuran label
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.date_range),
                          ),
                          onTap: () => _selectDate(_startCtrl),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. SAMPAI TANGGAL
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          controller: _endCtrl,
                          readOnly: true,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            labelText: "Sampai Tanggal",
                            labelStyle: TextStyle(fontSize: 16),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.date_range_outlined),
                          ),
                          onTap: () => _selectDate(_endCtrl),
                        ),
                      ),
                      const SizedBox(height: 30), // Spasi besar sebelum tombol
                      // 4. TOMBOL TAMPILKAN (LEBAR PENUH)
                      SizedBox(
                        width: double.infinity,
                        height: 55, // Tombol lebih tinggi
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _isSearchingLedger ? null : _filterLedger,
                          label: _isSearchingLedger
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "TAMPILKAN BUKU BESAR",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- KOTAK HASIL BUKU BESAR ---
          if (_ledgerResult != null)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rincian Transaksi Akun: ${_ledgerResult!['account']['name']}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (summary != null)
                        Text(
                          "Saldo Akhir: ${currencyFormatter.format(double.tryParse(summary['saldo_akhir']?.toString() ?? '0'))}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  transactions.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              "Tidak ada transaksi pada periode ini.",
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade100,
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "Tanggal",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "No Jurnal",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Keterangan",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Debit (+)",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Kredit (-)",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Saldo Berjalan",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: transactions.map((item) {
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
                              double saldo =
                                  double.tryParse(
                                    item['saldo']?.toString() ?? '0',
                                  ) ??
                                  0;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item['journal_date']?.toString().split(
                                            ' ',
                                          )[0] ??
                                          '-',
                                    ),
                                  ),
                                  DataCell(Text(item['journal_number'] ?? '-')),
                                  DataCell(Text(item['description'] ?? '-')),
                                  DataCell(
                                    Text(
                                      debit > 0
                                          ? currencyFormatter.format(debit)
                                          : '-',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      credit > 0
                                          ? currencyFormatter.format(credit)
                                          : '-',
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      currencyFormatter.format(saldo),
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
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==============================================================
  // WIDGET TAB 2: NERACA SALDO (TRIAL BALANCE)
  // ==============================================================
  Widget _buildTrialBalanceTab() {
    Map<String, dynamic> byType = _trialBalanceResult?['by_type'] ?? {};
    double totalDebit =
        double.tryParse(
          _trialBalanceResult?['total_debit']?.toString() ?? '0',
        ) ??
        0;
    double totalCredit =
        double.tryParse(
          _trialBalanceResult?['total_credit']?.toString() ?? '0',
        ) ??
        0;
    bool isBalanced = _trialBalanceResult?['balanced'] ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KOTAK FILTER (DIPERBAIKI) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Column(
              // UBAH ROW MENJADI COLUMN
              children: [
                const Text(
                  "Tarik Neraca Saldo",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 25),
                Column(
                  children: [
                    // DARI TANGGAL
                    SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _startCtrl,
                        readOnly: true,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: "Dari Tanggal",
                          labelStyle: TextStyle(fontSize: 16),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        onTap: () => _selectDate(_startCtrl),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SAMPAI TANGGAL
                    SizedBox(
                      width: double.infinity,
                      child: TextFormField(
                        controller: _endCtrl,
                        readOnly: true,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          labelText: "Sampai Tanggal",
                          labelStyle: TextStyle(fontSize: 16),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.date_range_outlined),
                        ),
                        onTap: () => _selectDate(_endCtrl),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // TOMBOL (LEBAR PENUH)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _isSearchingTrialBalance
                            ? null
                            : _filterTrialBalance,
                        label: _isSearchingTrialBalance
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "TARIK NERACA SALDO",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- KOTAK HASIL NERACA SALDO ---
          if (_trialBalanceResult != null)
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Neraca Saldo (Trial Balance)",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isBalanced
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isBalanced ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          isBalanced ? "BALANCE ✓" : "TIDAK BALANCE ❌",
                          style: TextStyle(
                            color: isBalanced ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),

                  // LOOPING PER TIPE AKUN DARI PHP
                  ...byType.entries.map((entry) {
                    String typeName = entry.key.toUpperCase();
                    List<dynamic> accounts = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Golongan: $typeName",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              dataRowMinHeight: 35,
                              dataRowMaxHeight: 45,
                              headingRowColor: WidgetStateProperty.all(
                                Colors.grey.shade50,
                              ),
                              columns: const [
                                DataColumn(label: Text("Kode Akun")),
                                DataColumn(label: Text("Nama Akun")),
                                DataColumn(label: Text("Total Debit")),
                                DataColumn(label: Text("Total Kredit")),
                              ],
                              rows: accounts.map((acc) {
                                double d =
                                    double.tryParse(
                                      acc['total_debit']?.toString() ?? '0',
                                    ) ??
                                    0;
                                double c =
                                    double.tryParse(
                                      acc['total_credit']?.toString() ?? '0',
                                    ) ??
                                    0;
                                return DataRow(
                                  cells: [
                                    DataCell(Text(acc['code'] ?? '-')),
                                    DataCell(Text(acc['name'] ?? '-')),
                                    DataCell(
                                      Text(
                                        d > 0
                                            ? currencyFormatter.format(d)
                                            : '-',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        c > 0
                                            ? currencyFormatter.format(c)
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
                    );
                  }),

                  const Divider(height: 30, thickness: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        "TOTAL KESELURUHAN DEBIT: \n${currencyFormatter.format(totalDebit)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        "TOTAL KESELURUHAN KREDIT: \n${currencyFormatter.format(totalCredit)}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

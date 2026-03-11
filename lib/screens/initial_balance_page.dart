import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tambahkan untuk format mata uang jika diperlukan
import '../constants/colors.dart';
import '../services/data_service.dart';

class InitialBalancePage extends StatefulWidget {
  const InitialBalancePage({super.key});

  @override
  State<InitialBalancePage> createState() => _InitialBalancePageState();
}

class _InitialBalancePageState extends State<InitialBalancePage> {
  bool _isLoading = true;

  // Data Master
  List<dynamic> _accounts = [];
  List<dynamic> _balances = [];

  // State Form
  final TextEditingController _yearController = TextEditingController(
    text: DateTime.now().year.toString(),
  );
  List<Map<String, dynamic>> _inputItems = [];

  @override
  void initState() {
    super.initState();
    _addInputRow();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    try {
      var accounts = await DataService().getChartOfAccounts();
      var balances = await DataService().getInitialBalances();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        _balances = balances;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetch data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addInputRow() {
    setState(() {
      _inputItems.add({
        "account_id": null,
        "debit_ctrl": TextEditingController(text: "0"),
        "credit_ctrl": TextEditingController(text: "0"),
      });
    });
  }

  void _removeInputRow(int index) {
    if (_inputItems.length > 1) {
      setState(() => _inputItems.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimal harus ada 1 baris akun")),
      );
    }
  }

  void _submit() async {
    // 1. PERBAIKAN: Gunakan tryParse untuk mencegah crash jika user tidak sengaja mengetik huruf/simbol
    int? yearInput = int.tryParse(_yearController.text);
    if (yearInput == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tahun wajib diisi dengan angka valid!")),
      );
      return;
    }

    List<Map<String, dynamic>> itemsToSend = [];
    double totalDebit = 0;
    double totalCredit = 0;

    // 2. PERBAIKAN: Set untuk melacak agar tidak ada akun (COA) yang diinput 2x (Duplikat)
    Set<int> selectedAccounts = {};

    for (var item in _inputItems) {
      int? accId = item['account_id'];
      double debit = double.tryParse(item['debit_ctrl'].text) ?? 0;
      double credit = double.tryParse(item['credit_ctrl'].text) ?? 0;

      if (accId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ada baris akun yang belum dipilih!")),
        );
        return;
      }

      // Validasi Cegah Akun Duplikat
      if (selectedAccounts.contains(accId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Tidak boleh memilih akun (COA) yang sama lebih dari 1 kali!",
            ),
          ),
        );
        return;
      }
      selectedAccounts.add(accId);

      if (debit == 0 && credit == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Nominal Debit atau Kredit harus diisi (tidak boleh 0 semua)!",
            ),
          ),
        );
        return;
      }

      // 3. PERBAIKAN: Validasi akuntansi (1 Akun tidak boleh terisi Debit dan Kredit sekaligus)
      if (debit > 0 && credit > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Satu baris akun tidak boleh memiliki nilai Debit dan Kredit sekaligus!",
            ),
          ),
        );
        return;
      }

      totalDebit += debit;
      totalCredit += credit;

      itemsToSend.add({
        "account_id": accId,
        "debit": debit,
        "credit": credit,
        "budget": 0,
      });
    }

    // Validasi Balance
    if (totalDebit != totalCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Total Debit ($totalDebit) tidak sama dengan Kredit ($totalCredit)!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);

    bool success = await DataService().createInitialBalance({
      "year": yearInput, // Gunakan variabel yang sudah di-parse aman
      "items": itemsToSend,
    });

    if (!mounted) return;

    if (success) {
      _fetchData();
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Saldo Awal Berhasil Disimpan sebagai Draft!"),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _inputItems.clear();
        _addInputRow();
      });
    } else {
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal menyimpan saldo awal (Tahun mungkin sudah di-Approve).",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _approve(String year) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    bool success = await DataService().approveInitialBalance(year);
    if (success) {
      _fetchData();
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Berhasil di-approve!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Gagal approve."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Tambahkan Scaffold agar layout background abu-abu lebih rapi
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FORM INPUT SALDO AWAL ---
            Container(
              padding: const EdgeInsets.all(20),
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
                  const Text(
                    "Input Saldo Awal (COA)",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Pastikan total kolom Debit dan Kredit pada akhirnya seimbang (Balance).",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  if (_isLoading && _accounts.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INPUT TAHUN
                        SizedBox(
                          width:
                              double.infinity, // Buat full width agar responsif
                          child: TextField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Tahun Pembukuan",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          "Daftar Akun Saldo Awal:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // LIST BARIS AKUN (UBAH KE BENTUK KARTU VERTIKAL)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _inputItems.length,
                          itemBuilder: (ctx, index) {
                            var row = _inputItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 15),
                              elevation: 2,
                              color: Colors.white, // pastikan warna kartu putih
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Column(
                                  // UBAH ROW MENJADI COLUMN
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Akun ke-${index + 1}",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _removeInputRow(index),
                                          tooltip: "Hapus Akun Ini",
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    // 1. DROPDOWN PILIH AKUN
                                    DropdownButtonFormField<int>(
                                      value: row['account_id'],
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        labelText: "Pilih Akun COA *",
                                        border: OutlineInputBorder(),
                                      ),
                                      items: _accounts
                                          .map(
                                            (a) => DropdownMenuItem<int>(
                                              value: a['id'],
                                              child: Text(
                                                "${a['code']} - ${a['name']}",
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (val) => setState(
                                        () => row['account_id'] = val,
                                      ),
                                    ),
                                    const SizedBox(height: 15),

                                    // 2. DEBIT DAN KREDIT BISA SEJAJAR (JIKA LAYAR BESAR) ATAU VERTIKAL LAGI
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: row['debit_ctrl'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: "Nominal Debit",
                                              border: OutlineInputBorder(),
                                              prefixText: "Rp ",
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: TextField(
                                            controller: row['credit_ctrl'],
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              labelText: "Nominal Kredit",
                                              border: OutlineInputBorder(),
                                              prefixText: "Rp ",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: _addInputRow,
                            icon: const Icon(Icons.add_circle, size: 24),
                            label: const Text(
                              "Tambah Baris Akun",
                              style: TextStyle(fontSize: 16),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text(
                              "SIMPAN DRAFT SALDO AWAL",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- TABEL DATA RIWAYAT ---
            Container(
              padding: const EdgeInsets.all(20),
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
                  const Text(
                    "Riwayat Saldo Awal",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _balances.isEmpty
                      ? const Center(
                          child: Text("Belum ada data riwayat saldo awal."),
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
                                  "Tahun",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Akun",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Debit",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Kredit",
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
                            rows: _balances.map((item) {
                              bool isDraft = item['status'] == 'draft';
                              // Format mata uang untuk tabel
                              final formatCurrency = NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              );

                              return DataRow(
                                cells: [
                                  DataCell(Text(item['year'].toString())),
                                  DataCell(
                                    Text(item['account']?['name'] ?? '-'),
                                  ),
                                  DataCell(
                                    Text(
                                      formatCurrency.format(
                                        double.tryParse(
                                              item['debit'].toString(),
                                            ) ??
                                            0,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      formatCurrency.format(
                                        double.tryParse(
                                              item['credit'].toString(),
                                            ) ??
                                            0,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDraft
                                            ? Colors.orange.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item['status'].toString().toUpperCase(),
                                        style: TextStyle(
                                          color: isDraft
                                              ? Colors.orange.shade800
                                              : Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    isDraft
                                        ? ElevatedButton(
                                            onPressed: () => _approve(
                                              item['year'].toString(),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 0,
                                                  ),
                                            ),
                                            child: const Text(
                                              "Approve",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                        : const Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                "Approved",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

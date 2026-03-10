import 'package:flutter/material.dart';
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
      // Menggunakan fungsi getChartOfAccounts yang sudah ada di DataService Anda
      var accounts = await DataService().getChartOfAccounts();
      var balances = await DataService().getInitialBalances();

      if (!mounted) return;

      setState(() {
        _accounts = accounts;
        // Grouping data dari backend berdasarkan tahun agar mudah ditampilkan
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
    if (_yearController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tahun wajib diisi!")));
      return;
    }

    List<Map<String, dynamic>> itemsToSend = [];
    double totalDebit = 0;
    double totalCredit = 0;

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
      if (debit == 0 && credit == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Debit atau Kredit harus diisi!")),
        );
        return;
      }

      totalDebit += debit;
      totalCredit += credit;

      itemsToSend.add({
        "account_id": accId,
        "debit": debit,
        "credit": credit,
        "budget": 0, // Bisa disesuaikan jika ingin menginput budget
      });
    }

    // Validasi Balance di sisi Frontend sebelum dikirim
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
      "year": int.parse(_yearController.text),
      "items": itemsToSend,
    });

    if (!mounted) return;

    if (success) {
      _fetchData();
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Saldo Awal Berhasil Dibuat!"),
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
          content: Text("Gagal menyimpan saldo awal."),
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
    return SingleChildScrollView(
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
                BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Input Saldo Awal (COA)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        width: 200,
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

                      // LIST BARIS AKUN
                      const Text(
                        "Daftar Akun:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _inputItems.length,
                        itemBuilder: (ctx, index) {
                          var row = _inputItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<int>(
                                    value: row['account_id'],
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: "Pilih Akun",
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
                                    onChanged: (val) =>
                                        setState(() => row['account_id'] = val),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: row['debit_ctrl'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Debit",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: row['credit_ctrl'],
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Kredit",
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _removeInputRow(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      TextButton.icon(
                        onPressed: _addInputRow,
                        icon: const Icon(Icons.add),
                        label: const Text("Tambah Baris Akun"),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            "SIMPAN DRAFT",
                            style: TextStyle(
                              color: Colors.white,
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

          const SizedBox(height: 30),

          // --- TABEL DATA ---
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
                  "Riwayat Saldo Awal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _balances.isEmpty
                    ? const Center(child: Text("Belum ada data saldo awal."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            Colors.grey.shade100,
                          ),
                          columns: const [
                            DataColumn(label: Text("Tahun")),
                            DataColumn(label: Text("Akun")),
                            DataColumn(label: Text("Debit")),
                            DataColumn(label: Text("Kredit")),
                            DataColumn(label: Text("Status")),
                            DataColumn(label: Text("Aksi")),
                          ],
                          rows: _balances.map((item) {
                            bool isDraft = item['status'] == 'draft';
                            return DataRow(
                              cells: [
                                DataCell(Text(item['year'].toString())),
                                DataCell(Text(item['account']?['name'] ?? '-')),
                                DataCell(Text(item['debit'].toString())),
                                DataCell(Text(item['credit'].toString())),
                                DataCell(
                                  Text(
                                    item['status'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: isDraft
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  isDraft
                                      ? ElevatedButton(
                                          onPressed: () =>
                                              _approve(item['year'].toString()),
                                          child: const Text("Approve"),
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
        ],
      ),
    );
  }
}

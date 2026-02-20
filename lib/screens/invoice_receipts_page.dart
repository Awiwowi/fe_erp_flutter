import 'package:flutter/material.dart';
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

  // --- HELPER WARNA STATUS ---
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft': return Colors.grey.shade600;
      case 'submitted': return Colors.orange.shade600;
      case 'approved': return Colors.green.shade600;
      case 'rejected': return Colors.red.shade600;
      default: return Colors.blue.shade600;
    }
  }

  // --- AKSI STATUS (SUBMIT / APPROVE / REJECT) ---
  void _changeStatus(int id, String action, String actionName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Konfirmasi $actionName"),
        content: Text("Apakah Anda yakin ingin memproses data ini menjadi $actionName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya, Proses", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().actionInvoiceReceipt(id, action);
      if (success) {
        _fetchData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Status berhasil diubah menjadi $actionName")));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal mengubah status! Pastikan faktur tidak kosong.")));
      }
    }
  }

  // --- AKSI HAPUS ---
  void _deleteInvoice(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Data?"),
        content: const Text("Tanda terima faktur yang dihapus tidak dapat dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().deleteInvoiceReceipt(id);
      if (success) {
        _fetchData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data dihapus")));
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
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tanda Terima Faktur (Invoice Receipt)",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: _fetchData,
                        tooltip: "Refresh Data",
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () {
                          // TODO: Navigasi ke Halaman Form Create Invoice
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Form Tambah belum diimplementasi")));
                        },
                        icon: const Icon(Icons.add, color: Colors.white, size: 18),
                        label: const Text("Buat Baru", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 20),

              // TABEL DATA
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _invoices.isEmpty
                        ? const Center(child: Text("Belum ada data Tanda Terima Faktur."))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                                columns: const [
                                  DataColumn(label: Text("No. Dokumen", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Supplier", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Pemohon (Requester)", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Aksi", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _invoices.map((item) {
                                  // 1. Mengambil status
                                  String status = (item['status'] ?? 'draft').toString().toLowerCase();
                                  Color statusColor = _getStatusColor(status);

                                  // 2. Tanggal transaksi
                                  String tgl = item['transaction_date']?.toString().split('T')[0] ?? '-';

                                  // 3. AMBIL SUPPLIER (Sangat Aman / Null-Safe)
                                  String supplierName = '-';
                                  // Cek apakah key purchase_order atau purchaseOrder ada
                                  var po = item['purchase_order'] ?? item['purchaseOrder'];
                                  if (po != null && po is Map) {
                                    var supp = po['supplier'];
                                    if (supp != null && supp is Map) {
                                      supplierName = supp['name']?.toString() ?? '-';
                                    }
                                  }

                                  // 4. AMBIL REQUESTER (Pemohon)
                                  String requesterName = '-';
                                  if (item['requester'] != null && item['requester'] is Map) {
                                    requesterName = item['requester']['name']?.toString() ?? '-';
                                  }

                                  // 5. Kalkulasi Total Amount
                                  double totalAmount = 0;
                                  if (item['invoices'] != null && item['invoices'] is List) {
                                    for (var inv in item['invoices']) {
                                      totalAmount += double.tryParse(inv['amount']?.toString() ?? '0') ?? 0;
                                    }
                                  }

                                  return DataRow(cells: [
                                    DataCell(Text(item['receipt_number']?.toString() ?? '-')),
                                    DataCell(Text(tgl)),
                                    
                                    // Kolom Supplier Name
                                    DataCell(Text(
                                      supplierName, 
                                      style: const TextStyle(fontWeight: FontWeight.w600)
                                    )),

                                    // Kolom Requester Name
                                    DataCell(Text(requesterName)),
                                    
                                    // Kolom Total Amount
                                    DataCell(Text(
                                      "Rp ${totalAmount.toStringAsFixed(0)}", 
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)
                                    )),
                                    
                                    // Kolom Status
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: statusColor.withOpacity(0.5))
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    
                                    // Kolom Aksi
                                    DataCell(Row(
                                      children: [
                                        // Aksi Submit (Hanya jika Draft)
                                        if (status == 'draft')
                                          IconButton(
                                            icon: const Icon(Icons.send, color: Colors.blue, size: 20),
                                            tooltip: 'Submit',
                                            onPressed: () => _changeStatus(item['id'], 'submit', 'Submitted'),
                                          ),
                                        
                                        // Aksi Approve / Reject (Hanya jika Submitted)
                                        if (status == 'submitted') ...[
                                          IconButton(
                                            icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                            tooltip: 'Approve',
                                            onPressed: () => _changeStatus(item['id'], 'approve', 'Approved'),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel, color: Colors.orange, size: 20),
                                            tooltip: 'Reject',
                                            onPressed: () => _changeStatus(item['id'], 'reject', 'Rejected'),
                                          ),
                                        ],

                                        // Aksi Hapus (Hanya jika Draft atau Rejected)
                                        if (status == 'draft' || status == 'rejected')
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            tooltip: 'Hapus',
                                            onPressed: () => _deleteInvoice(item['id']),
                                          ),
                                      ],
                                    )),
                                  ]);
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
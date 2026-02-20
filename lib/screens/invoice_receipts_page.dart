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

  // --- FORM CREATE TANDA TERIMA ---
  void _showCreateDialog() async {
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    
    var allGRs = await DataService().getGoodsReceipts();
    var allUsers = await DataService().getUsers(); 
    
    if (!mounted) return;
    Navigator.pop(context); // Tutup loading

    var postedGRs = allGRs.where((gr) => gr['status'] == 'posted').toList();

    if (postedGRs.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tidak ada Penerimaan Barang (Goods Receipt) yang valid/posted")));
      return;
    }

    String? selectedGRId; 
    String? selectedPoId; 
    String? selectedRequesterId; 

    final invoiceNoCtrl = TextEditingController();
    final trxDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final invDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final dueDateCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0]);
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) { // Ubah nama variabel context agar tidak bentrok dengan context halaman
        return StatefulBuilder( 
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Buat Tanda Terima Faktur", style: TextStyle(color: AppColors.primary)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Pilih Penerimaan Barang (GR) *", border: OutlineInputBorder()),
                        value: selectedGRId,
                        isExpanded: true,
                        items: postedGRs.map((gr) {
                          String grNo = gr['receipt_number'] ?? '-';
                          String poNo = gr['po_reference'] ?? '-';
                          
                          String supp = '-';
                          var po = gr['purchase_order'];
                          if (po != null && po['supplier'] != null) {
                            supp = po['supplier']['nama'] ?? po['supplier']['name'] ?? '-';
                          }

                          return DropdownMenuItem<String>(
                            value: gr['id'].toString(),
                            child: Text("$grNo (PO: $poNo) - $supp", style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                            onTap: () {
                              if (gr['purchase_order_id'] != null) {
                                selectedPoId = gr['purchase_order_id'].toString();
                              }
                            },
                          );
                        }).toList(),
                        onChanged: (val) => setStateDialog(() => selectedGRId = val),
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Pemohon (Requester) *", border: OutlineInputBorder()),
                        value: selectedRequesterId,
                        isExpanded: true,
                        items: allUsers.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['id'].toString(),
                            child: Text(user['name'] ?? 'User ID: ${user['id']}', style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) => setStateDialog(() => selectedRequesterId = val),
                      ),
                      const SizedBox(height: 10),

                      TextField(controller: invoiceNoCtrl, decoration: const InputDecoration(labelText: "No. Faktur (Dari Supplier) *", border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: trxDateCtrl, decoration: const InputDecoration(labelText: "Tanggal Transaksi (YYYY-MM-DD)", border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: invDateCtrl, decoration: const InputDecoration(labelText: "Tanggal Faktur (YYYY-MM-DD)", border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: dueDateCtrl, decoration: const InputDecoration(labelText: "Tanggal Jatuh Tempo (YYYY-MM-DD)", border: OutlineInputBorder())),
                      const SizedBox(height: 10),
                      TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Catatan", border: OutlineInputBorder()), maxLines: 2),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    if (selectedPoId == null || selectedRequesterId == null || invoiceNoCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lengkapi Pilihan GR, Pemohon, dan No Faktur!")));
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

                    // PERBAIKAN ERROR: Simpan messenger sebelum Navigator.pop()
                    final messenger = ScaffoldMessenger.of(context);
                    
                    Navigator.pop(dialogContext); // Tutup dialog
                    setState(() => _isLoading = true);
                    
                    bool success = await DataService().createInvoiceReceipt(payload);
                    
                    // Pastikan widget halaman utama masih aktif (mounted) sebelum update state
                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      // Gunakan messenger yang sudah disimpan
                      messenger.showSnackBar(const SnackBar(content: Text("Berhasil membuat Tanda Terima (Draft)")));
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(const SnackBar(content: Text("Gagal membuat data. Cek format tanggal/input")));
                    }
                  },
                  child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
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

  // --- AKSI STATUS ---
  void _changeStatus(int id, String action, String actionName) async {
    bool confirm = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Konfirmasi $actionName"),
        content: Text("Apakah Anda yakin ingin memproses data ini menjadi $actionName?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Ya, Proses", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      bool success = await DataService().actionInvoiceReceipt(id, action);
      
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(SnackBar(content: Text("Status berhasil diubah menjadi $actionName")));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text("Gagal mengubah status!")));
      }
    }
  }

  // --- AKSI HAPUS ---
  void _deleteInvoice(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Hapus Data?"),
        content: const Text("Tanda terima faktur yang dihapus tidak dapat dikembalikan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Tanda Terima Faktur (Invoice Receipt)",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppColors.primary),
                        onPressed: _fetchData,
                        tooltip: "Refresh Data",
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text("Buat Baru", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                                  DataColumn(label: Text("Pemohon", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Total Amount", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text("Aksi", style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _invoices.map((item) {
                                  String status = (item['status'] ?? 'draft').toString().toLowerCase();
                                  Color statusColor = _getStatusColor(status);
                                  String tgl = item['transaction_date']?.toString().split('T')[0] ?? '-';

                                  String supplierName = '-';
                                  var po = item['purchase_order'] ?? item['purchaseOrder'];
                                  if (po != null && po is Map) {
                                    var supp = po['supplier'];
                                    if (supp != null && supp is Map) {
                                      supplierName = supp['nama'] ?? supp['name']?.toString() ?? '-';
                                    }
                                  }

                                  String requesterName = '-';
                                  if (item['requester'] != null && item['requester'] is Map) {
                                    requesterName = item['requester']['name']?.toString() ?? '-';
                                  }

                                  double totalAmount = 0;
                                  if (item['invoices'] != null && item['invoices'] is List) {
                                    for (var inv in item['invoices']) {
                                      totalAmount += double.tryParse(inv['amount']?.toString() ?? '0') ?? 0;
                                    }
                                  }

                                  return DataRow(cells: [
                                    DataCell(Text(item['receipt_number']?.toString() ?? '-')),
                                    DataCell(Text(tgl)),
                                    DataCell(Text(supplierName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(requesterName)),
                                    DataCell(Text("Rp ${totalAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.5))),
                                        child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    DataCell(Row(
                                      children: [
                                        if (status == 'draft')
                                          IconButton(icon: const Icon(Icons.send, color: Colors.blue, size: 20), tooltip: 'Submit', onPressed: () => _changeStatus(item['id'], 'submit', 'Submitted')),
                                        if (status == 'submitted') ...[
                                          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green, size: 20), tooltip: 'Approve', onPressed: () => _changeStatus(item['id'], 'approve', 'Approved')),
                                          IconButton(icon: const Icon(Icons.cancel, color: Colors.orange, size: 20), tooltip: 'Reject', onPressed: () => _changeStatus(item['id'], 'reject', 'Rejected')),
                                        ],
                                        if (status == 'draft' || status == 'rejected')
                                          IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), tooltip: 'Hapus', onPressed: () => _deleteInvoice(item['id'])),
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
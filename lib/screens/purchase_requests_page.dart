import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class PurchaseRequestsPage extends StatefulWidget {
  const PurchaseRequestsPage({super.key});

  @override
  State<PurchaseRequestsPage> createState() => _PurchaseRequestsPageState();
}

class _PurchaseRequestsPageState extends State<PurchaseRequestsPage> {
  bool _isLoading = true;
  List<dynamic> _requests = [];
  
  // Form Controller
  final TextEditingController _dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final TextEditingController _deptCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  
  // PERBAIKAN 1: Default value disesuaikan dengan salah satu enum di database (raw_materials/product)
  String _selectedType = 'raw_materials'; 

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var reqs = await DataService().getPurchaseRequests();
    
    if (!mounted) return;
    setState(() {
      _requests = reqs;
      _isLoading = false;
    });
  }

  // --- ACTIONS: SUBMIT / APPROVE / REJECT ---
  // (Bagian ini tidak berubah, disembunyikan agar ringkas)
  void _processAction(int id, String actionName, Function(int) apiCall) async {
    // ... code existing ...
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text("$actionName PR"),
        content: Text("Anda yakin ingin melakukan aksi '$actionName' pada PR ini?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: Text("Ya, $actionName", style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      
      bool success = await apiCall(id);
      
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(SnackBar(content: Text("Berhasil $actionName"), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(SnackBar(content: Text("Gagal $actionName"), backgroundColor: Colors.red));
      }
    }
  }

  // --- CRUD & FORM ---

  void _showFormDialog() {
    // Reset Form
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _deptCtrl.clear();
    _notesCtrl.clear();
    
    // PERBAIKAN 2: Reset ke value default yang valid
    _selectedType = 'raw_materials';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Buat Purchase Request"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "Tanggal Request", icon: Icon(Icons.calendar_today)),
                      onTap: () async {
                        DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if(p!=null) setStateDialog(() => _dateCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                      },
                    ),
                    const SizedBox(height: 10),
                    
                    // PERBAIKAN 3: Dropdown Item disesuaikan dengan Enum Backend
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(labelText: "Tipe"),
                      items: const [
                        DropdownMenuItem(value: 'raw_materials', child: Text('Raw Materials (Bahan Baku)')),
                        DropdownMenuItem(value: 'product', child: Text('Product (Produk Jadi)')),
                      ],
                      onChanged: (val) => setStateDialog(() => _selectedType = val!),
                    ),
                    
                    const SizedBox(height: 10),
                    TextField(controller: _deptCtrl, decoration: const InputDecoration(labelText: "Departemen")),
                    const SizedBox(height: 10),
                    TextField(controller: _notesCtrl, decoration: const InputDecoration(labelText: "Catatan")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    
                    // Data yang dikirim sekarang sesuai validasi Laravel: in:raw_materials,product
                    Map<String, dynamic> data = {
                      "request_date": _dateCtrl.text,
                      "type": _selectedType, 
                      "department": _deptCtrl.text,
                      "notes": _notesCtrl.text
                    };

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    
                    bool success = await DataService().createPurchaseRequest(data);
                    
                    if (!mounted) return;
                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(const SnackBar(content: Text("PR Berhasil Dibuat!"), backgroundColor: Colors.green));
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(const SnackBar(content: Text("Gagal membuat PR"), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("Simpan", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  // ... sisa kode delete dan build ...
  void _delete(int id) async {
     // ... (kode sama seperti sebelumnya) ...
     bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus PR"),
        content: const Text("Yakin ingin menghapus? (Hanya bisa saat Draft)"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Tidak")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if(confirm) {
      setState(() => _isLoading = true);
      bool success = await DataService().deletePurchaseRequest(id);
      if(success) _fetchData();
      else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus"), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildStatusBadge(String status) {
     // ... (kode sama seperti sebelumnya) ...
    Color color;
    switch (status.toLowerCase()) {
      case 'approved': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      case 'submitted': color = Colors.blue; break;
      default: color = Colors.orange; // draft
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Purchase Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Daftar permintaan pembelian", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showFormDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Buat PR Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _requests.isEmpty 
                ? const Center(child: Text("Belum ada data."))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text("Kode")),
                        DataColumn(label: Text("Tanggal")),
                        DataColumn(label: Text("Requester")), 
                        DataColumn(label: Text("Tipe")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Aksi")),
                      ],
                      rows: _requests.map((item) {
                        String status = (item['status'] ?? 'draft').toLowerCase();
                        
                        // Opsional: Format tampilan tipe agar lebih rapi (bukan raw string)
                        String typeDisplay = item['type'] ?? '-';
                        if(typeDisplay == 'raw_materials') typeDisplay = 'Raw Material';
                        if(typeDisplay == 'product') typeDisplay = 'Product';

                        return DataRow(cells: [
                          DataCell(Text(item['kode'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(item['request_date'] ?? '-')),
                          DataCell(Text(item['requester']?['name'] ?? '-')), 
                          DataCell(Text(typeDisplay)), // Tampilkan tipe yang sudah diformat
                          DataCell(_buildStatusBadge(status)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // STATUS: DRAFT -> Bisa Submit & Delete
                                if (status == 'draft') ...[
                                  IconButton(
                                    icon: const Icon(Icons.send, color: Colors.blue),
                                    tooltip: "Submit PR",
                                    onPressed: () => _processAction(item['id'], "Submit", DataService().submitPurchaseRequest),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Hapus PR",
                                    onPressed: () => _delete(item['id']),
                                  ),
                                ],

                                // STATUS: APPROVED -> Muncul Tombol Generate PO
                                if (status == 'approved') 
                                  IconButton(
                                    icon: const Icon(Icons.receipt_long, color: Colors.purple),
                                    tooltip: "Generate PO",
                                    onPressed: () async {
                                      bool confirm = await showDialog(
                                        context: context, 
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Generate PO"),
                                          content: const Text("Buat Purchase Order dari PR ini?"),
                                          actions: [
                                            TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
                                            TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya", style: TextStyle(fontWeight: FontWeight.bold))),
                                          ],
                                        )
                                      ) ?? false;

                                      if (confirm) {
                                        setState(() => _isLoading = true);
                                        bool success = await DataService().generatePOFromPR(item['id']);
                                        setState(() => _isLoading = false);

                                        if (success) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PO Berhasil Dibuat! Cek menu PO."), backgroundColor: Colors.green));
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal Generate (Mungkin PO sudah ada)."), backgroundColor: Colors.red));
                                        }
                                      }
                                    },
                                  ),

                                // STATUS: SUBMITTED -> Bisa Approve & Reject (Role Approver)
                                if (status == 'submitted') ...[
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    tooltip: "Approve",
                                    onPressed: () => _processAction(item['id'], "Approve", DataService().approvePurchaseRequest),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                    tooltip: "Reject",
                                    onPressed: () => _processAction(item['id'], "Reject", DataService().rejectPurchaseRequest),
                                  ),
                                ],

                                // STATUS: APPROVED/REJECTED -> View Only (bisa dikasih icon mata/info)
                                if (status == 'approved' || status == 'rejected')
                                  const Icon(Icons.lock_outline, color: Colors.grey, size: 20)
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
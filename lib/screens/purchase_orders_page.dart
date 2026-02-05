import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class PurchaseOrdersPage extends StatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  State<PurchaseOrdersPage> createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PurchaseOrdersPage> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  List<dynamic> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    
    try {
      var pos = await DataService().getPurchaseOrders();
      var sups = await DataService().getSuppliers(); 

      if (!mounted) return;
      setState(() {
        _orders = pos;
        _suppliers = sups;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // --- EDIT HEADER (Supplier, Date, Notes) ---
  void _editHeader(Map<String, dynamic> po) {
    if (po['status'] != 'draft') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hanya PO Draft yang bisa diedit!")));
      return;
    }

    final dateCtrl = TextEditingController(text: po['order_date'] ?? DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final notesCtrl = TextEditingController(text: po['notes'] ?? '');
    int? selectedSupplierId = po['supplier_id'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Edit Info PO"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedSupplierId,
                      decoration: const InputDecoration(labelText: "Supplier"),
                      // Pastikan key-nya 'nama' sesuai API
                      items: _suppliers.map((s) => DropdownMenuItem<int>(
                        value: s['id'], 
                        child: Text(s['nama'] ?? '-')
                      )).toList(),
                      onChanged: (val) => setStateDialog(() => selectedSupplierId = val),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "Tanggal Order", icon: Icon(Icons.calendar_today)),
                      onTap: () async {
                        DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                        if(p!=null) setStateDialog(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Catatan")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    // 1. Simpan Messenger sebelum async
                    final messenger = ScaffoldMessenger.of(context);

                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    
                    bool success = await DataService().updatePurchaseOrder(po['id'], {
                      "supplier_id": selectedSupplierId,
                      "order_date": dateCtrl.text,
                      "notes": notesCtrl.text
                    });

                    // 2. Cek mounted setelah await
                    if (!mounted) return;

                    // 3. Gunakan messenger yang sudah disimpan
                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(const SnackBar(content: Text("PO Updated!"), backgroundColor: Colors.green));
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(const SnackBar(content: Text("Gagal update PO"), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text("Simpan"),
                )
              ],
            );
          }
        );
      }
    );
  }

  // --- SET PRICE PER ITEM ---
  void _setPrice(int itemId, double currentPrice) {
    final priceCtrl = TextEditingController(text: currentPrice.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Set Harga Satuan"),
        content: TextField(
          controller: priceCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Harga (Rp)", prefixText: "Rp "),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              double? price = double.tryParse(priceCtrl.text);
              if (price == null || price < 0) return;

              // 1. Simpan Messenger
              final messenger = ScaffoldMessenger.of(context);

              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              
              bool success = await DataService().updatePOItemPrice(itemId, price);
              
              // 2. Cek mounted
              if (!mounted) return;

              // 3. Gunakan messenger
              if (success) {
                _fetchData();
                messenger.showSnackBar(const SnackBar(content: Text("Harga disimpan!"), backgroundColor: Colors.green));
              } else {
                setState(() => _isLoading = false);
                messenger.showSnackBar(const SnackBar(content: Text("Gagal simpan harga"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Simpan"),
          )
        ],
      )
    );
  }

  // --- ACTIONS: SUBMIT / RECEIVE ---
  void _processAction(int id, String action) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text("$action PO"),
        content: Text("Yakin ingin melakukan $action?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (confirm) {
      // 1. Simpan Messenger
      final messenger = ScaffoldMessenger.of(context);

      setState(() => _isLoading = true);
      bool success = false;
      if (action == "Submit") success = await DataService().submitPurchaseOrder(id);
      if (action == "Receive") success = await DataService().approvePurchaseOrder(id);

      // 2. Cek mounted
      if (!mounted) return;

      // 3. Gunakan messenger
      if (success) {
        _fetchData();
        messenger.showSnackBar(SnackBar(content: Text("Berhasil $action"), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(const SnackBar(content: Text("Gagal memproses"), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'received': color = Colors.green; break;
      case 'sent': color = Colors.blue; break;
      default: color = Colors.orange;
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
            const Text("Purchase Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Kelola pemesanan pembelian ke supplier", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),

            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _orders.isEmpty
                  ? const Center(child: Text("Belum ada data PO. Silakan Generate dari PR."))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _orders.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 15),
                      itemBuilder: (ctx, i) {
                        var po = _orders[i];
                        String status = po['status'] ?? 'draft';
                        List items = po['items'] ?? [];

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Card
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(po['kode'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 2),
                                        Text("Ref PR: ${po['purchase_request']?['kode'] ?? '-'}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                      ],
                                    ),
                                    _buildStatusBadge(status),
                                  ],
                                ),
                                const Divider(),
                                
                                // Info Supplier & Tanggal
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Gunakan ['nama'] karena backend SupplierController pakai 'nama'
                                    Text("Supplier: ${po['supplier']?['nama'] ?? 'Belum dipilih'}", style: TextStyle(fontWeight: FontWeight.bold, color: po['supplier'] == null ? Colors.red : Colors.black87)),
                                    Text(po['order_date'] ?? '-'),
                                  ],
                                ),
                                if (status == 'draft')
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () => _editHeader(po), 
                                      icon: const Icon(Icons.edit, size: 14), 
                                      label: const Text("Edit Info")
                                    ),
                                  ),
                                
                                const SizedBox(height: 10),
                                const Text("Items:", style: TextStyle(fontWeight: FontWeight.bold)),
                                
                                // List Items (Tabel Mini)
                                ...items.map((item) {
                                  // Mapping nama item manual
                                  String itemName = item['raw_material']?['name'] ?? item['product']?['name'] ?? 'Item #${item['id']}';
                                  
                                  double price = double.tryParse(item['price'].toString()) ?? 0;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Expanded(flex: 3, child: Text("- $itemName")),
                                        Expanded(flex: 1, child: Text("x${item['quantity']}")),
                                        Expanded(flex: 2, child: Text("Rp ${price.toStringAsFixed(0)}", textAlign: TextAlign.right)),
                                        // Tombol Edit Harga (Hanya Draft)
                                        if (status == 'draft')
                                          IconButton(
                                            icon: const Icon(Icons.edit_note, color: Colors.blue, size: 18),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _setPrice(item['id'], price),
                                          ),
                                      ],
                                    ),
                                  );
                                }),

                                // Actions
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (status == 'draft') ...[
                                      OutlinedButton.icon(
                                        // Hapus PO tidak butuh messenger khusus karena fetch ulang
                                        onPressed: () => DataService().deletePurchaseOrder(po['id']).then((_) => _fetchData()), 
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                        label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        onPressed: () => _processAction(po['id'], "Submit"),
                                        icon: const Icon(Icons.send, size: 16, color: Colors.white),
                                        label: const Text("Kirim ke Supplier", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                      ),
                                    ] else if (status == 'sent') ...[
                                      ElevatedButton.icon(
                                        onPressed: () => _processAction(po['id'], "Receive"),
                                        icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                                        label: const Text("Barang Diterima", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      ),
                                    ]
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ],
        ),
      ),
    );
  }
}
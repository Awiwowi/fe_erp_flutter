import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/data_service.dart';

class GoodsReceiptsPage extends StatefulWidget {
  const GoodsReceiptsPage({super.key});

  @override
  State<GoodsReceiptsPage> createState() => _GoodsReceiptsPageState();
}

class _GoodsReceiptsPageState extends State<GoodsReceiptsPage> {
  bool _isLoading = true;
  List<dynamic> _receipts = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _sentPurchaseOrders = []; // Hanya PO status 'sent'

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil data GR
      var grs = await DataService().getGoodsReceipts();
      
      // 2. Ambil data Gudang untuk dropdown
      var whs = await DataService().getWarehouses();

      // 3. Ambil PO, tapi filter hanya yang statusnya 'sent' (siap diterima)
      var allPos = await DataService().getPurchaseOrders();
      var sentPos = allPos.where((po) => po['status'] == 'sent').toList();

      if (!mounted) return;
      setState(() {
        _receipts = grs;
        _warehouses = whs;
        _sentPurchaseOrders = sentPos;
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- FORM CREATE GR (Pilih PO & Input Qty) ---
  void _showCreateDialog() {
    // Variabel form
    int? selectedPoId;
    int? selectedWarehouseId;
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final deliveryNoteCtrl = TextEditingController(); // Surat Jalan
    final vehicleCtrl = TextEditingController(); // Plat No
    final notesCtrl = TextEditingController();
    
    // List item sementara untuk input quantity
    List<Map<String, dynamic>> tempItems = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Terima Barang (Goods Receipt)"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Pilih PO (Hanya yang Sent)
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: "Pilih Purchase Order (Sent)"),
                        value: selectedPoId,
                        isExpanded: true,
                        items: _sentPurchaseOrders.map((po) {
                          return DropdownMenuItem<int>(
                            value: po['id'],
                            child: Text("${po['kode']} - ${po['supplier']?['nama']}", overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedPoId = val;
                            // Reset items saat ganti PO
                            tempItems = []; 
                            
                            // Cari data PO lengkap dari list yg sudah diload
                            var selectedPO = _sentPurchaseOrders.firstWhere((p) => p['id'] == val);
                            if (selectedPO['items'] != null) {
                              for (var item in selectedPO['items']) {
                                tempItems.add({
                                  'purchase_order_item_id': item['id'],
                                  'product_name': item['raw_material']?['name'] ?? item['product']?['name'],
                                  'unit_name': item['unit']?['name'] ?? '',
                                  'qty_ordered': double.tryParse(item['quantity'].toString()) ?? 0,
                                  'qty_received': double.tryParse(item['quantity'].toString()) ?? 0, // Default full
                                  'notes': '',
                                  'controller': TextEditingController(text: item['quantity'].toString()) // Controller untuk input
                                });
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),

                      // 2. Pilih Gudang
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(labelText: "Gudang Penerima"),
                        value: selectedWarehouseId,
                        items: _warehouses.map((w) => DropdownMenuItem<int>(
                          value: w['id'], child: Text(w['name'])
                        )).toList(),
                        onChanged: (val) => setStateDialog(() => selectedWarehouseId = val),
                      ),
                      const SizedBox(height: 10),

                      // 3. Info Tambahan
                      TextField(
                        controller: dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Tanggal Terima", icon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if(p!=null) setStateDialog(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                        },
                      ),
                      TextField(controller: deliveryNoteCtrl, decoration: const InputDecoration(labelText: "No. Surat Jalan")),
                      TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: "No. Kendaraan (Plat)")),
                      
                      const Divider(height: 30, thickness: 2),
                      const Text("Item Barang", style: TextStyle(fontWeight: FontWeight.bold)),
                      
                      // 4. List Items (Input Qty Received)
                      if (tempItems.isEmpty) 
                        const Padding(padding: EdgeInsets.all(10), child: Text("Pilih PO untuk memuat item", style: TextStyle(color: Colors.grey)))
                      else
                        ...tempItems.map((item) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['product_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text("Order: ${item['qty_ordered']} ${item['unit_name']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: item['controller'],
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            labelText: "Qty Diterima",
                                            isDense: true,
                                            border: OutlineInputBorder()
                                          ),
                                          onChanged: (val) {
                                            item['qty_received'] = double.tryParse(val) ?? 0;
                                          },
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedPoId == null || selectedWarehouseId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih PO dan Gudang!")));
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    // Susun payload sesuai backend
                    Map<String, dynamic> payload = {
                      "purchase_order_id": selectedPoId,
                      "warehouse_id": selectedWarehouseId,
                      "receipt_date": dateCtrl.text,
                      "delivery_note_number": deliveryNoteCtrl.text,
                      "vehicle_number": vehicleCtrl.text,
                      "type": "GOODS_RECEIPT",
                      "notes": notesCtrl.text,
                      "items": tempItems.map((item) => {
                        "purchase_order_item_id": item['purchase_order_item_id'],
                        "quantity_received": item['qty_received'],
                        "notes": item['notes']
                      }).toList()
                    };

                    bool success = await DataService().createGoodsReceipt(payload);

                    if (!mounted) return;
                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(const SnackBar(content: Text("Berhasil membuat Goods Receipt"), backgroundColor: Colors.green));
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(const SnackBar(content: Text("Gagal membuat GR"), backgroundColor: Colors.red));
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

  // --- ACTION: POST (FINALIZE) ---
  void _postGR(int id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Posting Penerimaan"),
        content: const Text("Stok akan bertambah dan data tidak bisa diedit lagi. Lanjutkan?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya, Posting", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      
      bool success = await DataService().postGoodsReceipt(id);
      
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(const SnackBar(content: Text("GR Berhasil Diposting!"), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(const SnackBar(content: Text("Gagal posting GR"), backgroundColor: Colors.red));
      }
    }
  }

  // --- ACTION: DELETE ---
  void _deleteGR(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus GR"),
        content: const Text("Yakin ingin menghapus data draft ini?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      setState(() => _isLoading = true);
      await DataService().deleteGoodsReceipt(id);
      _fetchData();
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'posted' ? Colors.green : Colors.orange;
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
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Penerimaan Barang", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text("Goods Receipt dari Supplier", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text("Buat Penerimaan", style: TextStyle(color: Colors.white, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                )
              ],
            ),
            const SizedBox(height: 20),

            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _receipts.isEmpty
                  ? const Center(child: Text("Belum ada data penerimaan."))
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _receipts.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 15),
                      itemBuilder: (ctx, i) {
                        var gr = _receipts[i];
                        String status = gr['status'] ?? 'draft';
                        List items = gr['items'] ?? [];
                        var po = gr['purchase_order'] ?? {};
                        var supplier = po['supplier'] ?? {};

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(gr['receipt_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          Text("Ref PO: ${gr['po_reference'] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    _buildStatusBadge(status),
                                  ],
                                ),
                                const Divider(),
                                
                                // Info Supplier & Gudang - Layout diperbaiki
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Supplier:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              const SizedBox(height: 2),
                                              Text(
                                                supplier['nama'] ?? '-', 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("Gudang:", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              const SizedBox(height: 2),
                                              Text(
                                                gr['warehouse']?['name'] ?? '-', 
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text("Tanggal: ", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        Text(gr['receipt_date'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                if (gr['delivery_note_number'] != null)
                                  Text("Surat Jalan: ${gr['delivery_note_number']}", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),

                                // List Items Mini
                                Container(
                                  margin: const EdgeInsets.only(top: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(5)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Barang Diterima:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(height: 5),
                                      ...items.map((item) {
                                        String name = item['raw_material']?['name'] ?? item['product']?['name'] ?? '-';
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(child: Text("- $name", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                                              Text("${item['quantity_received']} ${item['unit']?['name'] ?? ''}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ),

                                // Actions (Hanya Draft)
                                if (status == 'draft')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () => _deleteGR(gr['id']),
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                          label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton.icon(
                                          onPressed: () => _postGR(gr['id']),
                                          icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                                          label: const Text("Posting Stok", style: TextStyle(color: Colors.white)),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                        ),
                                      ],
                                    ),
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
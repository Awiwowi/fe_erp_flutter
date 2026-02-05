import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class StockTransferPage extends StatefulWidget {
  const StockTransferPage({super.key});

  @override
  State<StockTransferPage> createState() => _StockTransferPageState();
}

class _StockTransferPageState extends State<StockTransferPage> {
  bool _isLoading = true;
  List<dynamic> _transfers = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    try {
      var trf = await DataService().getStockTransfers();
      var wh = await DataService().getWarehouses();
      var prod = await DataService().getProducts();

      if (!mounted) return;
      setState(() {
        _transfers = trf;
        _warehouses = wh;
        _products = prod;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FORM INPUT TRANSFER ---
  void _showFormDialog() {
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final notesCtrl = TextEditingController();
    int? fromWhId;
    int? toWhId;
    
    // List Items
    List<Map<String, dynamic>> tempItems = [
      {"product_id": null, "qty_ctrl": TextEditingController(text: "0")}
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            void addRow() {
              setStateDialog(() {
                tempItems.add({"product_id": null, "qty_ctrl": TextEditingController(text: "0")});
              });
            }

            void removeRow(int idx) {
              if (tempItems.length > 1) setStateDialog(() => tempItems.removeAt(idx));
            }

            return AlertDialog(
              title: const Text("Buat Transfer Stok"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TANGGAL
                      TextField(
                        controller: dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Tanggal Transfer", icon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if(p!=null) setStateDialog(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                        },
                      ),
                      const SizedBox(height: 10),

                      // GUDANG ASAL
                      DropdownButtonFormField<int>(
                        value: fromWhId,
                        isExpanded: true, // Mencegah overflow text di dropdown
                        decoration: const InputDecoration(labelText: "Dari Gudang (Sumber)"),
                        items: _warehouses.map((w) => DropdownMenuItem<int>(
                          value: w['id'], 
                          child: Text(w['name'], overflow: TextOverflow.ellipsis)
                        )).toList(),
                        onChanged: (val) => setStateDialog(() => fromWhId = val),
                      ),
                      const SizedBox(height: 10),

                      // GUDANG TUJUAN
                      DropdownButtonFormField<int>(
                        value: toWhId,
                        isExpanded: true, // Mencegah overflow text di dropdown
                        decoration: const InputDecoration(labelText: "Ke Gudang (Tujuan)"),
                        items: _warehouses.map((w) => DropdownMenuItem<int>(
                          value: w['id'], 
                          child: Text(w['name'], overflow: TextOverflow.ellipsis),
                          enabled: w['id'] != fromWhId 
                        )).toList(),
                        onChanged: (val) => setStateDialog(() => toWhId = val),
                      ),
                      const SizedBox(height: 10),

                      TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Catatan")),
                      const SizedBox(height: 20),

                      const Align(alignment: Alignment.centerLeft, child: Text("Item Transfer:", style: TextStyle(fontWeight: FontWeight.bold))),
                      
                      // DYNAMIC ITEMS
                      ...tempItems.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var row = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: row['product_id'],
                                  isExpanded: true,
                                  decoration: const InputDecoration(hintText: "Pilih Produk", contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                                  items: _products.map((p) => DropdownMenuItem<int>(
                                    value: p['id'], 
                                    child: Text(p['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))
                                  )).toList(),
                                  onChanged: (val) => setStateDialog(() => row['product_id'] = val),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: row['qty_ctrl'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: "Qty", contentPadding: EdgeInsets.symmetric(horizontal: 5)),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => removeRow(idx))
                            ],
                          ),
                        );
                      }),
                      
                      TextButton.icon(onPressed: addRow, icon: const Icon(Icons.add), label: const Text("Tambah Item")),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    if (fromWhId == null || toWhId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Gudang Asal & Tujuan"))); return;
                    }
                    if (fromWhId == toWhId) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gudang Asal & Tujuan tidak boleh sama"))); return;
                    }

                    List<Map<String, dynamic>> itemsData = [];
                    for(var i in tempItems) {
                      double qty = double.tryParse(i['qty_ctrl'].text) ?? 0;
                      if(i['product_id'] != null && qty > 0) {
                        itemsData.add({
                          "product_id": i['product_id'],
                          "quantity": i['qty_ctrl'].text
                        });
                      }
                    }

                    if (itemsData.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimal 1 item valid"))); return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    bool success = await DataService().createStockTransfer({
                      "dari_warehouse_id": fromWhId,
                      "ke_warehouse_id": toWhId,
                      "transfer_date": dateCtrl.text,
                      "notes": notesCtrl.text,
                      "items": itemsData
                    });

                    if (!mounted) return;
                    setState(() => _isLoading = false);

                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(const SnackBar(content: Text("Draft Transfer Berhasil!"), backgroundColor: Colors.green));
                    } else {
                      messenger.showSnackBar(const SnackBar(content: Text("Gagal membuat transfer."), backgroundColor: Colors.red));
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

  // --- ACTIONS (APPROVE / EXECUTE / REJECT) ---
  void _process(int id, String action, Function(int) apiCall) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: Text("$action Transfer"),
        content: Text("Yakin ingin melakukan $action?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await apiCall(id);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        _fetchData();
        messenger.showSnackBar(SnackBar(content: Text("Berhasil $action"), backgroundColor: Colors.green));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text("Gagal memproses (Cek stok asal mungkin kurang)"), backgroundColor: Colors.red));
      }
    }
  }

  void _delete(int id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Transfer"),
        content: const Text("Yakin hapus draft ini?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if(confirm) {
      setState(() => _isLoading = true);
      await DataService().deleteStockTransfer(id);
      if(mounted) {
        _fetchData();
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'executed': color = Colors.green; break;
      case 'approved': color = Colors.blue; break;
      case 'rejected': color = Colors.red; break;
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
            const Text("Stock Transfer", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Pindahkan stok antar gudang", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showFormDialog,
                icon: const Icon(Icons.swap_horiz, color: Colors.white),
                label: const Text("Buat Transfer Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              : _transfers.isEmpty 
                ? const Center(child: Text("Belum ada data transfer."))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transfers.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      var item = _transfers[i];
                      String status = item['status'] ?? 'draft';
                      
                      // Handling nama relasi
                      String fromWh = item['from_warehouse']?['name'] ?? item['dari_warehouse']?['name'] ?? 'ID: ${item['dari_warehouse_id']}';
                      String toWh = item['to_warehouse']?['name'] ?? item['ke_warehouse']?['name'] ?? 'ID: ${item['ke_warehouse_id']}';

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HEADER ROW (Fixed with Expanded)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['kode'] ?? '-', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text("Tanggal: ${item['transfer_date'] ?? '-'}"),
                              const SizedBox(height: 5),
                              
                              // WAREHOUSE ROW (Fixed with Expanded)
                              Row(
                                children: [
                                  const Icon(Icons.store, size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      fromWh, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Padding(padding: EdgeInsets.symmetric(horizontal: 5), child: Icon(Icons.arrow_forward, size: 16)),
                                  const Icon(Icons.store, size: 16, color: Colors.grey),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      toWh, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const Divider(),
                              
                              // ACTIONS
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (status == 'draft') ...[
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red), 
                                      onPressed: () => _delete(item['id']),
                                      tooltip: "Hapus Draft",
                                    ),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                                      label: const Text("Approve", style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                      onPressed: () => _process(item['id'], "Approve", DataService().approveStockTransfer),
                                    ),
                                  ] else if (status == 'approved') ...[
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.send_to_mobile, size: 16, color: Colors.white),
                                      label: const Text("Execute", style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      onPressed: () => _process(item['id'], "Execute", DataService().executeStockTransfer),
                                    ),
                                  ] else
                                    const Text("Selesai / Ditutup", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
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
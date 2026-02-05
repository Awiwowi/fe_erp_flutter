import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class RawMaterialStockInPage extends StatefulWidget {
  const RawMaterialStockInPage({super.key});

  @override
  State<RawMaterialStockInPage> createState() => _RawMaterialStockInPageState();
}

class _RawMaterialStockInPageState extends State<RawMaterialStockInPage> {
  bool _isLoading = true;
  List<dynamic> _stockIns = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _rawMaterials = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    try {
      var resStock = await DataService().getRawMaterialStockIn();
      var resWh = await DataService().getWarehouses();
      var resRm = await DataService().getRawMaterials();

      if (!mounted) return;
      setState(() {
        _stockIns = resStock;
        _warehouses = resWh;
        _rawMaterials = resRm;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // --- FORM DIALOG (CREATE DRAFT) ---
  void _showFormDialog() {
    // Controllers & State
    final TextEditingController dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    int? selectedWarehouseId;
    
    // List Item Sementara
    List<Map<String, dynamic>> tempItems = [
      {"raw_material_id": null, "qty_ctrl": TextEditingController(text: "0")}
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            // Helper add row
            void addRow() {
              setStateDialog(() {
                tempItems.add({"raw_material_id": null, "qty_ctrl": TextEditingController(text: "0")});
              });
            }

            // Helper remove row
            void removeRow(int idx) {
              if (tempItems.length > 1) {
                setStateDialog(() => tempItems.removeAt(idx));
              }
            }

            return AlertDialog(
              title: const Text("Input Barang Masuk"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Tanggal
                      TextField(
                        controller: dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Tanggal Masuk", icon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if(p!=null) setStateDialog(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                        },
                      ),
                      const SizedBox(height: 10),

                      // 2. Gudang
                      DropdownButtonFormField<int>(
                        value: selectedWarehouseId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Pilih Gudang", icon: Icon(Icons.warehouse)),
                        items: _warehouses.map((w) => DropdownMenuItem<int>(value: w['id'], child: Text(w['name']))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedWarehouseId = val),
                      ),
                      const SizedBox(height: 20),

                      const Align(alignment: Alignment.centerLeft, child: Text("Daftar Item:", style: TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 5),

                      // 3. Dynamic Items List
                      ...tempItems.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var row = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              // Dropdown Raw Material
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: row['raw_material_id'],
                                  isExpanded: true,
                                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10), hintText: "Pilih Bahan"),
                                  items: _rawMaterials.map((rm) => DropdownMenuItem<int>(
                                    value: rm['id'], 
                                    child: Text("${rm['code']} - ${rm['name']}", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
                                  )).toList(),
                                  onChanged: (val) => setStateDialog(() => row['raw_material_id'] = val),
                                ),
                              ),
                              const SizedBox(width: 5),
                              // Input Qty
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: row['qty_ctrl'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: "Qty", contentPadding: EdgeInsets.symmetric(horizontal: 5)),
                                ),
                              ),
                              // Remove Icon
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () => removeRow(idx),
                              )
                            ],
                          ),
                        );
                      }),

                      TextButton.icon(onPressed: addRow, icon: const Icon(Icons.add), label: const Text("Tambah Item Lain")),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    // Validasi
                    if (selectedWarehouseId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Gudang terlebih dahulu!")));
                      return;
                    }

                    // Prepare Data
                    List<Map<String, dynamic>> itemsToSend = [];
                    for (var row in tempItems) {
                      int? rmId = row['raw_material_id'];
                      double qty = double.tryParse(row['qty_ctrl'].text) ?? 0;
                      
                      if (rmId == null || qty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data item tidak lengkap atau Qty 0")));
                        return;
                      }
                      itemsToSend.add({
                        "raw_material_id": rmId,
                        "quantity": qty
                      });
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    Map<String, dynamic> data = {
                      "stock_in_date": dateCtrl.text,
                      "warehouse_id": selectedWarehouseId,
                      "items": itemsToSend
                    };

                    bool success = await DataService().createRawMaterialStockIn(data);

                    if (!mounted) return;
                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(const SnackBar(content: Text("Draft Berhasil Dibuat!"), backgroundColor: Colors.green));
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(const SnackBar(content: Text("Gagal membuat draft."), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text("Simpan Draft", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  // --- ACTION: POSTING (Finalize) ---
  void _postDocument(int id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Posting Dokumen"),
        content: const Text("Stok akan bertambah dan dokumen tidak bisa diubah lagi. Lanjutkan?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya, Posting", style: TextStyle(color: Colors.blue))),
        ],
      )
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().postRawMaterialStockIn(id);
      
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(const SnackBar(content: Text("Berhasil Diposting! Stok Bertambah."), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(const SnackBar(content: Text("Gagal Posting."), backgroundColor: Colors.red));
      }
    }
  }

  // --- ACTION: DELETE ---
  void _deleteDocument(int id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Dokumen"),
        content: const Text("Yakin ingin menghapus dokumen draft ini?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().deleteRawMaterialStockIn(id);
      
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(const SnackBar(content: Text("Berhasil dihapus"), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(const SnackBar(content: Text("Gagal menghapus"), backgroundColor: Colors.red));
      }
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
            const Text("Raw Material Stock In", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Penerimaan barang masuk (Bahan Baku)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),

            // Tombol Add
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showFormDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Input Barang Masuk", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
                ),
              ),
            ),
            const SizedBox(height: 20),

            // LIST VIEW (KARTU)
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _stockIns.isEmpty 
                ? const Center(child: Text("Belum ada data."))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stockIns.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      var item = _stockIns[i];
                      String status = item['status'] ?? 'draft';
                      List items = item['items'] ?? [];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header Kartu
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['stock_in_number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  _buildStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text("Tanggal: ${item['stock_in_date'] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text("Gudang: ${item['warehouse']?['name'] ?? '-'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              
                              const Divider(height: 20),
                              const Text("Daftar Barang:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 5),

                              // LIST ITEM DI DALAM KARTU
                              ...items.map((it) {
                                String name = it['raw_material']?['name'] ?? 'Item #${it['raw_material_id']}';
                                String qty = it['quantity'].toString();
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("- $name", style: const TextStyle(fontSize: 13)),
                                      Text("Qty: $qty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                );
                              }),

                              const SizedBox(height: 10),
                              // Tombol Aksi
                              if (status == 'draft')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                      label: const Text("Hapus", style: TextStyle(color: Colors.red, fontSize: 12)),
                                      onPressed: () => _deleteDocument(item['id']),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check_circle, color: Colors.white, size: 16),
                                      label: const Text("Posting", style: TextStyle(color: Colors.white, fontSize: 12)),
                                      onPressed: () => _postDocument(item['id']),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                    ),
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({super.key});

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  bool _isLoading = true;
  List<dynamic> _adjustments = [];
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
      var adj = await DataService().getStockAdjustments();
      var wh = await DataService().getWarehouses();
      var prod = await DataService().getProducts();

      if (!mounted) return;
      setState(() {
        _adjustments = adj;
        _warehouses = wh;
        _products = prod;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FORM INPUT ADJUSTMENT ---
  void _showFormDialog() {
    final dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    int? selectedWarehouseId;
    
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
              title: const Text("Buat Penyesuaian Stok"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Tanggal", icon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if(p!=null) setStateDialog(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: selectedWarehouseId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Pilih Gudang", icon: Icon(Icons.warehouse)),
                        items: _warehouses.map((w) => DropdownMenuItem<int>(
                          value: w['id'], 
                          child: Text(w['name'], overflow: TextOverflow.ellipsis)
                        )).toList(),
                        onChanged: (val) => setStateDialog(() => selectedWarehouseId = val),
                      ),
                      const SizedBox(height: 10),
                      TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Alasan (Opsional)")),
                      const SizedBox(height: 10),
                      TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Catatan")),
                      
                      const SizedBox(height: 20),
                      const Align(alignment: Alignment.centerLeft, child: Text("Input Stok Fisik (Actual):", style: TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 5),

                      // Dynamic Items (Safe Row)
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
                                  decoration: const InputDecoration(hintText: "Produk", contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                                  items: _products.map((p) => DropdownMenuItem<int>(
                                    value: p['id'], 
                                    child: Text(p['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))
                                  )).toList(),
                                  onChanged: (val) => setStateDialog(() => row['product_id'] = val),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: row['qty_ctrl'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: "Fisik", suffixText: "Qty", contentPadding: EdgeInsets.symmetric(horizontal: 5)),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle, color: Colors.red), 
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => removeRow(idx)
                              )
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
                    if (selectedWarehouseId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Gudang!"))); return;
                    }

                    List<Map<String, dynamic>> itemsData = [];
                    for(var i in tempItems) {
                      double qty = double.tryParse(i['qty_ctrl'].text) ?? -1;
                      if(i['product_id'] != null && qty >= 0) {
                        itemsData.add({
                          "product_id": i['product_id'],
                          "actual_qty": qty
                        });
                      }
                    }

                    if (itemsData.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi data produk & qty fisik dengan benar (>=0)"))); return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    bool success = await DataService().createStockAdjustment({
                      "adjustment_date": dateCtrl.text,
                      "warehouse_id": selectedWarehouseId,
                      "reason": reasonCtrl.text,
                      "notes": notesCtrl.text,
                      "items": itemsData
                    });

                    if (!mounted) return;
                    setState(() => _isLoading = false);

                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(const SnackBar(content: Text("Draft Adjustment Berhasil Dibuat!"), backgroundColor: Colors.green));
                    } else {
                      messenger.showSnackBar(const SnackBar(content: Text("Gagal membuat adjustment."), backgroundColor: Colors.red));
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

  // --- ACTIONS ---
  void _approve(int id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Posting Adjustment"),
        content: const Text("Stok di sistem akan diubah mengikuti jumlah fisik yang diinput. Lanjutkan?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya, Posting", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      )
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().approveStockAdjustment(id);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        _fetchData();
        messenger.showSnackBar(const SnackBar(content: Text("Berhasil Diposting! Stok Diupdate."), backgroundColor: Colors.green));
      } else {
        messenger.showSnackBar(const SnackBar(content: Text("Gagal memproses."), backgroundColor: Colors.red));
      }
    }
  }

  void _delete(int id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Data"),
        content: const Text("Yakin hapus draft ini?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if(confirm) {
      setState(() => _isLoading = true);
      await DataService().deleteStockAdjustment(id);
      if(mounted) {
        _fetchData();
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved' ? Colors.green : Colors.orange;
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
            const Text("Stock Adjustment", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Penyesuaian stok (Stock Opname)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showFormDialog,
                icon: const Icon(Icons.tune, color: Colors.white),
                label: const Text("Buat Penyesuaian Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              : _adjustments.isEmpty 
                ? const Center(child: Text("Belum ada data."))
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _adjustments.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      var item = _adjustments[i];
                      String status = item['status'] ?? 'draft';
                      List details = item['items'] ?? [];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HEADER ROW (DIPERBAIKI: Menggunakan Expanded)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Expanded agar teks panjang tidak overflow
                                  Expanded(
                                    child: Text(
                                      item['adjustment_number'] ?? '-', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text("Tanggal: ${item['adjustment_date'] ?? '-'}"),
                              Text("Gudang: ${item['warehouse']?['name'] ?? '-'}"),
                              if(item['reason'] != null) Text("Alasan: ${item['reason']}", style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                              
                              const Divider(),
                              const Text("Detail Item:", style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              
                              // DETAIL ITEMS (Juga menggunakan Expanded)
                              ...details.map((d) {
                                String prodName = d['product']?['name'] ?? 'ID:${d['product_id']}';
                                num sysQty = d['system_qty'] ?? 0;
                                num actQty = d['actual_qty'] ?? 0;
                                num diff = d['difference'] ?? 0;
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 4, 
                                        child: Text("- $prodName", overflow: TextOverflow.ellipsis, maxLines: 1)
                                      ),
                                      Expanded(
                                        flex: 3, 
                                        child: Text(" Sys:$sysQty / Act:$actQty", style: const TextStyle(fontSize: 11, color: Colors.grey))
                                      ),
                                      Expanded(
                                        flex: 2, 
                                        child: Text(
                                          "${diff > 0 ? '+' : ''}$diff", 
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 12,
                                            color: diff == 0 ? Colors.grey : (diff > 0 ? Colors.green : Colors.red)
                                          )
                                        )
                                      ),
                                    ],
                                  ),
                                );
                              }),

                              // ACTIONS
                              const SizedBox(height: 10),
                              if (status == 'draft')
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                                      label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                      onPressed: () => _delete(item['id']),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.check_circle, size: 16, color: Colors.white),
                                      label: const Text("Posting", style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                      onPressed: () => _approve(item['id']),
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
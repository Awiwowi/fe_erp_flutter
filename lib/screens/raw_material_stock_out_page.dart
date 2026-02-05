import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class RawMaterialStockOutPage extends StatefulWidget {
  const RawMaterialStockOutPage({super.key});

  @override
  State<RawMaterialStockOutPage> createState() => _RawMaterialStockOutPageState();
}

class _RawMaterialStockOutPageState extends State<RawMaterialStockOutPage> {
  bool _isLoading = true;
  List<dynamic> _stockOuts = [];
  List<dynamic> _warehouses = [];
  List<dynamic> _rawMaterials = [];
  List<dynamic> _units = []; // Kita butuh list unit

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    
    // Ambil semua data master yang diperlukan
    var resStock = await DataService().getRawMaterialStockOut();
    var resWh = await DataService().getWarehouses();
    var resRm = await DataService().getRawMaterials();
    var resUnit = await DataService().getUnits(); // Pastikan DataService punya getUnits()

    if (!mounted) return;
    setState(() {
      _stockOuts = resStock;
      _warehouses = resWh;
      _rawMaterials = resRm;
      _units = resUnit;
      _isLoading = false;
    });
  }

  // --- FORM DIALOG (CREATE DRAFT) ---
  void _showFormDialog() {
    final TextEditingController dateCtrl = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
    final TextEditingController notesCtrl = TextEditingController();
    int? selectedWarehouseId;
    
    // List Item Sementara
    List<Map<String, dynamic>> tempItems = [
      {
        "raw_material_id": null, 
        "unit_id": null, 
        "qty_ctrl": TextEditingController(text: "0")
      }
    ];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            
            void addRow() {
              setStateDialog(() {
                tempItems.add({
                  "raw_material_id": null, 
                  "unit_id": null, 
                  "qty_ctrl": TextEditingController(text: "0")
                });
              });
            }

            void removeRow(int idx) {
              if (tempItems.length > 1) {
                setStateDialog(() => tempItems.removeAt(idx));
              }
            }

            return AlertDialog(
              title: const Text("Input Pengeluaran Bahan Baku"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Header Info
                      TextField(
                        controller: dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(labelText: "Tanggal Keluar", icon: Icon(Icons.calendar_today)),
                        onTap: () async {
                          DateTime? p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if(p!=null) setStateDialog(() => dateCtrl.text = DateFormat('yyyy-MM-dd').format(p));
                        },
                      ),
                      const SizedBox(height: 10),

                      DropdownButtonFormField<int>(
                        value: selectedWarehouseId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Dari Gudang", icon: Icon(Icons.warehouse)),
                        items: _warehouses.map((w) => DropdownMenuItem<int>(value: w['id'], child: Text(w['name']))).toList(),
                        onChanged: (val) => setStateDialog(() => selectedWarehouseId = val),
                      ),
                      const SizedBox(height: 10),
                      
                      TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Catatan / Keterangan", icon: Icon(Icons.note))),
                      const SizedBox(height: 20),

                      const Align(alignment: Alignment.centerLeft, child: Text("Daftar Item:", style: TextStyle(fontWeight: FontWeight.bold))),
                      const SizedBox(height: 5),

                      // 2. Dynamic Items List
                      ...tempItems.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var row = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(5)),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Bahan Baku
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<int>(
                                      value: row['raw_material_id'],
                                      isExpanded: true,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 5), labelText: "Bahan"),
                                      items: _rawMaterials.map((rm) => DropdownMenuItem<int>(
                                        value: rm['id'], 
                                        child: Text("${rm['code']} - ${rm['name']}", overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
                                      )).toList(),
                                      onChanged: (val) => setStateDialog(() => row['raw_material_id'] = val),
                                    ),
                                  ),
                                  // Hapus
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                    onPressed: () => removeRow(idx),
                                  )
                                ],
                              ),
                              Row(
                                children: [
                                  // Satuan (Unit) - WAJIB DI Backend
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<int>(
                                      value: row['unit_id'],
                                      isExpanded: true,
                                      decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 5), labelText: "Satuan"),
                                      items: _units.map((u) => DropdownMenuItem<int>(
                                        value: u['id'], 
                                        child: Text(u['name'], overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
                                      )).toList(),
                                      onChanged: (val) => setStateDialog(() => row['unit_id'] = val),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Qty
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: row['qty_ctrl'],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(labelText: "Qty", contentPadding: EdgeInsets.symmetric(horizontal: 5)),
                                    ),
                                  ),
                                ],
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
                      int? unitId = row['unit_id'];
                      double qty = double.tryParse(row['qty_ctrl'].text) ?? 0;
                      
                      if (rmId == null || unitId == null || qty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data item tidak lengkap (Cek Bahan, Satuan, Qty)")));
                        return;
                      }
                      itemsToSend.add({
                        "raw_material_id": rmId,
                        "unit_id": unitId, // Backend butuh ini
                        "quantity": qty
                      });
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);

                    Map<String, dynamic> data = {
                      "issued_at": dateCtrl.text,
                      "warehouse_id": selectedWarehouseId,
                      "notes": notesCtrl.text,
                      "items": itemsToSend
                    };

                    bool success = await DataService().createRawMaterialStockOut(data);

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
        content: const Text("Stok di gudang akan berkurang. Pastikan stok mencukupi. Lanjutkan?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Ya, Posting", style: TextStyle(color: Colors.blue))),
        ],
      )
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().postRawMaterialStockOut(id);
      
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(const SnackBar(content: Text("Berhasil Diposting! Stok Berkurang."), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        // Error handling detail ada di debug console (misal stok kurang)
        messenger.showSnackBar(const SnackBar(content: Text("Gagal Posting. Cek stok gudang."), backgroundColor: Colors.red));
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
      setState(() => _isLoading = true);
      bool success = await DataService().deleteRawMaterialStockOut(id);
      
      if (!mounted) return;
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Berhasil dihapus"), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus"), backgroundColor: Colors.red));
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
            const Text("Raw Material Stock Out", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Pengeluaran bahan baku dari gudang", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),

            // Tombol Add
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showFormDialog,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Input Barang Keluar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tabel Data
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _stockOuts.isEmpty 
                ? const Center(child: Text("Belum ada data."))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                      columns: const [
                        DataColumn(label: Text("Tanggal")),
                        DataColumn(label: Text("Gudang")),
                        DataColumn(label: Text("Notes")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Aksi")),
                      ],
                      rows: _stockOuts.map((item) {
                        String status = item['status'] ?? 'draft';
                        return DataRow(cells: [
                          DataCell(Text(item['issued_at'] ?? '-')),
                          DataCell(Text(item['warehouse']?['name'] ?? '-')),
                          DataCell(Text(item['notes'] ?? '-')),
                          DataCell(_buildStatusBadge(status)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Tombol POSTING
                              if (status == 'draft')
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.blue),
                                  tooltip: "Posting",
                                  onPressed: () => _postDocument(item['id']),
                                ),
                              
                              // Tombol HAPUS
                              if (status == 'draft')
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: "Hapus Draft",
                                  onPressed: () => _deleteDocument(item['id']),
                                ),
                            ],
                          )),
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
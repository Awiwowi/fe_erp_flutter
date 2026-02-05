import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class PurchaseRequestItemsPage extends StatefulWidget {
  const PurchaseRequestItemsPage({super.key});

  @override
  State<PurchaseRequestItemsPage> createState() => _PurchaseRequestItemsPageState();
}

class _PurchaseRequestItemsPageState extends State<PurchaseRequestItemsPage> {
  bool _isLoading = false;
  
  // Data Master (Disimpan untuk lookup nama nanti)
  List<dynamic> _draftPRs = [];
  List<dynamic> _rawMaterials = [];
  List<dynamic> _products = [];
  List<dynamic> _units = [];

  // State Pilihan
  int? _selectedPRId;
  Map<String, dynamic>? _selectedPRDetail;

  @override
  void initState() {
    super.initState();
    _fetchMasterData();
  }

  void _fetchMasterData() async {
    setState(() => _isLoading = true);
    
    try {
      var allPRs = await DataService().getPurchaseRequests();
      var rms = await DataService().getRawMaterials();
      var prods = await DataService().getProducts();
      var us = await DataService().getUnits();

      if (!mounted) return;

      setState(() {
        // Filter hanya PR Draft
        _draftPRs = allPRs.where((pr) => pr['status'] == 'draft').toList();
        _rawMaterials = rms;
        _products = prods;
        _units = us;
        _isLoading = false;
      });
    } catch (e) {
      print("Error Fetch Master: $e");
      setState(() => _isLoading = false);
    }
  }

  void _loadPRDetail(int prId) async {
    setState(() => _isLoading = true);
    var detail = await DataService().getPurchaseRequestDetail(prId);
    
    if (!mounted) return;
    setState(() {
      _selectedPRDetail = detail;
      _isLoading = false;
    });
  }

  // --- FUNGSI PENTING: MENCARI NAMA BERDASARKAN ID (FIX MASALAH ANDA) ---
  String _getItemName(Map<String, dynamic> item) {
    // Cek Bahan Baku
    if (item['raw_material_id'] != null) {
      // Cari di list _rawMaterials yang sudah didownload
      var match = _rawMaterials.firstWhere(
        (m) => m['id'] == item['raw_material_id'], 
        orElse: () => null
      );
      return match != null ? "[Bahan] ${match['name']}" : "ID: ${item['raw_material_id']}";
    } 
    // Cek Produk
    else if (item['product_id'] != null) {
      // Cari di list _products
      var match = _products.firstWhere(
        (p) => p['id'] == item['product_id'], 
        orElse: () => null
      );
      return match != null ? "[Produk] ${match['name']}" : "ID: ${item['product_id']}";
    }
    return "-";
  }

  String _getUnitName(int? unitId) {
    if (unitId == null) return "-";
    // Cari di list _units
    var match = _units.firstWhere((u) => u['id'] == unitId, orElse: () => null);
    return match != null ? match['name'] : "ID: $unitId";
  }

  // --- FORM DIALOG ---
  void _showItemDialog({Map<String, dynamic>? item}) {
    bool isEdit = item != null;
    
    // Controllers
    final qtyCtrl = TextEditingController(text: item != null ? item['quantity'].toString() : '1');
    final notesCtrl = TextEditingController(text: item?['notes'] ?? '');
    
    // State Form
    String itemType = (item != null && item['product_id'] != null) ? 'product' : 'material';
    int? selectedMaterialId = item?['raw_material_id'];
    int? selectedProductId = item?['product_id'];
    int? selectedUnitId = item?['unit_id'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Item PR" : "Tambah Item ke PR"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilihan Tipe (Hanya Add)
                    if (!isEdit) ...[
                      const Text("Jenis Item:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Bahan Baku", style: TextStyle(fontSize: 12)),
                              value: 'material',
                              groupValue: itemType,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setStateDialog(() { 
                                itemType = val!; 
                                selectedProductId = null; 
                              }),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Produk Jadi", style: TextStyle(fontSize: 12)),
                              value: 'product',
                              groupValue: itemType,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (val) => setStateDialog(() { 
                                itemType = val!; 
                                selectedMaterialId = null; 
                              }),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Dropdown Barang
                    if (itemType == 'material')
                      DropdownButtonFormField<int>(
                        value: selectedMaterialId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Pilih Bahan Baku"),
                        items: _rawMaterials.map((m) => DropdownMenuItem<int>(
                          value: m['id'], 
                          child: Text("${m['code']} - ${m['name']}", overflow: TextOverflow.ellipsis)
                        )).toList(),
                        onChanged: isEdit ? null : (val) => setStateDialog(() => selectedMaterialId = val),
                      )
                    else
                      DropdownButtonFormField<int>(
                        value: selectedProductId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: "Pilih Produk"),
                        items: _products.map((p) => DropdownMenuItem<int>(
                          value: p['id'], 
                          child: Text("${p['code']} - ${p['name']}", overflow: TextOverflow.ellipsis)
                        )).toList(),
                        onChanged: isEdit ? null : (val) => setStateDialog(() => selectedProductId = val),
                      ),
                    
                    const SizedBox(height: 10),

                    // Unit
                    DropdownButtonFormField<int>(
                      value: selectedUnitId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: "Satuan (Unit)"),
                      items: _units.map((u) => DropdownMenuItem<int>(
                        value: u['id'], child: Text(u['name'])
                      )).toList(),
                      onChanged: (val) => setStateDialog(() => selectedUnitId = val),
                    ),
                    const SizedBox(height: 10),

                    // Qty
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Quantity"),
                    ),
                    const SizedBox(height: 10),

                    // Notes
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Catatan Item")),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () async {
                    // Validasi
                    if (itemType == 'material' && selectedMaterialId == null && !isEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Bahan Baku!"))); return;
                    }
                    if (itemType == 'product' && selectedProductId == null && !isEdit) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Produk!"))); return;
                    }
                    if (selectedUnitId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Satuan!"))); return;
                    }
                    if (qtyCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi Quantity!"))); return;
                    }

Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    bool success;

                    // --- 2. LOGIKA PERBAIKAN ---
                    
                    if (isEdit) {
                      // KASUS UPDATE: Backend hanya menerima quantity, notes, reference_no (Flat Object)
                      // Lihat Controller: public function update(Request $request, $id)
                      Map<String, dynamic> updateData = {
                        "quantity": qtyCtrl.text,
                        "notes": notesCtrl.text,
                        // "unit_id": selectedUnitId // Backend update tidak memproses unit_id, jadi user tidak bisa ganti unit saat edit
                      };
                      
                      success = await DataService().updatePurchaseRequestItem(item['id'], updateData);
                      
                    } else {
                      // KASUS ADD: Backend mewajibkan struktur nested array "items"
                      // Lihat Controller: 'items' => 'required|array|min:1'
                      
                      // A. Buat data item tunggal
                      Map<String, dynamic> singleItem = {
                        "unit_id": selectedUnitId,
                        "quantity": qtyCtrl.text,
                        "notes": notesCtrl.text,
                      };

                      if (itemType == 'material') {
                        singleItem["raw_material_id"] = selectedMaterialId;
                      } else {
                        singleItem["product_id"] = selectedProductId;
                      }

                      // B. Bungkus dalam struktur yang diminta Laravel
                      Map<String, dynamic> payload = {
                        "purchase_request_id": _selectedPRId, 
                        "items": [ singleItem ] // <-- BUNGKUS KE DALAM ARRAY
                      };

                      success = await DataService().addPurchaseRequestItem(payload);
                    }

                    // --- 3. HASIL (Tetap sama) ---
                    if (!mounted) return;
                    
                    if (success) {
                      _loadPRDetail(_selectedPRId!);
                      messenger.showSnackBar(SnackBar(content: Text(isEdit ? "Item Diupdate!" : "Item Ditambahkan!"), backgroundColor: Colors.green));
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(const SnackBar(content: Text("Gagal menyimpan item"), backgroundColor: Colors.red));
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

  void _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Item"),
        content: const Text("Yakin ingin menghapus item ini?"),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Batal")),
          TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      )
    ) ?? false;

    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().deletePurchaseRequestItem(id);
      
      if (!mounted) return;

      if (success) {
        _loadPRDetail(_selectedPRId!);
        messenger.showSnackBar(const SnackBar(content: Text("Item Dihapus"), backgroundColor: Colors.green));
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(const SnackBar(content: Text("Gagal menghapus"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List items = _selectedPRDetail != null ? (_selectedPRDetail!['items'] ?? []) : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("PR Items Manager", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Text("Kelola barang di dalam Purchase Request (Draft)", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),

            // PILIH PR
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100)
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pilih Purchase Request:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<int>(
                    value: _selectedPRId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      filled: true, 
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)
                    ),
                    hint: const Text("Pilih No. PR (Draft Only)"),
                    items: _draftPRs.map((pr) => DropdownMenuItem<int>(
                      value: pr['id'],
                      child: Text("${pr['kode']} - ${pr['request_date']}"),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPRId = val);
                        _loadPRDetail(val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // LIST ITEMS
            if (_selectedPRId == null)
              const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("Silakan pilih PR terlebih dahulu.")))
            else if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Daftar Item (${items.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ElevatedButton.icon(
                        onPressed: () => _showItemDialog(),
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text("Tambah Item", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  if (items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(5)),
                      child: const Center(child: Text("Belum ada item di PR ini.")),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text("Barang")),
                          DataColumn(label: Text("Qty")),
                          DataColumn(label: Text("Satuan")),
                          DataColumn(label: Text("Catatan")),
                          DataColumn(label: Text("Aksi")),
                        ],
                        rows: items.map<DataRow>((item) {
                          
                          // --- PERBAIKAN: Gunakan fungsi Helper untuk mencari Nama ---
                          String name = _getItemName(item); 
                          String unitName = _getUnitName(item['unit_id']); 

                          return DataRow(cells: [
                            DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text(item['quantity'].toString())),
                            DataCell(Text(unitName)), 
                            DataCell(Text(item['notes'] ?? '-')),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showItemDialog(item: item)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(item['id'])),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                ],
              )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class RawMaterialStockAdjustmentPage extends StatefulWidget {
  const RawMaterialStockAdjustmentPage({super.key});

  @override
  State<RawMaterialStockAdjustmentPage> createState() => _RawMaterialStockAdjustmentPageState();
}

class _RawMaterialStockAdjustmentPageState extends State<RawMaterialStockAdjustmentPage> {
  List<dynamic> _adjustments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getRawMaterialStockAdjustments();
    setState(() {
      _adjustments = data;
      _isLoading = false;
    });
  }

  // --- FORM DIALOG (STOCK OPNAME) ---
  void _showAddDialog() async {
    // 1. Persiapkan Data Dropdown
    List<dynamic> rawMaterials = await DataService().getRawMaterials();
    List<dynamic> warehouses = await DataService().getWarehouses();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return _AdjustmentFormDialog(
          rawMaterials: rawMaterials,
          warehouses: warehouses,
          onSuccess: _fetchData, // Refresh tabel setelah sukses
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                  "Raw Material Stock Adjustment",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text("Stock Opname", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // TABLE
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _adjustments.isEmpty
                    ? const Center(child: Text("Belum ada data penyesuaian."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn(label: Text("Bahan Baku", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Gudang", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Sebelum", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Sesudah", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Selisih", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Alasan", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _adjustments.map((item) {
                            final rawMat = item['raw_material'] ?? {};
                            final wh = item['warehouse'] ?? {};
                            final diff = double.parse(item['difference'].toString());

                            return DataRow(cells: [
                              DataCell(Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(rawMat['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(rawMat['code'] ?? '-', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              )),
                              DataCell(Text(wh['name'] ?? '-')),
                              DataCell(Text(item['before_quantity'].toString())),
                              DataCell(Text(
                                item['after_quantity'].toString(),
                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              )),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: diff < 0 ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    diff > 0 ? "+$diff" : "$diff",
                                    style: TextStyle(
                                      color: diff < 0 ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(item['reason'] ?? '-')),
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

// --- WIDGET DIALOG TERPISAH AGAR LEBIH RAPI ---
class _AdjustmentFormDialog extends StatefulWidget {
  final List<dynamic> rawMaterials;
  final List<dynamic> warehouses;
  final VoidCallback onSuccess;

  const _AdjustmentFormDialog({
    required this.rawMaterials,
    required this.warehouses,
    required this.onSuccess,
  });

  @override
  State<_AdjustmentFormDialog> createState() => _AdjustmentFormDialogState();
}

class _AdjustmentFormDialogState extends State<_AdjustmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  int? _selectedRawMaterialId;
  int? _selectedWarehouseId;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Stock Opname (Penyesuaian)"),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PILIH BAHAN BAKU
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Bahan Baku", border: OutlineInputBorder()),
                  value: _selectedRawMaterialId,
                  items: widget.rawMaterials.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text("${item['code']} - ${item['name']}", overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRawMaterialId = val),
                  validator: (val) => val == null ? "Wajib dipilih" : null,
                ),
                const SizedBox(height: 15),

                // PILIH GUDANG
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Gudang", border: OutlineInputBorder()),
                  value: _selectedWarehouseId,
                  items: widget.warehouses.map((item) {
                    return DropdownMenuItem<int>(
                      value: item['id'],
                      child: Text(item['name']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedWarehouseId = val),
                  validator: (val) => val == null ? "Wajib dipilih" : null,
                ),
                const SizedBox(height: 15),

                // INPUT STOK FISIK (AFTER QUANTITY)
                TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(
                    labelText: "Stok Fisik Sekarang (After Qty)",
                    hintText: "Masukkan jumlah real saat ini",
                    border: OutlineInputBorder(),
                    suffixText: "Unit"
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Wajib diisi";
                    if (double.tryParse(val) == null) return "Harus angka";
                    return null;
                  },
                ),
                const SizedBox(height: 5),
                const Text(
                  "*Sistem akan otomatis menghitung selisihnya",
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 15),

                // ALASAN
                TextFormField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: "Alasan Penyesuaian",
                    hintText: "Contoh: Barang rusak, Salah hitung, dll",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Batal"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _isSaving ? null : _submit,
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("Simpan", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      // Mapping data sesuai controller Laravel store()
      Map<String, dynamic> data = {
        "raw_material_id": _selectedRawMaterialId,
        "warehouse_id": _selectedWarehouseId,
        "after_quantity": double.parse(_qtyCtrl.text), // Backend pakai 'after_quantity'
        "reason": _reasonCtrl.text,
      };

      bool success = await DataService().createRawMaterialStockAdjustment(data);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        Navigator.pop(context); // Tutup dialog
        widget.onSuccess(); // Refresh tabel
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Stok berhasil disesuaikan!"), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan data"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
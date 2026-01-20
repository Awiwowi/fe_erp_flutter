import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getProducts();
    setState(() {
      _products = data;
      _isLoading = false;
    });
  }

  void _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product"),
        content: const Text("Are you sure you want to delete this product?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text("Cancel")
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().deleteProduct(id);
      
      // ✅ PERBAIKAN: Cek Mounted sebelum update UI
      if (!mounted) return;

      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green)
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final TextEditingController kodeCtrl = TextEditingController(text: item?['kode']);
    final TextEditingController nameCtrl = TextEditingController(text: item?['name']);
    final TextEditingController unitIdCtrl = TextEditingController(text: item?['unit_id']?.toString() ?? '1');
    final TextEditingController tipeCtrl = TextEditingController(text: item?['tipe']);
    final TextEditingController volumeCtrl = TextEditingController(text: item?['volume']);
    final TextEditingController hargaCtrl = TextEditingController(text: item?['harga']?.toString());
    
    // Convert 1/0 or true/false to boolean
    bool isReturnable = item?['is_returnable'] == 1 || item?['is_returnable'] == true;

    showDialog(
      context: context, // Context Halaman Utama
      builder: (dialogContext) { // Context Dialog (Beri nama dialogContext)
        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Product" : "Add Product"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: kodeCtrl, decoration: const InputDecoration(labelText: "Kode")),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
                    TextField(controller: unitIdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Unit ID")),
                    TextField(controller: tipeCtrl, decoration: const InputDecoration(labelText: "Tipe")),
                    TextField(controller: volumeCtrl, decoration: const InputDecoration(labelText: "Volume")),
                    TextField(controller: hargaCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Harga")),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      title: const Text("Is Returnable"),
                      value: isReturnable,
                      onChanged: (val) => setStateDialog(() => isReturnable = val),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  // ✅ Pakai dialogContext untuk tutup dialog
                  onPressed: () => Navigator.pop(dialogContext), 
                  child: const Text("Cancel")
                ),
                ElevatedButton(
                  onPressed: () async {
                    // ✅ 1. Tutup Dialog pakai dialogContext
                    Navigator.pop(dialogContext);
                    
                    Map<String, dynamic> data = {
                      "kode": kodeCtrl.text,
                      "name": nameCtrl.text,
                      "unit_id": int.tryParse(unitIdCtrl.text) ?? 1,
                      "tipe": tipeCtrl.text,
                      "volume": volumeCtrl.text,
                      "harga": int.tryParse(hargaCtrl.text) ?? 0,
                      "is_returnable": isReturnable,
                    };

                    bool success;
                    if (isEdit) {
                      success = await DataService().updateProduct(item['id'], data);
                    } else {
                      success = await DataService().addProduct(data);
                    }

                    // ✅ 2. WAJIB: Cek Mounted sebelum pakai context halaman utama
                    if (!mounted) return;

                    // ✅ 3. Pakai context halaman utama untuk SnackBar
                    if (success) {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? "Updated!" : "Created!"), backgroundColor: Colors.green)
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Action Failed"), backgroundColor: Colors.red)
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(isEdit ? "Save" : "Add", style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(10), 
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Products List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text("Add Product", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9FC)),
                      columns: const [
                        DataColumn(label: Text("Kode", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Unit ID", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Tipe", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Volume", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Harga", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Returnable", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _products.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['kode']?.toString() ?? '-')),
                          DataCell(Text(item['name']?.toString() ?? '-')),
                          DataCell(Text(item['unit_id']?.toString() ?? '-')),
                          DataCell(Text(item['tipe']?.toString() ?? '-')),
                          DataCell(Text(item['volume']?.toString() ?? '-')),
                          DataCell(Text(item['harga']?.toString() ?? '-')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (item['is_returnable'] == true || item['is_returnable'] == 1) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (item['is_returnable'] == true || item['is_returnable'] == 1) ? "Yes" : "No",
                                style: TextStyle(color: (item['is_returnable'] == true || item['is_returnable'] == 1) ? Colors.green : Colors.red, fontSize: 12)
                              ),
                            )
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showFormDialog(item: item)),
                              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteItem(item['id'])),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
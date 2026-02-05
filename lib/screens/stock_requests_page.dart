import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../constants/colors.dart';
import '../services/data_service.dart';

class StockRequestsPage extends StatefulWidget {
  const StockRequestsPage({super.key});

  @override
  State<StockRequestsPage> createState() => _StockRequestsPageState();
}

class _StockRequestsPageState extends State<StockRequestsPage> {
  List<dynamic> _requests = [];
  List<dynamic> _products = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var reqs = await DataService().getStockRequests();
    var prods = await DataService().getProducts();
    
    if (!mounted) return;

    setState(() {
      _requests = reqs;
      _products = prods;
      _isLoading = false;
    });
  }

  String _getProductName(int id) {
    try {
      var prod = _products.firstWhere((element) => element['id'] == id, orElse: () => null);
      return prod != null ? prod['name'] : "ID: $id";
    } catch (e) {
      return "ID: $id";
    }
  }

  void _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Request"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().deleteStockRequest(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red));
      }
    }
  }

  // --- FORM DIALOG (CREATE & UPDATE) ---
  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;

    // 1. Controller untuk Header
    final TextEditingController dateCtrl = TextEditingController(
      text: isEdit ? item['request_date'] : DateFormat('yyyy-MM-dd').format(DateTime.now())
    );
    final TextEditingController notesCtrl = TextEditingController(text: item?['notes']);
    
    // 2. Persiapan Data Items (Jika Edit, masukkan data lama ke tempItems)
    List<Map<String, dynamic>> tempItems = [];
    
    if (isEdit && item['items'] != null) {
      for (var detail in (item['items'] as List)) {
        tempItems.add({
          "product_id": detail['product_id'],
          "product_name": _getProductName(detail['product_id']), // Cari nama biar user paham
          "quantity": detail['quantity']
        });
      }
    }

    // 3. Controller untuk Input Item Kecil
    int? selectedProductId;
    final TextEditingController qtyCtrl = TextEditingController();

    showDialog(
      context: context, // Context Halaman Utama
      builder: (dialogContext) { // Context Dialog
        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit Stock Request" : "New Stock Request"),
              content: SizedBox(
                width: 600, 
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INPUT TANGGAL
                      TextField(
                        controller: dateCtrl, 
                        decoration: const InputDecoration(labelText: "Request Date", icon: Icon(Icons.calendar_today)),
                        readOnly: true,
                        onTap: () async {
                          DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                          }
                        },
                      ),
                      // INPUT CATATAN
                      TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: "Notes", icon: Icon(Icons.note))),
                      
                      const Divider(height: 30, thickness: 2),
                      const Text("Manage Items", style: TextStyle(fontWeight: FontWeight.bold)),
                      
                      // FORM KECIL TAMBAH BARANG
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<int>(
                              value: selectedProductId,
                              hint: const Text("Select Product"),
                              isExpanded: true,
                              items: _products.map((p) {
                                return DropdownMenuItem<int>(
                                  value: p['id'],
                                  child: Text(p['name'] ?? '-', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) => setStateDialog(() => selectedProductId = val),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: qtyCtrl, 
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Qty"),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: AppColors.primary),
                            onPressed: () {
                              if (selectedProductId != null && qtyCtrl.text.isNotEmpty) {
                                var prodName = _getProductName(selectedProductId!);
                                setStateDialog(() {
                                  // Tambah ke list sementara
                                  tempItems.add({
                                    "product_id": selectedProductId,
                                    "product_name": prodName,
                                    "quantity": int.parse(qtyCtrl.text)
                                  });
                                  // Reset input kecil
                                  qtyCtrl.clear();
                                  selectedProductId = null;
                                });
                              }
                            },
                          )
                        ],
                      ),

                      // LIST BARANG SEMENTARA (YANG AKAN DISIMPAN)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        height: 150,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                        child: tempItems.isEmpty 
                          ? const Center(child: Text("No items added yet.", style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: tempItems.length,
                              itemBuilder: (ctx, i) {
                                var tItem = tempItems[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(tItem['product_name']),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text("Qty: ${tItem['quantity']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        onPressed: () {
                                          setStateDialog(() {
                                            tempItems.removeAt(i);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext), 
                  child: const Text("Cancel")
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tempItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one item!")));
                      return;
                    }
                    Navigator.pop(dialogContext); // Tutup dialog

                    // Siapkan Data JSON
                    Map<String, dynamic> data = {
                      "request_date": dateCtrl.text,
                      "notes": notesCtrl.text,
                      "items": tempItems.map((e) => {
                        "product_id": e['product_id'],
                        "quantity": e['quantity']
                      }).toList(),
                    };

                    bool success;
                    if (isEdit) {
                      success = await DataService().updateStockRequest(item['id'], data);
                    } else {
                      success = await DataService().createStockRequest(data);
                    }
                    
                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isEdit ? "Updated Successfully!" : "Created Successfully!"), 
                        backgroundColor: Colors.green
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Action Failed"), 
                        backgroundColor: Colors.red
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(isEdit ? "Save Changes" : "Save Request", style: const TextStyle(color: Colors.white)),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(10), 
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                // 1. JUDUL (Tetap di atas)
               const Text(
                 "Stock Requests List", 
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)
               ),

            const SizedBox(height: 15), // Jarak antara tulisan dan tombol

            // 2. TOMBOL ADD REQUEST (Sekarang di bawah tulisan & memanjang)
            SizedBox(
              width: double.infinity, // Agar tombol full lebar
              child: ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text("Add Request", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                  padding: const EdgeInsets.symmetric(vertical: 12) // Sedikit lebih tebal biar enak ditekan
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
                    child: DataTable(
                      dataRowMinHeight: 60, 
                      dataRowMaxHeight: double.infinity, 
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9FC)),
                      columns: const [
                        DataColumn(label: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Notes", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Product", style: TextStyle(fontWeight: FontWeight.bold))), 
                        DataColumn(label: Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold))), 
                        DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _requests.map((item) {
                        
                        // WIDGET KOLOM PRODUK & QUANTITY (Dipisah)
                        List<Widget> productWidgets = [];
                        List<Widget> qtyWidgets = [];

                        if (item['items'] != null && (item['items'] as List).isNotEmpty) {
                          for (var detail in (item['items'] as List)) {
                            String prodName = _getProductName(detail['product_id']);
                            String qty = detail['quantity'].toString();

                            productWidgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(prodName, style: const TextStyle(fontSize: 13)),
                              )
                            );

                            qtyWidgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text(qty, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              )
                            );
                          }
                        } else {
                           productWidgets.add(const Text("-"));
                           qtyWidgets.add(const Text("-"));
                        }

                        return DataRow(cells: [
                          DataCell(Text(item['request_date']?.toString() ?? '-')),
                          DataCell(Text(item['notes']?.toString() ?? '-')),
                          
                          // KOLOM PRODUK
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: productWidgets,
                              ),
                            )
                          ),

                          // KOLOM QUANTITY
                          DataCell(
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: qtyWidgets,
                              ),
                            )
                          ),
                          
                          // KOLOM ACTIONS (Edit & Delete)
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                tooltip: "Edit Request",
                                onPressed: () => _showFormDialog(item: item), // Mode Edit
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                tooltip: "Delete Request",
                                onPressed: () => _deleteItem(item['id']),
                              ),
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
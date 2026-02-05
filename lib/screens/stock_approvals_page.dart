import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class StockApprovalsPage extends StatefulWidget {
  const StockApprovalsPage({super.key});

  @override
  State<StockApprovalsPage> createState() => _StockApprovalsPageState();
}

class _StockApprovalsPageState extends State<StockApprovalsPage> {
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

  // --- LOGIKA APPROVE & REJECT ---
  void _approveItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Approve Request"),
        content: const Text("Are you sure you want to APPROVE this request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Approve", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().approveStockRequest(id);
      if (!mounted) return;
      if (success) {
        _fetchData(); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Approved!"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to Approve"), backgroundColor: Colors.red));
      }
    }
  }

  void _rejectItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Request"),
        content: const Text("Are you sure you want to REJECT this request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Reject", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().rejectStockRequest(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request Rejected"), backgroundColor: Colors.orange));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to Reject"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Approval List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)),
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
                        DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Items", style: TextStyle(fontWeight: FontWeight.bold))), 
                        DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _requests.map((item) {
                        
                        // --- PERBAIKAN LOGIKA STATUS DI SINI ---
                        // Ambil status, ubah ke string lowercase, handle null
                        String rawStatus = (item['status'] ?? 'draft').toString();
                        String status = rawStatus.toLowerCase(); // 'DRAFT' -> 'draft'
                        
                        // Warna Badge
                        Color statusColor = Colors.grey;
                        if (status == 'approved') statusColor = Colors.green;
                        if (status == 'rejected') statusColor = Colors.red;
                        if (status == 'draft') statusColor = Colors.orange; // draft = pending

                        // Tentukan apakah tombol Approve/Reject harus muncul?
                        // Tombol muncul HANYA jika status == 'draft'
                        bool showActions = (status == 'draft');

                        // --- END LOGIKA ---

                        List<Widget> productWidgets = [];
                        if (item['items'] != null && (item['items'] as List).isNotEmpty) {
                          for (var detail in (item['items'] as List)) {
                            String prodName = _getProductName(detail['product_id']);
                            String qty = detail['quantity'].toString();
                            productWidgets.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Text("- $prodName ($qty)", style: const TextStyle(fontSize: 13)),
                              )
                            );
                          }
                        } else {
                           productWidgets.add(const Text("-"));
                        }

                        return DataRow(cells: [
                          DataCell(Text(item['request_date']?.toString() ?? '-')),
                          DataCell(Text(item['notes']?.toString() ?? '-')),
                          
                          // CELL STATUS
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: statusColor)),
                              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                            )
                          ),

                          // CELL ITEMS
                          DataCell(Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              mainAxisAlignment: MainAxisAlignment.center, 
                              children: productWidgets
                            ),
                          )),

                          // CELL ACTIONS (Approve & Reject)
                          DataCell(
                            showActions ? Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  tooltip: "Approve",
                                  onPressed: () => _approveItem(item['id']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  tooltip: "Reject",
                                  onPressed: () => _rejectItem(item['id']),
                                ),
                              ],
                            ) : const Text("-"), 
                          ),
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
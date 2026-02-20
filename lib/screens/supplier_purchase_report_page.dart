import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class SupplierPurchaseReportPage extends StatefulWidget {
  const SupplierPurchaseReportPage({super.key});

  @override
  State<SupplierPurchaseReportPage> createState() => _SupplierPurchaseReportPageState();
}

class _SupplierPurchaseReportPageState extends State<SupplierPurchaseReportPage> {
  List<dynamic> _reportData = [];
  Map<String, dynamic> _meta = {};
  bool _isLoading = true;
  
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    
    String? startStr = _startDate != null ? _startDate!.toIso8601String().split('T')[0] : null;
    String? endStr = _endDate != null ? _endDate!.toIso8601String().split('T')[0] : null;

    var result = await DataService().getSupplierPurchaseReport(
      startDate: startStr, 
      endDate: endStr
    );

    if (mounted) {
      setState(() {
        _reportData = result?['data'] ?? [];
        _meta = result?['meta'] ?? {};
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Laporan Pembelian per Supplier"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _fetchData, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Column(
        children: [
          // Filter & Summary Header
          Container(
            padding: const EdgeInsets.all(15),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDateRange(context),
                        icon: const Icon(Icons.date_range),
                        label: Text(_startDate == null ? "Pilih Rentang Tanggal" : 
                          "${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}"),
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        onPressed: () { setState(() { _startDate = null; _endDate = null; }); _fetchData(); },
                        icon: const Icon(Icons.close, color: Colors.red),
                      )
                  ],
                ),
                const SizedBox(height: 10),
                // Grand Total Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Grand Total Pembelian (Seluruh Supplier):", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Rp ${_meta['grand_total']?.toString() ?? '0'}", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: _reportData.length,
                  itemBuilder: (context, index) {
                    final item = _reportData[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        leading: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.business, color: Colors.white)),
                        title: Text(item['supplier_name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Total PO: ${item['total_po']} | Total Qty: ${item['total_quantity']}"),
                        trailing: Text("Rp ${item['total_pembelian']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              children: [
                                _buildStatRow("PO Draft", item['po_draft'].toString(), Colors.grey),
                                _buildStatRow("PO Terkirim", item['po_sent'].toString(), Colors.orange),
                                _buildStatRow("PO Diterima", item['po_received'].toString(), Colors.blue),
                                _buildStatRow("PO Selesai (Closed)", item['po_closed'].toString(), Colors.green),
                                const Divider(),
                                _buildStatRow("Email", item['supplier_email'] ?? '-', Colors.black87),
                                _buildStatRow("Telepon", item['supplier_phone'] ?? '-', Colors.black87),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
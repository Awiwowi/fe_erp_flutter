import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../services/data_service.dart';

class GoodsMovementReportPage extends StatefulWidget {
  const GoodsMovementReportPage({super.key});

  @override
  State<GoodsMovementReportPage> createState() => _GoodsMovementReportPageState();
}

class _GoodsMovementReportPageState extends State<GoodsMovementReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  Map<String, dynamic> _incomingData = {};
  Map<String, dynamic> _outgoingData = {};
  
  double _incomingGrandTotal = 0;
  double _outgoingGrandTotal = 0;

  bool _isLoading = true;
  
  // Filters
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    String? startStr = _startDate != null ? "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}" : null;
    String? endStr = _endDate != null ? "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}" : null;
    String searchStr = _searchController.text;

    var incomingRes = await DataService().getIncomingGoodsReport(startDate: startStr, endDate: endStr, search: searchStr);
    var outgoingRes = await DataService().getOutgoingGoodsReport(startDate: startStr, endDate: endStr, search: searchStr);

    if (mounted) {
      setState(() {
        _incomingData = incomingRes?['data'] ?? {};
        _incomingGrandTotal = double.tryParse(incomingRes?['meta']?['grand_total_qty']?.toString() ?? '0') ?? 0;
        
        _outgoingData = outgoingRes?['data'] ?? {};
        _outgoingGrandTotal = double.tryParse(outgoingRes?['meta']?['grand_total_qty']?.toString() ?? '0') ?? 0;
        
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _fetchData());
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
  }

  // --- WIDGET LIST KELOMPOK TANGGAL ---
  Widget _buildGroupedList(Map<String, dynamic> data, bool isIncoming, double grandTotal) {
    if (data.isEmpty) return const Center(child: Text("Tidak ada data transaksi."));

    List<String> dates = data.keys.toList();
    // Sort tanggal descending (terbaru di atas)
    dates.sort((a, b) => b.compareTo(a)); 

    return Column(
      children: [
        // Grand Total Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          color: isIncoming ? Colors.green.shade50 : Colors.red.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Grand Total Qty ${isIncoming ? 'Masuk' : 'Keluar'}:", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              Text(
                grandTotal.toString(), 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isIncoming ? Colors.green : Colors.red)
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            itemCount: dates.length,
            itemBuilder: (context, index) {
              String date = dates[index];
              Map<String, dynamic> categories = data[date];

              return ExpansionTile(
                initiallyExpanded: index == 0, // Buka otomatis yang paling atas
                title: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                backgroundColor: Colors.white,
                collapsedBackgroundColor: Colors.white,
                children: categories.entries.map((entry) {
                  String categoryName = entry.key; // 'Product' atau 'RawMaterial'
                  var categoryData = entry.value;
                  List<dynamic> items = categoryData['items'] ?? [];
                  String subTotal = categoryData['sub_total_qty']?.toString() ?? '0';

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori & Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              categoryName == 'Product' ? "Produk Jadi (FG)" : "Bahan Baku (RM)",
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Text("Subtotal Qty: $subTotal", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Tabel Detail Item
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 40,
                            dataRowMinHeight: 40,
                            dataRowMaxHeight: 50,
                            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                            columns: [
                              const DataColumn(label: Text("No. Dokumen")),
                              const DataColumn(label: Text("Kode")),
                              const DataColumn(label: Text("Nama Barang")),
                              if (!isIncoming) const DataColumn(label: Text("Penginput")), // Di outgoing ada nama_pengambil
                              const DataColumn(label: Text("Qty", textAlign: TextAlign.right)),
                            ],
                            rows: items.map((item) {
                              return DataRow(cells: [
                                DataCell(Text(item['no_dokumen']?.toString() ?? '-')),
                                DataCell(Text(item['kode_barang']?.toString() ?? '-')),
                                DataCell(Text(item['nama_barang']?.toString() ?? '-')),
                                if (!isIncoming) DataCell(Text(item['nama_pengambil']?.toString() ?? '-')),
                                DataCell(Text(item['qty']?.toString() ?? '0', style: const TextStyle(fontWeight: FontWeight.w600))),
                              ]);
                            }).toList(),
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeText = "Semua Tanggal";
    if (_startDate != null && _endDate != null) {
      dateRangeText = "${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}";
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // --- HEADER & FILTER ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Laporan Detail Transaksi Barang",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Cari no dokumen / kode / nama...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () => _selectDateRange(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.date_range, color: Colors.grey, size: 20),
                                  const SizedBox(width: 8),
                                  Text(dateRangeText, style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                              if (_startDate != null)
                                InkWell(
                                  onTap: () {
                                    setState(() { _startDate = null; _endDate = null; });
                                    _fetchData();
                                  },
                                  child: const Icon(Icons.close, color: Colors.red, size: 18),
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // --- TAB BAR ---
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(icon: Icon(Icons.arrow_downward, color: Colors.green), text: "Log Barang Masuk"),
                Tab(icon: Icon(Icons.arrow_upward, color: Colors.red), text: "Log Barang Keluar"),
              ],
            ),
          ),

          // --- TAB BAR VIEW ---
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    Container(color: Colors.white, child: _buildGroupedList(_incomingData, true, _incomingGrandTotal)),
                    Container(color: Colors.white, child: _buildGroupedList(_outgoingData, false, _outgoingGrandTotal)),
                  ],
                ),
          )
        ],
      ),
    );
  }
}
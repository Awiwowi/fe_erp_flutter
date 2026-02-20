import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/colors.dart';
import '../services/data_service.dart';

class InventoryReportPage extends StatefulWidget {
  const InventoryReportPage({super.key});

  @override
  State<InventoryReportPage> createState() => _InventoryReportPageState();
}

class _InventoryReportPageState extends State<InventoryReportPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<dynamic> _productData = [];
  List<dynamic> _rawMaterialData = [];
  
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
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Refresh state saat pindah tab
      }
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
    
    // Format tanggal ke YYYY-MM-DD
    String? startStr = _startDate != null ? "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}" : null;
    String? endStr = _endDate != null ? "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}" : null;
    String searchStr = _searchController.text;

    var products = await DataService().getInventoryProducts(startDate: startStr, endDate: endStr, search: searchStr);
    var rawMaterials = await DataService().getInventoryRawMaterials(startDate: startStr, endDate: endStr, search: searchStr);

    if (mounted) {
      setState(() {
        _productData = products;
        _rawMaterialData = rawMaterials;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchData();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) 
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
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

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _fetchData();
  }

  // --- WIDGET TABEL ---
  Widget _buildTable(List<dynamic> data, bool isProduct) {
    if (data.isEmpty) {
      return const Center(child: Text("Tidak ada data persediaan."));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
        dataRowMaxHeight: double.infinity,
        dataRowMinHeight: 60,
        columns: const [
          DataColumn(label: Text("Kode", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Nama Barang", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Satuan", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Stok Awal", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Masuk", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
          DataColumn(label: Text("Keluar", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red))),
          DataColumn(label: Text("Stok Akhir", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: data.map((item) {
          // Menangani perbedaan key di backend antara product dan raw material
          String kode = (isProduct ? item['kode'] : item['kode_produk'])?.toString() ?? '-';
          String nama = (isProduct ? item['nama'] : item['nama_produk'])?.toString() ?? '-';
          String kategori = item['kategori']?.toString() ?? '-';
          String satuan = item['satuan']?.toString() ?? '-';
          
          double awal = double.tryParse(item['stok_awal']?.toString() ?? '0') ?? 0;
          double masuk = double.tryParse(item['stok_masuk']?.toString() ?? '0') ?? 0;
          double keluar = double.tryParse(item['stok_keluar']?.toString() ?? '0') ?? 0;
          
          // Produk jadi punya stock_adj
          double adj = 0;
          if (isProduct) {
            adj = double.tryParse(item['stock_adj']?.toString() ?? '0') ?? 0;
          }

          double akhir = double.tryParse(item['stok_akhir']?.toString() ?? '0') ?? 0;

          return DataRow(cells: [
            DataCell(Text(kode, style: const TextStyle(fontWeight: FontWeight.w600))),
            DataCell(Text(nama)),
            DataCell(Text(kategori)),
            DataCell(Text(satuan)),
            DataCell(Text(awal.toString())),
            DataCell(Text(masuk.toString(), style: const TextStyle(color: Colors.green))),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(keluar.toString(), style: const TextStyle(color: Colors.red)),
                  if (isProduct && adj != 0) 
                    Text(
                      "Adj: ${adj > 0 ? '+' : ''}$adj", 
                      style: TextStyle(fontSize: 10, color: Colors.orange.shade700)
                    ),
                ],
              )
            ),
            DataCell(
              Text(
                akhir.toString(), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              )
            ),
          ]);
        }).toList(),
      ),
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
                  "Laporan Kartu Persediaan",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                
                // Toolbar Pencarian dan Filter Tanggal
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Cari nama atau kode barang...",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    // Filter Tanggal
                    Expanded(
                      flex: 1,
                      child: InkWell(
                        onTap: () => _selectDateRange(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade50
                          ),
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
                                  onTap: _clearDateFilter,
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
                Tab(text: "Produk Jadi (Finish Good)"),
                Tab(text: "Bahan Baku (Raw Material)"),
              ],
            ),
          ),

          // --- TAB BAR VIEW / KONTEN TABEL ---
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Product
                    Container(
                      color: Colors.white,
                      child: _buildTable(_productData, true),
                    ),
                    // Tab 2: Raw Material
                    Container(
                      color: Colors.white,
                      child: _buildTable(_rawMaterialData, false),
                    ),
                  ],
                ),
          )
        ],
      ),
    );
  }
}
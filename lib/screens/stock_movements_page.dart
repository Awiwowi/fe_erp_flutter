import 'package:flutter/material.dart';
import 'dart:async'; // Untuk debouncing search
import '../constants/colors.dart';
import '../services/data_service.dart';

class StockMovementsPage extends StatefulWidget {
  const StockMovementsPage({super.key});

  @override
  State<StockMovementsPage> createState() => _StockMovementsPageState();
}

class _StockMovementsPageState extends State<StockMovementsPage> {
  List<dynamic> _allMovements = []; // Data asli dari API
  List<dynamic> _filteredMovements = []; // Data yang ditampilkan (setelah search)
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Ambil data dari API
  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getStockMovements();
    
    if (mounted) {
      setState(() {
        _allMovements = data;
        _filteredMovements = data;
        _isLoading = false;
      });
    }
  }

  // Filter data berdasarkan pencarian
  void _filterData(String query) {
    if (query.isEmpty) {
      setState(() => _filteredMovements = _allMovements);
    } else {
      setState(() {
        _filteredMovements = _allMovements.where((item) {
          final itemName = (item['item_name'] ?? '').toString().toLowerCase();
          final type = (item['movement_type'] ?? '').toString().toLowerCase();
          return itemName.contains(query.toLowerCase()) || type.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  // Helper Format Tanggal (Tanpa package intl biar simple)
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(dateString).toLocal();
      // Format: DD/MM/YYYY HH:MM
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          // --- HEADER & SEARCH ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Mutasi Stok (Stock Card)",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _fetchData,
                      tooltip: 'Refresh Data',
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: _filterData,
                  decoration: InputDecoration(
                    hintText: "Cari nama barang atau tipe...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),

          // --- LIST CONTENT ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMovements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 10),
                            Text(
                              "Tidak ada data mutasi stok.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        itemCount: _filteredMovements.length,
                        itemBuilder: (context, index) {
                          final item = _filteredMovements[index];
                          
                          // Tentukan warna dan icon berdasarkan tipe pergerakan
                          final String moveType = (item['movement_type'] ?? '').toString().toUpperCase();
                          final bool isOut = moveType.contains('OUT');
                          final bool isIn = moveType.contains('IN');
                          final bool isAdj = moveType.contains('ADJUSTMENT');

                          Color badgeColor = Colors.blue;
                          IconData badgeIcon = Icons.info;
                          String badgeText = moveType;

                          if (isOut) {
                            badgeColor = Colors.red.shade700;
                            badgeIcon = Icons.arrow_upward; // Panah naik (keluar)
                          } else if (isIn) {
                            badgeColor = Colors.green.shade700;
                            badgeIcon = Icons.arrow_downward; // Panah turun (masuk)
                          } else if (isAdj) {
                            badgeColor = Colors.orange.shade800;
                            badgeIcon = Icons.tune;
                          }

                          // Tipe Item (Product / Raw Material)
                          final String itemType = item['item_type'] == 'RawMaterial' ? 'Bahan Baku' : 'Produk Jadi';

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ICON BOX
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: badgeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(badgeIcon, color: badgeColor, size: 28),
                                  ),
                                  const SizedBox(width: 15),
                                  
                                  // CONTENT CENTER
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['item_name'] ?? 'Unknown Item',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                itemType,
                                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatDate(item['created_at']),
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                        if (item['notes'] != null && item['notes'] != '')
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Text(
                                              "Note: ${item['notes']}",
                                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // QUANTITY & TYPE RIGHT
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${isOut ? '-' : '+'}${item['quantity']}",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isOut ? Colors.red : Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        moveType.replaceAll('_', ' '),
                                        style: TextStyle(fontSize: 11, color: badgeColor, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class Sidebar extends StatefulWidget {
  final Function(int) onMenuClick;
  final int selectedIndex;

  const Sidebar({super.key, required this.onMenuClick, required this.selectedIndex});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool _isDataMasterExpanded = false;
  bool _isPersediaanExpanded = false;
  bool _isPembelianExpanded = false;
  bool _isPenjualanExpanded = false;
  bool _isProduksiExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedIndex >= 1 && widget.selectedIndex <= 4) {
      _isDataMasterExpanded = true;
    }
    if (widget.selectedIndex >= 5 && widget.selectedIndex <= 8) {
      _isPersediaanExpanded = true;
    }
    if (widget.selectedIndex == 9) { // Index 9 untuk PR
      _isPembelianExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.black, // Warna Hitam Full Background
      child: Column(
        children: [
          // 1. AREA LOGO (DIBUNGKUS SAFEAREA)
          // SafeArea otomatis mendeteksi tinggi status bar & mendorong konten ke bawah
          SafeArea(
            bottom: false, // Hanya peduli bagian atas
            child: Container(
              // Padding tambahan 10px dari batas aman agar sejajar Header
              padding: const EdgeInsets.only(top: 10, bottom: 15, left: 24, right: 24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1)))
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text("TailAdmin", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // 2. MENU LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _menuGroup("MENU"),
                _menuItem(0, "Dashboard", Icons.dashboard_outlined),

                _buildExpandableMenu(
                  title: "Data Master",
                  icon: Icons.layers_outlined,
                  isOpen: _isDataMasterExpanded,
                  onTap: () => setState(() => _isDataMasterExpanded = !_isDataMasterExpanded),
                  children: [
                    _subMenuItem(1, "Products"),
                    _subMenuItem(2, "Units"),
                    _subMenuItem(3, "Warehouses"),
                    _subMenuItem(4, "Suppliers"),
                    _subMenuItem(20, "COA"),
                  ],
                ),

                _buildExpandableMenu(
                  title: "Persediaan",
                  icon: Icons.inventory_2_outlined,
                  isOpen: _isPersediaanExpanded,
                  onTap: () => setState(() => _isPersediaanExpanded = !_isPersediaanExpanded),
                  children: [
                    _subMenuItem(5, "Stock Requests"),
                    _subMenuItem(6, "Stock Approvals"),
                    _subMenuItem(7, "Stock Out"),
                    _subMenuItem(8, "Stock Awal"),
                    _subMenuItem(15, "Stock Transfer"),
                    _subMenuItem(16, "Stock Adjustment"),
                    _subMenuItem(19, "Product Stock"), 
                    _subMenuItem(10, "Raw Materials"),
                    _subMenuItem(11, "RM Stock In"),
                    _subMenuItem(12, "RM Stock Out"),
                    _subMenuItem(21, "Raw Material Stock"),
                    _subMenuItem(22, "Stock Movements"),
                    _subMenuItem(23, "Kartu Persediaan"),
                    _subMenuItem(24, "Laporan"),
                  ],
                ),

                _buildExpandableMenu(
                  title: "Pembelian",
                  icon: Icons.shopping_cart_outlined,
                  isOpen: _isPembelianExpanded,
                  onTap: () => setState(() => _isPembelianExpanded = !_isPembelianExpanded),
                  children: [
                    _subMenuItem(9, "Purchase Requests"),
                    _subMenuItem(13, "PR Items"),
                    _subMenuItem(14, "Purchase Orders"),
                    _subMenuItem(17, "Goods Receipts"),
                    _subMenuItem(18, "Purchase Returns"),
                    _subMenuItem(25, "Tanda Terima Faktur"),
                    _subMenuItem(26, "Laporan Supplier"),
                  ],
                ),

                _buildExpandableMenu(
                  title: "Penjualan",
                  icon: Icons.shopping_basket_outlined,
                  isOpen: _isPenjualanExpanded,
                  onTap: () => setState(() => _isPenjualanExpanded = !_isPenjualanExpanded),
                  children: [
                    _subMenuItem(30, "Surat Jalan (DO)"),
                  ],
                ),

                _buildExpandableMenu(
                  title: "Produksi",
                  icon: Icons.factory_outlined,
                  isOpen: _isProduksiExpanded,
                  onTap: () => setState(() => _isProduksiExpanded = !_isProduksiExpanded),
                  children: [
                    _subMenuItem(27, "Bill of Materials (BOM)"),
                    _subMenuItem(28, "Product Order"),
                    _subMenuItem(29, "Eksekusi & HPP")
                  ],
                ),

                _menuItem(98, "Settings", Icons.settings_outlined),
                
                const SizedBox(height: 20),
                _menuGroup("OTHERS"),
                _menuItem(99, "Sign Out", Icons.logout, isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _menuGroup(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 12, top: 10),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _menuItem(int index, String title, IconData icon, {bool isLogout = false}) {
    bool isActive = widget.selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: isActive ? const Color(0xFF333A48) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: () => widget.onMenuClick(index),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            child: Row(
              children: [
                Icon(icon, color: isLogout ? Colors.redAccent : Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(color: isLogout ? Colors.redAccent : Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableMenu({
    required String title,
    required IconData icon,
    required bool isOpen,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16))),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  )
                ],
              ),
            ),
          ),
        ),
        if (isOpen)
          Column(children: children),
      ],
    );
  }

  Widget _subMenuItem(int index, String title) {
    bool isActive = widget.selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: isActive ? const Color(0xFF333A48).withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: () => widget.onMenuClick(index),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 48, right: 15),
            child: Row(
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    border: Border.all(color: isActive ? Colors.white : Colors.grey),
                    shape: BoxShape.circle,
                    color: isActive ? Colors.white : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.grey, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
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

  @override
  void initState() {
    super.initState();
    // Otomatis buka menu Data Master jika sedang di halaman Products (1) atau Units (2) atau Warehouses (3)
    if (widget.selectedIndex >= 1 && widget.selectedIndex <= 4) {
      _isDataMasterExpanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: AppColors.black,
      child: Column(
        children: [
          // LOGO
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
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
          
          // MENU LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _menuGroup("MENU"),
                
                // 0. Dashboard
                _menuItem(0, "Dashboard", Icons.dashboard_outlined),

                // GROUP: DATA MASTER (Expandable)
                _buildExpandableMenu(
                  title: "Data Master",
                  icon: Icons.layers_outlined,
                  isOpen: _isDataMasterExpanded,
                  onTap: () => setState(() => _isDataMasterExpanded = !_isDataMasterExpanded),
                  children: [
                    // 1. Products
                    _subMenuItem(1, "Products"),
                    // 2. Units
                    _subMenuItem(2, "Units"),
                    // 3. Warehouses
                    _subMenuItem(3, "Warehouses"),
                    // 4. Suppliers
                    _subMenuItem(4, "Suppliers"),
                  ],
                ),

                _menuItem(5, "Settings", Icons.settings_outlined),
                
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

  // Widget Judul Group Kecil
  Widget _menuGroup(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 12, top: 10),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  // Widget Menu Biasa
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

  // Widget Menu Induk (Bisa diklik untuk buka/tutup)
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

  // Widget Sub Menu (Anak)
  Widget _subMenuItem(int index, String title) {
    bool isActive = widget.selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        // Kalau aktif warnanya agak terang sedikit
        color: isActive ? const Color(0xFF333A48).withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: () => widget.onMenuClick(index),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            // Padding kiri lebih besar supaya menjorok ke dalam
            padding: const EdgeInsets.only(top: 10, bottom: 10, left: 48, right: 15),
            child: Row(
              children: [
                // Bulatan kecil indikator
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
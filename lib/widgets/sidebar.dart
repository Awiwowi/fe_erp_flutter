import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Colors.white,
      child: Column(
        children: [
          // ================= LOGO HEADER =================
          Container(
            height: 80,
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF465FFF), // Brand Color dari CSS
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  "TailAdmin",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C2434),
                  ),
                ),
              ],
            ),
          ),

          // ================= MENU LIST =================
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildMenuTitle("MENU"),
                _buildMenuItem(
                  title: "Dashboard",
                  icon: Icons.dashboard_outlined,
                  isActive: true, // Ceritanya sedang aktif
                  hasSubmenu: true,
                ),
                _buildMenuItem(title: "Calendar", icon: Icons.calendar_month_outlined),
                _buildMenuItem(title: "Profile", icon: Icons.person_outline),
                _buildMenuItem(title: "Forms", icon: Icons.assignment_outlined, hasSubmenu: true),
                _buildMenuItem(title: "Tables", icon: Icons.table_chart_outlined, hasSubmenu: true),
                _buildMenuItem(title: "Settings", icon: Icons.settings_outlined),
                
                const SizedBox(height: 20),
                _buildMenuTitle("OTHERS"),
                _buildMenuItem(title: "Chart", icon: Icons.pie_chart_outline),
                _buildMenuItem(title: "UI Elements", icon: Icons.interests_outlined),
                _buildMenuItem(title: "Authentication", icon: Icons.login_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10, left: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    bool isActive = false,
    bool hasSubmenu = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF3C50E0) : Colors.transparent, // Warna aktif biru
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: hasSubmenu
            ? Icon(
                Icons.keyboard_arrow_down,
                color: isActive ? Colors.white : Colors.grey,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        onTap: () {},
      ),
    );
  }
}
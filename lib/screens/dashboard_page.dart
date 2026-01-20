import 'package:fe_erp_flutter/screens/suppliers_page.dart';
import 'package:fe_erp_flutter/screens/warehouses_page.dart';
import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../constants/colors.dart';
import 'login_page.dart';

// Import Konten Halaman
import 'dashboard_content.dart';
import 'products_page.dart'; // Import Halaman Produk
import 'units_page.dart';    // Import Halaman Unit

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // 0 = Dashboard
  // 1 = Products
  // 2 = Units
  // 3 = Settings
  int _selectedIndex = 0; 

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      
      drawer: !isDesktop 
        ? Drawer(
            width: 280,
            child: Sidebar(
              selectedIndex: _selectedIndex,
              onMenuClick: _handleMenuClick,
            ),
          ) 
        : null,

      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Sidebar(
              selectedIndex: _selectedIndex,
              onMenuClick: _handleMenuClick,
            ),

          Expanded(
            child: Column(
              children: [
                Header(
                  onMenuTap: () {
                    if (!isDesktop) _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                Expanded(
                  child: _buildContent(_selectedIndex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuClick(int index) {
    if (index == 99) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      return;
    }
    
    setState(() => _selectedIndex = index);
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  // Router sederhana untuk ganti konten tengah
  Widget _buildContent(int index) {
    switch (index) {
      case 0: return const DashboardContent(); // Dashboard Utama
      case 1: return const ProductsPage();     // Halaman Produk
      case 2: return const UnitsPage();        // Halaman Unit
      case 3: return const WarehousesPage();   // Halaman Warehouse
      case 4: return const SuppliersPage();    // Halaman Supplier
      case 5: return const Center(child: Text("Settings Page"));
      default: return const Center(child: Text("Not Found"));
    }
  }
}
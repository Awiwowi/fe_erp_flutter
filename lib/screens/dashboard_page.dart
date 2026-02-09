import 'package:fe_erp_flutter/screens/goods_receipts_page.dart';
import 'package:fe_erp_flutter/screens/purchase_orders_page.dart';
import 'package:fe_erp_flutter/screens/purchase_request_items_page.dart';
import 'package:fe_erp_flutter/screens/purchase_requests_page.dart';
import 'package:fe_erp_flutter/screens/purchase_returns_page.dart';
import 'package:fe_erp_flutter/screens/raw_material_stock_in_page.dart';
import 'package:fe_erp_flutter/screens/raw_material_stock_out_page.dart';
import 'package:fe_erp_flutter/screens/raw_materials_page.dart';
import 'package:fe_erp_flutter/screens/stock_adjustment_page.dart';
import 'package:fe_erp_flutter/screens/stock_initial_page.dart';
import 'package:fe_erp_flutter/screens/stock_outs_page.dart';
import 'package:fe_erp_flutter/screens/stock_transfer_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Wajib Import
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart'; // Import AuthService
import 'login_page.dart';

// Import Halaman-Halaman
// (Pastikan nama file sesuai dengan yang ada di folder screens Anda)
import 'dashboard_content.dart'; 
import 'products_page.dart'; 
import 'units_page.dart'; 
import 'warehouses_page.dart';
import 'suppliers_page.dart';
import 'stock_requests_page.dart';
import 'stock_approvals_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  int _selectedIndex = 0; 

  // Variabel Data User
  String _userName = "User";
  String _userRole = "Staff";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fungsi Ambil Data User dari SharedPreferences
  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Cek mounted agar tidak error jika pindah halaman cepat
    if (!mounted) return;

    setState(() {
      _userName = prefs.getString('user_name') ?? "User";
      
      String rawRole = prefs.getString('user_role') ?? "Staff";
      _userRole = rawRole.replaceAll('-', ' ').toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Deteksi Layar Desktop (> 800px)
    bool isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      
      // DRAWER (Hanya muncul di HP/Tablet Kecil)
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
          // SIDEBAR DESKTOP (Hanya muncul di Layar Besar)
          if (isDesktop)
            Sidebar(
              selectedIndex: _selectedIndex,
              onMenuClick: _handleMenuClick,
            ),

          // KONTEN UTAMA
          Expanded(
            child: Column(
              children: [
                // HEADER (Sekarang Menerima Data User)
                Header(
                  userName: _userName, // Kirim Nama
                  userRole: _userRole, // Kirim Role
                  onMenuTap: () {
                    // Buka Drawer jika di HP
                    if (!isDesktop) _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                
                // ISI HALAMAN (Ganti-ganti sesuai menu)
                Expanded(
                  child: Container(
                    // Padding agar konten tidak mepet pinggir
                    padding: const EdgeInsets.all(20), 
                    child: _buildContent(_selectedIndex),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handle Klik Menu Sidebar
  void _handleMenuClick(int index) async {
    // LOGOUT (Index 99)
    if (index == 99) {
      await AuthService().logout(); // Panggil fungsi logout dari service
      
      if (!mounted) return;
      // Kembali ke Login Page & Hapus history route sebelumnya
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
      return;
    }
    
    // GANTI HALAMAN
    setState(() => _selectedIndex = index);
    
    // Tutup Drawer jika sedang terbuka (User HP)
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  // Router Halaman
  Widget _buildContent(int index) {
    switch (index) {
      case 0: return const DashboardContent(); 
      case 1: return const ProductsPage();    
      case 2: return const UnitsPage();        
      case 3: return const WarehousesPage();   
      case 4: return const SuppliersPage();    
      case 5: return const StockRequestsPage(); 
      case 6: return const StockApprovalsPage(); 
      case 7: return const StockOutsPage();
      case 8: return const InitialStocksPage();
      case 9: return const PurchaseRequestsPage();
      case 10: return const RawMaterialsPage();
      case 11: return const RawMaterialStockInPage();
      case 12: return const RawMaterialStockOutPage();
      case 13: return const PurchaseRequestItemsPage();
      case 14: return const PurchaseOrdersPage();
      case 15: return const StockTransferPage();
      case 16: return const StockAdjustmentPage();
      case 17: return const GoodsReceiptsPage();
      case 18: return const PurchaseReturnsPage();
      case 98: return const Center(child: Text("Settings Page"));
      default: return const Center(child: Text("Page Not Found"));
    }
  }
}
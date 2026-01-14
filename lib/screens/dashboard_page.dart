import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import 'login_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Kunci untuk mengontrol Drawer (buka/tutup sidebar di HP)
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    
    // Cek Lebar Layar
    final double width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 800;

    return Scaffold(
      key: scaffoldKey, // Pasang kuncinya di sini
      backgroundColor: const Color(0xFFF1F5F9),
      
      // LOGIKA 1: Kalau layar kecil, pasang Drawer. Kalau besar, null.
      drawer: !isLargeScreen 
          ? const Drawer(
              backgroundColor: Colors.white,
              child: Sidebar(), // Sidebar dijadikan isi Drawer
            ) 
          : null,
      
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LOGIKA 2: Kalau layar besar, Sidebar dipasang permanen di kiri
          if (isLargeScreen) 
            const Sidebar(),

          Expanded(
            child: Column(
              children: [
                // Header dengan fungsi buka Drawer
                Header(
                  onMenuTap: () {
                    // Kalau di HP, buka Drawer. Kalau di Laptop, abaikan.
                    if (!isLargeScreen) {
                      scaffoldKey.currentState?.openDrawer();
                    }
                  },
                ),

                // Konten Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // LOGIKA 3: Grid Responsif (4, 2, atau 1 kolom)
                        GridView.count(
                          crossAxisCount: width > 1100 ? 4 : (width > 600 ? 2 : 1),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          // Rasio aspek diatur biar kartu tidak terlalu gepeng di HP
                          childAspectRatio: width < 600 ? 1.8 : 1.5,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _buildStatCard(
                              title: "Total Views",
                              value: "\$3.456K",
                              percentage: "0.43%",
                              isIncrease: true,
                              icon: Icons.remove_red_eye_outlined,
                              iconColor: const Color(0xFF3C50E0),
                            ),
                            _buildStatCard(
                              title: "Total Profit",
                              value: "\$45.2K",
                              percentage: "4.35%",
                              isIncrease: true,
                              icon: Icons.shopping_cart_outlined,
                              iconColor: const Color(0xFF3C50E0),
                            ),
                            _buildStatCard(
                              title: "Total Product",
                              value: "2.450",
                              percentage: "2.59%",
                              isIncrease: true,
                              icon: Icons.shopping_bag_outlined,
                              iconColor: const Color(0xFF3C50E0),
                            ),
                            _buildStatCard(
                              title: "Total Users",
                              value: "3.456",
                              percentage: "0.95%",
                              isIncrease: false,
                              icon: Icons.people_outline,
                              iconColor: const Color(0xFF3C50E0),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Placeholder Chart
                        Container(
                          height: 400,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bar_chart, size: 80, color: Colors.grey),
                                const SizedBox(height: 10),
                                const Text("Revenue Chart Placeholder", style: TextStyle(color: Colors.grey)),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text("Logout (Demo)", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String percentage,
    required bool isIncrease,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2F7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: iconColor),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    "${isIncrease ? '+' : ''}$percentage",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isIncrease ? const Color(0xFF10B981) : const Color(0xFFF0950C),
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
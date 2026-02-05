import 'package:flutter/material.dart';
import '../constants/colors.dart';

class Header extends StatelessWidget {
  final VoidCallback onMenuTap;
  
  // 1. Tambahkan parameter untuk menampung data
  final String userName;
  final String userRole;

  const Header({
    super.key, 
    required this.onMenuTap,
    // 2. Tambahkan di constructor dengan nilai default biar aman
    this.userName = "User",
    this.userRole = "Staff",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10, // Safe Area
        bottom: 15,
        left: 16,
        right: 16
      ),
      child: Row(
        children: [
          // Tombol Menu (Hamburger)
          InkWell(
            onTap: onMenuTap,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: AppColors.black),
            ),
          ),
          
          const Spacer(),

          // User Profile (Sekarang Dinamis)
          Row(
            children: [
              // Sembunyikan teks jika layar terlalu kecil (< 400)
              if (MediaQuery.of(context).size.width > 400)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 3. Panggil variabel userName
                    Text(
                      userName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    // 4. Panggil variabel userRole
                    Text(
                      userRole, 
                      style: const TextStyle(fontSize: 12, color: Colors.grey)
                    ),
                  ],
                ),
              const SizedBox(width: 12),
              Container(
                height: 40, width: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: const Icon(Icons.person, color: Colors.grey),
              ),
            ],
          )
        ],
      ),
    );
  }
}
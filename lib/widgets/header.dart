import 'package:flutter/material.dart';
import '../constants/colors.dart';

class Header extends StatelessWidget {
  final VoidCallback onMenuTap;

  const Header({super.key, required this.onMenuTap});

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

          // User Profile (Static dulu)
          Row(
            children: [
              if (MediaQuery.of(context).size.width > 400)
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("Thomas Anree", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text("UX Designer", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
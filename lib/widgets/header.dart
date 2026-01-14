import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final VoidCallback onMenuTap;

  const Header({super.key, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white, // Warna background tetap sampai ujung atas layar
      child: SafeArea(
        bottom: false, // Hanya amankan bagian atas (Status Bar)
        child: Container(
          height: 70, // Tinggi area konten header
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center, // Pastikan isi header di tengah vertikal
          child: Row(
            children: [
              // TOMBOL MENU (HAMBURGER)
              // Dibungkus Material transparan agar efek riak (bulat) terlihat jelas
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onMenuTap,
                  borderRadius: BorderRadius.circular(50), // Efek pencet bulat sempurna
                  child: Container(
                    padding: const EdgeInsets.all(10), // Area sentuh diperluas
                    child: const Icon(Icons.menu, color: Colors.black54),
                  ),
                ),
              ),
              
              const SizedBox(width: 10),

              // SEARCH BAR
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100], // Sedikit dikasih warna biar beda
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: "Type to search...",
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10), // Teks pas di tengah
                    ),
                  ),
                ),
              ),

              // ICONS & PROFILE
              // Logika: Tampilkan ikon hanya jika layar cukup lebar (bukan HP kecil)
              if (MediaQuery.of(context).size.width > 600) ...[
                const SizedBox(width: 16),
                IconButton(icon: const Icon(Icons.dark_mode_outlined), onPressed: () {}),
                IconButton(icon: const Icon(Icons.notifications_none_outlined), onPressed: () {}),
              ],
              
              const SizedBox(width: 12),
              
              // USER PROFILE
              Row(
                children: [
                  // Sembunyikan nama di HP biar tidak sempit
                  if (MediaQuery.of(context).size.width > 400)
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("Thomas Anree", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("UX Designer", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  
                  // Foto Profil
                  Container(
                    height: 40,
                    width: 40,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFEFF4FB),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF64748B)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
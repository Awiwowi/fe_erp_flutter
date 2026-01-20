import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ProductTable extends StatelessWidget {
  const ProductTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER TABEL
          const Text(
            "Top Products",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 20),

          // TABEL (Scrollable ke samping kalau di HP)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 0,
              columnSpacing: 20,
              headingRowColor: WidgetStateColor.resolveWith((states) => const Color(0xFFF7F9FC)),
              columns: const [
                DataColumn(label: Text("Product Name", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Category", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Price", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Sold", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Profit", style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: [
                _buildRow("Apple Watch Series 7", "Electronics", "\$269", "22", "\$45"),
                _buildRow("Macbook Pro M1", "Laptop", "\$1,299", "12", "\$120"),
                _buildRow("Dell Inspiron 15", "Laptop", "\$899", "54", "\$90"),
                _buildRow("HP Probook 450", "Laptop", "\$999", "32", "\$100"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildRow(String name, String category, String price, String sold, String profit) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            children: [
              // Gambar Dummy Kotak Kecil
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.image, size: 20, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        DataCell(Text(category)),
        DataCell(Text(price)),
        DataCell(Text(sold)),
        DataCell(Text(profit, style: const TextStyle(color: AppColors.success))),
      ],
    );
  }
}
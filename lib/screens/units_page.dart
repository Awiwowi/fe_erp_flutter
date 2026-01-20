import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class UnitsPage extends StatefulWidget {
  const UnitsPage({super.key});

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  List<dynamic> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getUnits();
    setState(() {
      _units = data;
      _isLoading = false;
    });
  }

  void _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Unit"),
        content: const Text("Are you sure you want to delete this unit?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().deleteUnit(id);
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete"), backgroundColor: Colors.red));
      }
    }
  }

  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    final TextEditingController kodeCtrl = TextEditingController(text: item?['kode']);
    final TextEditingController nameCtrl = TextEditingController(text: item?['name']);
    final TextEditingController descCtrl = TextEditingController(text: item?['description']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? "Edit Unit" : "Add Unit"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: kodeCtrl, decoration: const InputDecoration(labelText: "Kode")),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Map<String, dynamic> data = {
                "kode": kodeCtrl.text,
                "name": nameCtrl.text,
                "description": descCtrl.text,
              };

              bool success;
              if (isEdit) {
                success = await DataService().updateUnit(item['id'], data);
              } else {
                success = await DataService().addUnit(data);
              }

              if (success) {
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEdit ? "Updated!" : "Created!"), backgroundColor: Colors.green));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Action Failed"), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isEdit ? "Save" : "Add", style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Units List", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.black)),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text("Add Unit", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9FC)),
                      columns: const [
                        DataColumn(label: Text("Kode", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Description", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _units.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item['kode']?.toString() ?? '-')),
                          DataCell(Text(item['name']?.toString() ?? '-')),
                          DataCell(Text(item['description']?.toString() ?? '-')),
                          DataCell(Row(
                            children: [
                              IconButton(icon: const Icon(Icons.edit, size: 18, color: Colors.blue), onPressed: () => _showFormDialog(item: item)),
                              IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red), onPressed: () => _deleteItem(item['id'])),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
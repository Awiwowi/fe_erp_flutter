import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class BOMPage extends StatefulWidget {
  const BOMPage({super.key});

  @override
  State<BOMPage> createState() => _BOMPageState();
}

class _BOMPageState extends State<BOMPage> {
  List<dynamic> _boms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getBOMs();
    if (mounted) {
      setState(() {
        _boms = data;
        _isLoading = false;
      });
    }
  }

  void _showDetailModal(Map<String, dynamic> bom) {
    List<dynamic> items = bom['items'] ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Detail Resep: ${bom['bom_number'] ?? 'BOM'}"),
        content: SizedBox(
          width: double.maxFinite,
          child: items.isEmpty
              ? const Text("Tidak ada rincian bahan baku.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    var item = items[index];
                    String materialName =
                        item['raw_material']?['name'] ??
                        item['raw_material']?['nama'] ??
                        "Bahan #${item['raw_material_id']}";
                    String unitName =
                        item['unit']?['name'] ?? item['unit']?['nama'] ?? "";
                    return ListTile(
                      leading: CircleAvatar(child: Text("${index + 1}")),
                      title: Text(materialName),
                      subtitle: Text(
                        "Kebutuhan: ${item['quantity']} $unitName",
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    var products = await DataService().getProducts();
    var rawMaterials = await DataService().getRawMaterials();
    var units = await DataService().getUnits(); // Mengambil master data satuan

    if (!mounted) return;
    Navigator.pop(context);

    int? selectedProductId;
    final bomNumberCtrl = TextEditingController();
    final batchSizeCtrl = TextEditingController(text: '1');
    List<Map<String, dynamic>> bomItems = [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Buat Bill of Material (BOM)",
                style: TextStyle(color: AppColors.primary),
              ),
              content: SizedBox(
                width: 800, // Diperlebar agar dropdown Unit muat di samping Qty
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Produk Jadi (Target) *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedProductId,
                        isExpanded: true,
                        items: products.map((prod) {
                          String pName =
                              prod['nama'] ??
                              prod['name'] ??
                              'Produk ${prod['id']}';
                          return DropdownMenuItem<int>(
                            value: prod['id'],
                            child: Text(pName, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedProductId = val),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: bomNumberCtrl,
                        decoration: const InputDecoration(
                          labelText: "Kode BOM *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: batchSizeCtrl,
                        decoration: const InputDecoration(
                          labelText: "Batch Size (Output) *",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const Divider(height: 30, thickness: 2),
                      const Text(
                        "Bahan Baku Pendukung:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...bomItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // 1. Pilih Bahan
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: "Bahan",
                                    isDense: true,
                                  ),
                                  value: item['raw_material_id'],
                                  isExpanded: true,
                                  items: rawMaterials.map((rm) {
                                    String mName =
                                        rm['name'] ??
                                        rm['nama'] ??
                                        'Material ${rm['id']}';
                                    return DropdownMenuItem<int>(
                                      value: rm['id'],
                                      child: Text(
                                        mName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setStateDialog(
                                    () => item['raw_material_id'] = val,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 2. Isi Qty
                              Expanded(
                                flex: 1,
                                child: TextField(
                                  controller: item['qtyCtrl'],
                                  decoration: const InputDecoration(
                                    labelText: "Qty",
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // 3. Pilih Satuan (Unit_ID) - SEPERTI PCS, LITER, DLL
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: "Satuan (Unit) *",
                                    isDense: true,
                                  ),
                                  value: item['unit_id'],
                                  isExpanded: true,
                                  items: units.map((u) {
                                    String uName =
                                        u['name'] ??
                                        u['nama'] ??
                                        'Unit ${u['id']}';
                                    return DropdownMenuItem<int>(
                                      value: u['id'],
                                      child: Text(
                                        uName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setStateDialog(
                                    () => item['unit_id'] = val,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => setStateDialog(
                                  () => bomItems.removeAt(index),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      TextButton.icon(
                        onPressed: () => setStateDialog(() {
                          bomItems.add({
                            'raw_material_id': null,
                            'unit_id': null,
                            'qtyCtrl': TextEditingController(),
                          });
                        }),
                        icon: const Icon(Icons.add_circle),
                        label: const Text("Tambah Bahan"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () async {
                    if (selectedProductId == null ||
                        bomNumberCtrl.text.isEmpty ||
                        bomItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lengkapi form!")),
                      );
                      return;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    Map<String, dynamic> payload = {
                      "product_id": selectedProductId,
                      "bom_number": bomNumberCtrl.text,
                      "batch_size": double.tryParse(batchSizeCtrl.text) ?? 1,
                      "items": bomItems
                          .where(
                            (i) =>
                                i['raw_material_id'] != null &&
                                i['unit_id'] != null,
                          )
                          .map((i) {
                            return {
                              "raw_material_id": i['raw_material_id'],
                              "quantity":
                                  double.tryParse(i['qtyCtrl'].text) ?? 0,
                              "unit_id": i['unit_id'],
                            };
                          })
                          .toList(),
                    };
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    bool success = await DataService().createBOM(payload);
                    if (!mounted) return;
                    if (success) {
                      _fetchData();
                      messenger.showSnackBar(
                        const SnackBar(content: Text("BOM berhasil dibuat!")),
                      );
                    } else {
                      setState(() => _isLoading = false);
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Gagal membuat BOM. Pastikan Satuan sudah dipilih.",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Simpan Resep",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteBOM(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Hapus BOM?"),
            content: const Text("Yakin ingin menghapus resep ini?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Hapus",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (confirm) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() => _isLoading = true);
      bool success = await DataService().deleteBOM(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        messenger.showSnackBar(const SnackBar(content: Text("BOM dihapus")));
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bill of Materials (BOM)",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        "Daftar resep produksi produk jadi",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Buat BOM Baru",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _boms.isEmpty
                    ? const Center(child: Text("Belum ada data BOM."))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text("Kode BOM")),
                              DataColumn(label: Text("Produk Jadi")),
                              DataColumn(label: Text("Batch Size")),
                              DataColumn(label: Text("Status")),
                              DataColumn(label: Text("Aksi")),
                            ],
                            rows: _boms.map((bom) {
                              // Fix: Pengecekan nama produk agar tidak hilang di tabel
                              String productName =
                                  bom['product']?['nama'] ??
                                  bom['product']?['name'] ??
                                  "-";
                              bool isActive =
                                  bom['is_active'] == 1 ||
                                  bom['is_active'] == true;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      bom['bom_number'] ?? "-",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(productName)),
                                  DataCell(Text("${bom['batch_size'] ?? 0}")),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isActive
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      child: Text(
                                        isActive ? "AKTIF" : "NON-AKTIF",
                                        style: TextStyle(
                                          color: isActive
                                              ? Colors.green
                                              : Colors.red,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.receipt_long,
                                            color: Colors.blue,
                                          ),
                                          onPressed: () =>
                                              _showDetailModal(bom),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteBOM(bom['id']),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

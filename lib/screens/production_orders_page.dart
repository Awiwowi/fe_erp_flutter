import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class ProductionOrdersPage extends StatefulWidget {
  const ProductionOrdersPage({super.key});

  @override
  State<ProductionOrdersPage> createState() => _ProductionOrdersPageState();
}

class _ProductionOrdersPageState extends State<ProductionOrdersPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getProductionOrders();
    if (mounted) {
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    }
  }

  // --- FORM BUAT PESANAN PRODUKSI BARU ---
  void _showCreateDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    var products = await DataService().getProducts();
    var boms = await DataService().getBOMs();
    var warehouses = await DataService().getWarehouses();

    Navigator.pop(context);

    int? selectedProductId;
    int? selectedBomId;
    int? selectedWarehouseId;
    List<dynamic> filteredBoms = [];

    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final qtyCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                "Buat Perencanaan Produksi",
                style: TextStyle(color: AppColors.primary),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Produk Jadi *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedProductId,
                        isExpanded: true,
                        items: products.map((prod) {
                          return DropdownMenuItem<int>(
                            value: prod['id'],
                            child: Text(
                              prod['nama'] ?? prod['name'] ?? '-',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedProductId = val;
                            selectedBomId = null;
                            filteredBoms = boms
                                .where(
                                  (b) =>
                                      b['product_id'].toString() ==
                                      val.toString(),
                                )
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Bill of Material (BOM) *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedBomId,
                        isExpanded: true,
                        items: filteredBoms.map((bom) {
                          return DropdownMenuItem<int>(
                            value: bom['id'],
                            child: Text(
                              "${bom['bom_number'] ?? bom['bom_code']} (Batch: ${bom['batch_size']})",
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: filteredBoms.isEmpty
                            ? null
                            : (val) =>
                                  setStateDialog(() => selectedBomId = val),
                        hint: Text(
                          selectedProductId == null
                              ? "Pilih Produk dulu"
                              : filteredBoms.isEmpty
                              ? "Tidak ada BOM"
                              : "Pilih BOM",
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Gudang Tujuan *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedWarehouseId,
                        isExpanded: true,
                        items: warehouses.map((w) {
                          return DropdownMenuItem<int>(
                            value: w['id'],
                            child: Text(
                              w['name'] ?? '-',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedWarehouseId = val),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tanggal Produksi (YYYY-MM-DD)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: "Rencana Kuantitas *",
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: "Catatan",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
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
                        selectedBomId == null ||
                        selectedWarehouseId == null ||
                        qtyCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Lengkapi form wajib (*)"),
                        ),
                      );
                      return;
                    }

                    Map<String, dynamic> payload = {
                      "product_id": selectedProductId,
                      "bom_id": selectedBomId,
                      "warehouse_id": selectedWarehouseId,
                      "production_date": dateCtrl.text,
                      "quantity_plan": double.tryParse(qtyCtrl.text) ?? 1,
                      "notes": notesCtrl.text,
                    };

                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    bool success = await DataService().createProductionOrder(
                      payload,
                    );

                    if (!mounted) return;
                    if (success) {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Draft Produksi dibuat")),
                      );
                    } else {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Gagal membuat data")),
                      );
                    }
                  },
                  child: const Text(
                    "Simpan Draft",
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

  // --- AKSI: RELEASE PRODUCTION ORDER ---
  void _releaseOrder(int id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Release Pesanan Produksi?"),
            content: const Text(
              "Sistem akan memastikan stok bahan baku cukup dan meneruskan ke lantai produksi. Lanjutkan?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Release",
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

      var result = await DataService().releaseProductionOrder(id);

      if (!mounted) return;
      if (result['success']) {
        _fetchData();
        messenger.showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoading = false);
        if (result['data'] != null && result['data'] is List) {
          _showInsufficientMaterialDialog(result['message'], result['data']);
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showInsufficientMaterialDialog(String title, List<dynamic> materials) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: materials.length,
            itemBuilder: (context, index) {
              var mat = materials[index];
              return ListTile(
                leading: const Icon(Icons.warning, color: Colors.orange),
                title: Text(mat['material'] ?? 'Bahan Baku'),
                subtitle: Text(
                  "Butuh: ${mat['required']} | Ada: ${mat['available']}",
                ),
                trailing: Text(
                  "Kurang:\n${mat['shortage']}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _deleteOrder(int id) async {
    setState(() => _isLoading = true);
    bool success = await DataService().deleteProductionOrder(id);
    if (!mounted) return;
    if (success) {
      _fetchData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey.shade600;
      case 'released':
        return Colors.blue.shade600;
      case 'in_progress':
        return Colors.orange.shade600;
      case 'completed':
        return Colors.green.shade600;
      default:
        return Colors.black;
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Production Orders (Perencanaan)",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Fokus pada pembuatan draft pesanan produksi dan checking bahan baku (Release).",
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _fetchData,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onPressed: _showCreateDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  "Buat Draft Produksi",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _orders.isEmpty
                    ? const Center(
                        child: Text("Belum ada data Production Order."),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                              Colors.grey.shade100,
                            ),
                            columns: const [
                              DataColumn(
                                label: Text(
                                  "No. Produksi",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Tgl Rencana",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Produk Jadi",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Rencana Qty",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Status",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Aksi",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: _orders.map((item) {
                              String status = (item['status'] ?? 'draft')
                                  .toString()
                                  .toLowerCase();
                              Color statusColor = _getStatusColor(status);
                              String tgl =
                                  item['production_date']?.toString().split(
                                    'T',
                                  )[0] ??
                                  '-';
                              String productName =
                                  item['product']?['nama'] ??
                                  item['product']?['name'] ??
                                  '-';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item['production_number']?.toString() ??
                                          '-',
                                    ),
                                  ),
                                  DataCell(Text(tgl)),
                                  DataCell(
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      item['quantity_plan']?.toString() ?? '0',
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: statusColor.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        if (status == 'draft') ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.blue,
                                              size: 20,
                                            ),
                                            tooltip: 'Cek Bahan & Release',
                                            onPressed: () =>
                                                _releaseOrder(item['id']),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Hapus Draft',
                                            onPressed: () =>
                                                _deleteOrder(item['id']),
                                          ),
                                        ] else ...[
                                          const Text(
                                            "Lanjut ke Eksekusi",
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
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

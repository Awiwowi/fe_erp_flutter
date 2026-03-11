import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class DeliveryOrdersPage extends StatefulWidget {
  const DeliveryOrdersPage({super.key});

  @override
  State<DeliveryOrdersPage> createState() => _DeliveryOrdersPageState();
}

class _DeliveryOrdersPageState extends State<DeliveryOrdersPage> {
  List<dynamic> _dos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getDeliveryOrders();
    if (mounted) {
      setState(() {
        _dos = data;
        _isLoading = false;
      });
    }
  }

  // --- MODAL DETAIL DO ---
  void _showDetailModal(int id) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );
    var res = await DataService().getDeliveryOrderDetail(id);
    if (!mounted) return;
    Navigator.pop(context);

    var detail = res?['data'] ?? res;
    if (detail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil detail Surat Jalan.")),
      );
      return;
    }

    List<dynamic> items = detail['items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Detail Surat Jalan: ${detail['no_sj'] ?? '-'}",
          style: const TextStyle(color: AppColors.primary),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Referensi SPK: ${detail['sales_order']?['no_spk'] ?? '-'}",
                ),
                Text("Customer: ${detail['customer']?['name'] ?? '-'}"),
                Text("Gudang Asal: ${detail['warehouse']?['name'] ?? '-'}"),
                Text("Tanggal SJ: ${detail['tanggal'] ?? '-'}"),
                Text("Catatan: ${detail['notes'] ?? '-'}"),
                const Divider(height: 20),
                const Text(
                  "Daftar Barang Dikirim:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text("Produk")),
                      DataColumn(label: Text("Qty Dikirim")),
                    ],
                    rows: items.map((item) {
                      String prodName =
                          item['product']?['nama'] ??
                          item['product']?['name'] ??
                          '-';
                      String qty = item['qty_realisasi']?.toString() ?? '0';
                      return DataRow(
                        cells: [
                          DataCell(Text(prodName)),
                          DataCell(
                            Text(
                              qty,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
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

  // --- MODAL BUAT DO BARU DARI SO ---
  void _showCreateDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    // Ambil Data Master yang dibutuhkan
    var warehouses = await DataService().getWarehouses();
    var allSOs = await DataService().getSalesOrders();

    // Filter SO: Hanya ambil yang berstatus approved, in progress, atau partial
    var validSOs = allSOs.where((so) {
      String status = (so['status'] ?? '').toString().toLowerCase();
      return status == 'approved' ||
          status == 'in progress' ||
          status == 'processing' ||
          status == 'partial';
    }).toList();

    if (!mounted) return;
    Navigator.pop(context);

    int? selectedSoId;
    int? selectedCustomerId;
    int? selectedWarehouseId;
    final dateCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().split('T')[0],
    );
    final notesCtrl = TextEditingController();

    List<Map<String, dynamic>> outstandingItems = [];
    bool isLoadingItems = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // FUNGSI INI YANG DIPERBAIKI (Menggunakan by-pass hitung di Flutter)
            void loadOutstandingItems(int soId) async {
              setStateDialog(() => isLoadingItems = true);

              // Tembak fungsi manual yang kita buat di DataService
              var itemsList = await DataService().getManualOutstandingItems(
                soId,
              );

              setStateDialog(() {
                if (itemsList.isNotEmpty) {
                  outstandingItems = itemsList.map((item) {
                    return {
                      'sales_order_item_id': item['sales_order_item_id'],
                      'product_id': item['product_id'],
                      'product_name': item['product_name'],
                      'qty_sisa':
                          double.tryParse(item['qty_sisa'].toString()) ?? 0,
                      'qtyCtrl': TextEditingController(
                        text: item['qty_sisa'].toString(),
                      ),
                      'selected': true, // Checkbox untuk dikirim atau tidak
                    };
                  }).toList();
                } else {
                  outstandingItems = [];
                }
                isLoadingItems = false;
              });
            }

            return AlertDialog(
              title: const Text(
                "Buat Surat Jalan",
                style: TextStyle(color: AppColors.primary),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Peringatan agar user paham batasan PHP
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.all(15),
                        color: Colors.yellow.shade100,
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Jika ingin mengirim sebagian barang (cicil), usahakan langsung gunakan tombol 'Simpan & Kirim'. Menyimpan sebagai Draft akan mengganggu kalkulasi sisa barang.",
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Pilih Sales Order (SPK) *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedSoId,
                        isExpanded: true,
                        items: validSOs.map((so) {
                          return DropdownMenuItem<int>(
                            value: so['id'],
                            child: Text(
                              "${so['no_spk']} - ${so['customer']?['name'] ?? ''}",
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedSoId = val;
                            var selectedSo = validSOs.firstWhere(
                              (element) => element['id'] == val,
                            );
                            selectedCustomerId = selectedSo['customer_id'];
                          });
                          if (val != null) loadOutstandingItems(val);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: "Pilih Gudang Asal Stok *",
                          border: OutlineInputBorder(),
                        ),
                        value: selectedWarehouseId,
                        isExpanded: true,
                        items: warehouses.map((w) {
                          return DropdownMenuItem<int>(
                            value: w['id'],
                            child: Text(w['name'] ?? '-'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setStateDialog(() => selectedWarehouseId = val),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: dateCtrl,
                        decoration: const InputDecoration(
                          labelText: "Tanggal Pengiriman (YYYY-MM-DD) *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notesCtrl,
                        decoration: const InputDecoration(
                          labelText: "Catatan (Opsional)",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const Divider(height: 30, thickness: 2),
                      const Text(
                        "Barang yang belum dikirim (Outstanding):",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      if (isLoadingItems)
                        const Center(child: CircularProgressIndicator())
                      else if (selectedSoId == null)
                        const Text(
                          "Silakan pilih SPK terlebih dahulu.",
                          style: TextStyle(color: Colors.red),
                        )
                      else if (outstandingItems.isEmpty)
                        const Text(
                          "Semua barang pada SPK ini sudah terkirim penuh.",
                          style: TextStyle(color: Colors.green),
                        )
                      else
                        ...outstandingItems.map((item) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: item['selected'],
                                    onChanged: (val) => setStateDialog(
                                      () => item['selected'] = val,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['product_name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Sisa harus dikirim: ${item['qty_sisa']}",
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: item['qtyCtrl'],
                                      decoration: const InputDecoration(
                                        labelText: "Qty Dikirim",
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      enabled: item['selected'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                if (outstandingItems.isNotEmpty) ...[
                  OutlinedButton(
                    onPressed: () => _submitDO(
                      context,
                      'draft',
                      selectedSoId,
                      selectedCustomerId,
                      selectedWarehouseId,
                      dateCtrl.text,
                      notesCtrl.text,
                      outstandingItems,
                    ),
                    child: const Text("Simpan Draft"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () => _submitDO(
                      context,
                      'shipped',
                      selectedSoId,
                      selectedCustomerId,
                      selectedWarehouseId,
                      dateCtrl.text,
                      notesCtrl.text,
                      outstandingItems,
                    ),
                    child: const Text(
                      "Simpan & Kirim (Potong Stok)",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  void _submitDO(
    BuildContext dialogContext,
    String status,
    int? soId,
    int? customerId,
    int? warehouseId,
    String tanggal,
    String notes,
    List<Map<String, dynamic>> allItems,
  ) async {
    if (soId == null || warehouseId == null || tanggal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi SPK, Gudang, dan Tanggal!")),
      );
      return;
    }

    var selectedItems = allItems.where((i) => i['selected'] == true).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih minimal 1 barang untuk dikirim!")),
      );
      return;
    }

    // Validasi Qty dan Parsing
    List<Map<String, dynamic>> payloadItems = [];
    for (var i in selectedItems) {
      double inputQty = double.tryParse(i['qtyCtrl'].text) ?? 0;
      if (inputQty <= 0 || inputQty > i['qty_sisa']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Qty ${i['product_name']} tidak valid atau melebihi sisa pesanan (${i['qty_sisa']})!",
            ),
          ),
        );
        return;
      }
      payloadItems.add({
        "sales_order_item_id": i['sales_order_item_id'],
        "product_id": i['product_id'],
        "qty": inputQty,
      });
    }

    Map<String, dynamic> payload = {
      "sales_order_id": soId,
      "customer_id": customerId,
      "warehouse_id": warehouseId,
      "tanggal": tanggal,
      "notes": notes,
      "status": status,
      "items": payloadItems,
    };

    Navigator.pop(dialogContext); // Tutup modal
    setState(() => _isLoading = true);

    bool success = await DataService().createDeliveryOrder(payload);
    if (!mounted) return;

    if (success) {
      _fetchData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'shipped'
                ? "Surat Jalan dikirim, stok terpotong."
                : "Draft Surat Jalan berhasil disimpan.",
          ),
        ),
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal menyimpan Surat Jalan.")),
      );
    }
  }

  // --- AKSI PERUBAHAN STATUS & DELETE ---
  void _executeAction(
    int id,
    String actionTitle,
    Future<bool> Function(int) apiCall,
  ) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("Konfirmasi $actionTitle"),
            content: Text(
              "Yakin ingin mengeksekusi aksi $actionTitle pada Surat Jalan ini?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  "Ya, Lanjutkan",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() => _isLoading = true);
      bool success = await apiCall(id);
      if (!mounted) return;
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$actionTitle berhasil")));
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$actionTitle gagal")));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange.shade600;
      case 'shipped':
        return Colors.blue.shade600;
      case 'received':
        return Colors.green.shade600;
      default:
        return Colors.grey;
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
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
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
                        "Delivery Orders (Surat Jalan)",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Manajemen pengiriman barang pesanan ke pelanggan",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _fetchData,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onPressed: _showCreateDialog,
                icon: const Icon(
                  Icons.local_shipping,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  "Buat Surat Jalan (Kirim SPK)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dos.isEmpty
                    ? const Center(child: Text("Belum ada data Surat Jalan."))
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
                                  "No. Surat Jalan",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Ref. SPK",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Tanggal",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Customer",
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
                            rows: _dos.map((item) {
                              String status = (item['status'] ?? 'draft')
                                  .toString()
                                  .toLowerCase();
                              Color statusColor = _getStatusColor(status);

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      item['no_sj'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      item['sales_order']?['no_spk'] ??
                                          item['no_spk'] ??
                                          '-',
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      item['tanggal'] ??
                                          item['tanggal_sj'] ??
                                          '-',
                                    ),
                                  ),
                                  DataCell(
                                    Text(item['customer']?['name'] ?? '-'),
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
                                        border: Border.all(color: statusColor),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_red_eye,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          tooltip: 'Lihat Detail',
                                          onPressed: () =>
                                              _showDetailModal(item['id']),
                                        ),
                                        if (status == 'draft') ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.send,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
                                            tooltip: 'Kirim (Potong Stok)',
                                            onPressed: () => _executeAction(
                                              item['id'],
                                              "Kirim Barang",
                                              DataService().sendDeliveryOrder,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Hapus Draft',
                                            onPressed: () => _executeAction(
                                              item['id'],
                                              "Hapus",
                                              DataService().deleteDeliveryOrder,
                                            ),
                                          ),
                                        ],
                                        if (status == 'shipped') ...[
                                          IconButton(
                                            icon: const Icon(
                                              Icons.check_circle,
                                              color: Colors.green,
                                              size: 20,
                                            ),
                                            tooltip:
                                                'Konfirmasi Diterima Pelanggan',
                                            onPressed: () => _executeAction(
                                              item['id'],
                                              "Konfirmasi Terima",
                                              DataService().confirmReceivedDO,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.cancel,
                                              color: Colors.red,
                                              size: 20,
                                            ),
                                            tooltip: 'Batalkan Pengiriman',
                                            onPressed: () => _executeAction(
                                              item['id'],
                                              "Batal & Hapus",
                                              DataService().deleteDeliveryOrder,
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

import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter tanggal
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();

  // Filter tahun (trend bulanan)
  int _selectedYear = DateTime.now().year;

  // Filter payment status (per customer)
  // null = semua, 'paid' = lunas, 'unpaid' = belum lunas
  String? _paymentStatus;

  // State data
  bool _isLoadingResume = false;
  bool _isLoadingProduct = false;
  bool _isLoadingCustomer = false;
  bool _isLoadingTrend = false;
  bool _isLoadingAging = false;

  Map<String, dynamic>? _resume;
  List<dynamic> _productData = [];
  List<dynamic> _customerData = [];
  List<dynamic> _trendData = [];
  List<dynamic> _agingData = [];

  final List<String> _bulanNames = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    // 5 tab: Resume, Per Produk, Per Customer, Tren Bulanan, Aging Piutang
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadCurrentTab();
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _startDateStr =>
      "${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}";

  String get _endDateStr =>
      "${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}";

  void _loadAllData() {
    _loadResume();
    _loadProduct();
    _loadCustomer();
    _loadTrend();
    _loadAging();
  }

  void _loadCurrentTab() {
    switch (_tabController.index) {
      case 0:
        _loadResume();
        break;
      case 1:
        _loadProduct();
        break;
      case 2:
        _loadCustomer();
        break;
      case 3:
        _loadTrend();
        break;
      case 4:
        _loadAging();
        break;
    }
  }

  void _loadResume() async {
    setState(() => _isLoadingResume = true);
    var data = await DataService().getSalesResume(
      startDate: _startDateStr,
      endDate: _endDateStr,
    );
    if (mounted)
      setState(() {
        _resume = data;
        _isLoadingResume = false;
      });
  }

  void _loadProduct() async {
    setState(() => _isLoadingProduct = true);
    var data = await DataService().getSalesReportByProduct(
      startDate: _startDateStr,
      endDate: _endDateStr,
    );
    if (mounted)
      setState(() {
        _productData = data;
        _isLoadingProduct = false;
      });
  }

  void _loadCustomer() async {
    setState(() => _isLoadingCustomer = true);
    var data = await DataService().getSalesReportByCustomer(
      startDate: _startDateStr,
      endDate: _endDateStr,
      paymentStatus: _paymentStatus,
    );
    if (mounted)
      setState(() {
        _customerData = data;
        _isLoadingCustomer = false;
      });
  }

  void _loadTrend() async {
    setState(() => _isLoadingTrend = true);
    var data = await DataService().getSalesMonthlyTrend(
      year: _selectedYear.toString(),
    );
    if (mounted)
      setState(() {
        _trendData = data;
        _isLoadingTrend = false;
      });
  }

  void _loadAging() async {
    setState(() => _isLoadingAging = true);
    var data = await DataService().getSalesAgingReport();
    if (mounted)
      setState(() {
        _agingData = data;
        _isLoadingAging = false;
      });
  }

  // --- DATE RANGE PICKER ---
  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadResume();
      _loadProduct();
      _loadCustomer();
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    double amount = double.tryParse(value.toString()) ?? 0;
    String str = amount.toStringAsFixed(0);
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) result = '.$result';
      result = str[i] + result;
      count++;
    }
    return 'Rp $result';
  }

  // --- TAB RESUME ---
  Widget _buildResumeTab() {
    if (_isLoadingResume)
      return const Center(child: CircularProgressIndicator());
    if (_resume == null)
      return const Center(child: Text("Gagal memuat data resume."));

    String topCustomerName = _resume!['top_customer']?['name'] ?? '-';
    String topCustomerTotal = _formatCurrency(
      _resume!['top_customer']?['total'],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChip(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: "Total Omzet",
                  value: _formatCurrency(_resume!['total_omzet']),
                  icon: Icons.attach_money,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: "Total Transaksi",
                  value: (_resume!['total_transaksi'] ?? 0).toString(),
                  icon: Icons.receipt_long,
                  color: AppColors.primary,
                  suffix: "SPK",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade600, Colors.orange.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Top Customer Periode Ini",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topCustomerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        topCustomerTotal,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB PER PRODUK ---
  Widget _buildProductTab() {
    if (_isLoadingProduct)
      return const Center(child: CircularProgressIndicator());
    if (_productData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 8),
            const Text(
              "Tidak ada data produk pada periode ini.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildFilterChip(),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _buildFilterChip(),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(
                    label: Text(
                      "Kode",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Nama Produk",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Total Qty",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Total Omzet",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _productData.asMap().entries.map((entry) {
                  int index = entry.key;
                  var item = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.resolveWith(
                      (states) => index == 0 ? Colors.amber.shade50 : null,
                    ),
                    cells: [
                      DataCell(
                        Text(
                          item['product_code'] ?? '-',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (index == 0)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              ),
                            Text(
                              item['product_name'] ?? '-',
                              style: TextStyle(
                                fontWeight: index == 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          item['total_qty']?.toString() ?? '0',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index == 0
                                ? Colors.green.shade700
                                : Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _formatCurrency(item['total_omzet']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  // --- TAB PER CUSTOMER ---
  Widget _buildCustomerTab() {
    return Column(
      children: [
        // Filter bar: tanggal + payment status
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              _buildFilterChip(),
              const SizedBox(width: 8),
              // Filter payment status sesuai PHP: null | 'paid' | 'unpaid'
              DropdownButton<String?>(
                value: _paymentStatus,
                hint: const Text("Semua", style: TextStyle(fontSize: 12)),
                isDense: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text("Semua")),
                  DropdownMenuItem(value: 'paid', child: Text("Lunas")),
                  DropdownMenuItem(value: 'unpaid', child: Text("Belum Lunas")),
                ],
                onChanged: (val) {
                  setState(() => _paymentStatus = val);
                  _loadCustomer();
                },
              ),
            ],
          ),
        ),
        if (_isLoadingCustomer)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_customerData.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Tidak ada data customer pada periode ini.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.grey.shade100,
                  ),
                  columns: const [
                    DataColumn(
                      label: Text(
                        "Customer",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Total Order",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "Total Kontribusi",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Kolom baru sesuai PHP: total_piutang
                    DataColumn(
                      label: Text(
                        "Total Piutang",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  rows: _customerData.asMap().entries.map((entry) {
                    int index = entry.key;
                    var item = entry.value;
                    double piutang =
                        double.tryParse(
                          item['total_piutang']?.toString() ?? '0',
                        ) ??
                        0;
                    return DataRow(
                      color: WidgetStateProperty.resolveWith(
                        (states) => index == 0 ? Colors.amber.shade50 : null,
                      ),
                      cells: [
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (index == 0)
                                const Padding(
                                  padding: EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.emoji_events,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                ),
                              Text(
                                item['customer_name'] ?? '-',
                                style: TextStyle(
                                  fontWeight: index == 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            item['total_orders']?.toString() ?? '0',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(item['total_kontribusi']),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index == 0
                                  ? Colors.green.shade700
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(item['total_piutang']),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: piutang > 0
                                  ? Colors.red.shade600
                                  : Colors.green.shade600,
                            ),
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
    );
  }

  // --- TAB TREND BULANAN ---
  Widget _buildTrendTab() {
    if (_isLoadingTrend)
      return const Center(child: CircularProgressIndicator());

    Map<int, double> trendMap = {};
    for (var item in _trendData) {
      int bulan = int.tryParse(item['bulan']?.toString() ?? '0') ?? 0;
      double omzet =
          double.tryParse(item['total_omzet']?.toString() ?? '0') ?? 0;
      trendMap[bulan] = omzet;
    }

    double maxOmzet = trendMap.values.isEmpty
        ? 1
        : trendMap.values.reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Tahun: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(5, (i) => DateTime.now().year - i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedYear = val);
                    _loadTrend();
                  }
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primary),
                onPressed: _loadTrend,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (trendMap.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "Tidak ada data untuk tahun ini.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: List.generate(12, (i) {
                int bulan = i + 1;
                double omzet = trendMap[bulan] ?? 0;
                double ratio = maxOmzet > 0 ? omzet / maxOmzet : 0;
                bool hasData = omzet > 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          _bulanNames[bulan],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: ratio < 0.02 && hasData
                                  ? 0.02
                                  : ratio,
                              child: Container(
                                height: 28,
                                decoration: BoxDecoration(
                                  color: hasData
                                      ? AppColors.primary.withOpacity(0.85)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            if (hasData)
                              Positioned(
                                right: 8,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Text(
                                    _formatCurrency(omzet),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: ratio > 0.5
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  // --- TAB AGING PIUTANG ---
  Widget _buildAgingTab() {
    if (_isLoadingAging)
      return const Center(child: CircularProgressIndicator());

    if (_agingData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              "Tidak ada piutang yang belum lunas.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Summary per kategori aging
    Map<String, double> agingSummary = {};
    for (var item in _agingData) {
      String kat = item['status_aging'] ?? 'Belum Jatuh Tempo';
      double bal = double.tryParse(item['balance_due']?.toString() ?? '0') ?? 0;
      agingSummary[kat] = (agingSummary[kat] ?? 0) + bal;
    }

    Color _agingColor(String status) {
      if (status.contains('Belum')) return Colors.green.shade600;
      if (status.contains('1 - 30')) return Colors.orange.shade400;
      if (status.contains('31 - 60')) return Colors.orange.shade700;
      if (status.contains('61 - 90')) return Colors.red.shade400;
      return Colors.red.shade800; // >90 macet
    }

    return Column(
      children: [
        // Summary cards
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: agingSummary.entries.map((e) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _agingColor(e.key).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _agingColor(e.key).withOpacity(0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.key,
                        style: TextStyle(
                          fontSize: 11,
                          color: _agingColor(e.key),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(e.value),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _agingColor(e.key),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Detail tabel
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                columns: const [
                  DataColumn(
                    label: Text(
                      "Customer",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "No. Invoice",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Tgl Invoice",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Jatuh Tempo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Sisa Piutang",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Hari Lewat",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      "Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _agingData.map((item) {
                  String status = item['status_aging'] ?? 'Belum Jatuh Tempo';
                  int daysOverdue =
                      int.tryParse(item['days_overdue']?.toString() ?? '0') ??
                      0;
                  Color statusColor = _agingColor(status);

                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item['customer_name'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataCell(Text(item['no_invoice'] ?? '-')),
                      DataCell(Text(item['tanggal'] ?? '-')),
                      DataCell(Text(item['due_date'] ?? '-')),
                      DataCell(
                        Text(
                          _formatCurrency(item['balance_due']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          daysOverdue <= 0 ? '-' : '$daysOverdue hari',
                          style: TextStyle(
                            color: daysOverdue > 0
                                ? Colors.red.shade600
                                : Colors.grey,
                          ),
                        ),
                      ),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildFilterChip() {
    return GestureDetector(
      onTap: _pickDateRange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.date_range, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              "$_startDateStr  →  $_endDateStr",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit, size: 13, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            suffix != null ? "$value $suffix" : value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Laporan Penjualan",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Resume, produk, customer, tren & aging piutang",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                      onPressed: _loadAllData,
                    ),
                  ],
                ),
              ),

              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: "Resume"),
                  Tab(text: "Per Produk"),
                  Tab(text: "Per Customer"),
                  Tab(text: "Tren Bulanan"),
                  Tab(text: "Aging Piutang"),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildResumeTab(),
                    _buildProductTab(),
                    _buildCustomerTab(),
                    _buildTrendTab(),
                    _buildAgingTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

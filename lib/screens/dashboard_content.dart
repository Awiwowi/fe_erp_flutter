import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/data_service.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  List<dynamic> _users = [];
  bool _isLoading = true;

  // Daftar Role sesuai Seeder Laravel
  final List<String> _roleOptions = [
    'super-admin',
    'admin-operasional',
    'admin-penjualan',
    'staff-gudang',
    'staff-produksi',
    'qc',
    'kurir',
    'owner',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    setState(() => _isLoading = true);
    var data = await DataService().getUsers();
    setState(() {
      _users = data;
      _isLoading = false;
    });
  }

  // Fungsi Hapus User
  void _deleteItem(int id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("Are you sure? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      bool success = await DataService().deleteUser(id);
      if (success) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User deleted successfully"), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete user"), backgroundColor: Colors.red));
      }
    }
  }

  // Form Dialog (Create / Edit)
  void _showFormDialog({Map<String, dynamic>? item}) {
    final isEdit = item != null;
    
    // Controllers
    final TextEditingController nameCtrl = TextEditingController(text: item?['name']);
    final TextEditingController emailCtrl = TextEditingController(text: item?['email']);
    final TextEditingController passwordCtrl = TextEditingController(); // Password kosong saat edit

    // Handle Role Selection
    // Jika edit, ambil role pertama dari array roles (biasanya Laravel Spatie return array)
    String? currentRole;
    if (isEdit && item?['roles'] != null && (item?['roles'] as List).isNotEmpty) {
      // Mengambil nama role dari object role spatie (biasanya [{name: 'admin', ...}])
      // Sesuaikan logika ini dengan respons API Laravel kamu
      var roleData = item?['roles'][0]; 
      if (roleData is String) {
        currentRole = roleData;
      } else if (roleData is Map) {
        currentRole = roleData['name'];
      }
    }
    
    // Default role jika create baru
    String selectedRole = currentRole ?? _roleOptions.first;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sbContext, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? "Edit User" : "Create New User"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // NAME
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Full Name", icon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 10),
                    
                    // EMAIL
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "Email", icon: Icon(Icons.email)),
                    ),
                    const SizedBox(height: 10),

                    // ROLE DROPDOWN
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Assign Role", icon: Icon(Icons.security)),
                      value: _roleOptions.contains(selectedRole) ? selectedRole : _roleOptions.first,
                      items: _roleOptions.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.replaceAll('-', ' ').toUpperCase(), style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() => selectedRole = val!);
                      },
                    ),
                    const SizedBox(height: 10),

                    // PASSWORD (Hanya muncul saat Create)
                    if (!isEdit)
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: "Password", icon: Icon(Icons.lock)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                      return; // Validasi sederhana
                    }

                    Navigator.pop(ctx); // Tutup Dialog

                    Map<String, dynamic> data = {
                      "name": nameCtrl.text,
                      "email": emailCtrl.text,
                      "role": selectedRole, // Kirim role sebagai string (Laravel controller handle syncRoles)
                    };

                    bool success;
                    if (isEdit) {
                      // Update tidak kirim password
                      success = await DataService().updateUser(item['id'], data);
                    } else {
                      // Create wajib kirim password
                      data["password"] = passwordCtrl.text; 
                      success = await DataService().createUser(data);
                    }

                    if (!mounted) return;

                    if (success) {
                      _fetchData();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isEdit ? "User Updated!" : "User Created!"), 
                        backgroundColor: Colors.green
                      ));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Action Failed. Cek Email (harus unik)"), 
                        backgroundColor: Colors.red
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(isEdit ? "Save Changes" : "Create User", style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("User Management", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.black)),
                    Text("Manage access and roles", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showFormDialog(), // Buka form create
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text("New User", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            
            // TABEL USER
            _isLoading 
              ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F9FC)),
                      columns: const [
                        DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Email", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Role", style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _users.map((user) {
                        // Ambil role pertama untuk ditampilkan di tabel
                        String roleDisplay = "-";
                        if (user['roles'] != null && (user['roles'] as List).isNotEmpty) {
                           var r = user['roles'][0];
                           roleDisplay = (r is String ? r : r['name']).toString().replaceAll('-', ' ').toUpperCase();
                        }

                        return DataRow(cells: [
                          DataCell(Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(user['name'][0].toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                              ),
                              const SizedBox(width: 10),
                              Text(user['name']),
                            ],
                          )),
                          DataCell(Text(user['email'])),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getRoleColor(roleDisplay).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _getRoleColor(roleDisplay).withOpacity(0.2)),
                              ),
                              child: Text(roleDisplay, style: TextStyle(color: _getRoleColor(roleDisplay), fontSize: 11, fontWeight: FontWeight.w600)),
                            )
                          ),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                tooltip: "Edit User",
                                onPressed: () => _showFormDialog(item: user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                tooltip: "Delete User",
                                onPressed: () => _deleteItem(user['id']),
                              ),
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

  // Helper untuk warna badge role biar cantik
  Color _getRoleColor(String role) {
    if (role.contains("SUPER")) return Colors.red;
    if (role.contains("OPERASIONAL")) return Colors.blue;
    if (role.contains("GUDANG")) return Colors.orange;
    if (role.contains("OWNER")) return Colors.purple;
    return Colors.grey;
  }
}
import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<UserDto> _users = [];
  bool _isLoading = true;
  String _selectedRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final path = _selectedRoleFilter == 'All' ? '/api/users' : '/api/users?role=$_selectedRoleFilter';
      final res = await ApiClient.get(path);
      if (mounted) {
        setState(() {
          _users = (res as List).map((u) => UserDto.fromJson(u)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateUserDialog() async {
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'User@123456');
    final studentCodeCtrl = TextEditingController();
    String role = 'Student';
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm người dùng mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Tên đăng nhập *')),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email *')),
                const SizedBox(height: 10),
                TextField(controller: fullNameCtrl, decoration: const InputDecoration(labelText: 'Họ và tên *')),
                const SizedBox(height: 10),
                TextField(controller: studentCodeCtrl, decoration: const InputDecoration(labelText: 'MSSV (nếu là SV)')),
                const SizedBox(height: 10),
                TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Mật khẩu *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Vai trò *'),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin (Quản trị viên)')),
                    DropdownMenuItem(value: 'Lecturer', child: Text('Lecturer (Giảng viên)')),
                    DropdownMenuItem(value: 'Student', child: Text('Student (Sinh viên)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => role = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (usernameCtrl.text.isEmpty || emailCtrl.text.isEmpty || fullNameCtrl.text.isEmpty) {
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await ApiClient.post('/api/users', {
                    'username': usernameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'fullName': fullNameCtrl.text.trim(),
                    'password': passwordCtrl.text,
                    'role': role,
                    'studentCode': studentCodeCtrl.text.trim(),
                  });
                  _loadUsers();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Thêm người dùng thành công!'), backgroundColor: AppTheme.success),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
                  );
                }
              },
              child: const Text('Tạo tài khoản'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Tài khoản'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Filter row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Tất cả'),
                    selected: _selectedRoleFilter == 'All',
                    onSelected: (_) {
                      setState(() => _selectedRoleFilter = 'All');
                      _loadUsers();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Admin'),
                    selected: _selectedRoleFilter == 'Admin',
                    onSelected: (_) {
                      setState(() => _selectedRoleFilter = 'Admin');
                      _loadUsers();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Giảng viên'),
                    selected: _selectedRoleFilter == 'Lecturer',
                    onSelected: (_) {
                      setState(() => _selectedRoleFilter = 'Lecturer');
                      _loadUsers();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sinh viên'),
                    selected: _selectedRoleFilter == 'Student',
                    onSelected: (_) {
                      setState(() => _selectedRoleFilter = 'Student');
                      _loadUsers();
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _users.length,
                    itemBuilder: (ctx, i) {
                      final u = _users[i];
                      Color roleColor;
                      switch (u.role) {
                        case 'Admin':
                          roleColor = AppTheme.danger;
                          break;
                        case 'Lecturer':
                          roleColor = AppTheme.success;
                          break;
                        default:
                          roleColor = AppTheme.primary;
                          break;
                      }

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: roleColor.withAlpha(25),
                            child: Icon(Icons.person, color: roleColor),
                          ),
                          title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${u.username} • ${u.email}\nMSSV: ${u.studentCode ?? "N/A"}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: roleColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              u.role,
                              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

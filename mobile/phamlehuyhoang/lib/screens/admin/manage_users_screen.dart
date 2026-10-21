import 'package:flutter/material.dart';

import '../../models/auth_models.dart';
import '../../services/api_client.dart';
import 'management_widgets.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  List<UserDto> _users = [];
  bool _loading = true;
  bool _changing = false;
  String? _error;
  String _roleFilter = 'All';
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final version = ++_loadVersion;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiClient.get(
        _roleFilter == 'All' ? '/api/users' : '/api/users?role=$_roleFilter',
      );
      if (mounted && version == _loadVersion) {
        setState(
          () => _users = (result as List)
              .map((u) => UserDto.fromJson(u))
              .toList(),
        );
      }
    } catch (error) {
      if (mounted && version == _loadVersion) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && version == _loadVersion) setState(() => _loading = false);
    }
  }

  Future<void> _edit([UserDto? user]) async {
    var role = user?.role ?? 'Student';
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManagementFormDialog(
        title: user == null ? 'Thêm người dùng mới' : 'Sửa tài khoản',
        initial: {
          'username': user?.username ?? '',
          'email': user?.email ?? '',
          'fullName': user?.fullName ?? '',
          'studentCode': user?.studentCode ?? '',
          'password': '',
        },
        fields: (_, c, update) => [
          managementField(
            c['username']!,
            'Tên đăng nhập *',
            enabled: user == null,
          ),
          managementField(
            c['email']!,
            'Email *',
            keyboardType: TextInputType.emailAddress,
            validate: (v) =>
                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v?.trim() ?? '')
                ? null
                : 'Email không hợp lệ',
          ),
          managementField(c['fullName']!, 'Họ và tên *'),
          managementField(
            c['studentCode']!,
            'MSSV (nếu là SV)',
            validate: (_) => null,
          ),
          if (user == null)
            managementField(
              c['password']!,
              'Mật khẩu *',
              obscure: true,
              validate: (v) => (v?.length ?? 0) < 6
                  ? 'Mật khẩu phải có ít nhất 6 ký tự'
                  : null,
            ),
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(labelText: 'Vai trò *'),
            items: const [
              DropdownMenuItem(value: 'Admin', child: Text('Admin')),
              DropdownMenuItem(value: 'Lecturer', child: Text('Giảng viên')),
              DropdownMenuItem(value: 'Student', child: Text('Sinh viên')),
            ],
            onChanged: (value) {
              if (value != null) update(() => role = value);
            },
          ),
          if (user != null)
            Text(
              user.isActive
                  ? 'Trạng thái: Đang hoạt động'
                  : 'Trạng thái: Đã khóa',
            ),
        ],
        save: (c) async {
          final body = <String, dynamic>{
            'email': c['email']!.text.trim(),
            'fullName': c['fullName']!.text.trim(),
            'role': role,
            'studentCode': c['studentCode']!.text.trim().isEmpty
                ? null
                : c['studentCode']!.text.trim(),
          };
          if (user == null) {
            body.addAll({
              'username': c['username']!.text.trim(),
              'password': c['password']!.text,
            });
            await ApiClient.post('/api/users', body);
          } else {
            body['isActive'] = user.isActive;
            await ApiClient.put('/api/users/${user.id}', body);
          }
        },
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _toggle(UserDto user) async {
    final action = user.isActive ? 'Khóa' : 'Kích hoạt';
    if (!await confirmManagementAction(
      context,
      '$action tài khoản?',
      '$action tài khoản ${user.username}? Lịch sử điểm danh được giữ lại.',
      action: 'Xác nhận',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _changing = true);
    try {
      final result = await ApiClient.delete('/api/users/${user.id}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                (result['isActive'] == true
                    ? 'Đã kích hoạt tài khoản'
                    : 'Đã khóa tài khoản'),
          ),
        ),
      );
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Quản lý Tài khoản'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _loading ? null : () => _edit(),
      tooltip: 'Thêm tài khoản',
      child: const Icon(Icons.add),
    ),
    body: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              for (final entry in {
                'All': 'Tất cả',
                'Admin': 'Admin',
                'Lecturer': 'Giảng viên',
                'Student': 'Sinh viên',
              }.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: _roleFilter == entry.key,
                    onSelected: (_) {
                      _roleFilter = entry.key;
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? managementError(_error!, _load)
              : _users.isEmpty
              ? const Center(child: Text('Không có tài khoản phù hợp'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final user = _users[i];
                    return Card(
                      child: ListTile(
                        title: Text(user.fullName),
                        subtitle: Text(
                          '${user.username} • ${user.email}\n${user.role} • ${user.isActive ? 'Đang hoạt động' : 'Đã khóa'}\nMSSV: ${user.studentCode ?? '—'}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Sửa tài khoản',
                              onPressed: _changing ? null : () => _edit(user),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: user.isActive
                                  ? 'Khóa tài khoản'
                                  : 'Kích hoạt tài khoản',
                              onPressed: _changing ? null : () => _toggle(user),
                              icon: Icon(
                                user.isActive
                                    ? Icons.lock_outline
                                    : Icons.lock_open,
                              ),
                            ),
                          ],
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

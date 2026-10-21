import 'package:flutter/material.dart';
import '../../models/class_models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});

  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  List<SubjectDto> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/api/subjects');
      if (mounted) {
        setState(() {
          _subjects = (res as List).map((s) => SubjectDto.fromJson(s)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateSubjectDialog() async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: '3');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm môn học mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Mã môn học * (VD: INT3102)')),
            const SizedBox(height: 10),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên môn học *')),
            const SizedBox(height: 10),
            TextField(controller: creditsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số tín chỉ *')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (codeCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiClient.post('/api/subjects', {
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'name': nameCtrl.text.trim(),
                  'credits': int.tryParse(creditsCtrl.text) ?? 3,
                });
                _loadSubjects();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thêm môn học thành công!'), backgroundColor: AppTheme.success),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
                  );
                }
              }
            },
            child: const Text('Tạo môn học'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Môn học'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSubjects),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSubjectDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _subjects.length,
              itemBuilder: (ctx, i) {
                final s = _subjects[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.secondary.withAlpha(25),
                      child: Text('${s.credits} TC', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.secondary)),
                    ),
                    title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Mã môn: ${s.code}'),
                  ),
                );
              },
            ),
    );
  }
}

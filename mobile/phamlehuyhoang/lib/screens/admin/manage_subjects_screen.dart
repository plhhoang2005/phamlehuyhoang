import 'package:flutter/material.dart';

import '../../models/class_models.dart';
import '../../services/api_client.dart';
import 'management_widgets.dart';

class ManageSubjectsScreen extends StatefulWidget {
  const ManageSubjectsScreen({super.key});
  @override
  State<ManageSubjectsScreen> createState() => _ManageSubjectsScreenState();
}

class _ManageSubjectsScreenState extends State<ManageSubjectsScreen> {
  List<SubjectDto> _subjects = [];
  bool _loading = true;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiClient.get('/api/subjects');
      if (mounted) {
        setState(
          () => _subjects = (result as List)
              .map((s) => SubjectDto.fromJson(s))
              .toList(),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([SubjectDto? subject]) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManagementFormDialog(
        title: subject == null ? 'Thêm môn học mới' : 'Sửa môn học',
        initial: {
          'code': subject?.code ?? '',
          'name': subject?.name ?? '',
          'credits': '${subject?.credits ?? 3}',
        },
        fields: (_, c, _) => [
          managementField(c['code']!, 'Mã môn học *'),
          managementField(c['name']!, 'Tên môn học *'),
          managementField(
            c['credits']!,
            'Số tín chỉ *',
            keyboardType: TextInputType.number,
            validate: (v) => integerValue(v),
          ),
        ],
        save: (c) async {
          final body = {
            'code': c['code']!.text.trim().toUpperCase(),
            'name': c['name']!.text.trim(),
            'credits': int.parse(c['credits']!.text.trim()),
          };
          if (subject == null) {
            await ApiClient.post('/api/subjects', body);
          } else {
            await ApiClient.put('/api/subjects/${subject.id}', body);
          }
        },
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(SubjectDto subject) async {
    if (!await confirmManagementAction(
      context,
      'Xóa môn học?',
      'Xóa ${subject.code} — ${subject.name}? Môn đang có lớp học không thể xóa.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _deleting = true);
    try {
      await ApiClient.delete('/api/subjects/${subject.id}');
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Quản lý Môn học'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _loading ? null : () => _edit(),
      tooltip: 'Thêm môn học',
      child: const Icon(Icons.add),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? managementError(_error!, _load)
        : _subjects.isEmpty
        ? const Center(child: Text('Chưa có môn học. Nhấn + để thêm.'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _subjects.length,
            itemBuilder: (_, i) {
              final subject = _subjects[i];
              return Card(
                child: ListTile(
                  title: Text(subject.name),
                  subtitle: Text(
                    '${subject.code} • ${subject.credits} tín chỉ',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sửa môn học',
                        onPressed: _deleting ? null : () => _edit(subject),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Xóa môn học',
                        onPressed: _deleting ? null : () => _delete(subject),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}

import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../models/class_models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import 'class_enrollment_screen.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  List<CourseClassDto> _classes = [];
  List<SubjectDto> _subjects = [];
  List<UserDto> _lecturers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      final resC = await ApiClient.get('/api/courseclasses');
      final resS = await ApiClient.get('/api/subjects');
      final resL = await ApiClient.get('/api/users?role=Lecturer');

      if (mounted) {
        setState(() {
          _classes = (resC as List).map((c) => CourseClassDto.fromJson(c)).toList();
          _subjects = (resS as List).map((s) => SubjectDto.fromJson(s)).toList();
          _lecturers = (resL as List).map((u) => UserDto.fromJson(u)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateClassDialog() async {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo ít nhất 1 Môn học trước khi tạo Lớp học phần')),
      );
      return;
    }

    final codeCtrl = TextEditingController(text: '261_INT3101_02');
    String selectedSubjectId = _subjects.first.id;
    String? selectedLecturerId = _lecturers.isNotEmpty ? _lecturers.first.id : null;
    final totalSessionsCtrl = TextEditingController(text: '15');
    final maxAbsencesCtrl = TextEditingController(text: '3');
    final radiusCtrl = TextEditingController(text: '100');
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo Lớp học phần mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Mã lớp *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedSubjectId,
                  decoration: const InputDecoration(labelText: 'Môn học *'),
                  items: _subjects.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.code} - ${s.name}'))).toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedSubjectId = v);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedLecturerId,
                  decoration: const InputDecoration(labelText: 'Phân công Giảng viên'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Chưa phân công')),
                    ..._lecturers.map((l) => DropdownMenuItem(value: l.id, child: Text(l.fullName))),
                  ],
                  onChanged: (v) => setDialogState(() => selectedLecturerId = v),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalSessionsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tổng số buổi (N) *'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: maxAbsencesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tối đa vắng (L) *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: radiusCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bán kính GPS mặc định (mét)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiClient.post('/api/courseclasses', {
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'subjectId': selectedSubjectId,
                    'lecturerId': selectedLecturerId,
                    'totalSessions': int.tryParse(totalSessionsCtrl.text) ?? 15,
                    'maxAbsencesAllowed': int.tryParse(maxAbsencesCtrl.text) ?? 3,
                    'defaultRadiusMeters': double.tryParse(radiusCtrl.text) ?? 100.0,
                  });
                  _loadAll();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Tạo lớp học phần thành công!'), backgroundColor: AppTheme.success),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
                  );
                }
              },
              child: const Text('Tạo lớp'),
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
        title: const Text('Quản lý Lớp học phần'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateClassDialog,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _classes.length,
              itemBuilder: (ctx, i) {
                final c = _classes[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${c.code} — ${c.subjectName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Giảng viên: ${c.lecturerName ?? "Chưa phân công"}',
                          style: TextStyle(
                            color: c.lecturerName != null ? AppTheme.primary : AppTheme.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Tổng buổi N: ${c.totalSessions} • Cho phép vắng L: ${c.maxAbsencesAllowed} • Bán kính: ${c.defaultRadiusMeters.toStringAsFixed(0)}m'),
                        const Divider(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${c.enrolledCount} sinh viên đã ghi danh', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              icon: const Icon(Icons.group_add, size: 16),
                              label: const Text('Ghi danh SV'),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ClassEnrollmentScreen(courseClass: c)),
                                );
                                _loadAll();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

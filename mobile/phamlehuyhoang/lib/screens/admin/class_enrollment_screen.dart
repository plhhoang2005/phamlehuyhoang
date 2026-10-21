import 'package:flutter/material.dart';
import '../../models/auth_models.dart';
import '../../models/class_models.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';

class ClassEnrollmentScreen extends StatefulWidget {
  final CourseClassDto courseClass;

  const ClassEnrollmentScreen({super.key, required this.courseClass});

  @override
  State<ClassEnrollmentScreen> createState() => _ClassEnrollmentScreenState();
}

class _ClassEnrollmentScreenState extends State<ClassEnrollmentScreen> {
  List<EnrollmentDto> _enrollments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/api/courseclasses/${widget.courseClass.id}/students');
      if (mounted) {
        setState(() {
          _enrollments = (res as List).map((e) => EnrollmentDto.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddStudentDialog() async {
    List<UserDto> allStudents = [];
    try {
      final res = await ApiClient.get('/api/users?role=Student');
      allStudents = (res as List).map((u) => UserDto.fromJson(u)).toList();
    } catch (_) {}

    final enrolledIds = _enrollments.map((e) => e.studentId).toSet();
    final availableStudents = allStudents.where((s) => !enrolledIds.contains(s.id)).toList();

    if (availableStudents.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tất cả sinh viên trong hệ thống đều đã có trong lớp này')),
      );
      return;
    }

    String selectedStudentId = availableStudents.first.id;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Thêm sinh viên vào lớp'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedStudentId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Chọn sinh viên *'),
            items: availableStudents.map((s) {
              return DropdownMenuItem(
                value: s.id,
                child: Text('${s.fullName} (${s.studentCode ?? s.username})'),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setDialogState(() => selectedStudentId = v);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiClient.post('/api/courseclasses/${widget.courseClass.id}/enroll', {
                    'studentId': selectedStudentId,
                  });
                  _loadEnrollments();
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Ghi danh thành công!'), backgroundColor: AppTheme.success),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
                    );
                  }
                }
              },
              child: const Text('Thêm vào lớp'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUnenroll(EnrollmentDto enrollment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa sinh viên?'),
        content: Text('Bạn có chắc muốn xóa sinh viên ${enrollment.studentName} khỏi lớp này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.delete('/api/courseclasses/${widget.courseClass.id}/enroll/${enrollment.studentId}');
      _loadEnrollments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa sinh viên khỏi lớp')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sinh viên — ${widget.courseClass.code}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEnrollments),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty
              ? const Center(child: Text('Chưa có sinh viên nào trong lớp này'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _enrollments.length,
                  itemBuilder: (ctx, i) {
                    final e = _enrollments[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(e.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('MSSV: ${e.studentCode ?? "N/A"} • ${e.studentEmail}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                          tooltip: 'Xóa khỏi lớp',
                          onPressed: () => _handleUnenroll(e),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

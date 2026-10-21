import 'package:flutter/material.dart';

import '../../models/auth_models.dart';
import '../../models/class_models.dart';
import '../../services/api_client.dart';
import '../../services/location_service.dart';
import 'class_enrollment_screen.dart';
import 'management_widgets.dart';

class ManageClassesScreen extends StatefulWidget {
  const ManageClassesScreen({super.key});
  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  List<CourseClassDto> _classes = [];
  List<SubjectDto> _subjects = [];
  List<UserDto> _lecturers = [];
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
      final classes = await ApiClient.get('/api/courseclasses');
      final subjects = await ApiClient.get('/api/subjects');
      final lecturers = await ApiClient.get('/api/users?role=Lecturer');
      if (mounted) {
        setState(() {
          _classes = (classes as List)
              .map((c) => CourseClassDto.fromJson(c))
              .toList();
          _subjects = (subjects as List)
              .map((s) => SubjectDto.fromJson(s))
              .toList();
          _lecturers = (lecturers as List)
              .map((u) => UserDto.fromJson(u))
              .toList();
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([CourseClassDto? course]) async {
    if (_subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tạo môn học trước khi tạo lớp')),
      );
      return;
    }
    var subjectId = course?.subjectId ?? _subjects.first.id;
    var lecturerId = course?.lecturerId ?? '';
    var locating = false;
    String? locationError;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ManagementFormDialog(
        title: course == null ? 'Tạo lớp học phần' : 'Sửa lớp học',
        initial: {
          'code': course?.code ?? '',
          'total': '${course?.totalSessions ?? 15}',
          'max': '${course?.maxAbsencesAllowed ?? 3}',
          'latitude': course?.defaultLatitude.toString() ?? '',
          'longitude': course?.defaultLongitude.toString() ?? '',
          'radius': '${course?.defaultRadiusMeters ?? 100}',
        },
        fields: (dialogContext, c, update) => [
          managementField(c['code']!, 'Mã lớp *'),
          DropdownButtonFormField<String>(
            initialValue: subjectId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Môn học *'),
            items: _subjects
                .map(
                  (s) => DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.code} — ${s.name}'),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) update(() => subjectId = v);
            },
          ),
          DropdownButtonFormField<String>(
            initialValue: lecturerId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Giảng viên'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Chưa phân công')),
              if (lecturerId.isNotEmpty &&
                  !_lecturers.any((l) => l.id == lecturerId))
                DropdownMenuItem(
                  value: lecturerId,
                  child: Text(course?.lecturerName ?? 'Giảng viên hiện tại'),
                ),
              ..._lecturers.map(
                (l) => DropdownMenuItem(
                  value: l.id,
                  child: Text('${l.fullName}${l.isActive ? '' : ' (đã khóa)'}'),
                ),
              ),
            ],
            onChanged: (v) => update(() => lecturerId = v ?? ''),
          ),
          managementField(
            c['total']!,
            'Tổng số buổi (N) *',
            keyboardType: TextInputType.number,
            validate: (v) => integerValue(v),
          ),
          managementField(
            c['max']!,
            'Tối đa vắng (L) *',
            keyboardType: TextInputType.number,
            validate: (v) => integerValue(
              v,
              min: 0,
              max: int.tryParse(c['total']!.text.trim()) ?? 0,
            ),
          ),
          managementField(
            c['latitude']!,
            'Vĩ độ mặc định *',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            validate: (v) => coordinateValue(v, 90, 'Vĩ độ'),
          ),
          managementField(
            c['longitude']!,
            'Kinh độ mặc định *',
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            validate: (v) => coordinateValue(v, 180, 'Kinh độ'),
          ),
          OutlinedButton.icon(
            onPressed: locating
                ? null
                : () async {
                    update(() {
                      locating = true;
                      locationError = null;
                    });
                    try {
                      final position =
                          await LocationService.getCurrentLocation();
                      if (!dialogContext.mounted) return;
                      c['latitude']!.text = position.latitude.toString();
                      c['longitude']!.text = position.longitude.toString();
                    } catch (error) {
                      if (dialogContext.mounted) {
                        update(() => locationError = error.toString());
                      }
                    } finally {
                      if (dialogContext.mounted) update(() => locating = false);
                    }
                  },
            icon: const Icon(Icons.my_location),
            label: Text(locating ? 'Đang lấy GPS…' : 'Dùng vị trí hiện tại'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              final lat = double.tryParse(c['latitude']!.text);
              final lng = double.tryParse(c['longitude']!.text);
              if (lat != null && lng != null) {
                LocationService.openGoogleMaps(lat, lng, label: c['code']!.text);
              }
            },
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Xem tọa độ trên Google Maps', style: TextStyle(fontSize: 12)),
          ),
          if (locationError != null)
            Text(
              locationError!,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          managementField(
            c['radius']!,
            'Bán kính mặc định (m) *',
            keyboardType: TextInputType.number,
            validate: radiusValue,
          ),
        ],
        save: (c) async {
          final body = {
            'code': c['code']!.text.trim().toUpperCase(),
            'subjectId': subjectId,
            'lecturerId': lecturerId.isEmpty ? null : lecturerId,
            'totalSessions': int.parse(c['total']!.text.trim()),
            'maxAbsencesAllowed': int.parse(c['max']!.text.trim()),
            'defaultLatitude': double.parse(c['latitude']!.text.trim()),
            'defaultLongitude': double.parse(c['longitude']!.text.trim()),
            'defaultRadiusMeters': double.parse(c['radius']!.text.trim()),
          };
          if (course == null) {
            await ApiClient.post('/api/courseclasses', body);
          } else {
            await ApiClient.put('/api/courseclasses/${course.id}', body);
          }
        },
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(CourseClassDto course) async {
    if (!await confirmManagementAction(
      context,
      'Xóa lớp học?',
      'Xóa lớp ${course.code}? Máy chủ sẽ từ chối nếu lớp đã có dữ liệu cần giữ lại.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _deleting = true);
    try {
      await ApiClient.delete('/api/courseclasses/${course.id}');
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
      title: const Text('Quản lý Lớp học phần'),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _loading ? null : () => _edit(),
      tooltip: 'Tạo lớp học',
      child: const Icon(Icons.add),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? managementError(_error!, _load)
        : _classes.isEmpty
        ? const Center(child: Text('Chưa có lớp học. Nhấn + để tạo.'))
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _classes.length,
            itemBuilder: (_, i) {
              final course = _classes[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${course.code} — ${course.subjectName}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Giảng viên: ${course.lecturerName ?? 'Chưa phân công'}',
                      ),
                      Text(
                        'Tổng buổi: ${course.totalSessions} • Vắng tối đa: ${course.maxAbsencesAllowed}',
                      ),
                      Text(
                        'GPS: ${course.defaultLatitude}, ${course.defaultLongitude} • ${course.defaultRadiusMeters}m',
                      ),
                      Text('${course.enrolledCount} sinh viên đã ghi danh'),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClassEnrollmentScreen(
                                    courseClass: course,
                                  ),
                                ),
                              );
                              if (mounted) _load();
                            },
                            icon: const Icon(Icons.group_add),
                            label: const Text('Ghi danh SV'),
                          ),
                          IconButton(
                            tooltip: 'Sửa lớp học',
                            onPressed: _deleting ? null : () => _edit(course),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Xóa lớp học',
                            onPressed: _deleting ? null : () => _delete(course),
                            icon: const Icon(Icons.delete_outline),
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

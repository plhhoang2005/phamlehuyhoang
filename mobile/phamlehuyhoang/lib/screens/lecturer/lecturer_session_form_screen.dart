import 'package:flutter/material.dart';

import '../../models/class_models.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../admin/management_widgets.dart';

class LecturerSessionFormScreen extends StatefulWidget {
  final CourseClassDto courseClass;
  final ClassSessionDto? session;
  final int nextSessionNumber;

  const LecturerSessionFormScreen({
    super.key,
    required this.courseClass,
    this.session,
    this.nextSessionNumber = 1,
  });

  @override
  State<LecturerSessionFormScreen> createState() =>
      _LecturerSessionFormScreenState();
}

class _LecturerSessionFormScreenState extends State<LecturerSessionFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.session?.title ?? '');
  late final _number = TextEditingController(
    text: '${widget.session?.sessionNumber ?? widget.nextSessionNumber}',
  );
  late final _room = TextEditingController(
    text: widget.session?.roomName ?? '',
  );
  late final _latitude = TextEditingController(
    text: widget.session?.latitude.toString() ?? '',
  );
  late final _longitude = TextEditingController(
    text: widget.session?.longitude.toString() ?? '',
  );
  late final _radius = TextEditingController(
    text:
        '${widget.session?.radiusMeters ?? widget.courseClass.defaultRadiusMeters}',
  );
  late DateTime _start =
      widget.session?.startTimeUtc.toLocal() ?? DateTime.now();
  late DateTime _end =
      widget.session?.endTimeUtc.toLocal() ??
      _start.add(const Duration(minutes: 90));
  bool _saving = false;
  bool _locating = false;
  String? _error;
  String? _locationError;
  String? _resolvedAddress;
  double? _accuracy;

  @override
  void initState() {
    super.initState();
    _resolveInitialAddress();
  }

  void _resolveInitialAddress() {
    final lat = double.tryParse(_latitude.text);
    final lng = double.tryParse(_longitude.text);
    if (lat != null && lng != null) {
      LocationService.getAddressFromCoordinates(lat, lng).then((addr) {
        if (mounted) setState(() => _resolvedAddress = addr);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _number,
      _room,
      _latitude,
      _longitude,
      _radius,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickTime(bool start) async {
    final current = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    setState(() {
      final chosen = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (start) {
        _start = chosen;
      } else {
        _end = chosen;
      }
    });
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _locationError = null;
    });
    try {
      final position = await LocationService.getCurrentLocation();
      if (!mounted) return;
      _latitude.text = position.latitude.toString();
      _longitude.text = position.longitude.toString();
      _accuracy = position.accuracy;
      final addr = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() => _resolvedAddress = addr);
      }
    } catch (error) {
      if (mounted) setState(() => _locationError = error.toString());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'Giờ kết thúc phải sau giờ bắt đầu');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.session;
      if (existing == null) {
        await AttendanceService.createSession(
          courseClassId: widget.courseClass.id,
          sessionNumber: int.parse(_number.text.trim()),
          title: _title.text,
          startTime: _start,
          endTime: _end,
          roomName: _room.text,
          latitude: double.parse(_latitude.text.trim()),
          longitude: double.parse(_longitude.text.trim()),
          radiusMeters: double.parse(_radius.text.trim()),
        );
      } else {
        await AttendanceService.updateSession(
          sessionId: existing.id,
          sessionNumber: int.parse(_number.text.trim()),
          title: _title.text,
          startTime: _start,
          endTime: _end,
          roomName: _room.text,
          latitude: double.parse(_latitude.text.trim()),
          longitude: double.parse(_longitude.text.trim()),
          radiusMeters: double.parse(_radius.text.trim()),
          isCancelled: existing.isCancelled,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _saving = false;
        });
      }
    }
  }

  String _format(DateTime time) =>
      '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null ? 'Tạo buổi học' : 'Sửa buổi học'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${widget.courseClass.code} • ${widget.courseClass.subjectName}',
            ),
            const SizedBox(height: 12),
            managementField(
              _number,
              'Số buổi *',
              keyboardType: TextInputType.number,
              validate: (v) =>
                  integerValue(v, max: widget.courseClass.totalSessions),
            ),
            const SizedBox(height: 12),
            managementField(_title, 'Tiêu đề *'),
            const SizedBox(height: 12),
            managementField(_room, 'Phòng học *'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Bắt đầu (giờ địa phương)'),
              subtitle: Text(_format(_start)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _saving ? null : () => _pickTime(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kết thúc (giờ địa phương)'),
              subtitle: Text(_format(_end)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _saving ? null : () => _pickTime(false),
            ),
            const Text(
              'Nhập tọa độ phòng học hoặc dùng GPS khi bạn đang ở phòng học.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('session-latitude'),
              controller: _latitude,
              decoration: const InputDecoration(labelText: 'Vĩ độ *'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (v) => coordinateValue(v, 90, 'Vĩ độ'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('session-longitude'),
              controller: _longitude,
              decoration: const InputDecoration(labelText: 'Kinh độ *'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              validator: (v) => coordinateValue(v, 180, 'Kinh độ'),
            ),
            OutlinedButton.icon(
              onPressed: _saving || _locating ? null : _locate,
              icon: const Icon(Icons.my_location),
              label: Text(_locating ? 'Đang lấy GPS…' : 'Dùng vị trí hiện tại'),
            ),
            if (_resolvedAddress != null) ...[
              const SizedBox(height: 8),
              Card(
                color: const Color(0xFFF1F5F9),
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Địa điểm / Địa chỉ thực tế:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _resolvedAddress!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_accuracy != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.gps_fixed, size: 14, color: AppTheme.success),
                            const SizedBox(width: 4),
                            Text(
                              'Độ chính xác GPS: ±${_accuracy!.toStringAsFixed(1)}m (Tín hiệu tốt)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primary),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Mở xem trực tiếp trên Google Maps'),
                          onPressed: () {
                            final lat = double.tryParse(_latitude.text);
                            final lng = double.tryParse(_longitude.text);
                            if (lat != null && lng != null) {
                              LocationService.openGoogleMaps(lat, lng, label: _room.text);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_locationError != null)
              Text(
                _locationError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            managementField(
              _radius,
              'Bán kính (m) *',
              keyboardType: TextInputType.number,
              validate: radiusValue,
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: _saving || _locating ? null : _save,
              child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
            ),
          ],
        ),
      ),
    ),
  );
}

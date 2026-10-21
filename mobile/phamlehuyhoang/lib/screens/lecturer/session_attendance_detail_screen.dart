import 'package:flutter/material.dart';
import '../../models/attendance_models.dart';
import '../../models/class_models.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class SessionAttendanceDetailScreen extends StatefulWidget {
  final ClassSessionDto session;

  const SessionAttendanceDetailScreen({super.key, required this.session});

  @override
  State<SessionAttendanceDetailScreen> createState() => _SessionAttendanceDetailScreenState();
}

class _SessionAttendanceDetailScreenState extends State<SessionAttendanceDetailScreen> {
  List<AttendanceRecordDto> _records = [];
  bool _isLoading = true;
  bool _isFinalized = false;
  String? _roomAddress;

  @override
  void initState() {
    super.initState();
    _isFinalized = widget.session.isFinalized;
    _loadRecords();
    _resolveAddress();
  }

  void _resolveAddress() {
    LocationService.getAddressFromCoordinates(
      widget.session.latitude,
      widget.session.longitude,
    ).then((addr) {
      if (mounted) setState(() => _roomAddress = addr);
    });
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final records = await AttendanceService.getSessionAttendance(widget.session.id);
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFinalize() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chốt kết quả buổi học?'),
        content: const Text(
          'Khi chốt kết quả, toàn bộ sinh viên trong lớp chưa có bản ghi điểm danh sẽ tự động được ghi nhận VẮNG KHÔNG PHÉP. Bạn có chắc chắn muốn chốt?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Chốt kết quả ngay'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await AttendanceService.finalizeSession(widget.session.id);
      setState(() => _isFinalized = true);
      _loadRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã chốt kết quả điểm danh thành công!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
      );
    }
  }

  Future<void> _showAdjustDialog(AttendanceRecordDto record) async {
    AttendanceStatus selectedStatus = record.status;
    final reasonCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Điều chỉnh: ${record.studentName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chọn trạng thái mới:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              DropdownButtonFormField<AttendanceStatus>(
                initialValue: selectedStatus,
                items: AttendanceStatus.values.map((s) {
                  return DropdownMenuItem(value: s, child: Text(s.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedStatus = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lý do điều chỉnh * (Lưu lịch sử)',
                  hintText: 'Nhập lý do điều chỉnh...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập lý do điều chỉnh để lưu lịch sử')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await AttendanceService.adjustAttendance(
                    recordId: record.id,
                    newStatus: selectedStatus,
                    reason: reason,
                  );
                  _loadRecords();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Điều chỉnh điểm danh thành công'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppTheme.danger),
                  );
                }
              },
              child: const Text('Lưu thay đổi'),
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
        title: Text('Buổi ${widget.session.sessionNumber} — Kết quả'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecords),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top control bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isFinalized ? 'Trạng thái: ĐÃ CHỐT KẾT QUẢ' : 'Trạng thái: CHƯA CHỐT',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isFinalized ? AppTheme.success : AppTheme.warning,
                          ),
                        ),
                      ),
                      if (!_isFinalized)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.danger,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Chốt buổi học', style: TextStyle(fontSize: 13)),
                          onPressed: _handleFinalize,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppTheme.danger),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.session.roomName} • ${_roomAddress ?? "Tọa độ: ${widget.session.latitude}, ${widget.session.longitude}"} (Bán kính: ${widget.session.radiusMeters.toStringAsFixed(0)}m)',
                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ),
                      InkWell(
                        onTap: () => LocationService.openGoogleMaps(
                          widget.session.latitude,
                          widget.session.longitude,
                          label: widget.session.roomName,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.map, size: 14, color: AppTheme.primary),
                              SizedBox(width: 4),
                              Text(
                                'Bản đồ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                Expanded(
                  child: _records.isEmpty
                      ? const Center(child: Text('Chưa có sinh viên nào điểm danh trong buổi học này'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _records.length,
                          itemBuilder: (ctx, i) {
                            final r = _records[i];
                            Color statusColor;
                            switch (r.status) {
                              case AttendanceStatus.present:
                                statusColor = AppTheme.success;
                                break;
                              case AttendanceStatus.late:
                                statusColor = AppTheme.warning;
                                break;
                              case AttendanceStatus.excused:
                                statusColor = Colors.blue;
                                break;
                              case AttendanceStatus.absent:
                                statusColor = AppTheme.danger;
                                break;
                            }

                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: statusColor.withAlpha(25),
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.studentName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(25),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        r.status.label,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Text('MSSV: ${r.studentCode ?? "N/A"} • PT: ${r.checkInMethod}'),
                                    if (r.checkedInAtUtc != null)
                                      Text('Giờ: ${r.checkedInAtUtc!.toLocal().toString().substring(11, 19)}')
                                    else
                                      const Text('Không có giờ điểm danh'),
                                    if (r.distanceMeters != null)
                                      Text('Khoảng cách: ${r.distanceMeters!.toStringAsFixed(1)}m (Sai số GPS: ${r.accuracyMeters?.toStringAsFixed(1) ?? "?"}m)'),
                                    if (r.note != null && r.note!.isNotEmpty)
                                      Text('Ghi chú: ${r.note}',
                                          style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.primary, size: 20),
                                  tooltip: 'Điều chỉnh kết quả có lưu lịch sử',
                                  onPressed: () => _showAdjustDialog(r),
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

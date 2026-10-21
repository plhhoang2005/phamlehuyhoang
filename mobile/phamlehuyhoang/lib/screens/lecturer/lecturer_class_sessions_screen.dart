import 'package:flutter/material.dart';

import '../../models/class_models.dart';
import '../../services/attendance_service.dart';
import '../admin/management_widgets.dart';
import 'lecturer_session_form_screen.dart';
import 'open_qr_screen.dart';
import 'session_attendance_detail_screen.dart';

class LecturerClassSessionsScreen extends StatefulWidget {
  final CourseClassDto courseClass;
  const LecturerClassSessionsScreen({super.key, required this.courseClass});
  @override
  State<LecturerClassSessionsScreen> createState() =>
      _LecturerClassSessionsScreenState();
}

class _LecturerClassSessionsScreenState
    extends State<LecturerClassSessionsScreen> {
  List<ClassSessionDto> _sessions = [];
  bool _loading = true;
  bool _changing = false;
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
      final sessions = await AttendanceService.getSessionsForClass(
        widget.courseClass.id,
      );
      if (mounted) setState(() => _sessions = sessions);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([ClassSessionDto? session]) async {
    final used = _sessions.map((s) => s.sessionNumber).toSet();
    var next = 1;
    while (used.contains(next) && next <= widget.courseClass.totalSessions) {
      next++;
    }
    if (session == null && next > widget.courseClass.totalSessions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã tạo đủ số buổi của lớp. Hãy sửa buổi hiện có hoặc tăng tổng số buổi.',
          ),
        ),
      );
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LecturerSessionFormScreen(
          courseClass: widget.courseClass,
          session: session,
          nextSessionNumber: next,
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _toggleCancellation(ClassSessionDto session) async {
    final action = session.isCancelled ? 'Khôi phục buổi học' : 'Hủy buổi học';
    if (!await confirmManagementAction(
      context,
      '$action?',
      '$action ${session.sessionNumber}: ${session.title}?',
      action: 'Xác nhận',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _changing = true);
    try {
      await AttendanceService.updateSession(
        sessionId: session.id,
        sessionNumber: session.sessionNumber,
        title: session.title,
        startTime: session.startTimeUtc,
        endTime: session.endTimeUtc,
        roomName: session.roomName,
        latitude: session.latitude,
        longitude: session.longitude,
        radiusMeters: session.radiusMeters,
        isCancelled: !session.isCancelled,
      );
      if (mounted) await _load();
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
      title: Text(widget.courseClass.code),
      actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
    ),
    floatingActionButton: FloatingActionButton(
      tooltip: 'Tạo buổi học',
      onPressed: _loading || _changing ? null : () => _edit(),
      child: const Icon(Icons.add),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? managementError(_error!, _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(12),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (_sessions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Chưa có buổi học. Nhấn + để tạo buổi đầu tiên.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (final session in _sessions)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buổi ${session.sessionNumber}: ${session.title}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${session.roomName} • Bán kính ${session.radiusMeters.toStringAsFixed(0)}m',
                          ),
                          Text(
                            '${session.startTimeUtc.toLocal()} → ${session.endTimeUtc.toLocal()}',
                          ),
                          Text(
                            session.isCancelled
                                ? 'ĐÃ HỦY'
                                : session.isFinalized
                                ? 'ĐÃ CHỐT'
                                : session.hasActiveQrSession
                                ? 'ĐANG MỞ QR'
                                : 'CHƯA CHỐT',
                          ),
                          Wrap(
                            spacing: 4,
                            children: [
                              if (!session.isFinalized) ...[
                                IconButton(
                                  tooltip: 'Sửa buổi học',
                                  onPressed: _changing
                                      ? null
                                      : () => _edit(session),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: session.isCancelled
                                      ? 'Khôi phục buổi học'
                                      : 'Hủy buổi học',
                                  onPressed: _changing
                                      ? null
                                      : () => _toggleCancellation(session),
                                  icon: Icon(
                                    session.isCancelled
                                        ? Icons.restore
                                        : Icons.cancel_outlined,
                                  ),
                                ),
                              ],
                              if (!session.isFinalized && !session.isCancelled)
                                IconButton(
                                  tooltip: 'Mở QR điểm danh',
                                  icon: const Icon(Icons.qr_code),
                                  onPressed: _changing
                                      ? null
                                      : () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => OpenQrScreen(
                                                session: session,
                                                courseClass: widget.courseClass,
                                              ),
                                            ),
                                          );
                                          if (mounted) _load();
                                        },
                                ),
                              if (!session.isCancelled)
                                IconButton(
                                  tooltip: 'Danh sách điểm danh & Chốt',
                                  icon: const Icon(Icons.checklist),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SessionAttendanceDetailScreen(
                                              session: session,
                                            ),
                                      ),
                                    );
                                    if (mounted) _load();
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
  );
}

import 'package:flutter/material.dart';
import '../../models/class_models.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';
import 'open_qr_screen.dart';
import 'session_attendance_detail_screen.dart';

class LecturerClassSessionsScreen extends StatefulWidget {
  final CourseClassDto courseClass;

  const LecturerClassSessionsScreen({super.key, required this.courseClass});

  @override
  State<LecturerClassSessionsScreen> createState() => _LecturerClassSessionsScreenState();
}

class _LecturerClassSessionsScreenState extends State<LecturerClassSessionsScreen> {
  List<ClassSessionDto> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await AttendanceService.getSessionsForClass(widget.courseClass.id);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseClass.code),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSessions),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _sessions.length,
                itemBuilder: (ctx, i) {
                  final s = _sessions[i];
                  Color statusColor;
                  String statusText;

                  if (s.isFinalized) {
                    statusColor = AppTheme.success;
                    statusText = 'ĐÃ CHỐT';
                  } else if (s.hasActiveQrSession) {
                    statusColor = AppTheme.warning;
                    statusText = 'ĐANG MỞ QR';
                  } else {
                    statusColor = Colors.blueGrey;
                    statusText = 'CHƯA CHỐT';
                  }

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        'Buổi ${s.sessionNumber}: ${s.title}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('${s.roomName} • Bán kính ${s.radiusMeters.toStringAsFixed(0)}m'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!s.isFinalized)
                            IconButton(
                              icon: const Icon(Icons.qr_code, color: AppTheme.primary),
                              tooltip: 'Mở QR điểm danh',
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OpenQrScreen(session: s, courseClass: widget.courseClass),
                                  ),
                                );
                                _loadSessions();
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.checklist, color: Colors.black87),
                            tooltip: 'Danh sách điểm danh & Chốt',
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SessionAttendanceDetailScreen(session: s),
                                ),
                              );
                              _loadSessions();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

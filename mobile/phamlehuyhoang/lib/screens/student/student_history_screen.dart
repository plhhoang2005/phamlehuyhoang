import 'package:flutter/material.dart';
import '../../models/attendance_models.dart';
import '../../theme/app_theme.dart';

class StudentHistoryScreen extends StatelessWidget {
  final AttendanceForecastDto forecast;

  const StudentHistoryScreen({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    final records = forecast.sessionRecords;

    return Scaffold(
      appBar: AppBar(title: Text('Lịch sử — ${forecast.classCode}')),
      body: records.isEmpty
          ? const Center(child: Text('Chưa có bản ghi điểm danh nào trong các buổi đã chốt'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: records.length,
              itemBuilder: (ctx, i) {
                final r = records[i];
                Color statusColor;
                IconData statusIcon;

                switch (r.status) {
                  case AttendanceStatus.present:
                    statusColor = AppTheme.success;
                    statusIcon = Icons.check_circle;
                    break;
                  case AttendanceStatus.late:
                    statusColor = AppTheme.warning;
                    statusIcon = Icons.access_time_filled;
                    break;
                  case AttendanceStatus.excused:
                    statusColor = Colors.blue;
                    statusIcon = Icons.assignment_turned_in;
                    break;
                  case AttendanceStatus.absent:
                    statusColor = AppTheme.danger;
                    statusIcon = Icons.cancel;
                    break;
                }

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withAlpha(25),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text(
                      'Buổi ${i + 1}: ${r.status.label}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (r.checkedInAtUtc != null)
                          Text('Thời gian: ${r.checkedInAtUtc!.toLocal().toString().substring(0, 19)}')
                        else
                          const Text('Không có thời gian điểm danh'),
                        if (r.distanceMeters != null)
                          Text('Khoảng cách: ${r.distanceMeters!.toStringAsFixed(1)} m (Sai số GPS: ${r.accuracyMeters?.toStringAsFixed(1) ?? "?"}m)'),
                        if (r.note != null && r.note!.isNotEmpty)
                          Text('Ghi chú: ${r.note}', style: const TextStyle(fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

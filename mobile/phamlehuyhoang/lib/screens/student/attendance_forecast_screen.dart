import 'package:flutter/material.dart';
import '../../models/attendance_models.dart';
import '../../services/attendance_service.dart';
import '../../theme/app_theme.dart';
import 'forecast_simulator_screen.dart';

class AttendanceForecastScreen extends StatefulWidget {
  final AttendanceForecastDto forecast;

  const AttendanceForecastScreen({super.key, required this.forecast});

  @override
  State<AttendanceForecastScreen> createState() => _AttendanceForecastScreenState();
}

class _AttendanceForecastScreenState extends State<AttendanceForecastScreen> {
  late AttendanceForecastDto _forecast;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _forecast = widget.forecast;
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final updated = await AttendanceService.getForecast(_forecast.courseClassId);
      setState(() => _forecast = updated);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = _forecast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dự báo Chuyên cần'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science_outlined),
            tooltip: 'Demo Mô phỏng Kịch bản',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ForecastSimulatorScreen(
                    initialN: f.n,
                    initialM: f.m,
                    initialA: f.a,
                    initialL: f.l,
                    subjectName: f.subjectName,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới số liệu',
            onPressed: _refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.subjectName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('Lớp: ${f.classCode}', style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cảnh báo trạng thái
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: f.isLimitExceeded
                          ? AppTheme.danger.withAlpha(25)
                          : (f.remainingAbsencesAllowed == 0 && f.m < f.n
                              ? AppTheme.warning.withAlpha(25)
                              : AppTheme.success.withAlpha(25)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: f.isLimitExceeded
                            ? AppTheme.danger
                            : (f.remainingAbsencesAllowed == 0 && f.m < f.n
                                ? AppTheme.warning
                                : AppTheme.success),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          f.isLimitExceeded
                              ? Icons.dangerous
                              : (f.remainingAbsencesAllowed == 0 && f.m < f.n
                                  ? Icons.warning
                                  : Icons.check_circle),
                          color: f.isLimitExceeded
                              ? AppTheme.danger
                              : (f.remainingAbsencesAllowed == 0 && f.m < f.n
                                  ? AppTheme.warning
                                  : AppTheme.success),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f.statusDescription,
                            style: TextStyle(
                              color: f.isLimitExceeded
                                  ? AppTheme.danger
                                  : (f.remainingAbsencesAllowed == 0 && f.m < f.n
                                      ? AppTheme.warning
                                      : const Color(0xFF1B5E20)),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút mở Demo Mô phỏng
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.psychology_outlined),
                    label: const Text(
                      '🎮 MỞ DEMO MÔ PHỎNG & DỰ BÁO CẤM THI',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForecastSimulatorScreen(
                            initialN: f.n,
                            initialM: f.m,
                            initialA: f.a,
                            initialL: f.l,
                            subjectName: f.subjectName,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Chỉ số chính
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Tỷ lệ Hiện tại',
                          value: f.currentPercentage != null
                              ? '${f.currentPercentage!.toStringAsFixed(1)}%'
                              : 'Chưa có',
                          color: AppTheme.primary,
                          subText: 'Đã chốt: ${f.m}/${f.n} buổi',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Nếu vắng buổi tới',
                          value: f.nextAbsentPercentage != null
                              ? '${f.nextAbsentPercentage!.toStringAsFixed(1)}%'
                              : 'Hết buổi',
                          color: f.nextAbsentPercentage != null && f.nextAbsentPercentage! < 70
                              ? AppTheme.danger
                              : const Color(0xFFE65100),
                          subText: f.m < f.n ? 'Dự báo buổi ${f.m + 1}' : 'Khóa đã xong',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Số buổi đã vắng (A)',
                          value: '${f.a} buổi',
                          color: f.a > f.l ? AppTheme.danger : Colors.black87,
                          subText: 'Giới hạn cho phép: ${f.l} buổi',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Còn được vắng',
                          value: '${f.remainingAbsencesAllowed} buổi',
                          color: f.remainingAbsencesAllowed == 0 ? AppTheme.danger : AppTheme.success,
                          subText: 'min(N-M, max(0, L-A))',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bảng diễn giải công thức theo kế hoạch
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.functions, color: AppTheme.primary),
                              SizedBox(width: 8),
                              Text('Quy tắc & Công thức tính chuyên cần',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildFormulaRow('Tổng số buổi chính thức (N)', '${f.n} buổi'),
                          _buildFormulaRow('Số buổi đã chốt kết quả (M)', '${f.m} buổi'),
                          _buildFormulaRow('Số buổi vắng tính kỷ luật (A)', '${f.a} buổi'),
                          _buildFormulaRow('Giới hạn vắng tối đa (L)', '${f.l} buổi'),
                          _buildFormulaRow(
                            'Tỷ lệ chuyên cần hiện tại',
                            f.currentPercentage != null
                                ? '(${f.m} - ${f.a}) / ${f.m} = ${f.currentPercentage!.toStringAsFixed(2)}%'
                                : 'Chưa có dữ liệu (M=0)',
                          ),
                          if (f.m < f.n && f.nextAbsentPercentage != null)
                            _buildFormulaRow(
                              'Nếu vắng buổi tiếp theo',
                              '(${f.m} - ${f.a}) / (${f.m} + 1) = ${f.nextAbsentPercentage!.toStringAsFixed(2)}%',
                            ),
                          _buildFormulaRow(
                            'Số buổi còn có thể vắng',
                            'min(${f.n} - ${f.m}, max(0, ${f.l} - ${f.a})) = ${f.remainingAbsencesAllowed} buổi',
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '* Quy định lớp: "Có mặt" và "Đi muộn" được tính tham dự. "Vắng có phép" không làm tăng số buổi bị tính vắng (A).',
                            style: TextStyle(fontSize: 12, color: Colors.black54, fontStyle: FontStyle.italic),
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

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required String subText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(subText, style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildFormulaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

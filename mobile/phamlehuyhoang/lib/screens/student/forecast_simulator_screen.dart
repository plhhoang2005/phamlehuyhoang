import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Màn hình Demo Mô phỏng Động cơ Dự báo & Cảnh báo Cấm thi sớm
class ForecastSimulatorScreen extends StatefulWidget {
  final int initialN;
  final int initialM;
  final int initialA;
  final int initialL;
  final String? subjectName;

  const ForecastSimulatorScreen({
    super.key,
    this.initialN = 15,
    this.initialM = 8,
    this.initialA = 2,
    this.initialL = 3,
    this.subjectName,
  });

  @override
  State<ForecastSimulatorScreen> createState() => _ForecastSimulatorScreenState();
}

class _ForecastSimulatorScreenState extends State<ForecastSimulatorScreen> {
  late int _n; // Tổng số buổi
  late int _m; // Số buổi đã chốt
  late int _a; // Số buổi vắng
  late int _l; // Giới hạn vắng tối đa

  @override
  void initState() {
    super.initState();
    _n = widget.initialN;
    _m = widget.initialM.clamp(1, _n);
    _a = widget.initialA.clamp(0, _m);
    _l = widget.initialL.clamp(1, _n);
  }

  void _applyPreset(int n, int m, int a, int l) {
    setState(() {
      _n = n;
      _l = l.clamp(1, _n);
      _m = m.clamp(1, _n);
      _a = a.clamp(0, _m);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán theo thuật toán của động cơ dự báo
    final currentPercentage = _m > 0 ? ((_m - _a) / _m) * 100 : 100.0;
    final nextAbsentPercentage = _m < _n ? ((_m - _a) / (_m + 1)) * 100 : null;
    final remainingAllowed = (_n - _m < _l - _a ? _n - _m : _l - _a).clamp(0, _n);
    final isBanned = _a > _l;
    final isCritical = !isBanned && _a == _l && _m < _n;
    final isWarning = !isBanned && !isCritical && _a == _l - 1 && _m < _n;

    // Màu sắc và thông báo trạng thái
    final Color statusColor;
    final IconData statusIcon;
    final String statusTitle;
    final String statusDescription;

    if (isBanned) {
      statusColor = AppTheme.danger;
      statusIcon = Icons.cancel;
      statusTitle = '🚨 BÁO ĐỘNG ĐỎ: BỊ CẤM THI';
      statusDescription =
          'Sinh viên đã vắng $_a/$_l buổi tối đa cho phép. Đã vượt quá giới hạn và bị đình chỉ thi học phần theo Quy chế Đào tạo!';
    } else if (isCritical) {
      statusColor = const Color(0xFFE65100);
      statusIcon = Icons.error;
      statusTitle = '⚠️ BÁO ĐỘNG CAO: HẾT LƯỢT VẮNG';
      statusDescription =
          'Sinh viên đã chạm trần ($_a/$_l buổi). Bất kỳ lần vắng nào tiếp theo sẽ dẫn tới CẤM THI ngay lập tức!';
    } else if (isWarning) {
      statusColor = const Color(0xFFF57F17);
      statusIcon = Icons.warning_amber_rounded;
      statusTitle = '⚡ CẢNH BÁO NGUY CƠ: SÁT NGƯỠNG';
      statusDescription =
          'Sinh viên đã vắng $_a buổi. Chỉ còn DUY NHẤT 1 buổi vắng được phép. Hãy chú ý đi học đầy đủ!';
    } else {
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle;
      statusTitle = '✅ TRẠNG THÁI AN TOÀN';
      statusDescription =
          'Chuyên cần rất tốt ($_a/$_l buổi vắng). Sinh viên còn được phép vắng tối đa $remainingAllowed buổi nữa mà vẫn hợp lệ.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Động cơ Dự báo Cấm thi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Đặt lại mặc định',
            onPressed: () => _applyPreset(15, 8, 2, 3),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Tiêu đề Demo
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.psychology_outlined, color: Colors.white, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mô phỏng Động cơ Dự báo AI / Thuật toán',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Thử nghiệm kịch bản cấm thi & phân tích nguy cơ theo thời gian thực',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card Cảnh báo Phản ứng Thời gian thực
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          statusTitle,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isBanned ? 'CẤM THI' : '${currentPercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    statusDescription,
                    style: TextStyle(color: statusColor.withAlpha(220), fontSize: 13, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4 Nút Kịch bản Nhanh (Preset Scenarios)
            const Text(
              'Chọn nhanh kịch bản thử nghiệm (Preset Scenarios):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetButton(
                  label: '🟢 1. An toàn (Vắng 0)',
                  color: AppTheme.success,
                  onTap: () => _applyPreset(15, 8, 0, 3),
                ),
                _buildPresetButton(
                  label: '🟡 2. Sát nút (Vắng 2, còn 1)',
                  color: const Color(0xFFF57F17),
                  onTap: () => _applyPreset(15, 8, 2, 3),
                ),
                _buildPresetButton(
                  label: '🟠 3. Hết lượt (Vắng 3/3)',
                  color: const Color(0xFFE65100),
                  onTap: () => _applyPreset(15, 8, 3, 3),
                ),
                _buildPresetButton(
                  label: '🔴 4. CẤM THI (Vắng 4/3)',
                  color: AppTheme.danger,
                  onTap: () => _applyPreset(15, 8, 4, 3),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Các Thanh trượt Điều khiển Tham số (Sliders)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tùy chỉnh Tham số Đầu vào (What-If)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Slider 1: Số buổi đã vắng (A)
                    _buildSliderRow(
                      title: 'Số buổi đã vắng (A):',
                      valueText: '$_a buổi',
                      valueColor: isBanned ? AppTheme.danger : AppTheme.primary,
                      sliderValue: _a.toDouble(),
                      min: 0,
                      max: _m.toDouble(),
                      divisions: _m > 0 ? _m : 1,
                      activeColor: isBanned ? AppTheme.danger : AppTheme.primary,
                      onChanged: (val) => setState(() => _a = val.round()),
                    ),
                    const SizedBox(height: 12),

                    // Slider 2: Số buổi đã học / chốt (M)
                    _buildSliderRow(
                      title: 'Số buổi đã học (M):',
                      valueText: '$_m / $_n buổi',
                      valueColor: Colors.black87,
                      sliderValue: _m.toDouble(),
                      min: 1,
                      max: _n.toDouble(),
                      divisions: _n > 1 ? _n - 1 : 1,
                      activeColor: const Color(0xFF00897B),
                      onChanged: (val) {
                        setState(() {
                          _m = val.round();
                          if (_a > _m) _a = _m;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Slider 3: Giới hạn vắng tối đa (L)
                    _buildSliderRow(
                      title: 'Giới hạn vắng tối đa (L):',
                      valueText: '$_l buổi',
                      valueColor: Colors.black87,
                      sliderValue: _l.toDouble(),
                      min: 1,
                      max: 6,
                      divisions: 5,
                      activeColor: const Color(0xFF5E35B1),
                      onChanged: (val) => setState(() => _l = val.round()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bảng Chỉ số Đầu ra Dự báo
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    title: 'Tỷ lệ Chuyên cần',
                    value: '${currentPercentage.toStringAsFixed(1)}%',
                    subText: '($_m - $_a) / $_m',
                    color: isBanned ? AppTheme.danger : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    title: 'Nếu vắng buổi tới',
                    value: nextAbsentPercentage != null
                        ? '${nextAbsentPercentage.toStringAsFixed(1)}%'
                        : 'Hết buổi',
                    subText: _m < _n ? 'Dự báo buổi ${_m + 1}' : 'Hoàn tất khóa',
                    color: nextAbsentPercentage != null && nextAbsentPercentage < 70
                        ? AppTheme.danger
                        : const Color(0xFFE65100),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    title: 'Đã vắng / Tối đa',
                    value: '$_a / $_l buổi',
                    subText: isBanned ? 'Vượt giới hạn!' : 'Còn ${_l - _a} lần',
                    color: isBanned ? AppTheme.danger : Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    title: 'Còn được vắng',
                    value: '$remainingAllowed buổi',
                    subText: 'min(N-M, L-A)',
                    color: remainingAllowed == 0 ? AppTheme.danger : AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bảng Diễn giải Công thức Toán học
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.functions, color: AppTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Chi tiết Công thức & Giải thuật Động cơ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    _buildFormulaItem(
                      'Tỷ lệ chuyên cần (P)',
                      'P = (M - A) / M = ($_m - $_a) / $_m = ${currentPercentage.toStringAsFixed(2)}%',
                    ),
                    if (nextAbsentPercentage != null)
                      _buildFormulaItem(
                        'Dự báo vắng tiếp (P_next)',
                        'P_next = (M - A) / (M + 1) = ($_m - $_a) / (${_m + 1}) = ${nextAbsentPercentage.toStringAsFixed(2)}%',
                      ),
                    _buildFormulaItem(
                      'Số buổi còn được vắng (R)',
                      'R = min(N - M, max(0, L - A)) = min(${_n - _m}, ${_l - _a}) = $remainingAllowed buổi',
                    ),
                    _buildFormulaItem(
                      'Điều kiện Cấm thi',
                      'A > L ($_a > $_l) ➔ ${isBanned ? "VI PHẠM (CẤM THI)" : "HỢP LỆ (ĐƯỢC THI)"}',
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

  Widget _buildPresetButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ActionChip(
      backgroundColor: color.withAlpha(20),
      side: BorderSide(color: color.withAlpha(80)),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildSliderRow({
    required String title,
    required String valueText,
    required Color valueColor,
    required double sliderValue,
    required double min,
    required double max,
    required int divisions,
    required Color activeColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(
              valueText,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: valueColor),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: activeColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withAlpha(40),
            trackHeight: 4,
          ),
          child: Slider(
            value: sliderValue.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String title,
    required String value,
    required String subText,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(subText, style: const TextStyle(fontSize: 10, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildFormulaItem(String name, String expression) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
          const SizedBox(height: 2),
          Text(expression, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.black87)),
        ],
      ),
    );
  }
}

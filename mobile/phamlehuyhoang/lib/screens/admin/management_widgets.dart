import 'package:flutter/material.dart';

String? requiredValue(String? value) =>
    value == null || value.trim().isEmpty ? 'Vui lòng nhập thông tin' : null;

String? integerValue(String? value, {int min = 1, int? max}) {
  final number = int.tryParse(value?.trim() ?? '');
  return number == null || number < min || (max != null && number > max)
      ? 'Nhập số nguyên từ $min${max == null ? '' : ' đến $max'}'
      : null;
}

String? coordinateValue(String? value, double limit, String label) {
  final number = double.tryParse(value?.trim() ?? '');
  return number == null || !number.isFinite || number < -limit || number > limit
      ? '$label phải từ -$limit đến $limit'
      : null;
}

String? radiusValue(String? value) {
  final number = double.tryParse(value?.trim() ?? '');
  return number == null || !number.isFinite || number <= 0
      ? 'Bán kính phải lớn hơn 0'
      : null;
}

Widget managementError(String error, VoidCallback retry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(error, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: retry, child: const Text('Thử lại')),
      ],
    ),
  ),
);

Future<bool> confirmManagementAction(
  BuildContext context,
  String title,
  String message, {
  String action = 'Xóa',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

class ManagementFormDialog extends StatefulWidget {
  final String title;
  final Map<String, String> initial;
  final List<Widget> Function(
    BuildContext,
    Map<String, TextEditingController>,
    void Function(VoidCallback),
  )
  fields;
  final Future<void> Function(Map<String, TextEditingController>) save;

  const ManagementFormDialog({
    super.key,
    required this.title,
    required this.initial,
    required this.fields,
    required this.save,
  });
  @override
  State<ManagementFormDialog> createState() => _ManagementFormDialogState();
}

class _ManagementFormDialogState extends State<ManagementFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _controllers = widget.initial.map(
    (key, value) => MapEntry(key, TextEditingController(text: value)),
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save(_controllers);
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

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...widget
                    .fields(context, _controllers, setState)
                    .map(
                      (field) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: field,
                      ),
                    ),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Đang lưu…' : 'Lưu'),
        ),
      ],
    ),
  );
}

TextFormField managementField(
  TextEditingController controller,
  String label, {
  String? Function(String?)? validate,
  bool obscure = false,
  bool enabled = true,
  TextInputType? keyboardType,
}) => TextFormField(
  controller: controller,
  decoration: InputDecoration(labelText: label),
  validator: validate ?? requiredValue,
  obscureText: obscure,
  enabled: enabled,
  keyboardType: keyboardType,
);

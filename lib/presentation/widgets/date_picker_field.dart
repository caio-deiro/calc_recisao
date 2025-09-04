import 'package:flutter/material.dart';
import '../../../core/utils/formatters.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.initialDate,
    this.firstDate,
    this.lastDate,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'dd/mm/aaaa',
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: validator,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      controller.text = Formatters.formatDate(picked);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/formatters.dart';

class DateInputField extends StatefulWidget {
  const DateInputField({
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
  State<DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<DateInputField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'dd/mm/aaaa',
        suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context)),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, _DateInputFormatter()],
      validator: widget.validator,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.initialDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
    );

    if (picked != null) {
      widget.controller.text = Formatters.formatDate(picked);
    }
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Se o texto está sendo reduzido (backspace/delete), permitir a edição
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Remove todos os caracteres não numéricos
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limita a 8 dígitos
    final limitedDigits = digitsOnly.length > 8 ? digitsOnly.substring(0, 8) : digitsOnly;

    String formatted = '';

    if (limitedDigits.isNotEmpty) {
      formatted = limitedDigits.substring(0, 1);
    }
    if (limitedDigits.length >= 2) {
      formatted = '${limitedDigits.substring(0, 2)}/';
    }
    if (limitedDigits.length >= 3) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 3)}';
    }
    if (limitedDigits.length >= 4) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/';
    }
    if (limitedDigits.length >= 5) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/${limitedDigits.substring(4, 5)}';
    }
    if (limitedDigits.length >= 6) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/${limitedDigits.substring(4, 6)}';
    }
    if (limitedDigits.length >= 7) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/${limitedDigits.substring(4, 7)}';
    }
    if (limitedDigits.length >= 8) {
      formatted = '${limitedDigits.substring(0, 2)}/${limitedDigits.substring(2, 4)}/${limitedDigits.substring(4, 8)}';
    }

    // Calcula a posição do cursor
    int cursorPosition = formatted.length;

    // Se o usuário estava digitando no meio do texto, tenta manter a posição relativa
    if (oldValue.selection.baseOffset < oldValue.text.length) {
      final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
      final newDigits = formatted.replaceAll(RegExp(r'[^\d]'), '');

      if (newDigits.length > oldDigits.length) {
        // Adicionando caracteres
        cursorPosition = formatted.length;
      } else if (newDigits.length < oldDigits.length) {
        // Removendo caracteres
        cursorPosition = oldValue.selection.baseOffset;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition.clamp(0, formatted.length)),
    );
  }
}

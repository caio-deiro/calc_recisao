import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyTextField extends StatelessWidget {
  const CurrencyTextField({super.key, required this.controller, required this.label, this.validator, this.hintText});

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hintText ?? 'R\$ 0,00', prefixText: 'R\$ '),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')), _CurrencyInputFormatter()],
      validator: validator,
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove tudo exceto números
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Converte para centavos e formata
    double value = double.parse(text) / 100;
    String formatted = value.toStringAsFixed(2).replaceAll('.', ',');

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

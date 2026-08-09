import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyTextField extends StatefulWidget {
  const CurrencyTextField({super.key, required this.controller, required this.label, this.validator, this.hintText});

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final String? hintText;

  @override
  State<CurrencyTextField> createState() => _CurrencyTextFieldState();
}

class _CurrencyTextFieldState extends State<CurrencyTextField> {

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      hint: widget.hintText ?? 'Digite o valor em reais',
      textField: true,
      child: TextFormField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hintText ?? '0,00',
          prefixText: 'R\$ ',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          _CurrencyInputFormatter(),
        ],
        validator: widget.validator,
      ),
    );
  }
}

class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Remove tudo exceto números
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Converte para valor decimal (trata como centavos)
    final value = double.parse(text) / 100;
    
    // Formata com separador de milhares
    final parts = value.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    // Adicionar separadores de milhares
    String formattedInteger = '';
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        formattedInteger += '.';
      }
      formattedInteger += integerPart[i];
    }

    final formatted = '$formattedInteger,$decimalPart';

    // Mantém cursor no final ao digitar
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

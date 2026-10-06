import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import 'date_input_field.dart';

/// Fim previsto do contrato a prazo (B4-03/B4-09). Mostrado só nos tipos a prazo, com
/// o aviso não bloqueante do término normal logo abaixo do campo.
class FixedTermEndField extends StatelessWidget {
  const FixedTermEndField({super.key, required this.controller, this.warning});

  final TextEditingController controller;
  final String? warning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          identifier: 'form_fixed_term_end',
          child: DateInputField(
            controller: controller,
            label: 'Data de Fim Previsto do Contrato',
            lastDate: DateTime(2100),
            validator: (value) =>
                value?.isEmpty == true ? 'Campo obrigatório' : null,
          ),
        ),
        if (warning != null)
          Semantics(
            identifier: 'form_fixed_term_warning',
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                warning!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.tertiary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Opção de cláusula assecuratória do direito recíproco (CLT art. 481), só nas
/// antecipadas.
class RecipientClauseCheckbox extends StatelessWidget {
  const RecipientClauseCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'form_recipient_clause_checkbox',
      label:
          'O contrato tem cláusula que permite a qualquer parte encerrar antes do prazo',
      child: CheckboxListTile(
        title: const Text('O contrato permite encerrar antes do prazo'),
        subtitle: const Text(
          'Cláusula que dá a qualquer parte o direito de rescindir antes do fim',
        ),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
      ),
    );
  }
}

/// Converte o texto do campo em data; nulo se incompleto ou inválido.
DateTime? tryParseFormDate(String text) {
  if (text.length != 10) return null;
  try {
    return Formatters.parseDate(text);
  } catch (_) {
    return null;
  }
}

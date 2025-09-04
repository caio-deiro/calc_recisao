import 'package:flutter/material.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../domain/entities/termination_input.dart';
import '../../../core/utils/formatters.dart';
import '../../widgets/disclaimer_widget.dart';
import '../../widgets/currency_text_field.dart';
import '../../widgets/date_picker_field.dart';
import '../result/result_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key, required this.terminationType});

  final TerminationType terminationType;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _admissionDateController = TextEditingController();
  final _terminationDateController = TextEditingController();
  final _baseSalaryController = TextEditingController();
  final _averageAdditionsController = TextEditingController();
  final _workedDaysController = TextEditingController();
  final _existingFgtsController = TextEditingController();
  final _dependentsController = TextEditingController();
  final _otherDiscountsController = TextEditingController();

  bool _hasAccruedVacation = false;
  bool _noticeWorked = false;
  bool _hasExistingFgts = false;
  bool _calculateTaxes = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _admissionDateController.dispose();
    _terminationDateController.dispose();
    _baseSalaryController.dispose();
    _averageAdditionsController.dispose();
    _workedDaysController.dispose();
    _existingFgtsController.dispose();
    _dependentsController.dispose();
    _otherDiscountsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dados da Rescisão - ${widget.terminationType.label}'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildSalarySection(),
                    const SizedBox(height: 24),
                    _buildOptionsSection(),
                    const SizedBox(height: 24),
                    const DisclaimerWidget(),
                  ],
                ),
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informações Básicas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DatePickerField(
          controller: _admissionDateController,
          label: 'Data de Admissão',
          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 16),
        DatePickerField(
          controller: _terminationDateController,
          label: 'Data de Desligamento',
          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
        ),
      ],
    );
  }

  Widget _buildSalarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Remuneração', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        CurrencyTextField(
          controller: _baseSalaryController,
          label: 'Salário Base Mensal',
          validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
        ),
        const SizedBox(height: 16),
        CurrencyTextField(controller: _averageAdditionsController, label: 'Média de Adicionais Fixos (opcional)'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _workedDaysController,
          decoration: const InputDecoration(
            labelText: 'Dias Trabalhados no Mês (opcional)',
            hintText: 'Deixe em branco para calcular automaticamente',
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Opções', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Férias vencidas?'),
          subtitle: const Text('Possui férias não gozadas'),
          value: _hasAccruedVacation,
          onChanged: (value) => setState(() => _hasAccruedVacation = value ?? false),
        ),
        CheckboxListTile(
          title: const Text('Aviso prévio trabalhado'),
          subtitle: const Text('Cumpriu o aviso prévio'),
          value: _noticeWorked,
          onChanged: (value) => setState(() => _noticeWorked = value ?? false),
        ),
        CheckboxListTile(
          title: const Text('Possui depósitos FGTS existentes'),
          subtitle: const Text('Para cálculo da multa de 40%'),
          value: _hasExistingFgts,
          onChanged: (value) => setState(() => _hasExistingFgts = value ?? false),
        ),
        if (_hasExistingFgts) ...[
          const SizedBox(height: 16),
          CurrencyTextField(controller: _existingFgtsController, label: 'Valor total do FGTS no vínculo'),
        ],
        const SizedBox(height: 16),
        TextFormField(
          controller: _dependentsController,
          decoration: const InputDecoration(labelText: 'Número de Dependentes', hintText: '0'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        CurrencyTextField(controller: _otherDiscountsController, label: 'Outros Descontos (opcional)'),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('Calcular descontos (INSS/IRRF)'),
          subtitle: const Text('Descontos previdenciários e tributários'),
          value: _calculateTaxes,
          onChanged: (value) => setState(() => _calculateTaxes = value ?? true),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _calculateTermination,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Calcular Rescisão', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }

  void _calculateTermination() {
    if (_formKey.currentState?.validate() == true) {
      try {
        final input = TerminationInput(
          admissionDate: Formatters.parseDate(_admissionDateController.text),
          terminationDate: Formatters.parseDate(_terminationDateController.text),
          baseSalary: double.parse(_baseSalaryController.text.replaceAll(',', '.')),
          averageAdditions: double.tryParse(_averageAdditionsController.text.replaceAll(',', '.')) ?? 0.0,
          hasAccruedVacation: _hasAccruedVacation,
          workedDaysInMonth: int.tryParse(_workedDaysController.text) ?? 0,
          noticeWorked: _noticeWorked,
          hasExistingFgts: _hasExistingFgts,
          existingFgtsAmount: double.tryParse(_existingFgtsController.text.replaceAll(',', '.')) ?? 0.0,
          dependents: int.tryParse(_dependentsController.text) ?? 0,
          otherDiscounts: double.tryParse(_otherDiscountsController.text.replaceAll(',', '.')) ?? 0.0,
          calculateTaxes: _calculateTaxes,
        );

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(input: input, terminationType: widget.terminationType),
          ),
        );
      } catch (e) {
        String errorMessage = 'Erro ao processar dados';
        if (e.toString().contains('Formato de data inválido')) {
          errorMessage = 'Formato de data inválido. Verifique se as datas estão no formato dd/mm/aaaa';
        } else if (e.toString().contains('Invalid date format')) {
          errorMessage = 'Formato de data inválido. Verifique se as datas estão no formato dd/mm/aaaa';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      }
    }
  }
}

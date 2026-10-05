import 'package:flutter/material.dart';
import '../../../domain/entities/termination_type.dart';
import '../../../domain/entities/termination_input.dart';
import '../../../domain/rules/vacation_periods.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/logger.dart';
import '../../../core/validators/termination_input_validator.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/disclaimer_widget.dart';
import '../../widgets/currency_text_field.dart';
import '../../widgets/date_input_field.dart';
import '../../widgets/vacation_taken_field.dart';
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

  int _vacationTaken = 0;
  bool _vacationTouched = false;

  /// Anos completos entre as datas (`n`); nulo enquanto as datas forem inválidas.
  int? _vacationLimit;
  bool _noticeWorked = false;
  bool _hasExistingFgts = false;
  bool _calculateTaxes = true;

  @override
  void initState() {
    super.initState();
    _admissionDateController.addListener(_updateVacationLimit);
    _terminationDateController.addListener(_updateVacationLimit);
  }

  /// Recalcula `n` ao mudar as datas: o valor acompanha `n` até o toque e nunca o excede.
  void _updateVacationLimit() {
    int? limit;
    try {
      if (_admissionDateController.text.length != 10 || _terminationDateController.text.length != 10) {
        throw const FormatException('data incompleta');
      }
      final admission = Formatters.parseDate(_admissionDateController.text);
      final termination = Formatters.parseDate(_terminationDateController.text);
      if (!termination.isBefore(admission)) {
        limit = fullServiceYears(admission, termination);
      }
    } catch (_) {
      limit = null;
    }
    // Data incompleta (digitando): o valor tocado é guardado e reaparece quando as datas voltam a valer.
    final taken = _vacationTouched ? (limit == null ? _vacationTaken : _vacationTaken.clamp(0, limit)) : (limit ?? 0);
    if (limit == _vacationLimit && taken == _vacationTaken) return;
    setState(() {
      _vacationLimit = limit;
      _vacationTaken = taken;
    });
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
        title: Text(
          '${AppLocalizations.of(context)?.formTitle ?? 'Dados da Rescisão'} - ${widget.terminationType.label}',
        ),
        leading: Semantics(
          identifier: 'form_back_button',
          label: 'Voltar',
          button: true,
          child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.basicInfo ?? 'Informações Básicas',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'form_admission_date',
          child: DateInputField(
            controller: _admissionDateController,
            label: l10n?.admissionDate ?? 'Data de Admissão',
            validator: (value) => value?.isEmpty == true ? (l10n?.fieldRequired ?? 'Campo obrigatório') : null,
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'form_termination_date',
          child: DateInputField(
            controller: _terminationDateController,
            label: l10n?.terminationDate ?? 'Data de Desligamento',
            validator: (value) => value?.isEmpty == true ? (l10n?.fieldRequired ?? 'Campo obrigatório') : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSalarySection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n?.remuneration ?? 'Remuneração', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'form_base_salary',
          child: CurrencyTextField(
            controller: _baseSalaryController,
            label: l10n?.baseSalary ?? 'Salário Base Mensal',
            validator: (value) => value?.isEmpty == true ? (l10n?.fieldRequired ?? 'Campo obrigatório') : null,
          ),
        ),
        const SizedBox(height: 16),
        CurrencyTextField(
          controller: _averageAdditionsController,
          label: l10n?.averageAdditions ?? 'Média de Adicionais Fixos (opcional)',
        ),
        const SizedBox(height: 16),
        Semantics(
          label: l10n?.workedDaysInMonth ?? 'Dias Trabalhados no Mês',
          hint: 'Deixe em branco para calcular automaticamente',
          textField: true,
          child: TextFormField(
            controller: _workedDaysController,
            decoration: InputDecoration(
              labelText: l10n?.workedDaysInMonth ?? 'Dias Trabalhados no Mês (opcional)',
              hintText: 'Deixe em branco para calcular automaticamente',
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n?.options ?? 'Opções', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        VacationTakenField(
          value: _vacationLimit == null ? 0 : _vacationTaken,
          maxPeriods: _vacationLimit,
          onChanged: (value) => setState(() {
            _vacationTaken = value;
            _vacationTouched = true;
          }),
        ),
        const SizedBox(height: 8),
        Semantics(
          identifier: 'form_notice_worked_checkbox',
          label: l10n?.noticeWorked ?? 'Aviso prévio trabalhado',
          hint: 'Cumpriu o aviso prévio',
          child: CheckboxListTile(
            title: Text(l10n?.noticeWorked ?? 'Aviso prévio trabalhado'),
            subtitle: const Text('Cumpriu o aviso prévio'),
            value: _noticeWorked,
            onChanged: (value) => setState(() => _noticeWorked = value ?? false),
          ),
        ),
        Semantics(
          identifier: 'form_has_fgts_checkbox',
          label: l10n?.hasExistingFgts ?? 'Possui depósitos FGTS existentes',
          hint: 'Para cálculo da multa de 40%',
          child: CheckboxListTile(
            title: Text(l10n?.hasExistingFgts ?? 'Possui depósitos FGTS existentes'),
            subtitle: const Text('Para cálculo da multa de 40%'),
            value: _hasExistingFgts,
            onChanged: (value) => setState(() => _hasExistingFgts = value ?? false),
          ),
        ),
        if (_hasExistingFgts) ...[
          const SizedBox(height: 16),
          Semantics(
            identifier: 'form_fgts_amount',
            child: CurrencyTextField(
              controller: _existingFgtsController,
              label: l10n?.existingFgtsAmount ?? 'Valor total do FGTS no vínculo',
            ),
          ),
        ],
        const SizedBox(height: 16),
        Semantics(
          label: l10n?.dependents ?? 'Número de Dependentes',
          textField: true,
          child: TextFormField(
            controller: _dependentsController,
            decoration: InputDecoration(labelText: l10n?.dependents ?? 'Número de Dependentes', hintText: '0'),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(height: 16),
        CurrencyTextField(
          controller: _otherDiscountsController,
          label: l10n?.otherDiscounts ?? 'Outros Descontos (opcional)',
        ),
        const SizedBox(height: 16),
        Semantics(
          label: l10n?.calculateTaxes ?? 'Calcular descontos',
          hint: 'Descontos previdenciários e tributários',
          child: CheckboxListTile(
            title: Text(l10n?.calculateTaxes ?? 'Calcular descontos (INSS/IRRF)'),
            subtitle: const Text('Descontos previdenciários e tributários'),
            value: _calculateTaxes,
            onChanged: (value) => setState(() => _calculateTaxes = value ?? true),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Semantics(
      identifier: 'form_calculate_button',
      label: 'Botão para calcular a rescisão trabalhista',
      button: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, -2)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _calculateTermination,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                AppLocalizations.of(context)?.calculateTermination ?? 'Calcular Rescisão',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Converte texto formatado de moeda para double.
  /// Remove separadores de milhares (pontos) e converte vírgula para ponto decimal.
  double _parseCurrencyValue(String text) {
    if (text.isEmpty) return 0.0;
    // Remove tudo exceto números, vírgula e ponto
    String cleaned = text.replaceAll(RegExp(r'[^\d,.]'), '');
    // Remove pontos (separadores de milhares) e converte vírgula para ponto decimal
    cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  void _calculateTermination() {
    if (_formKey.currentState?.validate() == true) {
      try {
        // Parse dos dados
        final admissionDate = Formatters.parseDate(_admissionDateController.text);
        final terminationDate = Formatters.parseDate(_terminationDateController.text);

        final baseSalary = _parseCurrencyValue(_baseSalaryController.text);
        final averageAdditions = _parseCurrencyValue(_averageAdditionsController.text);

        final workedDaysInMonth = _workedDaysController.text.isEmpty
            ? 0
            : int.tryParse(_workedDaysController.text) ?? 0;

        final existingFgtsAmount = _parseCurrencyValue(_existingFgtsController.text);

        final dependents = _dependentsController.text.isEmpty ? 0 : int.tryParse(_dependentsController.text) ?? 0;

        final otherDiscounts = _parseCurrencyValue(_otherDiscountsController.text);

        final input = TerminationInput(
          admissionDate: admissionDate,
          terminationDate: terminationDate,
          baseSalary: baseSalary,
          averageAdditions: averageAdditions,
          vacationPeriodsTaken: _vacationTaken,
          workedDaysInMonth: workedDaysInMonth,
          noticeWorked: _noticeWorked,
          hasExistingFgts: _hasExistingFgts,
          existingFgtsAmount: existingFgtsAmount,
          dependents: dependents,
          otherDiscounts: otherDiscounts,
          calculateTaxes: _calculateTaxes,
        );

        // Validar dados
        final validationResult = TerminationInputValidator.validate(input);
        if (!validationResult.isValid) {
          _showValidationErrors(validationResult);
          return;
        }

        // Navegar para tela de resultado
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(input: input, terminationType: widget.terminationType),
          ),
        );
      } on ValidationException catch (e) {
        AppLogger.exception(e);
        _showValidationErrors(ValidationResult.failure(errors: [e.message], fieldErrors: e.fieldErrors ?? {}));
      } on FormatException catch (e) {
        AppLogger.error('Erro ao fazer parse dos dados', e);
        _showError('Formato de data inválido. Verifique se as datas estão no formato dd/mm/aaaa');
      } on AppException catch (e) {
        AppLogger.exception(e);
        _showError(e.message);
      } catch (e, stackTrace) {
        AppLogger.error('Erro inesperado ao processar dados', e, stackTrace);
        _showError(AppConstants.genericErrorMessage);
      }
    }
  }

  void _showValidationErrors(ValidationResult result) {
    final errorMessage = result.errors.isNotEmpty
        ? result.errors.join('\n')
        : 'Por favor, corrija os erros nos campos indicados.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
      ),
    );
  }
}

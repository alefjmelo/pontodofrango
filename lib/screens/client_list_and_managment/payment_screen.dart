import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pontodofrango/models/client_model.dart';
import 'package:pontodofrango/screens/client_list_and_managment/client_details_screen.dart';
import 'package:pontodofrango/utils/operations/bills_operations.dart';
import 'package:pontodofrango/utils/operations/payment_history_operations.dart';
import 'package:pontodofrango/utils/showCustomOverlay.dart';

import '../../utils/operations/client_operations.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    double value =
        double.parse(newValue.text.replaceAll(RegExp('[^0-9]'), '')) / 100;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  final Client client;
  final double totalBill;
  const PaymentScreen(
      {super.key, required this.client, required this.totalBill});

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final String _selectedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  bool _showHint = true;
  String searchText = '';
  double creditoConta = 0;
  double saldoDevedor = 0;
  late double suggestedPayment;

  @override
  void initState() {
    super.initState();
    _valueController.addListener(_updateHintVisibility);
    creditoConta = widget.client.creditoConta;
    saldoDevedor = widget.client.saldoDevedor;
    _calculateSuggestedPayment();
  }

  void _calculateSuggestedPayment() {
    suggestedPayment = widget.totalBill + saldoDevedor - creditoConta;
  }

  @override
  void dispose() {
    _valueController.removeListener(_updateHintVisibility);
    _valueController.dispose();
    super.dispose();
  }

  void _onKeyTap(String value) {
    final currentValue = _valueController.text.replaceAll(RegExp('[^0-9]'), '');
    final newValue = currentValue + value;
    if (newValue.length <= 8) {
      _formatAndSetValue(newValue);
    }
    _updateHintVisibility();
  }

  void _onBackspace() {
    final currentValue = _valueController.text.replaceAll(RegExp('[^0-9]'), '');
    if (currentValue.isNotEmpty) {
      final newValue = currentValue.substring(0, currentValue.length - 1);
      _formatAndSetValue(newValue);
    } else {
      _valueController.clear();
    }
  }

  void _formatAndSetValue(String newValue) {
    if (newValue.isEmpty) {
      _valueController.clear();
    } else {
      final formattedValue =
          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
              .format(int.parse(newValue) / 100);
      _valueController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }
  }

  void _updateHintVisibility() {
    setState(() {
      _showHint = _valueController.text.isEmpty;
    });
  }

  bool _isValueGreaterThanZero() {
    final numericValue =
        _valueController.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final doubleValue = double.tryParse(numericValue) ?? 0.0;
    return doubleValue > 0;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.yellow,
          title: const Text(
            'Pagamento de Conta',
            style: TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[800],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _showClientName(),
              const SizedBox(height: 20),
              _buildValueTextField(),
              const SizedBox(height: 20),
              _buildNumberKeyboard(),
              const SizedBox(height: 20),
              _buildPayButton(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueTextField() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _valueController,
      builder: (context, value, child) {
        return TextField(
          controller: _valueController,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            hintText: _showHint ? 'R\$ 0,00' : null,
            hintStyle: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.3),
            ),
            border: InputBorder.none,
          ),
          readOnly: true,
          showCursor: false,
        );
      },
    );
  }

  Widget _buildNumberKeyboard() {
    return SizedBox(
      width: 250,
      child: Column(
        children: [
          _buildKeyboardRow(['1', '2', '3']),
          const SizedBox(height: 10),
          _buildKeyboardRow(['4', '5', '6']),
          const SizedBox(height: 10),
          _buildKeyboardRow(['7', '8', '9']),
          const SizedBox(height: 10),
          _buildKeyboardRow(['', '0', 'backspace']),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        if (key == 'backspace') {
          return _buildKeyboardKey(
            child: const Icon(Icons.backspace, color: Colors.white),
            onTap: _onBackspace,
          );
        } else if (key.isEmpty) {
          return const SizedBox(width: 60, height: 60);
        }
        return _buildKeyboardKey(
          child: Text(
            key,
            style: const TextStyle(fontSize: 24, color: Colors.white),
          ),
          onTap: () => _onKeyTap(key),
        );
      }).toList(),
    );
  }

  Widget _buildKeyboardKey(
      {required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Center(child: child),
      ),
    );
  }

  _showClientName() {
    return Container(
      height: saldoDevedor > 0 || creditoConta > 0 ? 200 : 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Center(
            child: Text('Resumo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                )),
          ),
          Text(
            'Cliente: ${widget.client.nome}',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            'Data: $_selectedDate',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            'Total: R\$ ${widget.totalBill.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          if (widget.client.creditoConta > 0 && widget.client.saldoDevedor == 0)
            Text(
              'Crédito: R\$ ${widget.client.creditoConta.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          if (widget.client.saldoDevedor > 0 && widget.client.creditoConta == 0)
            Text(
              'Saldo Devedor: R\$ ${widget.client.saldoDevedor.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          Text(
            'Pagamento sugerido: R\$ ${(suggestedPayment).toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    double value = double.parse(_valueController.text
        .replaceAll(RegExp(r'[^0-9,]'), '')
        .replaceAll(',', '.'));

    double newCreditBalance = 0.0;
    double newDebitBalance = 0.0;

    // Calculate new balances
    if (value > suggestedPayment) {
      newCreditBalance = value - suggestedPayment;
      widget.client.saldoDevedor = 0.0;
    } else {
      newDebitBalance = suggestedPayment - value;
      widget.client.creditoConta = 0.0;
    }

    try {
      // Update payment history
      await addPaymentHistory(
        widget.client.code,
        _selectedDate,
        suggestedPayment,
        value,
        newDebitBalance,
        newCreditBalance,
      );

      // Update client balances in database
      await updateClientBalance(
        widget.client.code,
        newCreditBalance,
        newDebitBalance,
      );

      // Remove paid bills
      await removeAllBillsForClient(widget.client.code);

      if (!mounted) return;

      showCustomOverlay(context, 'Pagamento registrado com sucesso.');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ClientDetailsScreen(
            client: widget.client,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showCustomOverlay(context, 'Erro ao registrar o pagamento.');
    }
  }

  Widget _buildPayButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _valueController,
      builder: (context, value, child) {
        final bool isButtonEnabled = _isValueGreaterThanZero();

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(250, 50),
            foregroundColor: Colors.black,
            backgroundColor: isButtonEnabled ? Colors.white : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isButtonEnabled ? _handlePayment : null,
          child: const Text(
            'Pagar',
            style: TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }
}

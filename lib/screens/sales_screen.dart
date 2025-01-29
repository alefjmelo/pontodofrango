import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pontodofrango/utils/showCustomOverlay.dart';
import '../models/client_model.dart';
import '../utils/operations/bills_operations.dart';
import '../utils/operations/client_operations.dart';

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

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  SalesScreenState createState() => SalesScreenState();
}

class SalesScreenState extends State<SalesScreen> {
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String _selectedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  static const double _initialLineWidth = 175;
  double _lineWidth = _initialLineWidth;
  bool _showHint = true;
  String? _selectedClient;
  String? _selectedClientCode;
  String searchText = '';
  List<Client> _clients = [];

  Future<void> _fetchClients() async {
    List<Client> clients = await fetchClients();
    setState(() {
      _clients = clients;
    });
  }

  void _resetSelectedClient() {
    setState(() {
      _selectedClient = null;
      _selectedClientCode = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchClients();
    _descriptionController.addListener(_updateLineWidth);
    _descriptionController.addListener(_convertDescriptionToUpperCase);
    _valueController.addListener(_updateHintVisibility);
    _resetSelectedClient();
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_updateLineWidth);
    _valueController.removeListener(_updateHintVisibility);
    _descriptionController.removeListener(_convertDescriptionToUpperCase);
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _convertDescriptionToUpperCase() {
    _descriptionController.value = _descriptionController.value.copyWith(
      text: _descriptionController.text.toUpperCase(),
      selection: _descriptionController.selection,
    );
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

  void _updateLineWidth() {
    setState(() {
      _lineWidth =
          max(_descriptionController.text.length * 10.0, _initialLineWidth);
    });
  }

  void _updateHintVisibility() {
    setState(() {
      _showHint = _valueController.text.isEmpty;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _selectedDate = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
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
        appBar: PreferredSize(
            preferredSize: Size.fromHeight(100),
            child: Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[700],
              ),
              child: Text('Vendas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26)),
            )),
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.grey[800],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _showClientSelected(),
              const SizedBox(height: 20),
              _buildDateSelector(),
              const SizedBox(height: 20),
              _buildValueTextField(),
              _buildDescriptionFieldWithLine(),
              const SizedBox(height: 20),
              _buildNumberKeyboard(),
              const SizedBox(height: 20),
              _buildPayButton(),
              SizedBox(height: 20),
              _buildClientSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showClientSelected() {
    final bool isClientSelected = _selectedClient != null;

    return Center(
      child: Text(
        isClientSelected ? _selectedClient! : 'Nenhum cliente selecionado.',
        style: TextStyle(
          color: isClientSelected ? Colors.yellow : Colors.red,
          fontSize: isClientSelected ? 26 : 18,
          fontWeight: isClientSelected ? FontWeight.bold : FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildClientSelector() {
    return ElevatedButton(
      onPressed: _showClientDialog,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(250, 50),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        'Selecionar Cliente',
        style: TextStyle(color: Colors.black, fontSize: 18),
      ),
    );
  }

  void _showClientDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        bool showClientsList = false; // Move this outside StatefulBuilder

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.grey[800],
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[700]!, width: 1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Text(
                          'Selecionar Cliente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar Cliente...',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                          ),
                          filled: true,
                          fillColor: Colors.grey[700],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: IconButton(
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                iconColor:
                                    WidgetStateProperty.all(Colors.white),
                                backgroundColor:
                                    WidgetStateProperty.all(Colors.grey[800]),
                              ),
                              icon: Icon(Icons.search),
                              onPressed: () async {
                                List<Client> allClients = await fetchClients();
                                setState(() {
                                  _clients =
                                      allClients; // Always show all clients first
                                  if (searchText.isNotEmpty) {
                                    // Only filter if there's search text
                                    _clients = _clients.where((client) {
                                      return client.nome
                                          .toLowerCase()
                                          .contains(searchText.toLowerCase());
                                    }).toList();
                                  }
                                  showClientsList =
                                      true; // Always show the list
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      if (showClientsList &&
                          _clients.isNotEmpty) // Modify this line
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListView.builder(
                              itemCount: _clients.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedClient = _clients[index].nome;
                                        _selectedClientCode =
                                            _clients[index].code.toString();
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: _selectedClientCode ==
                                                _clients[index].code.toString()
                                            ? Colors.yellow
                                            : Colors.grey[800],
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _clients[index].nome,
                                        style: TextStyle(
                                          color: _selectedClientCode ==
                                                  _clients[index]
                                                      .code
                                                      .toString()
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedClientCode != null) {
                            Navigator.of(context).pop();
                            this.setState(() {
                              _selectedClient = _clients
                                  .firstWhere((client) =>
                                      client.code.toString() ==
                                      _selectedClientCode)
                                  .nome;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Concluir',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Text(
        _selectedDate,
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDescriptionFieldWithLine() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Descrição da venda',
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _lineWidth,
          height: 2,
          color: Colors.white,
        ),
      ],
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
      width: 250, // Set a fixed width for the keyboard
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
          return const SizedBox(
              width: 60, height: 60); // Placeholder for empty slot
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

  Widget _buildPayButton() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _valueController,
      builder: (context, value, child) {
        final bool isButtonEnabled =
            _selectedClient != null && _isValueGreaterThanZero();

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(250, 50),
            foregroundColor: Colors.black,
            backgroundColor: isButtonEnabled ? Colors.white : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isButtonEnabled
              ? () async {
                  double value = double.parse(_valueController.text
                      .replaceAll(RegExp(r'[^0-9,]'), '')
                      .replaceAll(',', '.'));

                  Client selectedClient = _clients
                      .firstWhere((client) => client.nome == _selectedClient);

                  try {
                    await addBill(
                      selectedClient.code,
                      _descriptionController.text,
                      value,
                      _selectedDate,
                    );
                    if (!context.mounted) return;
                    showCustomOverlay(context, 'Venda registrada com sucesso.');

                    setState(() {
                      _valueController.clear();
                      _descriptionController.clear();
                      _selectedDate =
                          DateFormat('dd/MM/yyyy').format(DateTime.now());
                      _resetSelectedClient();
                    });
                  } catch (e) {
                    if (!context.mounted) return;
                    showCustomOverlay(context, 'Erro ao registrar a venda.');
                  }
                }
              : null,
          child: const Text(
            'Vender',
            style: TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }
}

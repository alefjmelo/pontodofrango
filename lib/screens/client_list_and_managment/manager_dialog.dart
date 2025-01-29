import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:pontodofrango/utils/operations/client_operations.dart';
import 'package:pontodofrango/utils/showCustomOverlay.dart';
import '../../models/client_model.dart';

class ClientManagerDialogs extends StatefulWidget {
  final VoidCallback onClientChanged;

  const ClientManagerDialogs({super.key, required this.onClientChanged});

  @override
  ClientManagerDialogsState createState() => ClientManagerDialogsState();
}

class ClientManagerDialogsState extends State<ClientManagerDialogs> {
  String _dialogState = 'initial';
  String _searchText = '';
  String? _phoneErrorMessage, _nameErrorMessage, _addressErrorMessage;
  int _selectedClientCode = 0;
  List<Client> _filteredClients = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final MaskedTextController _phoneController =
      MaskedTextController(mask: '(00) 00000-0000');
  final TextEditingController _addressController = TextEditingController();

  bool _noPhone = false;
  bool _noAddress = false;

  bool _isValidPhoneNumber(String phoneNumber) {
    final RegExp phoneRegExp = RegExp(r'^\(\d{2}\) \d{5}-\d{4}$');
    return phoneRegExp.hasMatch(phoneNumber);
  }

  void _resetEditState() {
    _selectedClientCode = 0;
    _searchText = '';
    _searchController.clear();
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _filteredClients.clear();
    _noPhone = false;
    _noAddress = false;
    _phoneErrorMessage = null;
    _nameErrorMessage = null;
    _addressErrorMessage = null;
  }

  void _setDialogState(String state) {
    if (state == 'search') {
      _resetEditState();
    }
    setState(() {
      _dialogState = state;
    });
  }

  Future<void> _handleAddClient() async {
    String name = _nameController.text;
    String phoneNumber =
        _noPhone ? 'Sem número de telefone' : _phoneController.text;
    String address =
        _noAddress ? 'Sem endereço cadastrado' : _addressController.text;

    if (_validateInputs(name, phoneNumber, address)) {
      await addClient(name, phoneNumber, address);
      if (!mounted) return; // Check if the widget is still mounted
      widget.onClientChanged();
      Navigator.of(context).pop();
      showCustomOverlay(context, 'Cliente Adicionado!');
    }
  }

  Future<void> _handleRemoveClient() async {
    if (_selectedClientCode != 0) {
      await removeClient(_selectedClientCode);
      if (!mounted) return; // Check if the widget is still mounted
      widget.onClientChanged();
      Navigator.of(context).pop();
      showCustomOverlay(context, 'Cliente Removido!');
    }
  }

  Future<void> _handleSearch() async {
    List<Client> allClients = await fetchClients();
    setState(() {
      _filteredClients = allClients
          .where((client) =>
              client.nome.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    });
  }

  Future<void> _handleEditClient() async {
    String name = _nameController.text;
    String phoneNumber =
        _noPhone ? 'Sem número de telefone' : _phoneController.text;
    String address =
        _noAddress ? 'Sem endereço cadastrado' : _addressController.text;

    if (_validateInputs(name, phoneNumber, address)) {
      await editClientData(_selectedClientCode,
          name: name, phoneNumber: phoneNumber, address: address);
      if (!mounted) return;
      widget.onClientChanged();
      Navigator.of(context).pop();
      showCustomOverlay(context, 'Cliente Atualizado!');
    }
  }

  void _prepareEditDialog(Client client) {
    _selectedClientCode = client.code;
    _nameController.text = client.nome;
    _noPhone = client.numero == 'Sem número de telefone';
    _phoneController.text = _noPhone ? '' : client.numero;
    _noAddress = client.endereco == 'Sem endereço cadastrado';
    _addressController.text = _noAddress ? '' : client.endereco;
    _setDialogState('edit');
  }

  bool _validateInputs(String name, String phoneNumber, String address) {
    bool isValid = true;

    setState(() {
      _nameErrorMessage = name.isEmpty ? 'Nome não pode estar vazio' : null;
      _phoneErrorMessage = !_noPhone && !_isValidPhoneNumber(phoneNumber)
          ? 'Número Incorreto. Tente novamente'
          : null;
      _addressErrorMessage = !_noAddress && address.isEmpty
          ? 'Endereço não pode estar vazio'
          : null;
    });

    isValid = _nameErrorMessage == null &&
        (_noPhone || _phoneErrorMessage == null) &&
        (_noAddress || _addressErrorMessage == null);

    return isValid;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.grey[800]!.withOpacity(0.88),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(color: Colors.grey[700]!, width: 1)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(
          width: double.maxFinite,
          child: _dialogState == 'add'
              ? _buildAddDialog()
              : _dialogState == 'remove'
                  ? _buildRemoveDialog()
                  : _dialogState == 'edit'
                      ? _buildEditDialog()
                      : _dialogState == 'search'
                          ? _buildSearchDialog()
                          : _buildInitialDialog(),
        ),
      ),
    );
  }

  Widget _buildAddDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDialogHeader('Adicionar Cliente'),
        _buildTextField(
            _nameController, 'Nome do Cliente', _nameErrorMessage, 20),
        _buildTextField(_phoneController, 'Nº de Celular', _phoneErrorMessage,
            null, TextInputType.phone),
        _buildCheckbox('Cliente não possui celular', _noPhone, (value) {
          setState(() {
            _noPhone = value ?? false;
            if (_noPhone) {
              _phoneController.text = '';
            }
          });
        }),
        _buildTextField(
            _addressController, 'Endereço', _addressErrorMessage, 50),
        _buildCheckbox('Cliente não possui endereço', _noAddress, (value) {
          setState(() {
            _noAddress = value ?? false;
            if (_noAddress) {
              _addressController.text = 'Sem endereço cadastrado';
            } else {
              _addressController.text = '';
            }
          });
        }),
        SizedBox(height: 10),
        _buildActionButton('Concluir', _handleAddClient),
      ],
    );
  }

  Widget _buildRemoveDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDialogHeader('Remover Cliente'),
        _buildSearchField(),
        SizedBox(height: 10),
        if (_filteredClients.isNotEmpty) _buildClientList(),
        SizedBox(height: 10),
        _buildActionButton('Concluir', _handleRemoveClient),
      ],
    );
  }

  Widget _buildSearchDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                _resetEditState();
                _setDialogState('initial');
              },
            ),
            Text(
              'Selecionar Cliente',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        _buildSearchField(),
        SizedBox(height: 10),
        if (_filteredClients.isNotEmpty) _buildClientList(),
        SizedBox(height: 10),
        if (_selectedClientCode != 0)
          _buildActionButton('Confirmar Seleção', () {
            Client selectedClient = _filteredClients
                .firstWhere((client) => client.code == _selectedClientCode);
            _prepareEditDialog(selectedClient);
          }),
      ],
    );
  }

  Widget _buildEditDialog() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDialogHeader('Editar Cliente'),
        _buildTextField(
            _nameController, 'Nome do Cliente', _nameErrorMessage, 20),
        _buildTextField(_phoneController, 'Nº de Celular', _phoneErrorMessage,
            null, TextInputType.phone),
        _buildCheckbox('Cliente não possui celular', _noPhone, (value) {
          setState(() {
            _noPhone = value ?? false;
            if (_noPhone) _phoneController.text = '';
          });
        }),
        _buildTextField(
            _addressController, 'Endereço', _addressErrorMessage, 50),
        _buildCheckbox('Cliente não possui endereço', _noAddress, (value) {
          setState(() {
            _noAddress = value ?? false;
            if (_noAddress) {
              _addressController.text = 'Sem endereço cadastrado';
            } else {
              _addressController.text = '';
            }
          });
        }),
        SizedBox(height: 10),
        _buildActionButton('Salvar Alterações', _handleEditClient),
      ],
    );
  }

  Widget _buildInitialDialog() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogButton('Adicionar Cliente', () => _setDialogState('add')),
          SizedBox(height: 25),
          _buildDialogButton('Editar Cliente', () => _setDialogState('search')),
          SizedBox(height: 25),
          _buildDialogButton(
              'Remover Cliente', () => _setDialogState('remove')),
        ],
      ),
    );
  }

  Widget _buildDialogHeader(String title) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _setDialogState('initial'),
        ),
        Text(
          title,
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, String? errorMessage,
      [int? textSizeLimit, TextInputType? keyboardType]) {
    bool isDisabled = false;
    if (controller == _phoneController) isDisabled = _noPhone;
    if (controller == _addressController) isDisabled = _noAddress;

    if (controller == _phoneController && _noPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: TextEditingController(text: 'Sem número de telefone'),
            enabled: false,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey[300],
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          SizedBox(height: 10),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: !isDisabled,
          inputFormatters: [LengthLimitingTextInputFormatter(textSizeLimit)],
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: isDisabled ? Colors.grey[300] : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(errorMessage, style: TextStyle(color: Colors.red)),
          ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchText = value),
      decoration: InputDecoration(
        hintText: 'Buscar Cliente...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.grey[700],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        suffixIcon: _buildSearchButton(),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: IconButton(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          iconColor: WidgetStateProperty.all(Colors.white),
          backgroundColor: WidgetStateProperty.all(Colors.grey[800]),
        ),
        icon: Icon(Icons.search),
        onPressed: _handleSearch,
      ),
    );
  }

  Widget _buildClientList() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[700],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListView.builder(
          itemCount: _filteredClients.length,
          itemBuilder: (context, index) =>
              _buildClientListItem(_filteredClients[index]),
        ),
      ),
    );
  }

  Widget _buildClientListItem(Client client) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: InkWell(
        onTap: () {
          setState(() => _selectedClientCode = client.code);
          if (_dialogState == 'edit') {
            _prepareEditDialog(client);
          }
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _selectedClientCode == client.code
                ? Colors.yellow
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            client.nome,
            style: TextStyle(
              color: _selectedClientCode == client.code
                  ? Colors.black
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: TextStyle(color: Colors.black, fontSize: 16)),
    );
  }

  Widget _buildDialogButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        fixedSize: Size(250, 50),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label, style: TextStyle(color: Colors.black, fontSize: 18)),
    );
  }

  Widget _buildCheckbox(
      String label, bool value, void Function(bool?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              fillColor:
                  WidgetStateProperty.resolveWith((states) => Colors.white),
              checkColor: Colors.black,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 14)),
        ],
      ),
    );
  }
}

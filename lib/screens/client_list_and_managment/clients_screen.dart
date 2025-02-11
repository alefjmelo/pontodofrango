import 'package:flutter/material.dart';
import 'package:pontodofrango/utils/operations/client_operations.dart';
import '../../models/client_model.dart';
import 'client_details_screen.dart';
import 'manager_dialog.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientsScreen> {
  late Future<List<Client>> _clientsFuture;
  late bool isEditDialogOpen = false;
  late bool isClientDialogOpen = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _clientsFuture = _loadClients();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Client>> _loadClients() async {
    final fetchedClients = await fetchClients();
    fetchedClients.sort((a, b) => a.nome.compareTo(b.nome));
    return fetchedClients;
  }

  void _refreshClientList() {
    setState(() {
      _clientsFuture = _loadClients();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          appBar: PreferredSize(
              preferredSize: Size.fromHeight(100),
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                ),
                child: Text('Lista de Clientes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 26)),
              )),
          backgroundColor: Colors.grey[800],
          body: Padding(
            padding: const EdgeInsets.only(bottom: 25),
            child: Column(
              children: [
                Expanded(
                  child: _buildClientListView(),
                ),
              ],
            ),
          ),
          floatingActionButton:
              isEditDialogOpen ? null : _buildFloatingButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          isEditDialogOpen = true;
        });
        showDialog(
          context: context,
          builder: (context) {
            return ClientManagerDialogs(onClientChanged: _refreshClientList);
          },
        ).then((_) {
          setState(() {
            isEditDialogOpen = false;
          });
        });
      },
      backgroundColor: Colors.black,
      child: Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      cursorColor: Colors.white,
      controller: _searchController,
      onChanged: (value) => setState(() => _searchText = value),
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white),
        ),
        hintText: 'Buscar Cliente...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.grey[700],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
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
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          iconColor: WidgetStateProperty.all(Colors.white),
          backgroundColor: WidgetStateProperty.all(Colors.grey[800]),
        ),
        icon: Icon(Icons.search),
        onPressed: () {},
      ),
    );
  }

  Widget _buildClientListView() {
    return FutureBuilder<List<Client>>(
      future: _clientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
            color: Colors.yellow,
            strokeWidth: 5.0,
          ));
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return const Center(
              child: Text(
            'Nenhum cliente encontrado.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ));
        } else {
          List<Client> clients = snapshot.data!;
          if (_searchText.isNotEmpty) {
            clients = clients
                .where((client) => client.nome
                    .toLowerCase()
                    .contains(_searchText.toLowerCase()))
                .toList();
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildSearchField(),
              ),
              Expanded(
                child: clients.isEmpty
                    ? Center(
                        child: Text('Nenhum cliente encontrado.',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      )
                    : _buildClientList(clients),
              )
            ],
          );
        }
      },
    );
  }

  Widget _buildClientList(List<Client> clients) {
    return ListView.builder(
      itemCount: clients.length,
      itemBuilder: (context, index) {
        final showHeader =
            index == 0 || clients[index].nome[0] != clients[index - 1].nome[0];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _buildHeader(clients[index].nome[0]),
            _buildClientTile(clients[index]),
          ],
        );
      },
    );
  }

  Widget _buildHeader(String letter) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 10, bottom: 5),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildClientTile(Client client) {
    return ListTile(
      title: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              client.nome,
              style: const TextStyle(color: Colors.black),
            ),
            Text(
              '#${client.code.toString().padLeft(3, '0')}',
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ClientDetailsScreen(client: client)));
      },
      onLongPress: () {
        setState(() {
          isClientDialogOpen = true;
        });
        showDialog(
            context: context,
            builder: (context) {
              return clientOptionsDialog(client); // pass client parameter
            }).then((_) {
          setState(() {
            isClientDialogOpen = false;
          });
        });
      },
    );
  }

  Widget clientOptionsDialog(Client client) {
    return Dialog(
      backgroundColor: Colors.grey[800]!.withOpacity(0.88),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
        side: BorderSide(color: Colors.grey[700]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  await removeClient(client.code);
                  if (mounted) Navigator.pop(context);
                  _refreshClientList();
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(250, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Remover',
                    style: TextStyle(color: Colors.black, fontSize: 18)),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ClientManagerDialogs(
                        client: client,
                        onClientChanged: _refreshClientList,
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  fixedSize: Size(250, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Editar',
                    style: TextStyle(color: Colors.black, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

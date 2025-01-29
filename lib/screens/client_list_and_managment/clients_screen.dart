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
  late bool isDialogOpen = false;
  @override
  void initState() {
    super.initState();
    _clientsFuture = _loadClients();
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
          body: Column(
            children: [
              Expanded(child: _buildClientListView()),
            ],
          ),
          floatingActionButton: isDialogOpen ? null : _buildFloatingButton(),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ),
      ),
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          isDialogOpen = true;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ClientManagerDialogs(onClientChanged: _refreshClientList);
          },
        ).then((_) {
          setState(() {
            isDialogOpen = false;
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
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text(
            'Nenhum cliente encontrado.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ));
        } else {
          return _buildClientList(snapshot.data!);
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
    );
  }
}

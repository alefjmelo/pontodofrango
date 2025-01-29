import 'dart:math';

import '../../models/client_model.dart';
import '../database/client_database.dart';

Future<void> addClient(name, phoneNumber, address) async {
  List<Client> existingClients = await ClientDataBase().getClients();
  Set<int?> existingCodes =
      existingClients.map((client) => client.code).toSet();

  int generateUniqueCode() {
    Random random = Random();
    int code;
    do {
      code = random.nextInt(900);
    } while (existingCodes.contains(code));
    return code;
  }

  int uniqueCode = generateUniqueCode();

  Client client = Client(
    nome: name,
    numero: phoneNumber,
    endereco: address,
    code: uniqueCode,
  );
  await ClientDataBase().insertClient(client);
}

// Retrieve all clients
Future<List<Client>> fetchClients() async {
  return await ClientDataBase().getClients();
}

// Update an existing client
Future<void> modifyClient(Client client) async {
  await ClientDataBase().updateClient(client);
}

// Delete a client
Future<void> removeClient(int code) async {
  await ClientDataBase().deleteClient(code);
}

// Update client balance
Future<void> updateClientBalance(
    int clientCode, double creditoConta, double saldoDevedor) async {
  await ClientDataBase()
      .updateClientBalance(clientCode, creditoConta, saldoDevedor);
}

// Get client with balances
Future<Client> getClientWithBalances(int code) async {
  return await ClientDataBase().getClientWithBalances(code);
}

// Edit client data
Future<void> editClientData(int code,
    {String? name, String? phoneNumber, String? address}) async {
  await ClientDataBase().editClientData(
    code,
    nome: name,
    numero: phoneNumber,
    endereco: address,
  );
}

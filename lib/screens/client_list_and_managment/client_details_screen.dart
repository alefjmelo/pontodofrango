import 'package:flutter/material.dart';
import 'package:pontodofrango/screens/navigation_screen.dart';
import '../../models/client_model.dart';
import '../../models/clientbill_model.dart';
import '../../models/paymenthistory_model.dart';
import '../../utils/operations/bills_operations.dart';
import '../../utils/operations/client_operations.dart';
import '../../utils/operations/payment_history_operations.dart';
import 'payment_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;

  const ClientDetailsScreen({
    super.key,
    required this.client,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  late Client currentClient;

  @override
  void initState() {
    super.initState();
    currentClient = widget.client;
    _refreshClientData();
  }

  Future<void> _refreshClientData() async {
    try {
      final updatedClient = await getClientWithBalances(widget.client.code);
      setState(() {
        currentClient = updatedClient;
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => NavigationScreen(),
          ),
          (route) => false,
        );
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.grey[800],
          appBar: AppBar(
            backgroundColor: Colors.grey[700],
            title: const Text(
              'Detalhes da Conta',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                weight: 2.0,
              ),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NavigationScreen(),
                  ),
                );
              },
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.client.nome,
                    style: const TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Endereço: ${widget.client.endereco}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Número: ${widget.client.numero}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  _buildPaymentHistoryButton(context),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 400,
                    child: _buildBillsSection(),
                  ),
                  const SizedBox(height: 20),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentHistoryButton(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        foregroundColor: Colors.black,
        backgroundColor: Colors.yellow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () => _showPaymentHistoryDialog(context),
      child: const Text(
        'Histórico de Pagamentos',
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  void _showPaymentHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        'Histórico de Pagamentos',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                  Flexible(
                    child: FutureBuilder<List<PaymentHistory>>(
                      future: fetchPaymentHistoryByClient(widget.client.code),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                              child: Container(
                            constraints: BoxConstraints(minHeight: 70),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'Sem histórico de pagamentos.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ));
                        } else {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: double.maxFinite,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final payment = snapshot.data![index];
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                    color: Colors.yellow[100],
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Data: ${payment.paymentDate}'),
                                          Text(
                                              'Total da Conta: R\$ ${payment.totalBill.toStringAsFixed(2)}'),
                                          Text(
                                              'Valor Pago: R\$ ${payment.amountPaid.toStringAsFixed(2)}'),
                                          if (payment.debit != null &&
                                              payment.debit! > 0)
                                            Text(
                                                'Saldo Devedor: R\$ ${payment.debit!.toStringAsFixed(2)}'),
                                          if (payment.credit != null &&
                                              payment.credit! > 0)
                                            Text(
                                                'Crédito em Conta: R\$ ${payment.credit!.toStringAsFixed(2)}'),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillsSection() {
    return Container(
      constraints: BoxConstraints(
          minHeight: 400, maxHeight: 400, minWidth: double.maxFinite),
      color: Colors.yellow[100],
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          const Text(
            'NFC-e',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Crédito em conta: R\$ ${currentClient.creditoConta.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16)),
                Text(
                    'Saldo Devedor: R\$ ${currentClient.saldoDevedor.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Bill>>(
              future: fetchBillsForClient(widget.client.code),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Align(
                    alignment: Alignment.center,
                    child: const Text(
                      'Nenhuma conta encontrada para esse cliente.',
                      style: TextStyle(fontSize: 14),
                    ),
                  );
                } else {
                  return Column(
                    children: [
                      Flexible(child: _buildBillsList(snapshot.data!)),
                      _buildTotalSection(snapshot.data!),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList(List<Bill> bills) {
    return ListView.builder(
      itemCount: bills.length,
      itemBuilder: (context, index) => _buildBillItem(bills[index]),
    );
  }

  Widget _buildBillItem(Bill bill) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(bill.date,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bill.description.isNotEmpty
                    ? bill.description
                    : 'Descrição não informada',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                'R\$ ${bill.value.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(List<Bill> bills) {
    final total = bills.fold<double>(0, (sum, item) => sum + item.value);
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.yellow[700],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(
            'R\$ ${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(250, 50),
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            // Fetch the latest client data
            final updatedClient =
                await getClientWithBalances(widget.client.code);
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FutureBuilder<List<Bill>>(
                    future: fetchBillsForClient(updatedClient.code),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return PaymentScreen(
                            client: updatedClient, totalBill: 0);
                      } else {
                        final total = snapshot.data!
                            .fold<double>(0, (sum, item) => sum + item.value);
                        return PaymentScreen(
                            client: updatedClient, totalBill: total);
                      }
                    },
                  ),
                ),
              );
            }
          },
          child: Text(
            'Pagar',
            style: TextStyle(fontSize: 18),
          ),
        ),
        SizedBox(
          height: 50,
          width: 50,
          child: FloatingActionButton(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            onPressed: () {
              // Add your "Compartilhar" button logic here
            },
            backgroundColor: Colors.white,
            child: Icon(Icons.share), // You can customize the color
          ),
        )
      ],
    );
  }
}

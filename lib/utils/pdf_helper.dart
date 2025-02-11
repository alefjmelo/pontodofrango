import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/client_model.dart';
import '../models/clientbill_model.dart';

class PdfHelper {
  static Future<File> generateBillReport(
      Client client, List<Bill> bills) async {
    final pdf = pw.Document();
    final total = bills.fold<double>(0, (sum, bill) => sum + bill.value);

    // Load the app icon
    final ByteData imageData = await rootBundle.load('assets/icon.png');
    final Uint8List iconBytes = imageData.buffer.asUint8List();
    final logoImage = pw.MemoryImage(iconBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80.copyWith(
          marginLeft: 8,
          marginRight: 8,
          marginTop: 8,
          marginBottom: 8,
        ),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (context) {
          return pw.Container(
            color: PdfColor.fromHex('FFFFF0'),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 40,
                      height: 40,
                      child: pw.Image(logoImage),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PONTO DO FRANGO',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              )),
                          pw.Text('DOCUMENTO AUXILIAR',
                              style: pw.TextStyle(fontSize: 8)),
                          pw.Text('DE CONTA DO CLIENTE',
                              style: pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5),

                // Client Info
                pw.Container(
                  width: double.infinity,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Cliente: ${client.nome}',
                          style: pw.TextStyle(fontSize: 8)),
                      pw.Text('End.: ${client.endereco}',
                          style: pw.TextStyle(fontSize: 8)),
                      pw.Text('Tel.: ${client.numero}',
                          style: pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.Divider(thickness: 0.5),

                // Items Header
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('DATA', style: pw.TextStyle(fontSize: 7)),
                    ),
                    pw.Expanded(
                      flex: 4,
                      child: pw.Text('DESCRIÇÃO',
                          style: pw.TextStyle(fontSize: 7)),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text('VALOR',
                          style: pw.TextStyle(fontSize: 7),
                          textAlign: pw.TextAlign.right),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5),

                // Items
                ...bills.map((bill) => pw.Container(
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(bill.date,
                                style: pw.TextStyle(fontSize: 7)),
                          ),
                          pw.Expanded(
                            flex: 4,
                            child: pw.Text(bill.description,
                                style: pw.TextStyle(fontSize: 7)),
                          ),
                          pw.Expanded(
                            flex: 2,
                            child: pw.Text(
                                'R\$ ${bill.value.toStringAsFixed(2)}',
                                style: pw.TextStyle(fontSize: 7),
                                textAlign: pw.TextAlign.right),
                          ),
                        ],
                      ),
                    )),

                pw.Divider(thickness: 0.5),

                // Totals and Balance
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(vertical: 5),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Valor parcial:',
                              style: pw.TextStyle(fontSize: 8)),
                          pw.Text('R\$ ${total.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                      pw.SizedBox(height: 5),
                      pw.Container(
                        padding: pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(width: 0.5),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Crédito:',
                                    style: pw.TextStyle(fontSize: 8)),
                                pw.Text(
                                    'R\$ ${client.creditoConta.toStringAsFixed(2)}',
                                    style: pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                            pw.SizedBox(height: 2),
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Débito:',
                                    style: pw.TextStyle(fontSize: 8)),
                                pw.Text(
                                    'R\$ ${client.saldoDevedor.toStringAsFixed(2)}',
                                    style: pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Valor total:',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          pw.Text(
                              'R\$ ${(total + client.saldoDevedor - client.creditoConta).toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                // Footer
                pw.SizedBox(height: 10),
                pw.Text('Emissão: ${DateTime.now().toString().split('.')[0]}',
                    style: pw.TextStyle(fontSize: 6)),
                pw.Text('* * * * * * * * * * * * * * *',
                    style: pw.TextStyle(fontSize: 6)),
              ],
            ),
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/extrato_${client.nome}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

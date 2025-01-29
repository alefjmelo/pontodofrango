import '../../models/paymenthistory_model.dart';
import '../database/payment_history_database.dart';

// Insert a new payment history record
Future<void> addPaymentHistory(int clientCode, String paymentDate,
    double totalBill, double amountPaid, double debit, double credit) async {
  PaymentHistory paymentHistory = PaymentHistory(
    clientCode: clientCode,
    paymentDate: paymentDate,
    totalBill: totalBill,
    amountPaid: amountPaid,
    debit: debit,
    credit: credit,
  );

  await PaymentHistoryDatabase.instance
      .insertPaymentHistory(paymentHistory.toMap());
}

// Retrieve all payment history records for a client
Future<List<PaymentHistory>> fetchPaymentHistoryByClient(int clientCode) async {
  final List<Map<String, dynamic>> maps = await PaymentHistoryDatabase.instance
      .getPaymentHistoryForClient(clientCode);
  return List.generate(maps.length, (i) {
    return PaymentHistory.fromMap(maps[i]);
  });
}

// Update an existing payment history record
Future<void> modifyPaymentHistory(PaymentHistory paymentHistory) async {
  await PaymentHistoryDatabase.instance
      .updatePaymentHistory(paymentHistory.toMap());
}

// Delete a payment history record
Future<void> removePaymentHistory(int id) async {
  await PaymentHistoryDatabase.instance.deletePaymentHistory(id);
}

// Retrieve total amount for the current week
Future<Map<String, double>> getTotalAmountForWeekPayments() async {
  return await PaymentHistoryDatabase.instance.getTotalAmountForWeek();
}

// Retrieve total amount for a specific month
Future<Map<String, double>> getTotalAmountForMonthPayments(int month) async {
  return await PaymentHistoryDatabase.instance.getTotalAmountForMonth(month);
}

// Retrieve total amount for a specific year
Future<Map<String, double>> getTotalAmountForYearPayments(int year) async {
  return await PaymentHistoryDatabase.instance.getTotalAmountForYear(year);
}

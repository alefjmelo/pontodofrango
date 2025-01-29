import '../../models/clientbill_model.dart';
import '../database/bills_database.dart';

// Insert a new bill
Future<void> addBill(
    int clientCode, String description, double value, String date) async {
  Bill bill = Bill(
    clientCode: clientCode,
    description: description,
    value: value,
    date: date,
  );
  await BillDatabaseHelper().insertBill(bill);
}

// Retrieve all bills for a specific client
Future<List<Bill>> fetchBillsForClient(int clientCode) async {
  return await BillDatabaseHelper().getBillsForClient(clientCode);
}

// Delete a bill
Future<void> removeBill(int clientCode, String description, String date) async {
  await BillDatabaseHelper().deleteBill(clientCode, description, date);
}

// Update removeAllBillsForClient to save history first
Future<void> removeAllBillsForClient(int clientCode) async {
  final db = BillDatabaseHelper();
  await db.moveBillsToHistory(clientCode);
  await db.deleteAllBillsForClient(clientCode);
}

// Retrieve total amount for the current week
Future<Map<String, double>> getTotalAmountForWeekBills() async {
  return await BillDatabaseHelper().getTotalAmountForWeek();
}

// Retrieve total amount for a specific month
Future<Map<String, double>> getTotalAmountForMonthBills(int month) async {
  return await BillDatabaseHelper().getTotalAmountForMonth(month);
}

// Retrieve total amount for a specific year
Future<Map<String, double>> getTotalAmountForYearBills(int year) async {
  return await BillDatabaseHelper().getTotalAmountForYear(year);
}

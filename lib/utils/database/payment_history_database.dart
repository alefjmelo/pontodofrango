import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PaymentHistoryDatabase {
  static final PaymentHistoryDatabase instance =
      PaymentHistoryDatabase._internal();
  static Database? _database;

  PaymentHistoryDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'payment_history_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE payment_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        clientCode INTEGER,
        paymentDate TEXT,
        totalBill REAL,
        amountPaid REAL,
        debit REAL,
        credit REAL,
        FOREIGN KEY(clientCode) REFERENCES clients(code)
      )
    ''');
  }

  Future<int> insertPaymentHistory(Map<String, dynamic> payment) async {
    Database db = await database;
    return await db.insert('payment_history', payment);
  }

  Future<List<Map<String, dynamic>>> getPaymentHistoryForClient(
      int clientCode) async {
    Database db = await database;
    return await db.query(
      'payment_history',
      where: 'clientCode = ?',
      whereArgs: [clientCode],
      orderBy: 'paymentDate DESC',
    );
  }

  Future<int> updatePaymentHistory(Map<String, dynamic> payment) async {
    Database db = await database;
    return await db.update(
      'payment_history',
      payment,
      where: 'id = ?',
      whereArgs: [payment['id']],
    );
  }

  Future<int> deletePaymentHistory(int id) async {
    Database db = await database;
    return await db.delete(
      'payment_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, double>> getTotalAmountForWeek() async {
    Database db = await database;
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    Map<String, double> dailyTotals = {};

    for (int i = 0; i < 7; i++) {
      DateTime day = startOfWeek.add(Duration(days: i));
      String dayStr = DateFormat('dd/MM/yyyy').format(day);
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT SUM(amountPaid) as totalAmount
        FROM payment_history
        WHERE paymentDate = ?
      ''', [dayStr]);

      dailyTotals[dayStr] =
          result.isNotEmpty && result[0]['totalAmount'] != null
              ? result[0]['totalAmount'] as double
              : 0.0;
    }

    return dailyTotals;
  }

  Future<Map<String, double>> getTotalAmountForMonth(int month) async {
    Database db = await database;
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, month, 1);
    DateTime endOfMonth = DateTime(now.year, month + 1, 0);

    Map<String, double> dailyTotals = {};

    for (int i = 0; i < endOfMonth.day; i++) {
      DateTime day = startOfMonth.add(Duration(days: i));
      String dayStr = DateFormat('dd/MM/yyyy').format(day);
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT SUM(amountPaid) as totalAmount
        FROM payment_history
        WHERE paymentDate = ?
      ''', [dayStr]);

      dailyTotals[dayStr] =
          result.isNotEmpty && result[0]['totalAmount'] != null
              ? result[0]['totalAmount'] as double
              : 0.0;
    }

    return dailyTotals;
  }

  Future<Map<String, double>> getTotalAmountForYear(int year) async {
    Database db = await database;
    Map<String, double> monthlyTotals = {};

    // Initialize monthly totals for all months
    for (int month = 1; month <= 12; month++) {
      String monthName =
          DateFormat('MMMM', 'pt_BR').format(DateTime(year, month, 1));
      monthlyTotals[monthName] = 0.0;
    }

    final List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT paymentDate, SUM(amountPaid) as totalAmount
    FROM payment_history
    WHERE SUBSTR(paymentDate, 7, 4) = ?
    GROUP BY paymentDate
  ''', [year.toString()]);

    for (var row in result) {
      String dateStr = row['paymentDate'];
      double totalAmount = row['totalAmount'] ?? 0.0;
      DateTime date = DateFormat('dd/MM/yyyy').parse(dateStr);
      String monthName =
          DateFormat('MMMM', 'pt_BR').format(DateTime(year, date.month, 1));
      monthlyTotals[monthName] =
          (monthlyTotals[monthName] ?? 0.0) + totalAmount;
    }

    return monthlyTotals;
  }
}

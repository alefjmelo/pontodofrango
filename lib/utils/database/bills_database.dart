import 'dart:async';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/clientbill_model.dart';

class BillDatabaseHelper {
  static final BillDatabaseHelper _instance = BillDatabaseHelper._internal();
  factory BillDatabaseHelper() => _instance;
  static Database? _database;

  BillDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bill_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bills(
        clientCode INTEGER,
        description TEXT,
        value REAL,
        date TEXT,
        FOREIGN KEY(clientCode) REFERENCES clients(code)
      )
    ''');

    await db.execute('''
      CREATE TABLE bills_history(
        clientCode INTEGER,
        description TEXT,
        value REAL,
        date TEXT,
        FOREIGN KEY(clientCode) REFERENCES clients(code)
      )
    ''');
  }

  Future<int> insertBill(Bill bill) async {
    Database db = await database;
    return await db.insert('bills', bill.toMap());
  }

  Future<List<Bill>> getBillsForClient(int clientCode) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bills',
      where: 'clientCode = ?',
      whereArgs: [clientCode],
    );
    return List.generate(maps.length, (i) {
      return Bill.fromMap(maps[i]);
    });
  }

  Future<int> deleteBill(
      int clientCode, String description, String date) async {
    Database db = await database;
    return await db.delete(
      'bills',
      where: 'clientCode = ? AND description = ? AND date = ?',
      whereArgs: [clientCode, description, date],
    );
  }

  Future<int> deleteAllBillsForClient(int clientCode) async {
    Database db = await database;
    return await db.delete(
      'bills',
      where: 'clientCode = ?',
      whereArgs: [clientCode],
    );
  }

  Future<void> moveBillsToHistory(int clientCode) async {
    Database db = await database;
    await db.transaction((txn) async {
      // Get all bills for the client
      final List<Map<String, dynamic>> bills = await txn.query(
        'bills',
        where: 'clientCode = ?',
        whereArgs: [clientCode],
      );

      // Insert bills into history
      for (var bill in bills) {
        await txn.insert('bills_history', bill);
      }
    });
  }

  Future<Map<String, double>> getTotalAmountForWeek() async {
    Database db = await database;
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    Map<String, double> dailyTotals = {};

    for (int i = 0; i < 7; i++) {
      DateTime day = startOfWeek.add(Duration(days: i));
      String dayStr = DateFormat('dd/MM/yyyy').format(day);

      final List<Map<String, dynamic>> combinedBills = await db.rawQuery('''
        SELECT CAST(COALESCE(SUM(CAST(value AS REAL)), 0) AS REAL) as totalAmount
        FROM (
          SELECT value, date FROM bills
          UNION ALL
          SELECT value, date FROM bills_history
        )
        WHERE date = ?
      ''', [dayStr]);

      double total = (combinedBills[0]['totalAmount'] as num).toDouble();
      dailyTotals[dayStr] = total;
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

      final List<Map<String, dynamic>> combinedBills = await db.rawQuery('''
        SELECT CAST(COALESCE(SUM(CAST(value AS REAL)), 0) AS REAL) as totalAmount
        FROM (
          SELECT value, date FROM bills
          UNION ALL
          SELECT value, date FROM bills_history
        )
        WHERE date = ?
      ''', [dayStr]);

      double total = (combinedBills[0]['totalAmount'] as num).toDouble();
      dailyTotals[dayStr] = total;
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
      SELECT date, CAST(SUM(CAST(value AS REAL)) AS REAL) as totalAmount
      FROM (
        SELECT value, date FROM bills
        UNION ALL
        SELECT value, date FROM bills_history
      )
      WHERE SUBSTR(date, 7, 4) = ?
      GROUP BY date
    ''', [year.toString()]);

    for (var row in result) {
      String dateStr = row['date'];
      double totalAmount = (row['totalAmount'] as num).toDouble();
      DateTime date = DateFormat('dd/MM/yyyy').parse(dateStr);
      String monthName =
          DateFormat('MMMM', 'pt_BR').format(DateTime(year, date.month, 1));
      monthlyTotals[monthName] =
          (monthlyTotals[monthName] ?? 0.0) + totalAmount;
    }

    return monthlyTotals;
  }
}

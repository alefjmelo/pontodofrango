class PaymentHistory {
  final int clientCode;
  final String paymentDate;
  double totalBill;
  double amountPaid;
  double? debit;
  double? credit;

  PaymentHistory({
    required this.clientCode,
    required this.paymentDate,
    required this.totalBill,
    required this.amountPaid,
    this.debit,
    this.credit,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientCode': clientCode,
      'paymentDate': paymentDate,
      'totalBill': totalBill,
      'amountPaid': amountPaid,
      'debit': debit,
      'credit': credit,
    };
  }

  factory PaymentHistory.fromMap(Map<String, dynamic> map) {
    return PaymentHistory(
      clientCode: map['clientCode'],
      paymentDate: map['paymentDate'],
      totalBill: map['totalBill'],
      amountPaid: map['amountPaid'],
      debit: map['debit'],
      credit: map['credit'],
    );
  }
}

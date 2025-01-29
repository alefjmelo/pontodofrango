class Bill {
  final int clientCode;
  final String description;
  final double value;
  final String date;

  Bill({
    required this.clientCode,
    required this.description,
    required this.value,
    required this.date,
  });

  // Convert a Bill object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'clientCode': clientCode,
      'description': description,
      'value': value,
      'date': date,
    };
  }

  // Extract a Bill object from a Map object
  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      clientCode: map['clientCode'],
      description: map['description'],
      value: map['value'],
      date: map['date'],
    );
  }
}

class Client {
  final int code;
  final String nome;
  final String endereco;
  final String numero;
  double creditoConta;
  double saldoDevedor;

  Client({
    required this.code,
    required this.nome,
    required this.endereco,
    required this.numero,
    this.creditoConta = 0.0,
    this.saldoDevedor = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'nome': nome,
      'endereco': endereco,
      'numero': numero,
      'creditoConta': creditoConta,
      'saldoDevedor': saldoDevedor,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      code: map['code'],
      nome: map['nome'],
      endereco: map['endereco'],
      numero: map['numero'],
      creditoConta: map['creditoConta']?.toDouble() ?? 0.0,
      saldoDevedor: map['saldoDevedor']?.toDouble() ?? 0.0,
    );
  }

  Client copyWith({
    int? code,
    String? nome,
    String? endereco,
    String? numero,
    double? creditoConta,
    double? saldoDevedor,
  }) {
    return Client(
      code: code ?? this.code,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      numero: numero ?? this.numero,
      creditoConta: creditoConta ?? this.creditoConta,
      saldoDevedor: saldoDevedor ?? this.saldoDevedor,
    );
  }
}

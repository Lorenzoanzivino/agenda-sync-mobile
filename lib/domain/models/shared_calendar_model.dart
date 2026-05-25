class SharedCalendarModel {
  final String id;
  final String nome;
  final String? inviteCode;

  SharedCalendarModel({
    required this.id,
    required this.nome,
    this.inviteCode,
  });

  factory SharedCalendarModel.fromJson(Map<String, dynamic> json) {
    return SharedCalendarModel(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Calendario Condiviso',
      inviteCode: json['inviteCode']?.toString(), // Ora il JSON conterrà il valore
    );
  }
}
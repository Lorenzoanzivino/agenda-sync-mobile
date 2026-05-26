class TaskModel {
  final String id;
  final String titolo;
  final String descrizione;
  final String dataInizio;
  final String dataFine;
  final bool tuttoIlGiorno;
  final String colore;
  final String userId;
  final String? sharedCalendarId;
  final String? sharedCalendarNome;
  final String status;
  final String priorita;

  TaskModel({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.dataInizio,
    required this.dataFine,
    required this.tuttoIlGiorno,
    required this.colore,
    required this.userId,
    this.sharedCalendarId,
    this.sharedCalendarNome,
    required this.status,
    required this.priorita,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id']?.toString() ?? '',
      titolo: json['titolo']?.toString() ?? 'Senza Titolo',
      descrizione: json['descrizione']?.toString() ?? '',
      dataInizio: json['dataInizio']?.toString() ?? DateTime.now().toIso8601String(),
      dataFine: json['dataFine']?.toString() ?? DateTime.now().toIso8601String(),
      tuttoIlGiorno: json['tuttoIlGiorno'] == true,
      colore: json['colore']?.toString() ?? '#06B6D4',
      userId: json['userId']?.toString() ?? '',
      sharedCalendarId: json['sharedCalendarId']?.toString(),
      sharedCalendarNome: json['sharedCalendarNome']?.toString(),
      status: json['status']?.toString() ?? 'TODO',
      priorita: json['priorita']?.toString() ?? 'LOW',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titolo': titolo,
      'descrizione': descrizione,
      'dataInizio': dataInizio,
      'dataFine': dataFine,
      'tuttoIlGiorno': tuttoIlGiorno,
      'colore': colore,
      'userId': userId,
      'sharedCalendarId': sharedCalendarId,
      'sharedCalendarNome': sharedCalendarNome,
      'status': status,
      'priorita': priorita,
    };
  }
}
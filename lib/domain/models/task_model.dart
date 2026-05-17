class TaskModel {
  final String id;
  final String titolo;
  final String descrizione;
  final String dataInizio;
  final String dataFine;
  final bool tuttoIlGiorno;
  final String userId;
  final String? sharedCalendarId; // Aggiunto questo campo
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
    required this.userId,
    this.sharedCalendarId, // Aggiunto qui
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
      userId: json['userId']?.toString() ?? '',
      sharedCalendarId: json['sharedCalendarId']?.toString(), // Mappatura JSON
      sharedCalendarNome: json['sharedCalendarNome']?.toString(),
      status: json['status']?.toString() ?? 'TODO',
      priorita: json['priorita']?.toString() ?? 'LOW',
    );
  }
}
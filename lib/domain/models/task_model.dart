class TaskModel {
  final String id;
  final String titolo;
  final String descrizione;
  final String dataInizio;
  final String dataFine;
  final String priorita;
  final String status;
  final bool tuttoIlGiorno;
  final String? sharedCalendarNome;

  TaskModel({
    required this.id,
    required this.titolo,
    required this.descrizione,
    required this.dataInizio,
    required this.dataFine,
    required this.priorita,
    required this.status,
    required this.tuttoIlGiorno,
    this.sharedCalendarNome,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    dynamic rawNome = json['sharedCalendarNome'] ?? json['sharedCalendarId'];
    String? calendarNome;

    if (rawNome != null) {
      String s = rawNome.toString().trim();
      // Ora diciamo a Flutter che se la stringa è "Privato", equivale a null!
      if (s.isNotEmpty &&
          s.toLowerCase() != "null" &&
          s.toLowerCase() != "undefined" &&
          s.toLowerCase() != "privato") { // <--- LA MAGIA È QUI
        calendarNome = s;
      }
    }

    return TaskModel(
      id: json['id']?.toString() ?? '',
      titolo: json['titolo']?.toString() ?? 'Senza Titolo',
      descrizione: json['descrizione']?.toString() ?? '',
      dataInizio: json['dataInizio']?.toString() ?? DateTime.now().toIso8601String(),
      dataFine: json['dataFine']?.toString() ?? DateTime.now().toIso8601String(),
      priorita: json['priorita']?.toString() ?? 'LOW',
      status: json['status']?.toString() ?? 'TODO',
      tuttoIlGiorno: json['tuttoIlGiorno'] == true || json['tuttoIlGiorno'] == 'true',
      sharedCalendarNome: calendarNome,
    );
  }
}
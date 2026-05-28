class UserModel {
  final String id;
  final String email;
  final String nome;
  final String? dataNascita;
  final String? token;
  final String? orarioNotificaMattutina;

  UserModel({
    required this.id,
    required this.email,
    required this.nome,
    this.dataNascita,
    this.token,
    this.orarioNotificaMattutina,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nome: json['nome'] ?? '',
      dataNascita: json['dataNascita'],
      token: json['token'],
      orarioNotificaMattutina: json['orarioNotificaMattutina'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nome': nome,
      'dataNascita': dataNascita,
      'token': token,
      'orarioNotificaMattutina': orarioNotificaMattutina,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? nome,
    String? dataNascita,
    String? token,
    String? orarioNotificaMattutina,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      nome: nome ?? this.nome,
      dataNascita: dataNascita ?? this.dataNascita,
      token: token ?? this.token,
      orarioNotificaMattutina: orarioNotificaMattutina ?? this.orarioNotificaMattutina,
    );
  }
}
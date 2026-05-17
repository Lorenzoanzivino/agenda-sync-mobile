// lib/domain/models/user_model.dart
class UserModel {
  final String id;
  final String email;
  final String nome;
  final String? token;

  UserModel({
    required this.id,
    required this.email,
    required this.nome,
    this.token,
  });

  // Factory per deserializzare il JSON che arriva da Spring Boot
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      nome: json['nome'] ?? '',
      token: json['token'],
    );
  }
}
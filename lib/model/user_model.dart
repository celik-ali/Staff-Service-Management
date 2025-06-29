class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> services;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.services,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      services: List<String>.from(json['services'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'services': services,
    };
  }
}

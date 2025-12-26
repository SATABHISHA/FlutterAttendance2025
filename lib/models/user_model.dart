import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String corpId;
  final String companyId;
  final String companyName;
  final bool isAdmin;
  final bool isSupervisor;
  final String? supervisorId;
  final String? profileImagePath;
  final bool biometricEnabled;
  final bool canCheckInFromAnywhere; // Admin can allow supervisor to check-in from anywhere
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.corpId,
    required this.companyId,
    required this.companyName,
    this.isAdmin = false,
    this.isSupervisor = false,
    this.supervisorId,
    this.profileImagePath,
    this.biometricEnabled = false,
    this.canCheckInFromAnywhere = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromRealtimeDB(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      corpId: data['corpId'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      isSupervisor: data['isSupervisor'] ?? false,
      supervisorId: data['supervisorId'],
      profileImagePath: data['profileImagePath'],
      biometricEnabled: data['biometricEnabled'] ?? false,
      canCheckInFromAnywhere: data['canCheckInFromAnywhere'] ?? false,
      createdAt: data['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['createdAt']) 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toRealtimeDB() {
    return {
      'name': name,
      'email': email,
      'corpId': corpId,
      'companyId': companyId,
      'companyName': companyName,
      'isAdmin': isAdmin,
      'isSupervisor': isSupervisor,
      'supervisorId': supervisorId,
      'profileImagePath': profileImagePath,
      'biometricEnabled': biometricEnabled,
      'canCheckInFromAnywhere': canCheckInFromAnywhere,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? corpId,
    String? companyId,
    String? companyName,
    bool? isAdmin,
    bool? isSupervisor,
    String? supervisorId,
    String? profileImagePath,
    bool? biometricEnabled,
    bool? canCheckInFromAnywhere,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      corpId: corpId ?? this.corpId,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      isAdmin: isAdmin ?? this.isAdmin,
      isSupervisor: isSupervisor ?? this.isSupervisor,
      supervisorId: supervisorId ?? this.supervisorId,
      profileImagePath: profileImagePath ?? this.profileImagePath,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      canCheckInFromAnywhere: canCheckInFromAnywhere ?? this.canCheckInFromAnywhere,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        corpId,
        companyId,
        companyName,
        isAdmin,
        isSupervisor,
        supervisorId,
        profileImagePath,
        biometricEnabled,
        canCheckInFromAnywhere,
        createdAt,
        updatedAt,
      ];
}

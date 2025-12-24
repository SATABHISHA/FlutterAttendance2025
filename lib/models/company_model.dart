import 'package:equatable/equatable.dart';

class CompanyModel extends Equatable {
  final String id;
  final String companyName;
  final String corpId;
  final String branch;
  final String state;
  final String city;
  final String address;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CompanyModel({
    required this.id,
    required this.companyName,
    required this.corpId,
    required this.branch,
    required this.state,
    required this.city,
    required this.address,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.updatedAt,
  });

  factory CompanyModel.fromRealtimeDB(String id, Map<String, dynamic> data) {
    return CompanyModel(
      id: id,
      companyName: data['companyName'] ?? '',
      corpId: data['corpId'] ?? '',
      branch: data['branch'] ?? '',
      state: data['state'] ?? '',
      city: data['city'] ?? '',
      address: data['address'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdByName: data['createdByName'] ?? '',
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
      'companyName': companyName,
      'corpId': corpId,
      'branch': branch,
      'state': state,
      'city': city,
      'address': address,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  CompanyModel copyWith({
    String? id,
    String? companyName,
    String? corpId,
    String? branch,
    String? state,
    String? city,
    String? address,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      corpId: corpId ?? this.corpId,
      branch: branch ?? this.branch,
      state: state ?? this.state,
      city: city ?? this.city,
      address: address ?? this.address,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyName,
        corpId,
        branch,
        state,
        city,
        address,
        createdBy,
        createdByName,
        createdAt,
        updatedAt,
      ];
}

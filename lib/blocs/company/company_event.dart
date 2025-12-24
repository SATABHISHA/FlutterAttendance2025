import 'package:equatable/equatable.dart';

abstract class CompanyEvent extends Equatable {
  const CompanyEvent();

  @override
  List<Object?> get props => [];
}

class CompanyLoadAll extends CompanyEvent {}

class CompanyLoadCorpIds extends CompanyEvent {}

class CompanyCreate extends CompanyEvent {
  final String companyName;
  final String corpId;
  final String branch;
  final String state;
  final String city;
  final String address;
  final String createdBy;
  final String createdByName;

  const CompanyCreate({
    required this.companyName,
    required this.corpId,
    required this.branch,
    required this.state,
    required this.city,
    required this.address,
    required this.createdBy,
    required this.createdByName,
  });

  @override
  List<Object?> get props => [
        companyName,
        corpId,
        branch,
        state,
        city,
        address,
        createdBy,
        createdByName,
      ];
}

class CompanyUpdate extends CompanyEvent {
  final String id;
  final String companyName;
  final String corpId;
  final String branch;
  final String state;
  final String city;
  final String address;

  const CompanyUpdate({
    required this.id,
    required this.companyName,
    required this.corpId,
    required this.branch,
    required this.state,
    required this.city,
    required this.address,
  });

  @override
  List<Object?> get props => [id, companyName, corpId, branch, state, city, address];
}

class CompanyDelete extends CompanyEvent {
  final String id;

  const CompanyDelete({required this.id});

  @override
  List<Object?> get props => [id];
}

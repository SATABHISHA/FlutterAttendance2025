import 'package:equatable/equatable.dart';
import '../../models/company_model.dart';

enum CompanyStateStatus { initial, loading, loaded, error }

class CompanyState extends Equatable {
  final CompanyStateStatus status;
  final List<CompanyModel> companies;
  final List<String> corpIds;
  final String? errorMessage;
  final bool isCreating;

  const CompanyState({
    this.status = CompanyStateStatus.initial,
    this.companies = const [],
    this.corpIds = const [],
    this.errorMessage,
    this.isCreating = false,
  });

  CompanyState copyWith({
    CompanyStateStatus? status,
    List<CompanyModel>? companies,
    List<String>? corpIds,
    String? errorMessage,
    bool? isCreating,
  }) {
    return CompanyState(
      status: status ?? this.status,
      companies: companies ?? this.companies,
      corpIds: corpIds ?? this.corpIds,
      errorMessage: errorMessage ?? this.errorMessage,
      isCreating: isCreating ?? this.isCreating,
    );
  }

  @override
  List<Object?> get props => [
        status,
        companies,
        corpIds,
        errorMessage,
        isCreating,
      ];
}

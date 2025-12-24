import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/company_service.dart';
import 'company_event.dart';
import 'company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  final CompanyService _companyService;

  CompanyBloc({required CompanyService companyService})
      : _companyService = companyService,
        super(const CompanyState()) {
    on<CompanyLoadAll>(_onLoadAll);
    on<CompanyLoadCorpIds>(_onLoadCorpIds);
    on<CompanyCreate>(_onCreate);
    on<CompanyUpdate>(_onUpdate);
    on<CompanyDelete>(_onDelete);
  }

  Future<void> _onLoadAll(
    CompanyLoadAll event,
    Emitter<CompanyState> emit,
  ) async {
    emit(state.copyWith(status: CompanyStateStatus.loading));

    try {
      final companies = await _companyService.getAllCompanies();
      final corpIds = companies.map((c) => c.corpId).toSet().toList();

      emit(state.copyWith(
        status: CompanyStateStatus.loaded,
        companies: companies,
        corpIds: corpIds,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CompanyStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadCorpIds(
    CompanyLoadCorpIds event,
    Emitter<CompanyState> emit,
  ) async {
    try {
      final corpIds = await _companyService.getCorpIds();

      emit(state.copyWith(corpIds: corpIds));
    } catch (e) {
      emit(state.copyWith(
        status: CompanyStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCreate(
    CompanyCreate event,
    Emitter<CompanyState> emit,
  ) async {
    emit(state.copyWith(isCreating: true));

    try {
      final company = await _companyService.createCompany(
        companyName: event.companyName,
        corpId: event.corpId,
        branch: event.branch,
        state: event.state,
        city: event.city,
        address: event.address,
        createdBy: event.createdBy,
        createdByName: event.createdByName,
      );

      emit(state.copyWith(
        isCreating: false,
        companies: [company, ...state.companies],
        corpIds: [...state.corpIds, event.corpId].toSet().toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        isCreating: false,
        status: CompanyStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdate(
    CompanyUpdate event,
    Emitter<CompanyState> emit,
  ) async {
    try {
      final existingCompany = state.companies.firstWhere((c) => c.id == event.id);
      final updatedCompany = existingCompany.copyWith(
        companyName: event.companyName,
        corpId: event.corpId,
        branch: event.branch,
        state: event.state,
        city: event.city,
        address: event.address,
        updatedAt: DateTime.now(),
      );

      await _companyService.updateCompany(updatedCompany);

      final updatedCompanies = state.companies.map((c) {
        if (c.id == event.id) return updatedCompany;
        return c;
      }).toList();

      emit(state.copyWith(companies: updatedCompanies));
    } catch (e) {
      emit(state.copyWith(
        status: CompanyStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDelete(
    CompanyDelete event,
    Emitter<CompanyState> emit,
  ) async {
    try {
      await _companyService.deleteCompany(event.id);

      emit(state.copyWith(
        companies: state.companies.where((c) => c.id != event.id).toList(),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CompanyStateStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}

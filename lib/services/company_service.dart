import 'package:firebase_database/firebase_database.dart';
import '../models/company_model.dart';

class CompanyService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<List<CompanyModel>> getAllCompanies() async {
    try {
      // Get all companies without orderByChild to avoid Firebase index requirement
      final snapshot = await _database.ref('companies').get();

      if (snapshot.exists) {
        final List<CompanyModel> companies = [];
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          companies.add(CompanyModel.fromRealtimeDB(
            key,
            Map<String, dynamic>.from(value),
          ));
        });
        // Sort client-side by company name
        companies.sort((a, b) => a.companyName.toLowerCase().compareTo(b.companyName.toLowerCase()));
        return companies;
      }
      return [];
    } catch (e) {
      print('Failed to fetch companies: $e');
      throw Exception('Failed to fetch companies: $e');
    }
  }

  Future<CompanyModel?> getCompanyById(String id) async {
    try {
      final snapshot = await _database.ref('companies/$id').get();
      if (snapshot.exists) {
        return CompanyModel.fromRealtimeDB(
          id,
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch company: $e');
    }
  }

  Future<List<String>> getCorpIds() async {
    try {
      final snapshot = await _database.ref('companies').get();
      if (snapshot.exists) {
        final Set<String> corpIds = {};
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data.forEach((key, value) {
          final company = Map<String, dynamic>.from(value);
          if (company['corpId'] != null) {
            corpIds.add(company['corpId'] as String);
          }
        });
        return corpIds.toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch corp IDs: $e');
    }
  }

  Future<CompanyModel> createCompany({
    required String companyName,
    required String corpId,
    required String branch,
    required String state,
    required String city,
    required String address,
    required String createdBy,
    required String createdByName,
  }) async {
    try {
      // Check if corpId already exists
      final existingSnapshot = await _database.ref('companies').get();
      if (existingSnapshot.exists) {
        final data = Map<String, dynamic>.from(existingSnapshot.value as Map);
        for (var entry in data.entries) {
          final company = Map<String, dynamic>.from(entry.value);
          if (company['corpId'] == corpId) {
            throw Exception('Corp ID already exists');
          }
        }
      }

      final company = CompanyModel(
        id: '',
        companyName: companyName,
        corpId: corpId,
        branch: branch,
        state: state,
        city: city,
        address: address,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: DateTime.now(),
      );

      final newRef = _database.ref('companies').push();
      await newRef.set(company.toRealtimeDB());

      return company.copyWith(id: newRef.key!);
    } catch (e) {
      throw Exception('Failed to create company: $e');
    }
  }

  Future<void> updateCompany(CompanyModel company) async {
    try {
      await _database.ref('companies/${company.id}').update({
        ...company.toRealtimeDB(),
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      throw Exception('Failed to update company: $e');
    }
  }

  Future<void> deleteCompany(String id) async {
    try {
      await _database.ref('companies/$id').remove();
    } catch (e) {
      throw Exception('Failed to delete company: $e');
    }
  }

  Stream<List<CompanyModel>> streamCompanies() {
    return _database
        .ref('companies')
        .onValue
        .map((event) {
          final List<CompanyModel> companies = [];
          if (event.snapshot.exists) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            data.forEach((key, value) {
              companies.add(CompanyModel.fromRealtimeDB(
                key,
                Map<String, dynamic>.from(value),
              ));
            });
            companies.sort((a, b) => a.companyName.compareTo(b.companyName));
          }
          return companies;
        });
  }
}

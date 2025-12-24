import 'package:equatable/equatable.dart';

enum AttendanceStatus { checkedIn, checkedOut, absent }

class AttendanceModel extends Equatable {
  final String id;
  final String oderId;
  final String userName;
  final String companyId;
  final String corpId;
  final DateTime date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final String? checkInAddress;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkOutAddress;
  final AttendanceStatus status;
  final String? country;
  final String? timezone;

  const AttendanceModel({
    required this.id,
    required this.oderId,
    required this.userName,
    required this.companyId,
    required this.corpId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInAddress,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutAddress,
    required this.status,
    this.country,
    this.timezone,
  });

  factory AttendanceModel.fromRealtimeDB(String id, Map<String, dynamic> data) {
    return AttendanceModel(
      id: id,
      oderId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      companyId: data['companyId'] ?? '',
      corpId: data['corpId'] ?? '',
      date: data['date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['date']) 
          : DateTime.now(),
      checkInTime: data['checkInTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['checkInTime']) 
          : null,
      checkOutTime: data['checkOutTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['checkOutTime']) 
          : null,
      checkInLatitude: data['checkInLatitude']?.toDouble(),
      checkInLongitude: data['checkInLongitude']?.toDouble(),
      checkInAddress: data['checkInAddress'],
      checkOutLatitude: data['checkOutLatitude']?.toDouble(),
      checkOutLongitude: data['checkOutLongitude']?.toDouble(),
      checkOutAddress: data['checkOutAddress'],
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AttendanceStatus.absent,
      ),
      country: data['country'],
      timezone: data['timezone'],
    );
  }

  Map<String, dynamic> toRealtimeDB() {
    return {
      'userId': oderId,
      'userName': userName,
      'companyId': companyId,
      'corpId': corpId,
      'date': date.millisecondsSinceEpoch,
      'checkInTime': checkInTime?.millisecondsSinceEpoch,
      'checkOutTime': checkOutTime?.millisecondsSinceEpoch,
      'checkInLatitude': checkInLatitude,
      'checkInLongitude': checkInLongitude,
      'checkInAddress': checkInAddress,
      'checkOutLatitude': checkOutLatitude,
      'checkOutLongitude': checkOutLongitude,
      'checkOutAddress': checkOutAddress,
      'status': status.name,
      'country': country,
      'timezone': timezone,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? companyId,
    String? corpId,
    DateTime? date,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    double? checkInLatitude,
    double? checkInLongitude,
    String? checkInAddress,
    double? checkOutLatitude,
    double? checkOutLongitude,
    String? checkOutAddress,
    AttendanceStatus? status,
    String? country,
    String? timezone,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      oderId: userId ?? this.oderId,
      userName: userName ?? this.userName,
      companyId: companyId ?? this.companyId,
      corpId: corpId ?? this.corpId,
      date: date ?? this.date,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkInAddress: checkInAddress ?? this.checkInAddress,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkOutAddress: checkOutAddress ?? this.checkOutAddress,
      status: status ?? this.status,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
    );
  }

  Duration? get workDuration {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!);
    }
    return null;
  }

  bool get hasCheckedIn => checkInTime != null;
  bool get hasCheckedOut => checkOutTime != null;

  @override
  List<Object?> get props => [
        id,
        oderId,
        userName,
        companyId,
        corpId,
        date,
        checkInTime,
        checkOutTime,
        checkInLatitude,
        checkInLongitude,
        checkInAddress,
        checkOutLatitude,
        checkOutLongitude,
        checkOutAddress,
        status,
        country,
        timezone,
      ];
}

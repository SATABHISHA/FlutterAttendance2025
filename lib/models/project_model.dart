import 'package:equatable/equatable.dart';

enum ProjectStatus { active, completed, onHold, cancelled }

/// Represents a geographical point
class GeoPoint extends Equatable {
  final double latitude;
  final double longitude;

  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  factory GeoPoint.fromMap(Map<String, dynamic> map) {
    return GeoPoint(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  List<Object?> get props => [latitude, longitude];
}

/// Represents the allocated area boundary (polygon or circle)
class LocationBoundary extends Equatable {
  final GeoPoint center;
  final double radiusInMeters; // For circular boundary
  final List<GeoPoint>? polygonPoints; // For polygon boundary
  final bool isCircular;

  const LocationBoundary({
    required this.center,
    this.radiusInMeters = 100.0,
    this.polygonPoints,
    this.isCircular = true,
  });

  factory LocationBoundary.fromMap(Map<String, dynamic> map) {
    List<GeoPoint>? points;
    if (map['polygonPoints'] != null) {
      points = (map['polygonPoints'] as List)
          .map((p) => GeoPoint.fromMap(Map<String, dynamic>.from(p)))
          .toList();
    }

    return LocationBoundary(
      center: GeoPoint.fromMap(Map<String, dynamic>.from(map['center'] ?? {})),
      radiusInMeters: (map['radiusInMeters'] ?? 100.0).toDouble(),
      polygonPoints: points,
      isCircular: map['isCircular'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'center': center.toMap(),
      'radiusInMeters': radiusInMeters,
      'polygonPoints': polygonPoints?.map((p) => p.toMap()).toList(),
      'isCircular': isCircular,
    };
  }

  @override
  List<Object?> get props => [center, radiusInMeters, polygonPoints, isCircular];
}

/// Main Project Model for project allocation
class ProjectModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String companyId;
  final String corpId;
  final LocationBoundary locationBoundary;
  final String address;
  final DateTime startDate;
  final DateTime endDate;
  final ProjectStatus status;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.companyId,
    required this.corpId,
    required this.locationBoundary,
    required this.address,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromRealtimeDB(String id, Map<String, dynamic> data) {
    return ProjectModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      companyId: data['companyId'] ?? '',
      corpId: data['corpId'] ?? '',
      locationBoundary: LocationBoundary.fromMap(
        Map<String, dynamic>.from(data['locationBoundary'] ?? {}),
      ),
      address: data['address'] ?? '',
      startDate: data['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['startDate'])
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['endDate'])
          : DateTime.now().add(const Duration(days: 30)),
      status: ProjectStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ProjectStatus.active,
      ),
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
      'name': name,
      'description': description,
      'companyId': companyId,
      'corpId': corpId,
      'locationBoundary': locationBoundary.toMap(),
      'address': address,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'status': status.name,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    String? companyId,
    String? corpId,
    LocationBoundary? locationBoundary,
    String? address,
    DateTime? startDate,
    DateTime? endDate,
    ProjectStatus? status,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      companyId: companyId ?? this.companyId,
      corpId: corpId ?? this.corpId,
      locationBoundary: locationBoundary ?? this.locationBoundary,
      address: address ?? this.address,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive {
    final now = DateTime.now();
    return status == ProjectStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  String get durationText {
    final days = endDate.difference(startDate).inDays;
    if (days < 30) return '$days days';
    if (days < 365) return '${(days / 30).round()} months';
    return '${(days / 365).round()} years';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        companyId,
        corpId,
        locationBoundary,
        address,
        startDate,
        endDate,
        status,
        createdBy,
        createdByName,
        createdAt,
        updatedAt,
      ];
}

/// Project Assignment to users (subordinates/supervisors)
class ProjectAssignment extends Equatable {
  final String id;
  final String projectId;
  final String projectName;
  final String userId;
  final String userName;
  final String assignedBy;
  final String assignedByName;
  final LocationBoundary locationBoundary;
  final String address;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final DateTime assignedAt;

  const ProjectAssignment({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.userId,
    required this.userName,
    required this.assignedBy,
    required this.assignedByName,
    required this.locationBoundary,
    required this.address,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.assignedAt,
  });

  factory ProjectAssignment.fromRealtimeDB(String id, Map<String, dynamic> data) {
    return ProjectAssignment(
      id: id,
      projectId: data['projectId'] ?? '',
      projectName: data['projectName'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      assignedBy: data['assignedBy'] ?? '',
      assignedByName: data['assignedByName'] ?? '',
      locationBoundary: LocationBoundary.fromMap(
        Map<String, dynamic>.from(data['locationBoundary'] ?? {}),
      ),
      address: data['address'] ?? '',
      startDate: data['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['startDate'])
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['endDate'])
          : DateTime.now().add(const Duration(days: 30)),
      isActive: data['isActive'] ?? true,
      assignedAt: data['assignedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['assignedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toRealtimeDB() {
    return {
      'projectId': projectId,
      'projectName': projectName,
      'userId': userId,
      'userName': userName,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'locationBoundary': locationBoundary.toMap(),
      'address': address,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isActive': isActive,
      'assignedAt': assignedAt.millisecondsSinceEpoch,
    };
  }

  ProjectAssignment copyWith({
    String? id,
    String? projectId,
    String? projectName,
    String? userId,
    String? userName,
    String? assignedBy,
    String? assignedByName,
    LocationBoundary? locationBoundary,
    String? address,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? assignedAt,
  }) {
    return ProjectAssignment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedByName: assignedByName ?? this.assignedByName,
      locationBoundary: locationBoundary ?? this.locationBoundary,
      address: address ?? this.address,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt ?? this.assignedAt,
    );
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        projectName,
        userId,
        userName,
        assignedBy,
        assignedByName,
        locationBoundary,
        address,
        startDate,
        endDate,
        isActive,
        assignedAt,
      ];
}

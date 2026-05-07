import 'package:intl/intl.dart';

class Incident {
  final int? id;
  final int userId;
  final String incidentType;
  final String description;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String status; // 'Pending', 'Verified', 'Resolved', 'False Report'

  // Populated via JOIN queries — null for user-only queries
  final String? reporterUsername;
  final String? reporterRealName;
  final String? reporterIcNumber;

  const Incident({
    this.id,
    required this.userId,
    required this.incidentType,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.status,
    this.reporterUsername,
    this.reporterRealName,
    this.reporterIcNumber,
  });

  /// e.g. "7 May 2026 • 3:45 PM"
  String get formattedTime {
    try {
      return DateFormat('d MMM yyyy • h:mm a')
          .format(DateTime.parse(timestamp).toLocal());
    } catch (_) {
      return timestamp;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'incident_type': incidentType,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp,
        'status': status,
      };

  factory Incident.fromMap(Map<String, dynamic> map) => Incident(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        incidentType: map['incident_type'] as String,
        description: map['description'] as String,
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        timestamp: map['timestamp'] as String,
        status: map['status'] as String,
        reporterUsername: map['random_username'] as String?,
        reporterRealName: map['real_name'] as String?,
        reporterIcNumber: map['ic_number'] as String?,
      );

  Incident copyWith({
    int? id,
    int? userId,
    String? incidentType,
    String? description,
    double? latitude,
    double? longitude,
    String? timestamp,
    String? status,
  }) =>
      Incident(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        incidentType: incidentType ?? this.incidentType,
        description: description ?? this.description,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        timestamp: timestamp ?? this.timestamp,
        status: status ?? this.status,
        reporterUsername: reporterUsername,
        reporterRealName: reporterRealName,
        reporterIcNumber: reporterIcNumber,
      );
}

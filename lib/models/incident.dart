import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Incident {
  final String? id; // Firestore document ID
  final String userId;
  final String incidentType;
  final String description;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String status; // 'Pending', 'Verified', 'Resolved', 'False Report'

  // Denormalized reporter info — stored directly in each incident document
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

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'userId': userId,
      'incidentType': incidentType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'status': status,
    };
    if (reporterUsername != null) map['reporterUsername'] = reporterUsername;
    if (reporterRealName != null) map['reporterRealName'] = reporterRealName;
    if (reporterIcNumber != null) map['reporterIcNumber'] = reporterIcNumber;
    return map;
  }

  factory Incident.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Incident(
      id: doc.id,
      userId: d['userId'] as String,
      incidentType: d['incidentType'] as String,
      description: d['description'] as String,
      latitude: (d['latitude'] as num).toDouble(),
      longitude: (d['longitude'] as num).toDouble(),
      timestamp: d['timestamp'] as String,
      status: d['status'] as String,
      reporterUsername: d['reporterUsername'] as String?,
      reporterRealName: d['reporterRealName'] as String?,
      reporterIcNumber: d['reporterIcNumber'] as String?,
    );
  }

  Incident copyWith({
    String? id,
    String? userId,
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

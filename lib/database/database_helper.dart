import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/incident.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _incidents =>
      _db.collection('incidents');

  // ---------------------------------------------------------------------------
  // Seed data — runs once on fresh Firestore database
  // ---------------------------------------------------------------------------

  Future<void> initSeedData() async {
    final adminCheck = await _users
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();
    if (adminCheck.docs.isNotEmpty) return;

    await _users.add({
      'icNumber': 'ADMIN001',
      'realName': 'System Administrator',
      'randomUsername': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });

    final demoRef = await _users.add({
      'icNumber': '990101145678',
      'realName': 'Ahmad Bin Abdullah',
      'randomUsername': 'Citizen_842',
      'password': 'user123',
      'role': 'user',
    });

    final now = DateTime.now();
    for (final seed in _seedIncidents(demoRef.id, now)) {
      await _incidents.add(seed);
    }
  }

  static List<Map<String, dynamic>> _seedIncidents(
      String userId, DateTime now) {
    const reporter = {
      'reporterUsername': 'Citizen_842',
      'reporterRealName': 'Ahmad Bin Abdullah',
      'reporterIcNumber': '990101145678',
    };
    return [
      {
        'userId': userId,
        'incidentType': 'Theft',
        'description':
            'Phone snatching near the main bus stop. Perpetrator fled on motorcycle.',
        'latitude': 3.1390,
        'longitude': 101.6869,
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'status': 'Pending',
        ...reporter,
      },
      {
        'userId': userId,
        'incidentType': 'Suspicious Activity',
        'description':
            'A group of individuals loitering around the parking lot after midnight.',
        'latitude': 3.1415,
        'longitude': 101.6890,
        'timestamp': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'status': 'Verified',
        ...reporter,
      },
      {
        'userId': userId,
        'incidentType': 'Harassment',
        'description':
            'Verbal harassment reported near the convenience store on Jalan Ampang.',
        'latitude': 3.1570,
        'longitude': 101.7200,
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'status': 'Resolved',
        ...reporter,
      },
      {
        'userId': userId,
        'incidentType': 'Vandalism',
        'description':
            'Public benches damaged and graffiti sprayed on the community notice board.',
        'latitude': 3.1320,
        'longitude': 101.6750,
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        'status': 'Pending',
        ...reporter,
      },
    ];
  }

  // ---------------------------------------------------------------------------
  // Username generator
  // ---------------------------------------------------------------------------

  static String generateRandomUsername() {
    const adjectives = [
      'Swift', 'Silent', 'Brave', 'Calm', 'Keen',
      'Bold', 'Wise', 'Sharp', 'Alert', 'Civic',
      'Loyal', 'Proud', 'Noble', 'Steady', 'Valiant',
    ];
    const nouns = [
      'Eagle', 'Tiger', 'Panther', 'Falcon', 'Wolf',
      'Hawk', 'Cobra', 'Lion', 'Lynx', 'Bear',
      'Osprey', 'Jaguar', 'Condor', 'Raven', 'Drake',
    ];
    final rng = Random();
    final adj = adjectives[rng.nextInt(adjectives.length)];
    final noun = nouns[rng.nextInt(nouns.length)];
    final number = rng.nextInt(9000) + 1000;
    return '$adj${noun}_$number';
  }

  // ---------------------------------------------------------------------------
  // User CRUD
  // ---------------------------------------------------------------------------

  Future<String> insertUser(User user) async {
    final ref = await _users.add(user.toMap());
    return ref.id;
  }

  Future<User?> getUserByCredentials(
      String identifier, String password) async {
    // Try by randomUsername
    var snap = await _users
        .where('randomUsername', isEqualTo: identifier)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) return User.fromDoc(snap.docs.first);

    // Try by icNumber
    snap = await _users
        .where('icNumber', isEqualTo: identifier)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return User.fromDoc(snap.docs.first);
  }

  Future<bool> icNumberExists(String icNumber) async {
    final snap = await _users
        .where('icNumber', isEqualTo: icNumber)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> usernameExists(String username) async {
    final snap = await _users
        .where('randomUsername', isEqualTo: username)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Incident CRUD
  // ---------------------------------------------------------------------------

  Future<void> insertIncident(Incident incident) async {
    await _incidents.add(incident.toMap());
  }

  /// All incidents ordered by time — for admin view (reporter info is denormalized).
  Future<List<Incident>> getAllIncidentsWithUser() async {
    final snap =
        await _incidents.orderBy('timestamp', descending: true).get();
    return snap.docs.map(Incident.fromDoc).toList();
  }

  /// Public feed — excludes false reports, client-side filtered.
  Future<List<Incident>> getPublicIncidents() async {
    final snap =
        await _incidents.orderBy('timestamp', descending: true).get();
    return snap.docs
        .map(Incident.fromDoc)
        .where((i) => i.status != 'False Report')
        .toList();
  }

  /// Incidents submitted by a specific user.
  Future<List<Incident>> getIncidentsByUser(String userId) async {
    final snap =
        await _incidents.where('userId', isEqualTo: userId).get();
    final list = snap.docs.map(Incident.fromDoc).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> updateIncidentStatus(String id, String status) async {
    await _incidents.doc(id).update({'status': status});
  }

  Future<void> deleteIncident(String id) async {
    await _incidents.doc(id).delete();
  }

  // ---------------------------------------------------------------------------
  // Safety Score
  // ---------------------------------------------------------------------------

  static const Map<String, double> _severityWeights = {
    'Assault': 20,
    'Theft': 15,
    'Harassment': 12,
    'Vandalism': 8,
    'Suspicious Activity': 5,
    'Road Accident': 7,
    'Other': 5,
  };

  /// Calculates area safety score (0–100). Fetches all incidents and filters
  /// client-side to avoid composite index requirements.
  Future<double> calculateSafetyScore() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final snap = await _incidents.get();

    double score = 100.0;
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['status'] == 'False Report') continue;
      final ts = DateTime.tryParse(data['timestamp'] as String? ?? '');
      if (ts == null || ts.isBefore(cutoff)) continue;
      score -= _severityWeights[data['incidentType'] as String? ?? ''] ?? 5.0;
    }
    return score.clamp(0.0, 100.0);
  }

  /// Location-aware safety score — only counts incidents within [radiusKm] of
  /// the user's GPS position in the last 30 days.
  Future<double> calculateSafetyScoreNear(
      double lat, double lng, {double radiusKm = 3.0}) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final snap = await _incidents.get();

    double score = 100.0;
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['status'] == 'False Report') continue;
      final ts = DateTime.tryParse(data['timestamp'] as String? ?? '');
      if (ts == null || ts.isBefore(cutoff)) continue;
      final iLat = (data['latitude'] as num?)?.toDouble() ?? 0;
      final iLng = (data['longitude'] as num?)?.toDouble() ?? 0;
      if (_haversineKm(lat, lng, iLat, iLng) > radiusKm) continue;
      score -= _severityWeights[data['incidentType'] as String? ?? ''] ?? 5.0;
    }
    return score.clamp(0.0, 100.0);
  }

  static double _haversineKm(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}

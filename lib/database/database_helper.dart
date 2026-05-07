import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/incident.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'safezone.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        ic_number       TEXT    NOT NULL UNIQUE,
        real_name       TEXT    NOT NULL,
        random_username TEXT    NOT NULL UNIQUE,
        password        TEXT    NOT NULL,
        role            TEXT    NOT NULL DEFAULT 'user'
      )
    ''');

    await db.execute('''
      CREATE TABLE incidents (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id       INTEGER NOT NULL,
        incident_type TEXT    NOT NULL,
        description   TEXT    NOT NULL,
        latitude      REAL    NOT NULL,
        longitude     REAL    NOT NULL,
        timestamp     TEXT    NOT NULL,
        status        TEXT    NOT NULL DEFAULT 'Pending',
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.insert('users', {
      'ic_number': 'ADMIN001',
      'real_name': 'System Administrator',
      'random_username': 'admin',
      'password': 'admin123',
      'role': 'admin',
    });

    await db.insert('users', {
      'ic_number': '990101145678',
      'real_name': 'Ahmad Bin Abdullah',
      'random_username': 'Citizen_842',
      'password': 'user123',
      'role': 'user',
    });

    final now = DateTime.now();
    final seedIncidents = [
      {
        'user_id': 2,
        'incident_type': 'Theft',
        'description':
            'Phone snatching near the main bus stop. Perpetrator fled on motorcycle.',
        'latitude': 3.1390,
        'longitude': 101.6869,
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'status': 'Pending',
      },
      {
        'user_id': 2,
        'incident_type': 'Suspicious Activity',
        'description':
            'A group of individuals loitering around the parking lot after midnight.',
        'latitude': 3.1415,
        'longitude': 101.6890,
        'timestamp': now.subtract(const Duration(hours: 6)).toIso8601String(),
        'status': 'Verified',
      },
      {
        'user_id': 2,
        'incident_type': 'Harassment',
        'description':
            'Verbal harassment reported near the convenience store on Jalan Ampang.',
        'latitude': 3.1570,
        'longitude': 101.7200,
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'status': 'Resolved',
      },
      {
        'user_id': 2,
        'incident_type': 'Vandalism',
        'description':
            'Public benches damaged and graffiti sprayed on the community notice board.',
        'latitude': 3.1320,
        'longitude': 101.6750,
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        'status': 'Pending',
      },
    ];

    for (final incident in seedIncidents) {
      await db.insert('incidents', incident);
    }
  }

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
    final number = rng.nextInt(9000) + 1000;
    final adj = adjectives[rng.nextInt(adjectives.length)];
    final noun = nouns[rng.nextInt(nouns.length)];
    return '$adj${noun}_$number';
  }

  static String _thirtyDayCutoff() =>
      DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

  // ---------------------------------------------------------------------------
  // User CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<User?> getUserByCredentials(
      String identifier, String password) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: '(random_username = ? OR ic_number = ?) AND password = ?',
      whereArgs: [identifier, identifier, password],
    );
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<bool> _fieldExists(String column, String value) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['id'],
      where: '$column = ?',
      whereArgs: [value],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<bool> icNumberExists(String icNumber) =>
      _fieldExists('ic_number', icNumber);

  Future<bool> usernameExists(String username) =>
      _fieldExists('random_username', username);

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', where: "role = 'user'");
    return maps.map(User.fromMap).toList();
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return db.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------------
  // Incident CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertIncident(Incident incident) async {
    final db = await database;
    return db.insert('incidents', incident.toMap());
  }

  /// All incidents joined with reporter info — for admin view.
  Future<List<Incident>> getAllIncidentsWithUser() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT incidents.*,
             users.random_username,
             users.real_name,
             users.ic_number
      FROM incidents
      JOIN users ON incidents.user_id = users.id
      ORDER BY incidents.timestamp DESC
    ''');
    return maps.map(Incident.fromMap).toList();
  }

  /// Incidents with anonymous join — for public user feed.
  Future<List<Incident>> getPublicIncidents() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT incidents.*,
             users.random_username
      FROM incidents
      JOIN users ON incidents.user_id = users.id
      WHERE incidents.status != 'False Report'
      ORDER BY incidents.timestamp DESC
    ''');
    return maps.map(Incident.fromMap).toList();
  }

  /// Incidents submitted by a specific user.
  Future<List<Incident>> getIncidentsByUser(int userId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT incidents.*, users.random_username
      FROM incidents
      JOIN users ON incidents.user_id = users.id
      WHERE incidents.user_id = ?
      ORDER BY incidents.timestamp DESC
    ''', [userId]);
    return maps.map(Incident.fromMap).toList();
  }

  Future<int> updateIncidentStatus(int id, String status) async {
    final db = await database;
    return db.update(
      'incidents',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateIncident(Incident incident) async {
    final db = await database;
    return db.update(
      'incidents',
      incident.toMap(),
      where: 'id = ?',
      whereArgs: [incident.id],
    );
  }

  Future<int> deleteIncident(int id) async {
    final db = await database;
    return db.delete('incidents', where: 'id = ?', whereArgs: [id]);
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

  /// Calculates the area safety score (0–100). Starts at 100 and subtracts
  /// [_severityWeights] for each non-false-report incident in the last 30 days.
  Future<double> calculateSafetyScore() async {
    final db = await database;
    final maps = await db.query(
      'incidents',
      columns: ['incident_type'],
      where: "timestamp > ? AND status != 'False Report'",
      whereArgs: [_thirtyDayCutoff()],
    );

    double score = 100.0;
    for (final row in maps) {
      score -= _severityWeights[row['incident_type'] as String] ?? 5.0;
    }
    return score.clamp(0.0, 100.0);
  }
}

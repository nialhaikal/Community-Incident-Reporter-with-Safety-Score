# SafeZone: Community Incident Reporter with Safety Score
## Project Documentation Report

**Application Name:** SafeZone  
**Platform:** Android (Flutter)  
**Backend:** Firebase (Cloud Firestore)  
**Academic Context:** Mobile Application Development — Mini Project  
**SDG Alignment:** UN Sustainable Development Goal 16 — Peace, Justice and Strong Institutions  

---

---

# 1. INTRODUCTION

## 1.1 Overview of the Application

SafeZone is a Flutter-based Android mobile application that empowers citizens to anonymously report community incidents and receive real-time safety assessments of their surroundings. The application bridges the gap between community members and local safety awareness by creating a crowd-sourced incident database that is verified by administrators and presented through an intuitive safety scoring system.

The application operates on a dual-portal architecture: a **Citizen Portal** for anonymous reporting and a **secure Admin Portal** for incident verification and identity management. Citizens are protected through pseudonymous usernames generated automatically at registration (e.g., `BraveEagle_2847`), while administrators retain access to verified real-world identities for accountability purposes.

## 1.2 Purpose and Motivation

Community safety information is often fragmented across social media, WhatsApp groups, and unofficial channels with no verified, centralised source of truth. Citizens frequently lack awareness of incidents occurring in their immediate vicinity, and authorities struggle to aggregate grassroots-level incident data.

SafeZone addresses these challenges by:

- Providing a **structured, pseudonymous reporting platform** that lowers the barrier for citizens to submit safety concerns
- Delivering a **real-time, location-aware safety score** that quantifies local risk based on recent verified incidents
- Enabling **administrative verification workflows** that filter out false reports and maintain data integrity
- Supporting **UN SDG Goal 16** by contributing to safer, more accountable, and more transparent communities

## 1.3 SDG 16 Alignment

| SDG Sub-Goal | Alignment |
|---|---|
| **16.1** — Reduce violence and related death rates | Incident reporting infrastructure enables data-driven response to violence hotspots |
| **16.6** — Develop effective, accountable institutions | Admin verification workflow ensures institutional accountability for data |
| **16.10** — Ensure public access to information | Community feed provides transparent, verified safety information to all citizens |

---

---

# 2. SYSTEM ANALYSIS

## 2.1 Target Users

The application serves two primary user groups:

### 2.1.1 Citizens (General Public)

| Attribute | Details |
|---|---|
| **Demographics** | Adults of all ages residing in or visiting a community area |
| **Technical Literacy** | Moderate; comfortable with smartphones and basic apps |
| **Primary Goal** | Report incidents they witness and assess the safety of their surroundings |
| **Privacy Concern** | High — users want to report without revealing their real identity publicly |
| **Motivation** | Community welfare, personal safety, civic responsibility |

### 2.1.2 Administrators (Safety Officers / Moderators)

| Attribute | Details |
|---|---|
| **Demographics** | Appointed community officers, law enforcement liaison, or platform moderators |
| **Technical Literacy** | Above average; familiar with data management tools |
| **Primary Goal** | Review, verify, and act upon submitted incident reports |
| **Access Level** | Full access — real name, IC number, and all incident details |
| **Responsibility** | Maintain data quality and prevent misinformation spread |

---

## 2.2 Functional Requirements

### 2.2.1 User Authentication and Registration

| ID | Requirement |
|---|---|
| FR-01 | The system shall allow citizens to register using their full name, IC number, and password |
| FR-02 | The system shall automatically generate a pseudonymous username upon registration |
| FR-03 | The system shall enforce uniqueness of IC numbers during registration |
| FR-04 | The system shall allow citizens to log in using their generated username or IC number with password |
| FR-05 | The system shall provide a separate Admin Login portal |
| FR-06 | The system shall enforce role-based access — citizens cannot access admin features |

### 2.2.2 Incident Reporting

| ID | Requirement |
|---|---|
| FR-07 | The system shall allow authenticated citizens to submit incident reports |
| FR-08 | Reports shall include: incident type, description, and GPS-tagged location |
| FR-09 | The system shall support 7 incident types: Theft, Harassment, Assault, Suspicious Activity, Vandalism, Road Accident, Other |
| FR-10 | Citizens shall be able to use current GPS location or manually place a pin on the map |
| FR-11 | Submitted reports shall display a local push notification confirming receipt |
| FR-12 | Reports shall be stored with denormalised reporter information for admin traceability |

### 2.2.3 Safety Score

| ID | Requirement |
|---|---|
| FR-13 | The system shall calculate a safety score (0–100) based on incidents in the last 30 days |
| FR-14 | The score shall be location-aware, using a 3 km radius when GPS is available |
| FR-15 | Severity weights shall differ by incident type (Assault highest, Other lowest) |
| FR-16 | The score shall update in real-time as the user moves (50 m movement threshold) |
| FR-17 | The system shall categorise the score as Safe (80–100), Moderate (60–79), or High Risk (0–59) |
| FR-18 | The system shall send a push notification alert when score drops below 60 |

### 2.2.4 Community Feed and Map

| ID | Requirement |
|---|---|
| FR-19 | The system shall display a public community feed of non-false-report incidents |
| FR-20 | Each feed item shall show: incident type, reporter username, status, description, location, and timestamp |
| FR-21 | The system shall render incidents on an interactive Google Map with colour-coded markers |
| FR-22 | Citizens shall be able to tap an incident card to view its pin on the map |

### 2.2.5 Admin Management

| ID | Requirement |
|---|---|
| FR-23 | Admins shall view all incidents including verified real name and IC number of reporters |
| FR-24 | Admins shall update incident status: Pending → Verified, Resolved, or False Report |
| FR-25 | Admins shall permanently delete incidents |
| FR-26 | The admin dashboard shall display aggregate statistics (Total, Pending, Verified, Resolved counts) |
| FR-27 | Admins shall filter incidents by status |

---

## 2.3 Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Privacy** | Public-facing views shall never expose real names or IC numbers |
| **Performance** | Safety score calculation shall complete within 2 seconds |
| **Availability** | Application shall function with graceful degradation when GPS is unavailable |
| **Security** | Admin portal shall be visually and functionally separated from the citizen portal |
| **Usability** | All critical workflows shall be completable in 3 taps or fewer |
| **Compatibility** | Android 8.0 (API 26) and above |

---

---

# 3. SYSTEM DESIGN

## 3.1 Architecture Overview

SafeZone follows a **client-server architecture** with Firebase Cloud Firestore as the backend. There is no custom server-side logic — all business logic runs on the Flutter client, with Firestore serving as a real-time NoSQL database.

```
┌──────────────────────────────────────────────────────────┐
│                     FLUTTER CLIENT (Android)              │
│                                                          │
│  ┌─────────────┐   ┌─────────────┐   ┌───────────────┐  │
│  │   Screens   │   │  Services   │   │    Models     │  │
│  │  (UI Layer) │◄─►│(Logic Layer)│◄─►│  (Data Layer) │  │
│  └─────────────┘   └──────┬──────┘   └───────────────┘  │
│                           │                              │
│                  ┌────────▼────────┐                     │
│                  │ DatabaseHelper  │                     │
│                  │  (Firestore     │                     │
│                  │  Singleton)     │                     │
│                  └────────┬────────┘                     │
└───────────────────────────┼──────────────────────────────┘
                            │ HTTPS / gRPC
┌───────────────────────────▼──────────────────────────────┐
│               FIREBASE CLOUD FIRESTORE                    │
│   ┌──────────────┐          ┌──────────────────────────┐  │
│   │    users     │          │        incidents         │  │
│   │  collection  │          │       collection         │  │
│   └──────────────┘          └──────────────────────────┘  │
└──────────────────────────────────────────────────────────┘

   External APIs:
   ┌──────────────────┐    ┌───────────────────────────────┐
   │  Google Maps SDK │    │  Device GPS (geolocator pkg)  │
   └──────────────────┘    └───────────────────────────────┘
```

---

## 3.2 Application Flow Diagrams

### 3.2.1 Citizen Registration & Login Flow

```
         START
           │
           ▼
    ┌─────────────┐
    │  Info Screen │
    │ (Home/Splash)│
    └──────┬──────┘
           │
      ┌────┴────┐
      │         │
      ▼         ▼
  Register    Login
      │         │
      ▼         ▼
 Enter Name  Enter Username
 IC Number   / IC Number
 Password    + Password
      │         │
      ▼         ▼
 Check IC    Query Firestore
 Uniqueness  users collection
      │         │
      ▼         ▼
 Generate    Credentials     ──NO──► Show Error
 Username    Match?
      │         │ YES
      ▼         ▼
 Store User  Role = admin?  ──YES──► Redirect to
 in Firestore               Admin Login
      │         │ NO
      ▼         ▼
 Show Alias  User Dashboard
 Dialog
      │
      ▼
 Redirect to
 Login Screen
```

### 3.2.2 Incident Reporting Flow

```
    User Dashboard
         │
         ▼
    Tap FAB (+)
         │
         ▼
  Report Incident Screen
         │
    ┌────┴────────────────┐
    │                     │
    ▼                     ▼
Select Type         Request GPS
    │               Permission
    ▼                     │
Enter Description   ┌─────┴──────┐
    │               │ Granted?   │
    ▼               └──┬─────┬───┘
Select Location     YES │     │ NO
    │               ▼   │     ▼
    │          Current  │  Simulated
    │          Location │  Location
    │               └───┼───┘
    │                   │
    ▼                   ▼
 ┌──────────────────────┐
 │  Validate Form       │
 │  (type, desc≥10ch,   │
 │   location set)      │
 └──────────┬───────────┘
            │ Valid
            ▼
    Store Incident in
    Firestore (with
    reporter info)
            │
            ▼
    Push Notification:
    "Report Submitted"
            │
            ▼
    Return to Dashboard
    (refresh feed)
```

### 3.2.3 Safety Score Calculation Flow

```
  App Launch / Location Change (>50m)
               │
               ▼
     GPS Permission Available?
               │
        ┌──────┴──────┐
        │ YES          │ NO
        ▼              ▼
  Get Current     Use Global
  GPS Position    Scoring Mode
        │              │
        ▼              ▼
  Fetch incidents  Fetch all
  within 3km       incidents
  radius           (last 30 days)
        │              │
        └──────┬────────┘
               │
               ▼
  Filter: last 30 days + NOT "False Report"
               │
               ▼
  For each incident:
  score -= severityWeight[incidentType]
               │
               ▼
  Clamp score to [0, 100]
               │
               ▼
  ┌────────────┼────────────┐
  │            │            │
  ▼            ▼            ▼
80-100       60-79        0-59
SAFE ZONE   MODERATE    HIGH RISK
(Green)     (Orange)     (Red)
               │
               ▼
  score < 60?
  │ YES → Send Push Alert
  │ NO  → No notification
  ▼
Update UI
```

---

## 3.3 Wireframes

### 3.3.1 Info Screen (Home / Splash)

```
╔══════════════════════════════════╗
║  [logo]          [Admin Login ⚙]║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │  ████ SafeZone ████      │   ║
║  │  Community Safety Network│   ║
║  │  SDG 16 — Peace &        │   ║
║  │  Strong Institutions     │   ║
║  └──────────────────────────┘   ║
║                                  ║
║  About SafeZone                  ║
║  ┌──────────────────────────┐   ║
║  │ SafeZone empowers        │   ║
║  │ citizens to anonymously  │   ║
║  │ report incidents...      │   ║
║  └──────────────────────────┘   ║
║                                  ║
║  How It Works                    ║
║  ① Register Anonymously          ║
║  ② Report Incidents              ║
║  ③ View Safety Scores            ║
║  ④ Stay Informed                 ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │   🔵 Login as Citizen    │   ║
║  └──────────────────────────┘   ║
║  ┌──────────────────────────┐   ║
║  │   ○  Register New Acct   │   ║
║  └──────────────────────────┘   ║
╚══════════════════════════════════╝
```

---

### 3.3.2 Registration Screen

```
╔══════════════════════════════════╗
║  ←   Create Account              ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │  Full Name               │   ║
║  │  ________________________│   ║
║  └──────────────────────────┘   ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │  IC Number               │   ║
║  │  ________________________│   ║
║  └──────────────────────────┘   ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │  Password                │   ║
║  │  ________________________│   ║
║  └──────────────────────────┘   ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │  Confirm Password        │   ║
║  │  ________________________│   ║
║  └──────────────────────────┘   ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │    Register Account      │   ║
║  └──────────────────────────┘   ║
║                                  ║
║   Already have an account?       ║
║   [ Login ]                      ║
╚══════════════════════════════════╝

  ┌────── SUCCESS DIALOG ──────┐
  │  Registration Successful!  │
  │                            │
  │  Your anonymous username:  │
  │  ┌──────────────────────┐  │
  │  │  BraveEagle_2847     │  │
  │  └──────────────────────┘  │
  │  Save this username!       │
  │         [ OK ]             │
  └────────────────────────────┘
```

---

### 3.3.3 Citizen Login Screen

```
╔══════════════════════════════════╗
║  ←   Citizen Login               ║
║                                  ║
║      🔵 SafeZone                 ║
║      Welcome Back                ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │  Username or IC Number   │   ║
║  │  ________________________│   ║
║  └──────────────────────────┘   ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │  Password        [ 👁 ]  │   ║
║  │  ________________________│   ║
║  └──────────────────────────┘   ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │         Login            │   ║
║  └──────────────────────────┘   ║
║                                  ║
║   Don't have an account?         ║
║   [ Register Here ]              ║
╚══════════════════════════════════╝
```

---

### 3.3.4 User Dashboard (Main Screen)

```
╔══════════════════════════════════╗
║  SafeZone    Hi, BraveEagle 🔔  ║
╠══════════════════════════════════╣
║  ┌──────────────────────────┐   ║
║  │    AREA SAFETY SCORE     │   ║
║  │                          │   ║
║  │       ╭─────────╮        │   ║
║  │       │   68    │        │   ║
║  │       │ /100    │        │   ║
║  │       ╰─────────╯        │   ║
║  │    🟠 MODERATE RISK      │   ║
║  │  Some incidents reported. │   ║
║  │  Exercise caution.       │   ║
║  │  📍 Location-aware score │   ║
║  └──────────────────────────┘   ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │     INCIDENT MAP         │   ║
║  │  ┌────────────────────┐  │   ║
║  │  │  🗺  [Google Map]   │  │   ║
║  │  │  📍 🔴 🟡 🔵       │  │   ║
║  │  │  (coloured markers) │  │   ║
║  │  └────────────────────┘  │   ║
║  │  [ ⛶ Full Screen Map ]  │   ║
║  └──────────────────────────┘   ║
║                                  ║
║  COMMUNITY FEED                  ║
║  ┌──────────────────────────┐   ║
║  │ 🔴 THEFT          PENDING│   ║
║  │ Reporter: SwiftTiger_... │   ║
║  │ Mobile phone snatching.. │   ║
║  │ 3.1432°N, 101.6865°E     │   ║
║  │ May 20, 2026, 2:30 PM    │   ║
║  └──────────────────────────┘   ║
║  ┌──────────────────────────┐   ║
║  │ 🟡 SUSPICIOUS    VERIFIED│   ║
║  │ Reporter: CalmFalcon_... │   ║
║  │ Unknown person loitering │   ║
║  └──────────────────────────┘   ║
║                                  ║
║                       ╭───╮     ║
║                       │ + │     ║  ← FAB: Report Incident
║                       ╰───╯     ║
╚══════════════════════════════════╝
```

---

### 3.3.5 Report Incident Screen

```
╔══════════════════════════════════╗
║  ←   Report an Incident          ║
║                                  ║
║  Incident Type *                 ║
║  ┌──────────────────────────┐   ║
║  │  Select type...       ▼  │   ║
║  └──────────────────────────┘   ║
║                                  ║
║  Location *                      ║
║  ┌──────────────────────────┐   ║
║  │ [📍 Get Current Location]│   ║
║  └──────────────────────────┘   ║
║  ┌──────────────────────────┐   ║
║  │  [Interactive Google Map]│   ║
║  │  (Tap to place marker,   │   ║
║  │   drag to fine-tune)     │   ║
║  └──────────────────────────┘   ║
║  Lat: 3.1432   Lng: 101.6865    ║
║                                  ║
║  Description *                   ║
║  ┌──────────────────────────┐   ║
║  │  Describe what happened  │   ║
║  │  ________________________│   ║
║  │  (minimum 10 characters) │   ║
║  └──────────────────────────┘   ║
║                                  ║
║  ┌──────────────────────────┐   ║
║  │    Submit Report         │   ║
║  └──────────────────────────┘   ║
╚══════════════════════════════════╝
```

---

### 3.3.6 Admin Dashboard

```
╔══════════════════════════════════╗  ← Dark theme (#0D1B2A)
║  🔐 ADMIN PORTAL    [Logout]     ║
╠══════════════════════════════════╣
║  ⚠ All access is logged         ║
╠══════════════════════════════════╣
║  STATISTICS                      ║
║  ┌──────┐ ┌──────┐ ┌──────┐    ║
║  │ 12   │ │  5   │ │  4   │    ║
║  │Total │ │Pend. │ │Verif.│    ║
║  └──────┘ └──────┘ └──────┘    ║
║  ┌──────┐                       ║
║  │  3   │                       ║
║  │Resol.│                       ║
║  └──────┘                       ║
╠══════════════════════════════════╣
║  FILTER: [All]▼                  ║
╠══════════════════════════════════╣
║  ┌──────────────────────────┐   ║
║  │ 🔴 ASSAULT  [PENDING 🟡] │   ║
║  │                          │   ║
║  │ VERIFIED REPORTER        │   ║
║  │ Real Name: Ahmad bin Ali │   ║
║  │ IC Number: 990101145678  │   ║
║  │ Username: BraveEagle_*** │   ║
║  │                          │   ║
║  │ Desc: Physical attack... │   ║
║  │ Loc: 3.1432, 101.6865    │   ║
║  │ May 20, 2026, 1:45 PM    │   ║
║  │                          │   ║
║  │ [Update Status] [Delete] │   ║
║  └──────────────────────────┘   ║
║  ┌──────────────────────────┐   ║
║  │ 🟡 THEFT    [VERIFIED ✓] │   ║
║  │ ...                      │   ║
║  └──────────────────────────┘   ║
╚══════════════════════════════════╝
```

---

---

# 4. IMPLEMENTATION

## 4.1 Technology Stack

| Layer | Technology |
|---|---|
| Frontend Framework | Flutter 3.x (Dart) |
| Database | Firebase Cloud Firestore (NoSQL) |
| Authentication | Custom credential matching (Firestore) |
| Maps | Google Maps Flutter SDK |
| Location | Geolocator package |
| Notifications | flutter_local_notifications |
| Date/Time | intl package |

---

## 4.2 Key Code Implementations

### 4.2.1 Main Entry Point — Firebase & App Initialisation

**File:** `lib/main.dart`

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().init();
  await DatabaseHelper().initSeedData();
  runApp(const MyApp());
}
```

The application initialises three critical services before the UI renders: Firebase, local notifications, and seed data for demo purposes.

---

### 4.2.2 Data Models

**File:** `lib/models/user.dart`

```dart
class User {
  final String? id;
  final String icNumber;
  final String realName;
  final String randomUsername;
  final String password;
  final String role;

  User({
    this.id,
    required this.icNumber,
    required this.realName,
    required this.randomUsername,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
    'icNumber': icNumber,
    'realName': realName,
    'randomUsername': randomUsername,
    'password': password,
    'role': role,
  };

  factory User.fromMap(String id, Map<String, dynamic> map) => User(
    id: id,
    icNumber: map['icNumber'] ?? '',
    realName: map['realName'] ?? '',
    randomUsername: map['randomUsername'] ?? '',
    password: map['password'] ?? '',
    role: map['role'] ?? 'user',
  );
}
```

**File:** `lib/models/incident.dart`

```dart
class Incident {
  final String? id;
  final String userId;
  final String incidentType;
  final String description;
  final double latitude;
  final double longitude;
  final String timestamp;
  String status;
  final String? reporterUsername;
  final String? reporterRealName;
  final String? reporterIcNumber;

  Incident({ /* ...required fields... */ });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'incidentType': incidentType,
    'description': description,
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': timestamp,
    'status': status,
    'reporterUsername': reporterUsername,
    'reporterRealName': reporterRealName,
    'reporterIcNumber': reporterIcNumber,
  };

  factory Incident.fromMap(String id, Map<String, dynamic> map) => Incident(
    id: id,
    userId: map['userId'] ?? '',
    incidentType: map['incidentType'] ?? '',
    description: map['description'] ?? '',
    latitude: (map['latitude'] ?? 0).toDouble(),
    longitude: (map['longitude'] ?? 0).toDouble(),
    timestamp: map['timestamp'] ?? '',
    status: map['status'] ?? 'Pending',
    reporterUsername: map['reporterUsername'],
    reporterRealName: map['reporterRealName'],
    reporterIcNumber: map['reporterIcNumber'],
  );
}
```

---

### 4.2.3 Safety Score Algorithm

**File:** `lib/database/database_helper.dart`

```dart
static const Map<String, double> _severityWeights = {
  'Assault': 20,
  'Theft': 15,
  'Harassment': 12,
  'Vandalism': 8,
  'Road Accident': 7,
  'Suspicious Activity': 5,
  'Other': 5,
};

Future<double> calculateSafetyScoreNear(
    double lat, double lng, {double radiusKm = 3.0}) async {
  final snapshot = await _firestore.collection('incidents').get();
  double score = 100.0;
  final now = DateTime.now();

  for (var doc in snapshot.docs) {
    final incident = Incident.fromMap(doc.id, doc.data());
    if (incident.status == 'False Report') continue;

    final incidentTime = DateTime.tryParse(incident.timestamp);
    if (incidentTime == null) continue;
    if (now.difference(incidentTime).inDays > 30) continue;

    final distKm = _haversineKm(
      lat, lng, incident.latitude, incident.longitude);
    if (distKm <= radiusKm) {
      score -= (_severityWeights[incident.incidentType] ?? 5);
    }
  }
  return score.clamp(0.0, 100.0);
}

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0; // Earth radius in km
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRad(lat1)) * cos(_toRad(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}
```

---

### 4.2.4 Pseudonymous Username Generation

**File:** `lib/database/database_helper.dart`

```dart
static const List<String> _adjectives = [
  'Swift', 'Silent', 'Brave', 'Calm', 'Keen', 'Bold', 'Wise',
  'Sharp', 'Alert', 'Civic', 'Loyal', 'Proud', 'Noble', 'Steady', 'Valiant'
];

static const List<String> _nouns = [
  'Eagle', 'Tiger', 'Panther', 'Falcon', 'Wolf', 'Hawk', 'Cobra',
  'Lion', 'Lynx', 'Bear', 'Osprey', 'Jaguar', 'Condor', 'Raven', 'Drake'
];

String generateRandomUsername() {
  final rand = Random();
  final adj = _adjectives[rand.nextInt(_adjectives.length)];
  final noun = _nouns[rand.nextInt(_nouns.length)];
  final num = rand.nextInt(9000) + 1000;
  return '${adj}${noun}_$num';
}
```

The generation pool provides 15 × 15 × 9000 = **2,025,000 unique combinations**, minimising collision risk in any community-scale deployment.

---

### 4.2.5 Real-Time Location Streaming (User Dashboard)

**File:** `lib/screens/user/user_dashboard.dart`

```dart
void _startLocationStream() {
  _locationStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // update every 50 metres
    ),
  ).listen((Position position) async {
    final score = await DatabaseHelper().calculateSafetyScoreNear(
      position.latitude, position.longitude);
    if (mounted) {
      setState(() {
        _safetyScore = score;
        _isLocationAware = true;
      });
      if (score < 60) {
        await NotificationService().showSafetyAlert(score.toInt());
      }
    }
  });
}
```

---

### 4.2.6 Citizen Login with Role Enforcement

**File:** `lib/screens/auth/login_screen.dart`

```dart
Future<void> _login() async {
  final identifier = _identifierController.text.trim();
  final password = _passwordController.text;

  if (identifier.isEmpty || password.isEmpty) {
    _showError('Please fill in all fields');
    return;
  }

  setState(() => _isLoading = true);

  try {
    final user = await DatabaseHelper()
        .getUserByCredentials(identifier, password);

    if (user == null) {
      _showError('Invalid credentials. Please try again.');
    } else if (user.role == 'admin') {
      _showError('Admin accounts must use the Admin Login portal.');
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UserDashboard(user: user),
        ),
      );
    }
  } catch (e) {
    _showError('Login failed: ${e.toString()}');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

### 4.2.7 Admin Status Update

**File:** `lib/screens/admin/admin_dashboard.dart`

```dart
void _showStatusUpdateDialog(Incident incident) {
  String selectedStatus = incident.status;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Update Status'),
      content: StatefulBuilder(
        builder: (ctx, setStateSB) => Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Pending', 'Verified', 'Resolved', 'False Report']
              .map((status) => RadioListTile<String>(
                    title: Text(status),
                    value: status,
                    groupValue: selectedStatus,
                    onChanged: (val) {
                      setStateSB(() => selectedStatus = val!);
                    },
                  ))
              .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await DatabaseHelper()
                .updateIncidentStatus(incident.id!, selectedStatus);
            await NotificationService()
                .showAdminStatusUpdated(incident.incidentType, selectedStatus);
            Navigator.pop(context);
            _loadIncidents();
          },
          child: const Text('Update'),
        ),
      ],
    ),
  );
}
```

---

### 4.2.8 Local Notification Service

**File:** `lib/services/notification_service.dart`

```dart
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notificationsPlugin.initialize(
        const InitializationSettings(android: androidSettings));
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showSafetyAlert(int score) async {
    final bool isHighRisk = score < 40;
    await _notificationsPlugin.show(
      1,
      isHighRisk ? '⚠️ HIGH RISK ALERT' : '⚠️ Safety Warning',
      isHighRisk
          ? 'Safety score is critically low ($score/100). Avoid travelling alone at night.'
          : 'Safety score has dropped to $score/100. Exercise caution in this area.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'safezone_alerts',
          'SafeZone Alerts',
          importance: Importance.high,
          priority: Priority.high,
          enableVibration: true,
        ),
      ),
    );
  }
}
```

---

## 4.3 Application Screenshots

> *The following descriptions correspond to the implemented screens of the SafeZone application as deployed on an Android device.*

### Screen 1 — Info Screen (Welcome Page)
The welcome screen displays the SafeZone branding with a blue gradient header, a brief description of the application's purpose aligned with SDG 16, a step-by-step "How It Works" section, and two primary action buttons: **Login as Citizen** and **Register New Account**. An admin login icon is accessible via the top-right corner.

### Screen 2 — Registration Screen
A clean white form prompting for Full Name, IC Number, Password, and Confirm Password. Upon successful submission, a dialog displays the auto-generated anonymous username (e.g., `BraveEagle_2847`) with an instruction to save it. Validation prevents duplicate IC numbers and enforces password confirmation match.

### Screen 3 — Citizen Login Screen
A centered login form with the SafeZone logo, accepting either the pseudonymous username or IC number alongside the password. Includes an eye-toggle for password visibility. Error messages appear inline if credentials are invalid or if an admin attempts to log in here.

### Screen 4 — User Dashboard
The primary citizen-facing screen with three vertically stacked sections:
- **Safety Score Card**: Circular indicator showing the current score (0–100), colour-coded (green/orange/red), with descriptive advice text and a "location-aware" badge when GPS is active.
- **Incident Map**: An embedded Google Maps widget displaying all non-false-report incidents as colour-coded map markers. A full-screen expansion button and "centre on me" GPS button are provided.
- **Community Feed**: A scrollable list of incident cards showing type, reporter pseudonym, status badge, description preview, coordinates, and formatted timestamp. A floating action button (+) in the bottom-right corner navigates to the reporting screen.

### Screen 5 — Report Incident Screen
A form with three fields: incident type dropdown (7 options), location (GPS button + interactive map for pin placement), and a description text area. Form validation ensures all fields are filled and the description is at least 10 characters. On submission, a local push notification confirms receipt.

### Screen 6 — Admin Dashboard
A dark-themed panel (`#0D1B2A` background with amber accents) displaying:
- A warning banner reminding admins that all access is logged.
- Four statistics chips (Total, Pending, Verified, Resolved).
- A status filter dropdown.
- Incident cards with the **Verified Reporter Identity** section showing real name, IC number, and masked username — information hidden from the public citizen view.
- Action buttons: **Update Status** (radio button dialog) and **Delete** (confirmation dialog).

### Screen 7 — Admin Login Screen
A dark-themed login page visually distinct from the citizen portal, with amber accent colours signalling elevated access. Prompts for admin username and password.

---

---

# 5. DATABASE DESIGN

## 5.1 Platform

SafeZone uses **Firebase Cloud Firestore**, a NoSQL document-based database. Data is organised into **collections** of **documents**, where each document is a key-value map.

**Project ID:** `safezone-cb78f`  
**Region:** Default Firebase region

---

## 5.2 Collections and Document Structure

### 5.2.1 `users` Collection

Each document represents one registered account (citizen or admin).

| Field | Type | Description | Example |
|---|---|---|---|
| `icNumber` | String | Identity card number (unique) | `"990101145678"` |
| `realName` | String | Full legal name | `"Ahmad bin Ali"` |
| `randomUsername` | String | Auto-generated pseudonym | `"BraveEagle_2847"` |
| `password` | String | Password (plain text, prototype) | `"user123"` |
| `role` | String | Access level: `"user"` or `"admin"` | `"user"` |

**Constraints:**
- `icNumber` must be unique across the collection (enforced at app level)
- `randomUsername` must be unique (collision retried at app level)
- `role` determines routing post-login

**Document ID:** Auto-generated by Firestore

**Sample Document:**
```json
{
  "icNumber": "990101145678",
  "realName": "Ahmad bin Ali",
  "randomUsername": "BraveEagle_2847",
  "password": "user123",
  "role": "user"
}
```

---

### 5.2.2 `incidents` Collection

Each document represents one community incident report.

| Field | Type | Description | Example |
|---|---|---|---|
| `userId` | String | Firestore document ID of the reporting user | `"Xk2mN9pQrT..."` |
| `incidentType` | String | Category of incident | `"Theft"` |
| `description` | String | User-provided narrative | `"Mobile phone snatched..."` |
| `latitude` | Number (Double) | GPS latitude of incident | `3.1432` |
| `longitude` | Number (Double) | GPS longitude of incident | `101.6865` |
| `timestamp` | String | ISO 8601 datetime of submission | `"2026-05-20T14:30:00"` |
| `status` | String | Workflow state | `"Pending"` |
| `reporterUsername` | String | Pseudonym (denormalised) | `"BraveEagle_2847"` |
| `reporterRealName` | String | Full name (admin-only display) | `"Ahmad bin Ali"` |
| `reporterIcNumber` | String | IC number (admin-only display) | `"990101145678"` |

**Document ID:** Auto-generated by Firestore

**Sample Document:**
```json
{
  "userId": "Xk2mN9pQrT4bvZ8",
  "incidentType": "Theft",
  "description": "Mobile phone was snatched near the bus stop.",
  "latitude": 3.1432,
  "longitude": 101.6865,
  "timestamp": "2026-05-20T14:30:00.000",
  "status": "Pending",
  "reporterUsername": "BraveEagle_2847",
  "reporterRealName": "Ahmad bin Ali",
  "reporterIcNumber": "990101145678"
}
```

---

## 5.3 Entity-Relationship Diagram (Logical)

```
┌─────────────────────────┐          ┌──────────────────────────────┐
│         users           │          │          incidents            │
├─────────────────────────┤          ├──────────────────────────────┤
│ id (Firestore doc ID) PK│          │ id (Firestore doc ID) PK     │
│ icNumber        UNIQUE  │◄────FK───│ userId                       │
│ realName                │          │ incidentType                 │
│ randomUsername  UNIQUE  │          │ description                  │
│ password                │          │ latitude                     │
│ role                    │          │ longitude                    │
└─────────────────────────┘          │ timestamp                    │
                                     │ status                       │
                                     │ reporterUsername  (denorm.)  │
                                     │ reporterRealName  (denorm.)  │
                                     │ reporterIcNumber  (denorm.)  │
                                     └──────────────────────────────┘

  Relationship: One User → Many Incidents  (1 : N)
```

> **Note on Denormalisation:** Reporter details (`reporterUsername`, `reporterRealName`, `reporterIcNumber`) are intentionally duplicated from the `users` collection into each `incidents` document. This Firestore best practice eliminates the need for expensive join queries and ensures that admin identity lookups remain fast even as the users collection scales.

---

## 5.4 Status Transition Diagram

```
  [SUBMISSION]
       │
       ▼
  ┌─────────┐
  │ Pending │
  └────┬────┘
       │ Admin reviews
       │
  ┌────┼──────────────────────────┐
  │    │                          │
  ▼    ▼                          ▼
┌──────────┐  ┌──────────┐  ┌─────────────┐
│ Verified │  │ Resolved │  │ False Report│
└──────────┘  └──────────┘  └─────────────┘
     │                           │
     └─── excluded from ─────────┘
          public safety
          score calculation?   NO  │  YES
```

| Status | Included in Feed? | Included in Safety Score? |
|---|---|---|
| Pending | Yes | Yes |
| Verified | Yes | Yes |
| Resolved | Yes | Yes |
| False Report | No | No |

---

## 5.5 Seed Data

On first application launch, the following records are created if the `users` collection is empty:

**Admin Account:**
```json
{
  "icNumber": "ADMIN001",
  "realName": "System Administrator",
  "randomUsername": "admin",
  "password": "admin123",
  "role": "admin"
}
```

**Demo Citizen Account:**
```json
{
  "icNumber": "990101145678",
  "realName": "Demo User",
  "randomUsername": "Citizen_842",
  "password": "user123",
  "role": "user"
}
```

**Demo Incidents (4 records):**
| Type | Description | Status |
|---|---|---|
| Theft | Motorcycle theft near shopping complex | Verified |
| Suspicious Activity | Unknown individuals loitering | Pending |
| Harassment | Verbal harassment on public transport | Pending |
| Vandalism | Graffiti on community wall | Resolved |

---

---

# 6. CONCLUSION AND FUTURE ENHANCEMENTS

## 6.1 Conclusion

SafeZone successfully demonstrates the viability of a community-driven, pseudonymous incident reporting system built on Flutter and Firebase. The application delivers three core value propositions:

1. **Privacy-Preserving Participation** — Citizens can report incidents without public exposure of their real identity, increasing reporting willingness through the pseudonymous username system.

2. **Real-Time Safety Intelligence** — The location-aware safety score, calculated using the Haversine formula and time-weighted incident severity, provides citizens with a quantifiable, dynamic measure of local risk.

3. **Administrative Accountability** — The separate admin portal with full identity visibility ensures that reports can be verified and false information suppressed, maintaining the quality and trustworthiness of the community dataset.

The application aligns directly with **UN SDG Goal 16** by building the data infrastructure for safer communities, promoting institutional accountability through verified reporting, and ensuring public access to safety-relevant information.

As a prototype, SafeZone validates the technical architecture and UX workflows required for a production community safety platform.

---

## 6.2 Limitations of the Current Implementation

| Limitation | Impact |
|---|---|
| Passwords stored in plain text | Security vulnerability; not suitable for production |
| No Firebase Authentication integration | Login is credential-matching only; no session tokens |
| No Firestore security rules documented | All data may be accessible without proper access control |
| Android-only support | iOS and web users are excluded |
| No map clustering for dense incident areas | Performance degrades at high incident density |
| Safety score computed client-side | Inconsistent results across devices; no server-side caching |

---

## 6.3 Future Enhancements

### Phase 1 — Security Hardening
- **Bcrypt password hashing** — Replace plain-text passwords with secure hashed storage
- **Firebase Authentication integration** — Use Firebase Auth for session management, token-based login, and password reset
- **Firestore Security Rules** — Implement role-based read/write rules server-side to prevent unauthorised data access
- **Rate limiting** — Prevent brute-force login and report-spam attacks

### Phase 2 — Feature Expansion
- **Photo/video evidence attachment** — Allow reporters to attach media to incident reports using Firebase Storage
- **Anonymous two-way messaging** — Enable admins to request clarification from reporters without revealing identity
- **Incident clustering and heatmaps** — Aggregate dense report areas into visual heatmaps for trend analysis
- **Offline report queuing** — Buffer reports locally when internet is unavailable and sync upon reconnection

### Phase 3 — Intelligence and Analytics
- **ML-based severity prediction** — Use a trained model to suggest incident type and severity from the description text
- **Historical trend analysis dashboard** — Admin view showing incident trends by hour, day, and type over time
- **Community safety alerts via SMS** — Send SMS notifications to residents in affected zones using a messaging API
- **Integration with emergency services** — Direct API connection to police/ambulance dispatch for high-severity verified incidents

### Phase 4 — Platform Expansion
- **iOS support** — Port the application to iOS with equivalent functionality
- **Web admin portal** — Dedicated browser-based admin dashboard for desktop use
- **Multi-language support** — Localisation for Bahasa Malaysia, Tamil, and Mandarin
- **Accessibility features** — Screen reader support, high-contrast themes, and large-text modes

---

---

# 7. REFERENCES

1. Firebase Documentation. (2024). *Cloud Firestore: NoSQL Document Database*. Google LLC. Retrieved from https://firebase.google.com/docs/firestore

2. Flutter Team. (2024). *Flutter: Build apps for any screen*. Google LLC. Retrieved from https://flutter.dev

3. Google Maps Platform. (2024). *Maps SDK for Android and google_maps_flutter Package*. Google LLC. Retrieved from https://developers.google.com/maps

4. BaseflowIT. (2023). *geolocator: A Flutter geolocation plugin*. pub.dev. Retrieved from https://pub.dev/packages/geolocator

5. MaikuB. (2024). *flutter_local_notifications: A cross-platform plugin for displaying local notifications*. pub.dev. Retrieved from https://pub.dev/packages/flutter_local_notifications

6. United Nations. (2015). *Transforming our world: the 2030 Agenda for Sustainable Development — Goal 16: Peace, Justice and Strong Institutions*. United Nations General Assembly. Retrieved from https://sdgs.un.org/goals/goal16

7. Sinnott, R. W. (1984). Virtues of the Haversine. *Sky and Telescope*, 68(2), 158. [Mathematical basis for the Haversine distance formula used in the safety score radius calculation]

8. Google LLC. (2024). *Firebase for Flutter — Codelab*. Retrieved from https://firebase.google.com/codelabs/firebase-get-to-know-flutter

9. Dart & Flutter Team. (2024). *Effective Dart: Style, Documentation, Usage and Design*. Retrieved from https://dart.dev/effective-dart

10. OWASP Foundation. (2023). *OWASP Mobile Application Security Verification Standard (MASVS)*. Retrieved from https://owasp.org/www-project-mobile-app-security/

---

*End of Report*

---

**Prepared by:** SafeZone Development Team  
**Date:** May 2026  
**Course:** Mobile Application Development — Mini Project  
**Application Repository:** Community Incident Reporter with Safety Score  

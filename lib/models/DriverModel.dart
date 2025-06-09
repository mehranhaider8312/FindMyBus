import 'package:cloud_firestore/cloud_firestore.dart';

class Driver {
  final String driverId;
  final String driverName;
  final String busId;
  final String routeId;
  final double latitude;
  final double longitude;
  final bool isActive;
  final DateTime? timestamp;

  Driver({
    required this.driverId,
    required this.driverName,
    required this.busId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.isActive,
    this.timestamp,
  });

  factory Driver.fromFirestore(String docId, Map<String, dynamic> data) {
    final currentLocation = data['currentLocation'] as GeoPoint?;
    final timestamp = data['timestamp'] as Timestamp?;

    return Driver(
      driverId: docId,
      driverName: data['driverName'] ?? 'Unknown Driver',
      busId: data['busID'] ?? '',
      routeId: data['routeId'] ?? '',
      latitude: currentLocation?.latitude ?? 0.0,
      longitude: currentLocation?.longitude ?? 0.0,
      isActive: data['isActive'] ?? false,
      timestamp: timestamp?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverName': driverName,
      'busID': busId,
      'routeId': routeId,
      'currentLocation': GeoPoint(latitude, longitude),
      'isActive': isActive,
      'timestamp':
          timestamp != null
              ? Timestamp.fromDate(timestamp!)
              : FieldValue.serverTimestamp(),
    };
  }

  // Check if driver location is valid
  bool get hasValidLocation {
    return latitude != 0.0 &&
        longitude != 0.0 &&
        !latitude.isNaN &&
        !longitude.isNaN &&
        !latitude.isInfinite &&
        !longitude.isInfinite;
  }

  // Check if driver is recently active (within last 5 minutes)
  bool get isRecentlyActive {
    if (timestamp == null) return false;
    final now = DateTime.now();
    final difference = now.difference(timestamp!);
    return difference.inMinutes <= 5;
  }

  // Get formatted location string
  String get locationString {
    return "${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}";
  }

  // Get time since last update
  String get timeSinceUpdate {
    if (timestamp == null) return 'Unknown';
    final now = DateTime.now();
    final difference = now.difference(timestamp!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  String toString() {
    return 'Driver(id: $driverId, name: $driverName, bus: $busId, route: $routeId, active: $isActive, location: $locationString)';
  }
}

// Global drivers list
List<Driver> allActiveDrivers = [];

// Load all active drivers from Firestore
Future<void> loadAllActiveDrivers() async {
  try {
    allActiveDrivers.clear();

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance
            .collection('driversLocation')
            .where('isActive', isEqualTo: true)
            .get();

    for (var doc in querySnapshot.docs) {
      try {
        final driver = Driver.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

        // Only add drivers with valid locations and recent activity
        if (driver.hasValidLocation && driver.isRecentlyActive) {
          allActiveDrivers.add(driver);
        }
      } catch (e) {
        print('Error loading driver ${doc.id}: $e');
        continue;
      }
    }

    print('Loaded ${allActiveDrivers.length} active drivers');
  } catch (e) {
    print('Error loading active drivers: $e');
    rethrow;
  }
}

// Stream to listen for real-time driver updates
Stream<List<Driver>> getActiveDriversStream() {
  return FirebaseFirestore.instance
      .collection('driversLocation')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        List<Driver> drivers = [];

        for (var doc in snapshot.docs) {
          try {
            final driver = Driver.fromFirestore(doc.id, doc.data());

            // Only add drivers with valid locations and recent activity
            if (driver.hasValidLocation && driver.isRecentlyActive) {
              drivers.add(driver);
            }
          } catch (e) {
            print('Error parsing driver ${doc.id}: $e');
            continue;
          }
        }

        return drivers;
      });
}

// Get drivers for a specific route
List<Driver> getDriversForRoute(String routeId) {
  return allActiveDrivers.where((driver) => driver.routeId == routeId).toList();
}

// Get driver by ID
Driver? getDriverById(String driverId) {
  try {
    return allActiveDrivers.firstWhere((driver) => driver.driverId == driverId);
  } catch (e) {
    return null;
  }
}

// Validation helper for driver data
Map<String, dynamic> validateDriversData() {
  return {
    'totalActiveDrivers': allActiveDrivers.length,
    'driversWithValidLocation':
        allActiveDrivers.where((d) => d.hasValidLocation).length,
    'recentlyActiveDrivers':
        allActiveDrivers.where((d) => d.isRecentlyActive).length,
    'uniqueRoutes': allActiveDrivers.map((d) => d.routeId).toSet().length,
    'uniqueBuses': allActiveDrivers.map((d) => d.busId).toSet().length,
    'driverDetails':
        allActiveDrivers
            .map(
              (d) => {
                'id': d.driverId,
                'name': d.driverName,
                'busId': d.busId,
                'routeId': d.routeId,
                'hasValidLocation': d.hasValidLocation,
                'isRecentlyActive': d.isRecentlyActive,
                'timeSinceUpdate': d.timeSinceUpdate,
              },
            )
            .toList(),
  };
}

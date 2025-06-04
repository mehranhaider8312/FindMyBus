import 'package:cloud_firestore/cloud_firestore.dart';

class Route {
  final String id;
  final bool isActive;
  final List<Stop> stops;

  Route({required this.id, required this.isActive, required this.stops});

  // Get total stops count
  int get totalStops => stops.length;

  // Get valid stops count (stops with valid coordinates)
  int get validStopsCount =>
      stops.where((stop) => stop.isValidCoordinate).length;

  // Check if route has enough valid stops for navigation
  bool get canNavigate => validStopsCount >= 2;

  factory Route.fromFirestore(String docId, Map<String, dynamic> data) {
    return Route(
      id: docId,
      isActive: data['isActive'] ?? false,
      stops:
          (data['stops'] as List<dynamic>?)
              ?.map(
                (stopData) => Stop.fromMap(stopData as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'stops': stops.map((stop) => stop.toMap()).toList(),
    };
  }

  // Get route name from first to last stop
  String get routeName {
    final sortedStops = List<Stop>.from(stops)
      ..sort((a, b) => a.order.compareTo(b.order));

    return sortedStops.isNotEmpty
        ? '${sortedStops.first.stopName} to ${sortedStops.last.stopName}'
        : 'No stops available';
  }

  // Get only valid stops sorted by order
  List<Stop> get validStops {
    return stops.where((stop) => stop.isValidCoordinate).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}

class Stop {
  final String stopId;
  final String stopName;
  final int order;
  final Map<String, dynamic>? stopCoordinates;

  Stop({
    required this.stopId,
    required this.stopName,
    required this.order,
    this.stopCoordinates,
  });

  factory Stop.fromMap(Map<String, dynamic> data) {
    return Stop(
      stopId: data['stopId'] ?? '',
      stopName: data['stopName'] ?? '',
      order: data['order'] ?? 0,
      stopCoordinates: data['stopCoordinates'] as Map<String, dynamic>?,
    );
  }

  // Extract latitude from the map structure
  double get lat {
    try {
      if (stopCoordinates == null) return 0.0;

      final latValue = stopCoordinates!['lat'];
      if (latValue == null) return 0.0;

      // Handle both int and double values
      if (latValue is int) {
        return latValue.toDouble();
      } else if (latValue is double) {
        return latValue;
      } else if (latValue is String) {
        return double.tryParse(latValue) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('Error parsing latitude for stop $stopId: $e');
      return 0.0;
    }
  }

  // Extract longitude from the map structure
  double get lng {
    try {
      if (stopCoordinates == null) return 0.0;

      final lngValue = stopCoordinates!['lng'];
      if (lngValue == null) return 0.0;

      // Handle both int and double values
      if (lngValue is int) {
        return lngValue.toDouble();
      } else if (lngValue is double) {
        return lngValue;
      } else if (lngValue is String) {
        return double.tryParse(lngValue) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      print('Error parsing longitude for stop $stopId: $e');
      return 0.0;
    }
  }

  // Get coordinates as a formatted string
  String get coordinatesString {
    if (stopCoordinates == null) {
      return "No coordinates available";
    }
    return "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
  }

  // Get coordinates in a specific format
  String getCoordinatesString({String separator = ", ", int precision = 6}) {
    if (stopCoordinates == null) {
      return "No coordinates available";
    }
    return "${lat.toStringAsFixed(precision)}$separator${lng.toStringAsFixed(precision)}";
  }

  // Validate coordinates
  bool get isValidCoordinate {
    double latitude = lat;
    double longitude = lng;

    return _isValidLatLng(latitude, longitude);
  }

  // Helper method for coordinate validation
  bool _isValidLatLng(double lat, double lng) {
    // Check for default invalid values
    if (lat == 0.0 && lng == 0.0) return false;
    if (lat.isNaN || lng.isNaN) return false;
    if (lat.isInfinite || lng.isInfinite) return false;

    // Range validation for Pakistan/South Asia
    // Latitude: roughly 20° to 40° N
    // Longitude: roughly 55° to 80° E
    if (lat < 20 || lat > 40) return false;
    if (lng < 55 || lng > 80) return false;

    return true;
  }

  // Get coordinate validation status with details
  Map<String, dynamic> get coordinateValidationInfo {
    double latitude = lat;
    double longitude = lng;

    return {
      'isValid': isValidCoordinate,
      'latitude': latitude,
      'longitude': longitude,
      'hasCoordinates': stopCoordinates != null,
      'validationErrors': _getValidationErrors(latitude, longitude),
    };
  }

  List<String> _getValidationErrors(double lat, double lng) {
    List<String> errors = [];

    if (stopCoordinates == null) {
      errors.add('No coordinates data');
      return errors;
    }

    if (lat == 0.0 && lng == 0.0) {
      errors.add('Default coordinates (0,0)');
    }

    if (lat.isNaN || lng.isNaN) {
      errors.add('Invalid coordinate values (NaN)');
    }

    if (lat.isInfinite || lng.isInfinite) {
      errors.add('Infinite coordinate values');
    }

    if (lat < 20 || lat > 40) {
      errors.add('Latitude out of Pakistan range');
    }

    if (lng < 55 || lng > 80) {
      errors.add('Longitude out of Pakistan range');
    }

    return errors;
  }

  // Convert stop to map (useful for saving back to Firestore)
  Map<String, dynamic> toMap() {
    return {
      'stopId': stopId,
      'stopName': stopName,
      'order': order,
      'stopCoordinates': stopCoordinates,
    };
  }

  @override
  String toString() {
    return 'Stop(id: $stopId, name: $stopName, order: $order, coordinates: $coordinatesString, valid: $isValidCoordinate)';
  }
}

// Global routes list
List<Route> allRoutes = [];

Future<void> loadAllRoutes() async {
  try {
    // Clear existing routes
    allRoutes.clear();

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    for (var doc in querySnapshot.docs) {
      try {
        final route = Route.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

        allRoutes.add(route);

        // Debug: Print route validation info
        print(
          'Loaded route ${route.id}: ${route.validStopsCount}/${route.totalStops} valid stops',
        );

        // Debug: Print invalid stops
        for (var stop in route.stops.where((s) => !s.isValidCoordinate)) {
          print(
            'Invalid stop ${stop.stopId}: ${stop.coordinateValidationInfo}',
          );
        }
      } catch (e) {
        print('Error loading route ${doc.id}: $e');
        continue;
      }
    }

    print('Loaded ${allRoutes.length} routes total');
  } catch (e) {
    print('Error loading routes: $e');
    rethrow;
  }
}

// Helper function to validate all routes
Future<Map<String, dynamic>> validateAllRoutes() async {
  await loadAllRoutes();

  Map<String, dynamic> validationReport = {
    'totalRoutes': allRoutes.length,
    'activeRoutes': allRoutes.where((r) => r.isActive).length,
    'navigableRoutes': allRoutes.where((r) => r.canNavigate).length,
    'routeDetails': [],
  };

  for (var route in allRoutes) {
    validationReport['routeDetails'].add({
      'id': route.id,
      'isActive': route.isActive,
      'totalStops': route.totalStops,
      'validStops': route.validStopsCount,
      'canNavigate': route.canNavigate,
      'routeName': route.routeName,
    });
  }

  return validationReport;
}

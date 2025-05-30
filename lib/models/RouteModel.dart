import 'package:cloud_firestore/cloud_firestore.dart';

class Route {
  final String id;
  final bool isActive;
  final List<Stop> stops;

  Route({required this.id, required this.isActive, required this.stops});

  // Get total stops count
  int get totalStops => stops.length;

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
}

class Stop {
  final String stopId;
  final String stopName;
  final int order;
  final String stopCoordinates;

  Stop({
    required this.stopId,
    required this.stopName,
    required this.order,
    required this.stopCoordinates,
  });

  factory Stop.fromMap(Map<String, dynamic> data) {
    return Stop(
      stopId: data['stopId'] ?? '',
      stopName: data['stopName'] ?? '',
      order: data['order'] ?? 0,
      stopCoordinates: data['stopCoordinates'] ?? '',
    );
  }

  // Parse coordinates string to get lat/lng
  List<double> get coordinates {
    try {
      // Remove brackets and split by comma
      String coords = stopCoordinates.replaceAll('[', '').replaceAll(']', '');
      List<String> parts = coords.split(',');
      return [double.parse(parts[0].trim()), double.parse(parts[1].trim())];
    } catch (e) {
      return [0.0, 0.0];
    }
  }

  double get lat => coordinates[0];
  double get lng => coordinates[1];
}

// routes_list.dart

List<Route> allRoutes = [];

Future<void> loadAllRoutes() async {
  try {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('routes').get();

    allRoutes =
        querySnapshot.docs.map((doc) {
          return Route.fromFirestore(
            doc.id,
            doc.data() as Map<String, dynamic>,
          );
        }).toList();

    print('Loaded ${allRoutes.length} routes');
  } catch (e) {
    print('Error loading routes: $e');
  }
}

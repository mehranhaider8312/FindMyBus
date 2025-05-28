import 'dart:async';
import 'package:findmybus/screens/ChangeLanguageScreen.dart';
import 'package:findmybus/screens/ContactUsScreen.dart';
import 'package:findmybus/screens/EmergencyNumbers.dart';
import 'package:findmybus/screens/LoginScreen.dart';
import 'package:findmybus/screens/ReportIssueScreen.dart';
import 'package:findmybus/screens/RoutesListScreen.dart';
import 'package:findmybus/screens/UserProfileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  Future<void> _logout(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Logging out..."),
              ],
            ),
          );
        },
      );

      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // Clear all data from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // This removes all stored data

      // Or if you want to remove specific keys only:
      await prefs.remove('user_email');
      await prefs.remove('user_role');
      await prefs.remove('user_id');
      await prefs.remove('is_logged_in');

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Navigate to login screen and clear all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // This removes all previous routes
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  final List<Map<String, dynamic>> routes = [
    {
      'routeNumber': 'Route 16',
      'stops': [
        {'name': 'Cannal Metro Station', 'location': LatLng(31.5101, 74.3321)},
        {'name': 'Kalma Chowk', 'location': LatLng(31.5078, 74.3219)},
        {
          'name': 'Pakistani Chowk Model Town',
          'location': LatLng(31.4962, 74.3167),
        },
        {'name': 'Pace Shopping Center', 'location': LatLng(31.4940, 74.3050)},
        {'name': 'Akbar Chowk', 'location': LatLng(31.4836, 74.2931)},
        {'name': 'UCP Johar Town', 'location': LatLng(31.4678, 74.2726)},
        {
          'name': 'Daewoo Terminal Thokar',
          'location': LatLng(31.4585, 74.2463),
        },
        {
          'name': 'Jinnah Terminal Thokar',
          'location': LatLng(31.4572, 74.2379),
        },
      ],
    },
    {
      'routeNumber': 'Route 2',
      'stops': [
        {'name': 'Stop A', 'location': LatLng(31.5300, 74.3400)},
        {'name': 'Stop B', 'location': LatLng(31.5200, 74.3300)},
        {'name': 'Stop C', 'location': LatLng(31.5100, 74.3200)},
      ],
    },
    {
      'routeNumber': 'Route 3',
      'stops': [
        {'name': 'Stop X', 'location': LatLng(31.5000, 74.3100)},
        {'name': 'Stop Y', 'location': LatLng(31.4900, 74.3000)},
        {'name': 'Stop Z', 'location': LatLng(31.4800, 74.2900)},
      ],
    },
  ];

  String? selectedRoute;
  String? busId;
  bool journeyStarted = false;

  double? latitude;
  double? longitude;
  bool locationLoading = true;

  GoogleMapController? mapController;
  Marker? currentLocationMarker;
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
          locationLoading = false;
          currentLocationMarker = Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(latitude!, longitude!),
            infoWindow: const InfoWindow(title: 'You are here'),
          );
        });
        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              16,
            ),
          );
        }
      } catch (e) {
        setState(() {
          locationLoading = false;
        });
        print("Error getting location: $e");
      }
    } else {
      setState(() {
        locationLoading = false;
      });
      print("Location permission denied");
    }
  }

  void _drawRoutePolyline() {
    final selected = routes.firstWhere(
      (route) => route['routeNumber'] == selectedRoute,
      orElse: () => {},
    );

    if (selected.isEmpty || selected['stops'] is! List) return;

    final List<LatLng> points = [];
    for (var stop in selected['stops']) {
      points.add(stop['location']);
    }

    setState(() {
      polylines = {
        Polyline(
          polylineId: const PolylineId('route_polyline'),
          color: Colors.blue,
          width: 5,
          points: points,
        ),
      };
    });

    if (mapController != null && points.isNotEmpty) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(_getBounds(points), 100),
      );
    }
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _showStartJourneyDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Start Journey'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Route'),
                value: selectedRoute,
                onChanged: (String? newRoute) {
                  setState(() {
                    selectedRoute = newRoute;
                  });
                },
                items:
                    routes
                        .map(
                          (route) => DropdownMenuItem<String>(
                            value: route['routeNumber'],
                            child: Text(route['routeNumber']),
                          ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 15),
              TextField(
                decoration: const InputDecoration(labelText: 'Bus ID'),
                onChanged: (value) {
                  setState(() {
                    busId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (selectedRoute != null && busId != null) {
                  setState(() {
                    journeyStarted = true;
                  });
                  _drawRoutePolyline();
                }
              },
              child: const Text('Start Journey'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red.shade600,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.red.shade600),
              accountName: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => UserProfileScreen(
                            name: 'Driver Name',
                            email: 'driver@example.com',
                            imagePath: 'assets/images/logo_image.jpg',
                          ),
                    ),
                  );
                },
                child: const Text(
                  'Driver Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              accountEmail: const Text('View Profile'),
              currentAccountPicture: const CircleAvatar(
                backgroundImage: AssetImage('assets/images/logo_image.jpg'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.directions_bus, color: Colors.yellow),
              title: const Text('Routes List'),
              subtitle: const Text('All the routes we offer'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Routeslistscreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: const Text('Change Language'),
              subtitle: const Text('Change language preferences'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChangeLanguageScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.share,
                color: Color.fromARGB(255, 54, 244, 241),
              ),
              title: const Text('Share Your Location'),
              subtitle: const Text(
                'Share your live location with your friends & family',
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_support, color: Colors.purple),
              title: const Text('Connect us'),
              subtitle: const Text('Your words mean a lot to us'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactUsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem, color: Colors.orange),
              title: const Text('Report an Issue'),
              subtitle: const Text(
                'Tell us about any problems you encountered',
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReportIssueScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.call, color: Colors.red),
              title: const Text('Call Emergency'),
              subtitle: const Text('Contact emergency services immediately'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EmergencyContactsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Logout'),
              subtitle: const Text('Logout from app'),
              onTap: () async {
                // Show confirmation dialog
                bool? shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );

                // If user confirmed logout
                if (shouldLogout == true) {
                  await _logout(context);
                }
              },
            ),
          ],
        ),
      ),
      body:
          locationLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(latitude!, longitude!),
                      zoom: 16,
                    ),
                    markers: {
                      if (currentLocationMarker != null) currentLocationMarker!,
                    },
                    polylines: polylines,
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: FloatingActionButton(
                      onPressed: () {
                        if (!journeyStarted) {
                          _showStartJourneyDialog();
                        } else {
                          setState(() {
                            journeyStarted = false;
                            polylines.clear();
                          });
                        }
                      },
                      backgroundColor: Colors.red.shade600,
                      child: Icon(
                        journeyStarted ? Icons.stop : Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}

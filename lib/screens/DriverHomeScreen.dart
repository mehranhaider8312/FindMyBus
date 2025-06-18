import 'dart:async';
import 'dart:io'; // Add this import for File class
import 'package:findmybus/models/RouteModel.dart' as model;
import 'package:findmybus/screens/ChangeLanguageScreen.dart';
import 'package:findmybus/screens/ContactUsScreen.dart';
import 'package:findmybus/screens/EmergencyNumbers.dart';
import 'package:findmybus/screens/LoginScreen.dart';
import 'package:findmybus/screens/ReportIssueScreen.dart';
import 'package:findmybus/screens/RoutesListScreen.dart';
import 'package:findmybus/screens/UserProfileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  List<model.Route> availableRoutes = [];
  bool routesLoading = true;
  bool locationLoading = true;
  bool journeyStarted = false;

  model.Route? selectedRoute;
  String? busId;
  String? driverId;
  String driverName = 'Driver';

  double? latitude;
  double? longitude;

  GoogleMapController? mapController;
  Set<Polyline> polylines = {};
  Set<Marker> routeMarkers = {};

  StreamSubscription<Position>? positionStreamSubscription;

  // User profile data
  String _userName = 'Driver';
  String _userEmail = '';
  String? _profileImagePath;
  bool _userDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _loadUserDataFromPrefs();
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    positionStreamSubscription?.cancel();
    mapController?.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      await _loadDriverData();
      await _fetchCurrentLocation();
      await _loadRoutes();
    } catch (e) {
      _showError('Initialization failed: ${e.toString()}');
    }
  }

  void _refreshUserData() {
    _loadUserDataFromPrefs();
  }

  Future<void> _loadUserDataFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Driver';
        _userEmail = prefs.getString('user_email') ?? '';
        _profileImagePath = prefs.getString('user_profile_image');
        _userDataLoaded = true;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _userDataLoaded = true);
    }
  }

  Future<void> _loadDriverData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        driverId =
            prefs.getString('driver_id') ??
            FirebaseAuth.instance.currentUser?.uid;
        driverName = prefs.getString('driver_name') ?? _userName;
      });
    } catch (e) {
      debugPrint('Error loading driver data: $e');
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => locationLoading = true);

    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
      _updateMapLocation(position);
    } catch (e) {
      _showError('Failed to get location: ${e.toString()}');
    } finally {
      setState(() => locationLoading = false);
    }
  }

  void _updateMapLocation(Position position) {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        16,
      ),
    );
  }

  Future<void> _loadRoutes() async {
    setState(() => routesLoading = true);

    try {
      await model.loadAllRoutes();
      setState(() {
        availableRoutes =
            model.allRoutes.where((route) => route.isActive).toList();
      });
    } catch (e) {
      _showError('Failed to load routes: ${e.toString()}');
    } finally {
      setState(() => routesLoading = false);
    }
  }

  void _drawRoutePolyline() {
    if (selectedRoute == null) return;

    final validStops =
        selectedRoute!.stops.where((stop) => stop.isValidCoordinate).toList();

    if (validStops.isEmpty) {
      _showError('No valid coordinates found in route ${selectedRoute!.id}');
      return;
    }

    validStops.sort((a, b) => a.order.compareTo(b.order));
    final points =
        validStops.map((stop) => LatLng(stop.lat, stop.lng)).toList();

    setState(() {
      polylines = {
        Polyline(
          polylineId: const PolylineId('route_polyline'),
          color: Colors.blue,
          width: 5,
          points: points,
        ),
      };

      routeMarkers =
          validStops.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;

            BitmapDescriptor markerColor;
            if (index == 0) {
              markerColor = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              );
            } else if (index == validStops.length - 1) {
              markerColor = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              );
            } else {
              markerColor = BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              );
            }

            return Marker(
              markerId: MarkerId(stop.stopId),
              position: LatLng(stop.lat, stop.lng),
              infoWindow: InfoWindow(
                title: stop.stopName,
                snippet: 'Stop ${stop.order} - ${stop.coordinatesString}',
              ),
              icon: markerColor,
            );
          }).toSet();
    });

    _animateCameraToRoute(points);
  }

  void _animateCameraToRoute(List<LatLng> points) {
    if (mapController == null || points.isEmpty) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      try {
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

        const double padding = 0.001;
        final bounds = LatLngBounds(
          southwest: LatLng(minLat - padding, minLng - padding),
          northeast: LatLng(maxLat + padding, maxLng + padding),
        );

        mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      } catch (e) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 14),
        );
      }
    });
  }

  void _startLocationTracking() {
    if (driverId == null || busId == null || selectedRoute == null) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) async {
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });

        try {
          await FirebaseFirestore.instance
              .collection('driversLocation')
              .doc(driverId)
              .set({
                'busID': busId,
                'routeId': selectedRoute!.id,
                'driverName': _userName, // Use the loaded user name
                'currentLocation': GeoPoint(
                  position.latitude,
                  position.longitude,
                ),
                'timestamp': FieldValue.serverTimestamp(),
                'isActive': true,
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error updating driver location: $e');
        }
      },
      onError: (error) {
        _showError('Location tracking failed');
      },
    );
  }

  Future<void> _stopJourney() async {
    positionStreamSubscription?.cancel();

    if (driverId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('driversLocation')
            .doc(driverId)
            .update({
              'isActive': false,
              'timestamp': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint('Error setting driver inactive: $e');
      }
    }

    setState(() {
      journeyStarted = false;
      selectedRoute = null;
      busId = null;
      polylines.clear();
      routeMarkers.clear();
    });
  }

  void _startJourney(model.Route route, String busIdInput) {
    setState(() {
      selectedRoute = route;
      busId = busIdInput;
      journeyStarted = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _drawRoutePolyline();
      _startLocationTracking();
    });

    _showSuccess('Journey started for ${route.id}');
  }

  Future<void> _logout(BuildContext context) async {
    _showLoadingDialog('Logging out...');

    try {
      if (journeyStarted) {
        await _stopJourney();
      }

      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        _showSuccess('Logged out successfully');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showError('Logout failed: ${e.toString()}');
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ],
            ),
          ),
    );
  }

  void _showStartJourneyDialog() {
    if (routesLoading) {
      _showError('Please wait, loading routes...');
      return;
    }

    if (availableRoutes.isEmpty) {
      _showError('No active routes available');
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => _StartJourneyDialog(
            routes: availableRoutes,
            onStartJourney: _startJourney,
          ),
    );
  }

  void _shareLiveLocation() {
    if (latitude == null || longitude == null) {
      _showError('Location not available yet');
      return;
    }

    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final message = 'Here is my current location: $googleMapsUrl';

    Share.share(message);
  }

  void _showStopJourneyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Stop Journey'),
            content: const Text(
              'Are you sure you want to stop the current journey?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _stopJourney();
                  _showSuccess('Journey stopped successfully');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Stop Journey'),
              ),
            ],
          ),
    );
  }

  void _refreshData() async {
    setState(() {
      routesLoading = true;
      locationLoading = true;
    });

    await Future.wait([_fetchCurrentLocation(), _loadRoutes()]);
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
        actions: [
          if (journeyStarted)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(latitude ?? 31.5204, longitude ?? 74.3587),
              zoom: 16,
            ),
            markers: routeMarkers,
            polylines: polylines,
            onMapCreated: (controller) {
              mapController = controller;
              if (latitude != null &&
                  longitude != null &&
                  routeMarkers.isEmpty) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(latitude!, longitude!),
                      16,
                    ),
                  );
                });
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            compassEnabled: true,
            zoomControlsEnabled: false,
          ),
          if (journeyStarted && selectedRoute != null)
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Journey Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Route: ${selectedRoute!.id}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      'Bus: $busId | Driver: $_userName',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      'Stops: ${selectedRoute!.totalStops}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // Loading indicator for location
          if (locationLoading)
            const Positioned(
              top: 120,
              left: 20,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading location...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            journeyStarted ? _showStopJourneyDialog : _showStartJourneyDialog,
        backgroundColor:
            journeyStarted ? Colors.red.shade600 : Colors.green.shade600,
        icon: Icon(
          journeyStarted ? Icons.stop : Icons.play_arrow,
          color: Colors.white,
        ),
        label: Text(
          journeyStarted ? 'Stop Journey' : 'Start Journey',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.red.shade600),
            accountName: Text(
              _userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: GestureDetector(
              onTap: () async {
                Navigator.pop(context); // Close drawer first
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserProfileScreen(),
                  ),
                );
                // Refresh user data when returning from profile screen
                _refreshUserData();
              },
              child: const Text(
                'View Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage:
                  _profileImagePath != null &&
                          File(_profileImagePath!).existsSync()
                      ? FileImage(File(_profileImagePath!))
                      : const AssetImage('assets/images/logo_image.jpg')
                          as ImageProvider,
              child:
                  _profileImagePath == null ||
                          !File(_profileImagePath!).existsSync()
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.directions_bus, color: Colors.yellow),
            title: const Text('Routes List'),
            subtitle: Text('${availableRoutes.length} active routes'),
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
                MaterialPageRoute(builder: (context) => ChangeLanguageScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.share_location,
              color: Color.fromARGB(255, 54, 244, 241),
            ),
            title: const Text('Share Your Location'),
            subtitle: const Text(
              'Share your live location with your friends & family',
            ),
            onTap: () {
              Navigator.pop(context);
              _shareLiveLocation();
            },
          ),

          ListTile(
            leading: const Icon(Icons.report_problem, color: Colors.orange),
            title: const Text('Report an Issue'),
            subtitle: const Text('Tell us about any problems you encountered'),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Logout'),
            subtitle: const Text('Logout from app'),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Are you sure you want to logout?'),
                          if (journeyStarted)
                            const Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Note: This will stop your current active journey.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
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
                    ),
              );

              if (shouldLogout == true) {
                await _logout(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StartJourneyDialog extends StatefulWidget {
  final List<model.Route> routes;
  final Function(model.Route, String) onStartJourney;

  const _StartJourneyDialog({
    required this.routes,
    required this.onStartJourney,
  });

  @override
  State<_StartJourneyDialog> createState() => _StartJourneyDialogState();
}

class _StartJourneyDialogState extends State<_StartJourneyDialog> {
  model.Route? selectedRoute;
  final TextEditingController busIdController = TextEditingController();

  @override
  void dispose() {
    busIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start Journey'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<model.Route>(
            decoration: const InputDecoration(labelText: 'Select Route'),
            value: selectedRoute,
            onChanged: (route) => setState(() => selectedRoute = route),
            items:
                widget.routes.map((route) {
                  return DropdownMenuItem<model.Route>(
                    value: route,
                    child: Text('${route.id} (${route.totalStops} stops)'),
                  );
                }).toList(),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: busIdController,
            decoration: const InputDecoration(labelText: 'Bus ID'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (selectedRoute != null && busIdController.text.isNotEmpty) {
              Navigator.pop(context);
              widget.onStartJourney(selectedRoute!, busIdController.text);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select route and enter bus ID'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Start Journey'),
        ),
      ],
    );
  }
}

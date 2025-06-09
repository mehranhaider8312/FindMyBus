import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:findmybus/models/DriverModel.dart';
import 'package:findmybus/screens/ChangeLanguageScreen.dart';
import 'package:findmybus/screens/ContactUsScreen.dart';
import 'package:findmybus/screens/EmergencyNumbers.dart';
import 'package:findmybus/screens/LoginScreen.dart';
import 'package:findmybus/screens/RoutesListScreen.dart';
import 'package:findmybus/screens/UserProfileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  GoogleMapController? mapController;
  Set<Marker> busMarkers = {};
  StreamSubscription<List<Driver>>? driversStreamSubscription;

  double? userLatitude;
  double? userLongitude;
  bool locationLoading = true;
  bool isMapReady = false;

  BitmapDescriptor? busIcon;

  final List<Map<String, String>> busStops = [
    {'stopName': 'SKMH Stop', 'distance': '0.5 km', 'duration': '1 min'},
    {'stopName': 'UCP Stop', 'distance': '1.2 km', 'duration': '3 min'},
    {'stopName': 'Model Town Stop', 'distance': '2.5 km', 'duration': '7 min'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }

  void _cleanupResources() {
    driversStreamSubscription?.cancel();
    mapController?.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      await _createBusIcon();
      await _getCurrentLocation();
      _startListeningToDrivers();
    } catch (e) {
      _showError('Initialization failed: ${e.toString()}');
    }
  }

  Future<void> _createBusIcon() async {
    try {
      // Create a custom bus icon
      final Uint8List busIconBytes = await _createBusMarkerIcon();
      busIcon = BitmapDescriptor.fromBytes(busIconBytes);
    } catch (e) {
      print('Error creating bus icon: $e');
      // Fallback to default marker
      busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<Uint8List> _createBusMarkerIcon() async {
    const int size = 100;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Draw bus icon background
    final Paint backgroundPaint =
        Paint()
          ..color = Colors.red.shade600
          ..style = PaintingStyle.fill;

    final Paint borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    // Draw circle background
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 5,
      backgroundPaint,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 5,
      borderPaint,
    );

    // Draw bus icon (simplified)
    final Paint busPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    // Bus body
    final Rect busBody = Rect.fromLTWH(
      size * 0.2,
      size * 0.3,
      size * 0.6,
      size * 0.4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(busBody, const Radius.circular(8)),
      busPaint,
    );

    // Bus windows
    final Paint windowPaint =
        Paint()
          ..color = Colors.red.shade600
          ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(size * 0.25, size * 0.35, size * 0.15, size * 0.15),
      windowPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size * 0.45, size * 0.35, size * 0.15, size * 0.15),
      windowPaint,
    );

    // Convert to image
    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(size, size);
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  Future<void> _getCurrentLocation() async {
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
        userLatitude = position.latitude;
        userLongitude = position.longitude;
      });

      _updateMapLocation();
    } catch (e) {
      _showError('Failed to get location: ${e.toString()}');
      // Set default location to Lahore if location fails
      setState(() {
        userLatitude = 31.5204;
        userLongitude = 74.3587;
      });
    } finally {
      setState(() => locationLoading = false);
    }
  }

  void _updateMapLocation() {
    if (mapController != null &&
        userLatitude != null &&
        userLongitude != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(userLatitude!, userLongitude!), 14),
      );
    }
  }

  void _startListeningToDrivers() {
    driversStreamSubscription = getActiveDriversStream().listen(
      (drivers) {
        _updateBusMarkers(drivers);
      },
      onError: (error) {
        print('Error listening to drivers: $error');
        _showError('Failed to load bus locations');
      },
    );
  }

  void _updateBusMarkers(List<Driver> drivers) {
    if (!isMapReady || busIcon == null) return;

    setState(() {
      busMarkers =
          drivers.map((driver) {
            return Marker(
              markerId: MarkerId(driver.driverId),
              position: LatLng(driver.latitude, driver.longitude),
              icon: busIcon!,
              infoWindow: InfoWindow(
                title: 'Bus ${driver.busId}',
                snippet:
                    'Route: ${driver.routeId}\nDriver: ${driver.driverName}\nLast updated: ${driver.timeSinceUpdate}',
              ),
              onTap: () => _showBusDetails(driver),
            );
          }).toSet();
    });
  }

  void _showBusDetails(Driver driver) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Bus ${driver.busId}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Route: ${driver.routeId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Driver: ${driver.driverName}'),
                const SizedBox(height: 8),
                Text('Last Updated: ${driver.timeSinceUpdate}'),
                const SizedBox(height: 8),
                Text(
                  'Location: ${driver.latitude.toStringAsFixed(6)}, ${driver.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: driver.isActive ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    driver.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _focusOnBus(driver);
                },
                child: const Text('Focus on Map'),
              ),
            ],
          ),
    );
  }

  void _focusOnBus(Driver driver) {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(driver.latitude, driver.longitude), 16),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      _showLoadingDialog('Logging out...');

      await FirebaseAuth.instance.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        _showSuccess('Logged out successfully');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showError('Logout failed: ${e.toString()}');
      }
    }
  }

  void _shareLiveLocation() {
    if (userLatitude == null || userLongitude == null) {
      _showError('Location not available yet');
      return;
    }

    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$userLatitude,$userLongitude';
    final message = 'Here is my current location: $googleMapsUrl';

    Share.share(message);
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

  void _refreshData() async {
    setState(() => locationLoading = true);
    await _getCurrentLocation();
    // The drivers stream will automatically refresh
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Find My Bus',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.red.shade600,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(userLatitude ?? 31.5204, userLongitude ?? 74.3587),
              zoom: 14,
            ),
            markers: busMarkers,
            onMapCreated: (controller) {
              mapController = controller;
              setState(() => isMapReady = true);
              _updateMapLocation();
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            compassEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Search Bar
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 3,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Tap to Search route',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.location_on_sharp),
                ),
              ),
            ),
          ),

          // Active Buses Count
          Positioned(
            top: 80,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${busMarkers.length} Active Buses',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bus Stops List at the Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 5,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Nearby Bus Stops',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          busStops.map((stop) {
                            return BusStopCard(
                              stopName: stop['stopName']!,
                              distance: stop['distance']!,
                              duration: stop['duration']!,
                            );
                          }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading indicator
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
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Colors.red.shade600),
            accountName: const Text(
              'Esha Khan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            accountEmail: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => UserProfileScreen(
                          name: 'Esha Khan',
                          email: 'eshakhan8312',
                          imagePath: 'assets/images/logo_image.jpg',
                        ),
                  ),
                );
              },
              child: const Text(
                'View Profile',
                style: TextStyle(color: Colors.white),
              ),
            ),
            currentAccountPicture: const CircleAvatar(
              backgroundImage: AssetImage('assets/images/logo_image.jpg'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.green),
            title: const Text('Nearby bus stops'),
            subtitle: const Text('View all nearby stops in the map'),
            onTap: () {
              Navigator.pop(context);
            },
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
              _shareLiveLocation();
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
            leading: const Icon(Icons.emergency_share, color: Colors.red),
            title: const Text('Report an emergency'),
            subtitle: const Text(
              'Call any emergency helpline in case for any danger',
            ),
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
            leading: const Icon(Icons.language, color: Colors.blue),
            title: const Text('Change Language'),
            subtitle: const Text('Change Language'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangeLanguageScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Logout'),
            subtitle: const Text('Logout from app'),
            onTap: () async {
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

// Bus Stop Card Widget (unchanged)
class BusStopCard extends StatelessWidget {
  final String stopName;
  final String distance;
  final String duration;

  const BusStopCard({
    required this.stopName,
    required this.distance,
    required this.duration,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(right: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 5,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, color: Colors.red.shade600, size: 30),
            const SizedBox(height: 5),
            Text(
              stopName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              '$distance ($duration)',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

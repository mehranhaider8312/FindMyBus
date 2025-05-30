import 'package:findmybus/screens/ChangeLanguageScreen.dart';
import 'package:findmybus/screens/ContactUsScreen.dart';
import 'package:findmybus/screens/EmergencyNumbers.dart';
import 'package:findmybus/screens/LoginScreen.dart';
import 'package:findmybus/screens/RoutesListScreen.dart';
import 'package:findmybus/screens/UserProfileScreen.dart';
import 'package:flutter/material.dart';

class PassangerHomeScreen extends StatelessWidget {
  PassangerHomeScreen({super.key});

  final List<Map<String, String>> busStops = [
    {'stopName': 'SKMH Stop', 'distance': '0.5 km', 'duration': '1 min'},
    {'stopName': 'UCP Stop', 'distance': '1.2 km', 'duration': '3 min'},
    {'stopName': 'Model Town Stop', 'distance': '2.5 km', 'duration': '7 min'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            'Find My Bus',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
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
              accountName: const Text(
                'Esha Khan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: GestureDetector(
                onTap: () {
                  // Navigate to the UserProfileScreen with user data
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
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage(
                  'assets/images/logo_image.jpg',
                ), // Replace with your profile image path
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
                'Call any emergeny helpline in case for any danger',
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
                  MaterialPageRoute(
                    builder: (context) => ChangeLanguageScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Logout'),
              subtitle: const Text('Logout from app'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Map Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/map_background.jpg', // Replace with your map image asset
              fit: BoxFit.cover,
            ),
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
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Tap to Search route',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.location_on_sharp),
                ),
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        ],
      ),
    );
  }
}

// Bus Stop Card Widget
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

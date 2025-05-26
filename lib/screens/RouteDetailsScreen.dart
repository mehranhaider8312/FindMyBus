import 'package:flutter/material.dart';

class RouteDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    // Extract the name of the route as "First Stop to Last Stop"
    final String routeName =
        '${route['stops'].first} to ${route['stops'].last}';

    final int activeBuses = 3; //Dummy value

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Route Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Number
            Text(
              'Route Number: ${route['routeNumber']}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 10),

            // Route Name
            Text(
              'Route Name: $routeName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            // Number of Active Buses
            Text(
              'Active Buses: $activeBuses',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // Stops Heading
            Text(
              'Stops on this route:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 10),

            // List of Stops
            Expanded(
              child: ListView.builder(
                itemCount: route['stops'].length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.shade600,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      route['stops'][index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:findmybus/models/RouteModel.dart';
import 'package:findmybus/models/RouteModel.dart' as RouteModel;
import 'package:flutter/material.dart';

class RouteDetailsScreen extends StatelessWidget {
  final RouteModel.Route route;

  const RouteDetailsScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    // Sort stops by order to ensure correct sequence
    final sortedStops = List<Stop>.from(route.stops)
      ..sort((a, b) => a.order.compareTo(b.order));

    // Extract the route name as "First Stop to Last Stop"
    final String routeName =
        sortedStops.isNotEmpty
            ? '${sortedStops.first.stopName} to ${sortedStops.last.stopName}'
            : 'No stops available';

    final int activeBuses = 3; // Dummy value - you can update this later

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade600,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
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
            // Route ID
            Text(
              'Route ID: ${route.id}',
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

            // Route Status
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        route.isActive
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    route.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          route.isActive
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
            const SizedBox(height: 10),

            // Total Stops
            Text(
              'Total Stops: ${route.totalStops}',
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
              child:
                  sortedStops.isEmpty
                      ? const Center(
                        child: Text(
                          'No stops available',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        itemCount: sortedStops.length,
                        itemBuilder: (context, index) {
                          final stop = sortedStops[index];
                          final bool isTerminal =
                              index == 0 || index == sortedStops.length - 1;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    isTerminal
                                        ? Colors.orange.shade600
                                        : Colors.red.shade600,
                                child: Text(
                                  '${stop.order}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                stop.stopName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      isTerminal
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stop ID: ${stop.stopId}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Coordinates: ${stop.stopCoordinates}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              trailing:
                                  isTerminal
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Terminal',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                      : null,
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

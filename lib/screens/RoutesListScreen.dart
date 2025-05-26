import 'package:flutter/material.dart';
import 'RouteDetailsScreen.dart';

class Routeslistscreen extends StatefulWidget {
  const Routeslistscreen({super.key});

  @override
  State<Routeslistscreen> createState() => _RouteslistscreenState();
}

class _RouteslistscreenState extends State<Routeslistscreen> {
  final List<Map<String, dynamic>> routes = [
    {
      'routeNumber': 'Route 1',
      'numberOfStops': 5,
      'stops': ['Stop 1', 'Stop 2', 'Stop 3', 'Stop 4', 'Stop 5'],
      'isFavorite': false,
    },
    {
      'routeNumber': 'Route 2',
      'numberOfStops': 6,
      'stops': ['Stop A', 'Stop B', 'Stop C', 'Stop D', 'Stop E', 'Stop F'],
      'isFavorite': false,
    },
    {
      'routeNumber': 'Route 3',
      'numberOfStops': 4,
      'stops': ['Stop X', 'Stop Y', 'Stop Z', 'Stop W'],
      'isFavorite': false,
    },
  ];
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredRoutes = routes
        .where((route) => route['routeNumber']
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList();

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
          'Speedo Bus Routes',
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
            const SizedBox(height: 20),
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by Route Number',
                prefixIcon: Icon(Icons.search, color: Colors.red.shade600),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 15,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Route List
            Expanded(
              child: filteredRoutes.isEmpty
                  ? const Center(
                      child: Text(
                        'No routes found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredRoutes.length,
                      itemBuilder: (context, index) {
                        final route = filteredRoutes[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    RouteDetailsScreen(route: route),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: Colors.red.shade600,
                                    width: 5,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          route['routeNumber'],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Number of Stops: ${route['numberOfStops']}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        route['isFavorite']
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: Colors.red.shade600,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          route['isFavorite'] =
                                              !route['isFavorite'];
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

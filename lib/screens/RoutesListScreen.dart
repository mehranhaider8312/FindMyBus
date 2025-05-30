import 'package:findmybus/models/RouteModel.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'RouteDetailsScreen.dart';

class Routeslistscreen extends StatefulWidget {
  const Routeslistscreen({super.key});

  @override
  State<Routeslistscreen> createState() => _RouteslistscreenState();
}

class _RouteslistscreenState extends State<Routeslistscreen> {
  String searchQuery = '';
  List<String> favoriteRoutes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    print('🔄 Starting to initialize data...');

    // Load routes from Firestore if not already loaded
    if (allRoutes.isEmpty) {
      print('📥 allRoutes is empty, loading from Firestore...');
      await loadAllRoutes();
    } else {
      print('✅ allRoutes already has ${allRoutes.length} routes');
    }

    // Print debug info about loaded routes
    print('📊 Total routes loaded: ${allRoutes.length}');
    for (int i = 0; i < allRoutes.length; i++) {
      final route = allRoutes[i];
      print(
        'Route $i: ID=${route.id}, Active=${route.isActive}, Stops=${route.totalStops}',
      );
    }

    // Load favorite routes from SharedPreferences
    await _loadFavorites();

    setState(() {
      isLoading = false;
    });

    print('✅ Data initialization complete');
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    favoriteRoutes = prefs.getStringList('favorite_routes') ?? [];
    print('💖 Loaded ${favoriteRoutes.length} favorite routes');
  }

  Future<void> _saveFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorite_routes', favoriteRoutes);
  }

  void _toggleFavorite(String routeId) {
    setState(() {
      if (favoriteRoutes.contains(routeId)) {
        favoriteRoutes.remove(routeId);
      } else {
        favoriteRoutes.add(routeId);
      }
    });
    _saveFavorites();
  }

  bool _isFavorite(String routeId) {
    return favoriteRoutes.contains(routeId);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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
        body: const Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    // Filter routes based on search query and active status
    final filteredRoutes =
        allRoutes.where((route) {
          final matchesSearch = route.id.toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
          final isActive = route.isActive;

          print(
            '🔍 Route ${route.id}: Active=$isActive, MatchesSearch=$matchesSearch (query="$searchQuery")',
          );

          return isActive && matchesSearch;
        }).toList();

    print(
      '📋 Filtered routes: ${filteredRoutes.length} out of ${allRoutes.length}',
    );

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
            // Debug Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🐛 Debug Info:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text('Total Routes: ${allRoutes.length}'),
                    Text('Filtered Routes: ${filteredRoutes.length}'),
                    Text('Search Query: "$searchQuery"'),
                    Text(
                      'Active Routes: ${allRoutes.where((r) => r.isActive).length}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Search Bar
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                print('🔍 Search query changed to: "$value"');
              },
              decoration: InputDecoration(
                hintText: 'Search by Route ID',
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
              child:
                  filteredRoutes.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No routes found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (allRoutes.isEmpty)
                              const Text(
                                'No routes loaded from database',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              )
                            else if (allRoutes.where((r) => r.isActive).isEmpty)
                              const Text(
                                'No active routes available',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              )
                            else
                              const Text(
                                'Try clearing the search or check route status',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
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
                                  builder:
                                      (context) =>
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            route.id,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Number of Stops: ${route.totalStops}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  route.isActive
                                                      ? Colors.green.shade100
                                                      : Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              route.isActive
                                                  ? 'Active'
                                                  : 'Inactive',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    route.isActive
                                                        ? Colors.green.shade700
                                                        : Colors.red.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isFavorite(route.id)
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: Colors.red.shade600,
                                        ),
                                        onPressed: () {
                                          _toggleFavorite(route.id);
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

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
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.red.shade600,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.red.shade600, Colors.red.shade700],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Route ID with icon
                      Row(
                        children: [
                          Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            route.id,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Route name
                      Text(
                        routeName,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Cards Row
                  Row(
                    children: [
                      // Status Card
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.circle,
                          iconColor: route.isActive ? Colors.green : Colors.red,
                          title: 'Status',
                          value: route.isActive ? 'Active' : 'Inactive',
                          backgroundColor:
                              route.isActive
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Active Buses Card
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.directions_bus_outlined,
                          iconColor: Colors.blue.shade600,
                          title: 'Active Buses',
                          value: activeBuses.toString(),
                          backgroundColor: Colors.blue.shade50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Total Stops Card
                  _buildStatCard(
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.orange.shade600,
                    title: 'Total Stops',
                    value: route.totalStops.toString(),
                    backgroundColor: Colors.orange.shade50,
                    isFullWidth: true,
                  ),

                  const SizedBox(height: 24),

                  // Stops Section Header
                  Row(
                    children: [
                      Icon(Icons.route, color: Colors.red.shade600, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Route Stops',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Stops List
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (sortedStops.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_off_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No stops available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final stop = sortedStops[index];
              final bool isFirst = index == 0;
              final bool isLast = index == sortedStops.length - 1;
              final bool isTerminal = isFirst || isLast;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _buildStopCard(stop, index, isTerminal, isFirst, isLast),
              );
            }, childCount: sortedStops.isEmpty ? 1 : sortedStops.length),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color backgroundColor,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child:
          isFullWidth
              ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStopCard(
    Stop stop,
    int index,
    bool isTerminal,
    bool isFirst,
    bool isLast,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Top line (hidden for first stop)
              if (!isFirst)
                Container(width: 2, height: 20, color: Colors.red.shade300),
              // Circle indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color:
                      isTerminal ? Colors.orange.shade600 : Colors.red.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${stop.order}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Bottom line (hidden for last stop)
              if (!isLast)
                Container(width: 2, height: 20, color: Colors.red.shade300),
            ],
          ),
          const SizedBox(width: 16),

          // Stop details card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color:
                      isTerminal
                          ? Colors.orange.shade200
                          : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stop.stopName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isTerminal ? FontWeight.bold : FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (isTerminal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isFirst ? 'Start' : 'End',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'ID: ${stop.stopId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stop.stopCoordinates,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
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

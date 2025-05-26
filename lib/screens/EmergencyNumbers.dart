import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  // Emergency contacts data
  final List<Map<String, String>> contacts = const [
    {'name': 'Police Emergency', 'contact': '15'},
    {'name': 'Rescue 1122', 'contact': '1122'},
    {'name': 'Fire Brigade', 'contact': '16'},
    {'name': 'Ambulance Service', 'contact': '115'},
    {'name': 'Traffic Police Lahore', 'contact': '042-99204619'},
    {'name': 'Women Protection Helpline', 'contact': '1043'},
    {'name': 'Child Protection Bureau', 'contact': '1121'},
    {'name': 'Anti-Terrorism Squad', 'contact': '0800-11111'},
    {'name': 'Punjab Highway Patrol', 'contact': '1124'},
    {'name': 'Lahore Waste Management Company', 'contact': '1139'},
  ];

  // Function to simulate a call
  void _makeCall(String phoneNumber) async {
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.phone, color: Colors.red),
                title: Text(
                  contact['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(contact['contact']!),
                onTap: () => _makeCall(contact['contact']!),
              ),
            );
          },
        ),
      ),
    );
  }
}

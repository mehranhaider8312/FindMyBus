import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  // Variables to store user input
  String? _issueType;
  DateTime? _selectedDateTime;
  TextEditingController _descriptionController = TextEditingController();

  // Date picker function
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _selectedDateTime) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (timePicked != null) {
        setState(() {
          _selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  // Function to handle report submission
  void _submitReport() {
    if (_issueType == null ||
        _selectedDateTime == null ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // Here you can add the logic to send the report to your backend or database.
    // For now, just a simple print to simulate the process.

    print("Report submitted");
    print("Issue Type: $_issueType");
    print("Date and Time: $_selectedDateTime");
    print("Description: ${_descriptionController.text}");

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report successfully submitted")),
    );

    // Clear the form after submission
    setState(() {
      _issueType = null;
      _selectedDateTime = null;
      _descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report an Issue',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red.shade600,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Issue Type Selection
              DropdownButtonFormField<String>(
                value: _issueType,
                decoration: const InputDecoration(labelText: 'Issue Type'),
                onChanged: (value) {
                  setState(() {
                    _issueType = value;
                  });
                },
                items: ['Bus Issue', 'Route Issue']
                    .map((issue) => DropdownMenuItem<String>(
                          value: issue,
                          child: Text(issue),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Date and Time Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDateTime == null
                        ? 'Select Date & Time'
                        : 'Selected: ${_selectedDateTime!.toLocal()}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDateTime(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Issue Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Describe the issue',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Report Button
              ElevatedButton(
                onPressed: _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text(
                  'Submit Report',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

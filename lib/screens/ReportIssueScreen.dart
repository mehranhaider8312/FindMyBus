import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  _ReportIssueScreenState createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  String? _selectedIssueType;
  final TextEditingController _descriptionController = TextEditingController();
  String _userId = '';
  String _userName = '';
  bool _isSubmitting = false;
  bool _isLoadingUserData = true;

  final List<String> _issueTypes = [
    'Bus Breakdown',
    'Route Blocked',
    'Safety Concern',
    'Bus Maintenance Needed',
    'Traffic Issue',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userId = prefs.getString('user_id') ?? '';
        _userName = prefs.getString('user_name') ?? 'Driver';
        _isLoadingUserData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUserData = false;
      });
      _showError('Failed to load user data. Please log in again.');
    }
  }

  Future<void> _submitReport() async {
    if (_selectedIssueType == null || _selectedIssueType!.isEmpty) {
      _showError('Please select an issue type');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please provide a description');
      return;
    }
    if (_userId.isEmpty) {
      _showError('User ID is missing. Please log in again.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('issues').add({
        'title': _selectedIssueType,
        'description': _descriptionController.text.trim(),
        'timeStamp': FieldValue.serverTimestamp(),
        'driverId': _userId,
        'driverName': _userName,
        'status': 'pending',
        'priority': _getPriorityForIssueType(_selectedIssueType!),
      });

      _showSuccess('Issue reported successfully!');
      setState(() {
        _selectedIssueType = null;
        _descriptionController.clear();
      });
    } catch (e) {
      _showError('Failed to submit report. Check your connection or rules.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  String _getPriorityForIssueType(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'safety concern':
      case 'bus breakdown':
        return 'high';
      case 'route blocked':
      case 'bus maintenance needed':
        return 'medium';
      default:
        return 'low';
    }
  }

  IconData _getIconForIssueType(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'bus breakdown':
        return Icons.build;
      case 'route blocked':
        return Icons.block;
      case 'safety concern':
        return Icons.warning;
      case 'bus maintenance needed':
        return Icons.directions_bus;
      case 'traffic issue':
        return Icons.traffic;
      default:
        return Icons.report_problem;
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUserData) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Issue',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'Driver: $_userName',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Issue Type *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedIssueType,
              decoration: InputDecoration(
                hintText: 'Select issue type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.red),
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              onChanged:
                  _isSubmitting
                      ? null
                      : (value) => setState(() => _selectedIssueType = value),
              items:
                  _issueTypes
                      .map(
                        (issue) => DropdownMenuItem<String>(
                          value: issue,
                          child: Row(
                            children: [
                              Icon(
                                _getIconForIssueType(issue),
                                size: 20,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Text(issue),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Description *',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isSubmitting,
              maxLines: 5,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Submitting...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                          : const Text(
                            'Submit Report',
                            style: TextStyle(fontSize: 16),
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  // Launch email functionality
  void _launchEmail() async {
    final email = Uri(
      scheme: 'mailto',
      path: 'afc.bss@pma.punjab.gov.pk',
      query: 'subject=Contact Us&body=Your Message Here', // Optional
    );
    if (await canLaunchUrl(email)) {
      await launchUrl(email);
    } else {
      throw 'Could not launch $email';
    }
  }

  // Launch call functionality
  void _launchCall() async {
    final phone = Uri(scheme: 'tel', path: '042111222627');
    if (await canLaunchUrl(phone)) {
      await launchUrl(phone);
    } else {
      throw 'Could not launch $phone';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Avoid keyboard issues
      appBar: AppBar(
        backgroundColor: Colors.red, // Your color scheme
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Connect Us', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white, // Background color for the screen
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Us',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'afc.bss@pma.punjab.gov.pk',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        IconButton(
                          onPressed: _launchEmail,
                          icon: const Icon(Icons.email, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Helpline Number',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '042 111 222 627',
                          style: TextStyle(color: Colors.black, fontSize: 14),
                        ),
                        IconButton(
                          onPressed: _launchCall,
                          icon: const Icon(Icons.phone, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Or write us',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: 'Enter Full Name',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.yellow,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ), // Fixed alignment
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: 'Enter Email Address',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.green,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ), // Fixed alignment
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      maxLines: 4,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[200],
                        hintText: 'Enter your message',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(Icons.edit, color: Colors.red),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 18,
                        ), // Fixed alignment
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Add submit functionality here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

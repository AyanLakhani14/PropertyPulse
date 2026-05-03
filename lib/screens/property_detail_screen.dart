import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'booking_screen.dart';

class PropertyDetailScreen extends StatelessWidget {
  final String propertyId;
  final Map<String, dynamic> data;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Property Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['title'],
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            Text("💰 Price: \$${data['price']}"),
            Text("📏 Size: ${data['size']} sqft"),
            Text("📍 Location: ${data['location']}"),
            Text("🏠 Condition: ${data['condition']}"),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(propertyId: propertyId),
                  ),
                );
              },
              child: const Text("Chat with Seller"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(propertyId: propertyId),
                  ),
                );
              },
              child: const Text("Book Viewing"),
            ),
          ],
        ),
      ),
    );
  }
}
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

            // 🖼️ IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                data['image'] ??
                    "https://via.placeholder.com/300",
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              data['title'],
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("💰 \$${data['price']}"),
            Text("📍 ${data['location']}"),
            Text("📏 ${data['size']} sqft"),
            Text("🏠 Condition: ${data['condition']}"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ChatScreen(propertyId: propertyId),
                  ),
                );
              },
              child: const Text("Chat"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      propertyId: propertyId,
                      propertyTitle: data['title'],
                    ),
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
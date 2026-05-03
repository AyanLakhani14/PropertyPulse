import 'package:flutter/material.dart';
import 'booking_screen.dart';
import 'edit_property_screen.dart';

// 🔥 ESTIMATOR
Map<String, dynamic> estimatePrice(Map<String, dynamic> data) {
  final size = (data['size'] ?? 1000).toDouble();
  final condition = (data['condition'] ?? 3).toDouble();

  double estimate = (size * 150) + (condition * 10000);

  return {
    'low': (estimate * 0.9).round(),
    'high': (estimate * 1.1).round(),
    'confidence': condition >= 4
        ? "High"
        : condition <= 2
            ? "Low"
            : "Medium",
  };
}

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
    final estimate = estimatePrice(data);

    return Scaffold(
      appBar: AppBar(title: const Text("Property Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [

            Text(
              data['title'] ?? "",
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text("💰 \$${data['price'] ?? 0}"),
            Text("📏 ${data['size'] ?? 0} sqft"),
            Text("📍 ${data['location'] ?? ""}"),
            Text("🏠 Condition: ${data['condition'] ?? ""}"),

            const SizedBox(height: 20),

            // 🔥 ESTIMATOR
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Estimated Price Range"),
                  Text(
                    "\$${estimate['low']} - \$${estimate['high']}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text("Confidence: ${estimate['confidence']}"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📅 BOOK
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      propertyId: propertyId,
                      propertyTitle: data['title'] ?? "",
                    ),
                  ),
                );
              },
              child: const Text("Book Viewing"),
            ),

            const SizedBox(height: 10),

            // ✏️ EDIT
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPropertyScreen(
                      propertyId: propertyId,
                      data: data,
                    ),
                  ),
                );
              },
              child: const Text("Edit Property"),
            ),
          ],
        ),
      ),
    );
  }
}
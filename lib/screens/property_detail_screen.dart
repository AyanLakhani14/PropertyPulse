import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'booking_screen.dart';
import 'edit_property_screen.dart';

Map<String, dynamic> estimatePrice(Map<String, dynamic> data) {
  final size = (data['size'] ?? 1000).toDouble();
  final condition = (data['condition'] ?? 3).toDouble();
  final location =
      (data['location'] ?? "").toString().toLowerCase();

  double base = size * 150;

  if (location.contains("atlanta")) base *= 1.2;
  if (location.contains("buckhead")) base *= 1.3;
  if (location.contains("tucker")) base *= 1.1;

  base += condition * 10000;

  return {
    'low': (base * 0.9).round(),
    'high': (base * 1.1).round(),
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

  Future<List<QueryDocumentSnapshot>> getComparables() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('properties')
        .limit(3)
        .get();
    return snapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    final est = estimatePrice(data);

    return Scaffold(
      appBar: AppBar(title: const Text("Property Details")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(data['title'] ?? "",
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            Text("💰 \$${data['price'] ?? 0}"),
            Text("📏 ${data['size'] ?? 0} sqft"),
            Text("📍 ${data['location'] ?? ""}"),
            Text("🏠 Condition: ${data['condition'] ?? ""}"),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Estimated Price Range"),
                  Text("\$${est['low']} - \$${est['high']}"),
                  Text("Confidence: ${est['confidence']}"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text("Comparable Properties"),

            FutureBuilder(
              future: getComparables(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final docs = snapshot.data!;

                return Column(
                  children: docs.map((doc) {
                    final d =
                        doc.data() as Map<String, dynamic>;

                    return ListTile(
                      leading: const Icon(Icons.home),
                      title: Text(d['title'] ?? ""),
                      subtitle:
                          Text("\$${d['price'] ?? 0}"),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 20),

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
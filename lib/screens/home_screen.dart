import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_property_screen.dart';
import 'chat_screen.dart';
import 'booking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchText = "";
  double maxPrice = 1000000;

  // ❤️ Toggle Favorite
  void toggleFavorite(String propertyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(propertyId);

    final doc = await favRef.get();

    if (doc.exists) {
      await favRef.delete();
    } else {
      await favRef.set({
        'savedAt': Timestamp.now(),
      });
    }
  }

  // ❤️ Check Favorite
  Stream<bool> isFavorite(String propertyId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(propertyId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // 🔥 PRICE ESTIMATOR
  Map<String, dynamic> estimatePrice(
      Map<String, dynamic> property,
      List<QueryDocumentSnapshot> allProperties) {

    double totalWeight = 0;
    double weightedSum = 0;
    int comparableCount = 0;

    for (var doc in allProperties) {
      final data = doc.data() as Map<String, dynamic>;

      // Skip same property
      if (data['title'] == property['title']) continue;

      final price = (data['price'] as num).toDouble();
      final size = (data['size'] as num).toDouble();
      final condition = (data['condition'] as num).toDouble();

      final targetSize = (property['size'] as num).toDouble();
      final targetCondition = (property['condition'] as num).toDouble();

      double sizeScore = 1 - ((size - targetSize).abs() / targetSize);
      sizeScore = sizeScore.clamp(0, 1);

      double conditionScore = 1 - ((condition - targetCondition).abs() / 5);
      conditionScore = conditionScore.clamp(0, 1);

      double weight = (0.6 * sizeScore) + (0.4 * conditionScore);

      weightedSum += price * weight;
      totalWeight += weight;

      comparableCount++;
    }

    double estimated =
        totalWeight > 0 ? weightedSum / totalWeight : 0;

    String confidence;
    if (comparableCount > 5) {
      confidence = "High";
    } else if (comparableCount >= 3) {
      confidence = "Medium";
    } else {
      confidence = "Low";
    }

    return {
      'price': estimated.toStringAsFixed(0),
      'confidence': confidence,
      'count': comparableCount
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PropertyPulse"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 Search
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by title or location",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // 💰 Price Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                const Text("Max Price"),
                Slider(
                  min: 0,
                  max: 1000000,
                  divisions: 20,
                  value: maxPrice,
                  label: "\$${maxPrice.toInt()}",
                  onChanged: (value) {
                    setState(() {
                      maxPrice = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // 📦 Property List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No properties found"));
                }

                final allDocs = snapshot.data!.docs;

                final filtered = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final title = data['title'].toString().toLowerCase();
                  final location = data['location'].toString().toLowerCase();
                  final price = (data['price'] as num).toDouble();

                  return (title.contains(searchText) ||
                          location.contains(searchText)) &&
                      price <= maxPrice;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final estimate =
                        estimatePrice(data, allDocs);

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(data['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Price: \$${data['price']}"),
                            Text("Size: ${data['size']} sqft"),
                            Text("Location: ${data['location']}"),
                            Text("Condition: ${data['condition']}"),

                            // 🔥 Estimator Output
                            Text("Est. Price: \$${estimate['price']}"),
                            Text(
                                "Confidence: ${estimate['confidence']} (${estimate['count']} comps)"),

                            // 📅 Booking
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BookingScreen(propertyId: doc.id),
                                  ),
                                );
                              },
                              child: const Text("Book Viewing"),
                            ),
                          ],
                        ),

                        // 💬 Chat
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(propertyId: doc.id),
                            ),
                          );
                        },

                        // ❤️ Favorite
                        trailing: StreamBuilder<bool>(
                          stream: isFavorite(doc.id),
                          builder: (context, snapshot) {
                            final isFav = snapshot.data ?? false;

                            return IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isFav ? Colors.red : null,
                              ),
                              onPressed: () {
                                toggleFavorite(doc.id);
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ➕ Add Property
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPropertyScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
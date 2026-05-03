import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'favorites_screen.dart';
import 'property_detail_screen.dart';
import 'add_property_screen.dart';
import 'my_bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchText = "";
  double maxPrice = 1000000;

  final user = FirebaseAuth.instance.currentUser;

  // 🔥 FAVORITE TOGGLE
  Future<void> toggleFavorite(
      String propertyId, Map<String, dynamic> data) async {
    final ref = FirebaseFirestore.instance
        .collection('favorites')
        .doc('${user!.uid}_$propertyId');

    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': user!.uid,
        'propertyId': propertyId,
        'title': data['title'],
        'price': data['price'],
        'createdAt': Timestamp.now(),
      });
    }
  }

  // 🔥 CHECK FAVORITE
  Stream<bool> isFavorited(String propertyId) {
    return FirebaseFirestore.instance
        .collection('favorites')
        .doc('${user!.uid}_$propertyId')
        .snapshots()
        .map((doc) => doc.exists);
  }

  // 🔍 SEARCH FILTER
  bool matchesSearch(Map<String, dynamic> data) {
    final title = (data['title'] ?? "").toString().toLowerCase();
    final location = (data['location'] ?? "").toString().toLowerCase();

    return title.contains(searchText) || location.contains(searchText);
  }

  // 💰 PRICE FILTER
  bool matchesPrice(Map<String, dynamic> data) {
    final price = (data['price'] ?? 0).toDouble();
    return price <= maxPrice;
  }

  // 🧠 COMBINED FILTER
  bool shouldShow(Map<String, dynamic> data) {
    return matchesSearch(data) && matchesPrice(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PropertyPulse"),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MyBookingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by title or location",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => searchText = "");
                  },
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          // 💰 PRICE SLIDER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Text("Max Price: \$${maxPrice.toInt()}"),
                Slider(
                  min: 0,
                  max: 1000000,
                  divisions: 20,
                  value: maxPrice,
                  onChanged: (value) {
                    setState(() {
                      maxPrice = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // 📦 PROPERTY LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No properties found"));
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;
                  return shouldShow(data);
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final doc = docs[index];
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final propertyId = doc.id;

                    return Card(
                      elevation: 5,
                      margin: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.all(10),

                        leading:
                            const Icon(Icons.home, size: 32),

                        title: Text(
                          data['title'] ?? "No Title",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),

                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("💰 \$${data['price'] ?? 0}"),
                            Text("📏 ${data['size'] ?? 0} sqft"),
                            Text("📍 ${data['location'] ?? ""}"),
                            Text(
                                "🏠 Condition: ${data['condition'] ?? ""}"),
                          ],
                        ),

                        trailing: StreamBuilder<bool>(
                          stream: isFavorited(propertyId),
                          builder: (context, snapshot) {
                            final fav =
                                snapshot.data ?? false;

                            return IconButton(
                              icon: Icon(
                                fav
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: fav
                                    ? Colors.red
                                    : Colors.grey,
                              ),
                              onPressed: () => toggleFavorite(
                                  propertyId, data),
                            );
                          },
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailScreen(
                                propertyId: propertyId,
                                data: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ➕ ADD PROPERTY
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const AddPropertyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
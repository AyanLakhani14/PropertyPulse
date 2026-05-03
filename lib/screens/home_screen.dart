import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_property_screen.dart';
import 'property_detail_screen.dart';
import 'favorites_screen.dart';
import 'my_bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchText = "";
  double maxPrice = 1000000;

  // ❤️ TOGGLE FAVORITE
  void toggleFavorite(String propertyId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(propertyId);

    final doc = await ref.get();

    if (doc.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'savedAt': Timestamp.now(),
      });
    }
  }

  // ❤️ CHECK FAVORITE
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
                  builder: (_) => const FavoritesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyBookingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      body: Column(
        children: [

          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by title or location",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
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

          // 💰 PRICE FILTER
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

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No properties found"),
                  );
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final title =
                      (data['title'] ?? "").toString().toLowerCase();
                  final location =
                      (data['location'] ?? "").toString().toLowerCase();
                  final price =
                      (data['price'] ?? 0).toDouble();

                  return (title.contains(searchText) ||
                          location.contains(searchText)) &&
                      price <= maxPrice;
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {

                    final doc = filtered[index];
                    final data =
                        doc.data() as Map<String, dynamic>;

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

                        // ❌ IMAGE REMOVED
                        leading: const Icon(Icons.home),

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

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PropertyDetailScreen(
                                propertyId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },

                        trailing: StreamBuilder<bool>(
                          stream: isFavorite(doc.id),
                          builder: (context, snapshot) {
                            final fav =
                                snapshot.data ?? false;

                            return IconButton(
                              icon: Icon(
                                fav
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    fav ? Colors.red : null,
                              ),
                              onPressed: () =>
                                  toggleFavorite(doc.id),
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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddPropertyScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
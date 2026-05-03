import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_property_screen.dart';
import 'property_detail_screen.dart';
import 'my_bookings_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PropertyPulse"),
        actions: [
          // 📅 My Bookings
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

          // 🚪 Logout
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
          // 🔍 SEARCH BAR
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
                    setState(() {
                      searchText = "";
                    });
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
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No properties found"),
                  );
                }

                final filtered = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final title =
                      data['title'].toString().toLowerCase();
                  final location =
                      data['location'].toString().toLowerCase();
                  final price =
                      (data['price'] as num).toDouble();

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
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          data['title'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text("💰 \$${data['price']}"),
                            Text("📏 ${data['size']} sqft"),
                            Text("📍 ${data['location']}"),
                            Text("🏠 Condition: ${data['condition']}"),
                          ],
                        ),

                        // 👉 OPEN DETAILS SCREEN
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

                        // ❤️ FAVORITE BUTTON
                        trailing: StreamBuilder<bool>(
                          stream: isFavorite(doc.id),
                          builder: (context, snapshot) {
                            final isFav =
                                snapshot.data ?? false;

                            return IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color:
                                    isFav ? Colors.red : null,
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

      // ➕ ADD PROPERTY BUTTON
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
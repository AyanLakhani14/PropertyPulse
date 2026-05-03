import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {

          // 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading favorites"));
          }

          final favorites = snapshot.data?.docs ?? [];

          // 📭 Empty
          if (favorites.isEmpty) {
            return const Center(child: Text("No favorites yet"));
          }

          // 📋 List
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: favorites.length,
            itemBuilder: (context, index) {

              final doc = favorites[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),

                  // 🏠 Icon instead of image (fixes your crash)
                  leading: const Icon(Icons.home, size: 32),

                  // 📌 Property title
                  title: Text(
                    data['title'] ?? "Unknown Property",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  // 💰 Price
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text("\$${data['price'] ?? 0}"),
                  ),

                  // ❌ Remove from favorites
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('favorites')
                          .doc(doc.id)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Removed from favorites")),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
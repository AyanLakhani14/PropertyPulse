import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'property_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Favorites")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final favs = snapshot.data!.docs;

          if (favs.isEmpty) {
            return const Center(child: Text("No favorites yet"));
          }

          return ListView.builder(
            itemCount: favs.length,
            itemBuilder: (context, index) {
              final favDoc = favs[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('properties')
                    .doc(favDoc.id)
                    .get(),
                builder: (context, snapshot) {

                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }

                  final data =
                      snapshot.data!.data() as Map<String, dynamic>?;

                  if (data == null) return const SizedBox();

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: Image.network(
                        data['image'] ??
                            "https://via.placeholder.com/150",
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                      title: Text(data['title']),
                      subtitle: Text("\$${data['price']}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PropertyDetailScreen(
                              propertyId: favDoc.id,
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
          );
        },
      ),
    );
  }
}
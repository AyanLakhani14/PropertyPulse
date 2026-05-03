import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  String formatDate(DateTime date) {
    return "${date.month}/${date.day}/${date.year} "
        "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("My Bookings")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(), // 🔥 removed orderBy (safer)
        builder: (context, snapshot) {

          // 🔄 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ ERROR
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          // 📭 EMPTY
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No bookings yet"));
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {

              final doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;

              final date =
                  (data['timeSlot'] as Timestamp).toDate();

              final status = data['status'] ?? "confirmed";

              return Card(
                elevation: 5,
                margin: const EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(

                  leading: const Icon(Icons.home),

                  title: Text(
                    data['propertyTitle'] ?? "Unknown Property",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(formatDate(date)),

                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // 🔥 STATUS
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == "confirmed"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // ❌ CANCEL BUTTON
                      if (status == "confirmed")
                        TextButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(doc.id)
                                .update({'status': 'cancelled'});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Booking cancelled"),
                              ),
                            );
                          },
                          child: const Text("Cancel"),
                        ),
                    ],
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
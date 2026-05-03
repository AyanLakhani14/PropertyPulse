import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  final String propertyId;

  const BookingScreen({super.key, required this.propertyId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;

  void bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || selectedDate == null) return;

    final appointmentRef =
        FirebaseFirestore.instance.collection('appointments');

    // 🔥 Prevent double booking
    final existing = await appointmentRef
        .where('propertyId', isEqualTo: widget.propertyId)
        .where('timeSlot', isEqualTo: selectedDate)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time slot already booked")),
      );
      return;
    }

    await appointmentRef.add({
      'propertyId': widget.propertyId,
      'userId': user.uid,
      'timeSlot': selectedDate,
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking successful")),
    );

    Navigator.pop(context);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Viewing")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickDate,
              child: const Text("Select Date"),
            ),

            const SizedBox(height: 20),

            Text(
              selectedDate != null
                  ? selectedDate.toString()
                  : "No date selected",
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: bookAppointment,
              child: const Text("Confirm Booking"),
            )
          ],
        ),
      ),
    );
  }
}
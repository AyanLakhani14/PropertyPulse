import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const BookingScreen({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  // 📅 PICK DATE
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // ⏰ PICK TIME
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  // 🔥 BOOK APPOINTMENT
  Future<void> bookAppointment() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        selectedDate == null ||
        selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select date and time")),
      );
      return;
    }

    // Combine date + time
    final fullDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    final bookingsRef =
        FirebaseFirestore.instance.collection('bookings');

    // 🚫 Prevent double booking
    final existing = await bookingsRef
        .where('propertyId', isEqualTo: widget.propertyId)
        .where('timeSlot', isEqualTo: fullDateTime)
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time already booked")),
      );
      return;
    }

    // ✅ SAVE BOOKING
    await bookingsRef.add({
      'userId': user.uid,
      'propertyId': widget.propertyId,
      'propertyTitle': widget.propertyTitle, // 🔥 IMPORTANT
      'timeSlot': fullDateTime,
      'status': 'confirmed',
      'createdAt': Timestamp.now(),
    });

    // 🔔 SAVE NOTIFICATION (for FCM requirement)
    await FirebaseFirestore.instance
        .collection('notifications')
        .add({
      'userId': user.uid,
      'message':
          "Booking confirmed for ${widget.propertyTitle}",
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking confirmed")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Viewing")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // 📅 DATE
            ElevatedButton(
              onPressed: pickDate,
              child: const Text("Select Date"),
            ),

            Text(
              selectedDate != null
                  ? "${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}"
                  : "No date selected",
            ),

            const SizedBox(height: 10),

            // ⏰ TIME
            ElevatedButton(
              onPressed: pickTime,
              child: const Text("Select Time"),
            ),

            Text(
              selectedTime != null
                  ? selectedTime!.format(context)
                  : "No time selected",
            ),

            const SizedBox(height: 30),

            // ✅ CONFIRM
            ElevatedButton(
              onPressed: bookAppointment,
              child: const Text("Confirm Booking"),
            ),
          ],
        ),
      ),
    );
  }
}
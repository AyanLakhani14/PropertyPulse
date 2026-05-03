import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/property.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final sizeController = TextEditingController();
  final locationController = TextEditingController();

  int condition = 3;

  void addProperty() async {
    final property = Property(
      title: titleController.text,
      price: double.parse(priceController.text),
      size: double.parse(sizeController.text),
      location: locationController.text,
      condition: condition,
    );

    await FirebaseFirestore.instance
        .collection('properties')
        .add(property.toMap());

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Property")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price")),
            TextField(controller: sizeController, decoration: const InputDecoration(labelText: "Size")),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: "Location")),

            const SizedBox(height: 10),

            DropdownButton<int>(
              value: condition,
              items: List.generate(5, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text("Condition ${index + 1}"),
                );
              }),
              onChanged: (value) {
                setState(() {
                  condition = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: addProperty,
              child: const Text("Add Property"),
            )
          ],
        ),
      ),
    );
  }
}
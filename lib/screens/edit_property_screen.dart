import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditPropertyScreen extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> data;

  const EditPropertyScreen({
    super.key,
    required this.propertyId,
    required this.data,
  });

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  late TextEditingController titleController;
  late TextEditingController priceController;
  late TextEditingController sizeController;
  late TextEditingController locationController;
  late TextEditingController conditionController;

  @override
  void initState() {
    super.initState();

    titleController =
        TextEditingController(text: widget.data['title']?.toString() ?? "");

    priceController =
        TextEditingController(text: widget.data['price']?.toString() ?? "");

    sizeController =
        TextEditingController(text: widget.data['size']?.toString() ?? "");

    locationController =
        TextEditingController(text: widget.data['location']?.toString() ?? "");

    conditionController =
        TextEditingController(text: widget.data['condition']?.toString() ?? "");
  }

  Future<void> updateProperty() async {
    await FirebaseFirestore.instance
        .collection('properties')
        .doc(widget.propertyId)
        .update({
      'title': titleController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'size': double.tryParse(sizeController.text) ?? 0,
      'location': locationController.text,
      'condition': int.tryParse(conditionController.text) ?? 3,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Property updated")),
    );

    Navigator.pop(context);
  }

  Widget input(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    priceController.dispose();
    sizeController.dispose();
    locationController.dispose();
    conditionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Property")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            input("Title", titleController),
            input("Price", priceController,
                type: TextInputType.number),
            input("Size", sizeController,
                type: TextInputType.number),
            input("Location", locationController),
            input("Condition (1-5)", conditionController,
                type: TextInputType.number),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: updateProperty,
              child: const Text("Update Property"),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  final conditionController = TextEditingController();

  File? imageFile;

  // 📸 PICK IMAGE
  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

  // ☁️ UPLOAD TO FIREBASE STORAGE
  Future<String?> uploadImage() async {
    if (imageFile == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('property_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

    await ref.putFile(imageFile!);

    return await ref.getDownloadURL();
  }

  // ➕ ADD PROPERTY
  Future<void> addProperty() async {
    final cleanedPrice =
        priceController.text.replaceAll(RegExp(r'[^0-9.]'), '');

    final imageUrl = await uploadImage();

    await FirebaseFirestore.instance.collection('properties').add({
      'title': titleController.text,
      'price': cleanedPrice.isEmpty ? 0 : double.parse(cleanedPrice),
      'size': double.tryParse(sizeController.text) ?? 0,
      'location': locationController.text,
      'condition': int.tryParse(conditionController.text) ?? 3,
      'image': imageUrl, // 🔥 STORAGE URL
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Property Added")),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Property")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            input("Title", titleController),
            input("Price", priceController, type: TextInputType.number),
            input("Size", sizeController, type: TextInputType.number),
            input("Location", locationController),
            input("Condition (1-5)", conditionController,
                type: TextInputType.number),

            const SizedBox(height: 10),

            // 📸 IMAGE BUTTON
            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Upload Image"),
            ),

            if (imageFile != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(imageFile!, height: 120),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: addProperty,
              child: const Text("Add Property"),
            ),
          ],
        ),
      ),
    );
  }
}
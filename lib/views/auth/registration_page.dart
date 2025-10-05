import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/main_screen.dart';

class RegistrationPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const RegistrationPage({super.key, required this.cloudinaryService});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _courseController = TextEditingController();
  final _departmentController = TextEditingController();
  final _interestsController = TextEditingController();
  final _bioController = TextEditingController();

  File? _profileImage;
  bool _isLoading = false;
  String? _gender;
  String? _interestedIn;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null)
      setState(() => _profileImage = File(pickedFile.path));
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _gender == null ||
        _interestedIn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await widget.cloudinaryService
            .uploadImage(_profileImage!, folder: "profiles");
      }

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "age": int.tryParse(_ageController.text.trim()) ?? 0,
        "gender": _gender,
        "interestedIn": _interestedIn,
        "course": _courseController.text.trim(),
        "department": _departmentController.text.trim(),
        "interests": _interestsController.text
            .trim()
            .split(',')
            .map((e) => e.trim())
            .toList(),
        "bio": _bioController.text.trim(),
        "email": user.email,
        "profileImageUrl": imageUrl ?? "",
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              MainScreen(cloudinaryService: widget.cloudinaryService),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildGenderOption(String label, String value) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        child: Text(
          label[0],
          style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInterestedOption(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _interestedIn == value,
      onSelected: (_) => setState(() => _interestedIn = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Registration")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  TextField(
                      controller: _firstNameController,
                      decoration:
                          const InputDecoration(labelText: "First Name")),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _lastNameController,
                      decoration:
                          const InputDecoration(labelText: "Last Name")),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Age")),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGenderOption("Female", "Female"),
                _buildGenderOption("Male", "Male"),
                _buildGenderOption("Custom", "Custom"),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
                controller: _courseController,
                decoration: const InputDecoration(labelText: "Course")),
            const SizedBox(height: 10),
            TextField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: "Department")),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              children: [
                _buildInterestedOption("Female", "Female"),
                _buildInterestedOption("Male", "Male"),
                _buildInterestedOption("All", "All"),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
                controller: _interestsController,
                decoration: const InputDecoration(
                    labelText: "Interests/Hobbies (comma separated)")),
            const SizedBox(height: 10),
            TextField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: "Bio/About Me"),
                maxLines: 3),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text("Save Profile"),
                  ),
          ],
        ),
      ),
    );
  }
}

// registration_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/main_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final age = int.tryParse(_ageController.text.trim());
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        age == null ||
        _gender == null ||
        _interestedIn == null) {
      _showSnack("Please complete all required fields");
      return;
    }

    if (age < 18) {
      _showSnack("You must be 18 years old or older to register");
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
        "age": age,
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
      _showSnack("Error saving profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildOptionButton(String label, String value, bool isForInterested) {
    final isSelected =
        isForInterested ? _interestedIn == value : _gender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isForInterested) {
            _interestedIn = value;
          } else {
            _gender = value;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0A0A), Color(0xFFFF3D6A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                "Complete Your Profile",
                style: GoogleFonts.readexPro(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt,
                          size: 40, color: Colors.white70)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTextField(_firstNameController, "First Name"),
                    const SizedBox(height: 10),
                    _buildTextField(_lastNameController, "Last Name"),
                    const SizedBox(height: 10),
                    _buildTextField(_ageController, "Age (18+)",
                        keyboardType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Gender Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Gender: ${_gender ?? 'Not selected'}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildOptionButton("Female", "Female", false),
                      _buildOptionButton("Male", "Male", false),
                      _buildOptionButton("Custom", "Custom", false),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Course and Department
              _buildTextField(_courseController, "Course"),
              const SizedBox(height: 10),
              _buildTextField(_departmentController, "Department"),
              const SizedBox(height: 20),

              // Interested In Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Interested In: ${_interestedIn ?? 'Not selected'}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildOptionButton("Female", "Female", true),
                      _buildOptionButton("Male", "Male", true),
                      _buildOptionButton("All", "All", true),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildTextField(
                  _interestsController, "Interests/Hobbies (comma separated)"),
              const SizedBox(height: 10),
              _buildTextField(_bioController, "Bio/About Me", maxLines: 3),
              const SizedBox(height: 30),

              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pinkAccent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40)),
                        ),
                        child: Text(
                          "Save Profile",
                          style: GoogleFonts.readexPro(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

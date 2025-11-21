// registration_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
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
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _interestsController = TextEditingController();
  final _bioController = TextEditingController();

  // Dropdowns
  String? _selectedDepartment;
  String? _selectedCourse;

  // File & options
  File? _profileImage;
  String? _gender;
  String? _interestedIn;
  bool _isLoading = false;

  // Department → Courses mapping
  final Map<String, List<String>> departmentCourses = {
    "CBE": ["BSBA", "BSEntrep"],
    "CCS": ["BSIT", "ACT"],
    "CTE": ["BEED", "BSED"],
  };

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final age = int.tryParse(_ageController.text.trim());
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        age == null ||
        _gender == null ||
        _interestedIn == null ||
        _selectedDepartment == null ||
        _selectedCourse == null) {
      _showSnack("Please complete all required fields");
      return;
    }
    if (age < 18) {
      _showSnack("You must be at least 18 to register");
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_profileImage != null) {
        imageUrl = await widget.cloudinaryService.uploadImage(
          _profileImage!,
          folder: "profiles",
        );
      }

      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "age": age,
        "gender": _gender,
        "interestedIn": _interestedIn,
        "department": _selectedDepartment,
        "course": _selectedCourse,
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _optionButton(String label, String value, bool isInterest) {
    final isSelected = isInterest ? _interestedIn == value : _gender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isInterest)
            _interestedIn = value;
          else
            _gender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.pinkAccent : Colors.white.withOpacity(0.18),
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

  Widget _textField(TextEditingController controller, String label,
      {TextInputType inputType = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _dropdownContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: child,
    );
  }

  Widget _departmentDropdown() {
    return _dropdownContainer(
      DropdownButtonFormField<String>(
        value: _selectedDepartment,
        items: departmentCourses.keys
            .map((dept) => DropdownMenuItem(
                  value: dept,
                  child:
                      Text(dept, style: const TextStyle(color: Colors.black)),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedDepartment = value;
            _selectedCourse = null;
          });
        },
        decoration: const InputDecoration(
          labelText: "Department",
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.black),
        dropdownColor: Colors.white,
        isExpanded: true,
      ),
    );
  }

  Widget _courseDropdown() {
    List<String> courses = _selectedDepartment != null
        ? departmentCourses[_selectedDepartment!]!
        : [];

    return _dropdownContainer(
      DropdownButtonFormField<String>(
        value: courses.contains(_selectedCourse) ? _selectedCourse : null,
        items: courses
            .map((course) => DropdownMenuItem(
                  value: course,
                  child:
                      Text(course, style: const TextStyle(color: Colors.black)),
                ))
            .toList(),
        onChanged: (value) => setState(() => _selectedCourse = value),
        decoration: const InputDecoration(
          labelText: "Course",
          labelStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        style: const TextStyle(color: Colors.black),
        dropdownColor: Colors.white,
        isExpanded: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
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
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt,
                          color: Colors.white70, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 25),

              // Basic Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _textField(_firstNameController, "First Name"),
                    const SizedBox(height: 10),
                    _textField(_lastNameController, "Last Name"),
                    const SizedBox(height: 10),
                    _textField(_ageController, "Age (18+)",
                        inputType: TextInputType.number),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Gender
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Gender: ${_gender ?? 'Not selected'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _optionButton("Female", "Female", false),
                  _optionButton("Male", "Male", false),
                  _optionButton("Custom", "Custom", false),
                ],
              ),
              const SizedBox(height: 25),

              // Department & Course Dropdown
              _departmentDropdown(),
              const SizedBox(height: 10),
              _courseDropdown(),
              const SizedBox(height: 25),

              // Interested In
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Interested In: ${_interestedIn ?? 'Not selected'}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _optionButton("Female", "Female", true),
                  _optionButton("Male", "Male", true),
                  _optionButton("All", "All", true),
                ],
              ),
              const SizedBox(height: 25),

              _textField(_interestsController,
                  "Interests / Hobbies (comma separated)"),
              const SizedBox(height: 10),
              _textField(_bioController, "Bio / About Me", maxLines: 3),
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
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        child: Text(
                          "Save Profile",
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

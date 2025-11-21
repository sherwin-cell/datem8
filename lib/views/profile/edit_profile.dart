import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfilePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;
  final String userId;

  const EditProfilePage({
    super.key,
    required this.cloudinaryService,
    required this.userId,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  String? _firstName;
  String? _lastName;
  String? _bio;
  int? _age;
  String? _course;
  String? _department;
  String? _gender;
  String? _interestedIn;
  List<String> _interests = [];
  String? _profilePicUrl;
  File? _newProfilePic;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!mounted || !doc.exists) return;
      final data = doc.data()!;

      setState(() {
        _firstName = data['firstName'] ?? '';
        _lastName = data['lastName'] ?? '';
        _bio = data['bio'] ?? '';
        _age = data['age'];
        _course = data['course'] ?? '';
        _department = data['department'] ?? '';
        _gender = data['gender'];
        _interestedIn = data['interestedIn'];
        _interests = List<String>.from(data['interests'] ?? []);
        _profilePicUrl = data['profilePic'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to load profile: $e")));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newProfilePic = File(picked.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      String? profilePicUrl = _profilePicUrl;
      if (_newProfilePic != null) {
        profilePicUrl =
            await widget.cloudinaryService.uploadImage(_newProfilePic!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'firstName': _firstName,
        'lastName': _lastName,
        'bio': _bio,
        'age': _age,
        'course': _course,
        'department': _department,
        'gender': _gender,
        'interestedIn': _interestedIn,
        'interests': _interests,
        'profilePic': profilePicUrl,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  Widget _inputField({
    required String label,
    String? value,
    TextInputType type = TextInputType.text,
    void Function(String?)? onSaved,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.readexPro(
                fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          keyboardType: type,
          maxLines: maxLines,
          validator: validator,
          onSaved: onSaved,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade200,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _newProfilePic != null
                            ? FileImage(_newProfilePic!)
                            : (_profilePicUrl != null &&
                                    _profilePicUrl!.isNotEmpty
                                ? NetworkImage(_profilePicUrl!)
                                : null) as ImageProvider?,
                        child: (_newProfilePic == null &&
                                (_profilePicUrl == null ||
                                    _profilePicUrl!.isEmpty))
                            ? const Icon(Icons.camera_alt,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: InkWell(
                          onTap: _pickProfileImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.edit,
                                size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _inputField(
                        label: "First Name",
                        value: _firstName,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                        onSaved: (v) => _firstName = v,
                      ),
                      _inputField(
                        label: "Last Name",
                        value: _lastName,
                        validator: (v) =>
                            v == null || v.isEmpty ? "Required" : null,
                        onSaved: (v) => _lastName = v,
                      ),
                      _inputField(
                        label: "Age",
                        value: _age?.toString(),
                        type: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          final n = int.tryParse(v);
                          if (n == null || n <= 0) return "Enter valid age";
                          return null;
                        },
                        onSaved: (v) => _age = int.parse(v!),
                      ),
                      _inputField(
                        label: "Course",
                        value: _course,
                        onSaved: (v) => _course = v,
                      ),
                      _inputField(
                        label: "Department",
                        value: _department,
                        onSaved: (v) => _department = v,
                      ),
                      _inputField(
                        label: "Bio",
                        value: _bio,
                        maxLines: 3,
                        onSaved: (v) => _bio = v,
                      ),
                      _inputField(
                        label: "Interests (comma separated)",
                        value: _interests.join(", "),
                        onSaved: (v) {
                          _interests = v != null && v.isNotEmpty
                              ? v.split(",").map((e) => e.trim()).toList()
                              : [];
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            "Save Changes",
                            style: GoogleFonts.readexPro(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:datem8/services/cloudinary_service.dart';

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
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (!mounted || !doc.exists) return;

    final data = doc.data()!;
    setState(() {
      _firstName = data['firstName'];
      _lastName = data['lastName'];
      _bio = data['bio'];
      _age = data['age'];
      _course = data['course'];
      _department = data['department'];
      _gender = data['gender'];
      _interestedIn = data['interestedIn'];
      _interests = List<String>.from(data['interests'] ?? []);
      _profilePicUrl = data['profilePic'] ?? data['profileImageUrl'];
      _isLoading = false;
    });
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _newProfilePic = File(pickedFile.path));
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
      Navigator.pop(context, true); // indicate successful update
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _newProfilePic != null
                            ? FileImage(_newProfilePic!)
                            : (_profilePicUrl != null &&
                                    _profilePicUrl!.isNotEmpty
                                ? NetworkImage(_profilePicUrl!)
                                : null) as ImageProvider<Object>?,
                        child: (_newProfilePic == null &&
                                (_profilePicUrl == null ||
                                    _profilePicUrl!.isEmpty))
                            ? const Icon(Icons.person, size: 50)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: _firstName,
                      decoration:
                          const InputDecoration(labelText: "First Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _firstName = v,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _lastName,
                      decoration: const InputDecoration(labelText: "Last Name"),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => _lastName = v,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _age?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Age"),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Enter valid age';
                        return null;
                      },
                      onSaved: (v) => _age = int.parse(v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _course,
                      decoration: const InputDecoration(labelText: "Course"),
                      onSaved: (v) => _course = v,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _department,
                      decoration:
                          const InputDecoration(labelText: "Department"),
                      onSaved: (v) => _department = v,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: "Gender"),
                      items: ['Male', 'Female', 'Other']
                          .map(
                              (g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _interestedIn,
                      decoration:
                          const InputDecoration(labelText: "Interested In"),
                      items: ['Male', 'Female', 'Other']
                          .map(
                              (i) => DropdownMenuItem(value: i, child: Text(i)))
                          .toList(),
                      onChanged: (v) => setState(() => _interestedIn = v),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _bio,
                      decoration: const InputDecoration(labelText: "Bio"),
                      maxLines: 3,
                      onSaved: (v) => _bio = v,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _interests.join(', '),
                      decoration: const InputDecoration(
                        labelText: "Interests (comma separated)",
                      ),
                      onSaved: (v) {
                        if (v != null && v.isNotEmpty) {
                          _interests =
                              v.split(',').map((e) => e.trim()).toList();
                        } else {
                          _interests = [];
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

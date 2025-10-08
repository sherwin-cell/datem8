import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/setting_widget.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const ProfilePage({super.key, required this.cloudinaryService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = '';
  String _bio = '';
  int _age = 0;
  String _profilePic = '';
  String _course = '';
  String _department = '';
  String _gender = '';
  String _interestedIn = '';
  DateTime? _createdAt;
  List<String> _interests = [];
  bool _isLoading = true;

  final currentUser = FirebaseAuth.instance.currentUser;
  final List<File?> _extraImages = [null, null, null];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (currentUser == null) return;
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!mounted || !doc.exists) return;
      final data = doc.data()!;

      final firstName = (data['firstName'] ?? '').toString();
      final lastName = (data['lastName'] ?? '').toString();
      final nameField = (data['name'] ?? '').toString();
      _fullName = nameField.isNotEmpty ? nameField : '$firstName $lastName';

      _bio = data['bio'] ?? '';
      _age = data['age'] ?? 0;
      _profilePic = data['profilePic'] ?? '';
      _course = data['course'] ?? '';
      _department = data['department'] ?? '';
      _gender = data['gender'] ?? '';
      _interestedIn = data['interestedIn'] ?? '';
      _createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      _interests = [];
      if (data['interests'] != null && data['interests'] is List) {
        _interests = (data['interests'] as List<dynamic>)
            .map((e) => e.toString())
            .toList();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickExtraImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() => _extraImages[index] = File(pickedFile.path));
  }

  Widget _buildProfileImage() {
    final hasImage = _profilePic.isNotEmpty;
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[300],
          child: hasImage
              ? ClipOval(
                  child: Image.network(
                    _profilePic,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.person, size: 50),
                  ),
                )
              : const Icon(Icons.person, size: 50),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
              onPressed: () async {
                if (currentUser == null) return;
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(
                      cloudinaryService: widget.cloudinaryService,
                      userId: currentUser!.uid,
                    ),
                  ),
                );
                if (updated == true) _loadProfile();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(_fullName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        if (_age > 0)
          Text("Age: $_age",
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        if (_gender.isNotEmpty)
          Text("Gender: $_gender",
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        if (_interestedIn.isNotEmpty)
          Text("Interested in: $_interestedIn",
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        if (_course.isNotEmpty && _department.isNotEmpty)
          Text("$_course - $_department",
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        if (_createdAt != null)
          Text("Joined: ${_createdAt!.toLocal().toString().split(' ')[0]}",
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        if (_bio.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(_bio,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
          ),
        if (_interests.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _interests.map((e) => Chip(label: Text(e))).toList(),
          ),
      ],
    );
  }

  Widget _buildExtraPhotos() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (index) {
        final imageFile = _extraImages[index];
        return GestureDetector(
          onTap: () => _pickExtraImage(index),
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
              image: imageFile != null
                  ? DecorationImage(
                      image: FileImage(imageFile), fit: BoxFit.cover)
                  : null,
            ),
            child: imageFile == null
                ? const Icon(Icons.add_a_photo, color: Colors.grey)
                : null,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          // Pass required parameters to SettingsIconButton
          SettingsIconButton(
            cloudinaryService: widget.cloudinaryService,
            userId: currentUser!.uid,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileImage(),
                    const SizedBox(height: 16),
                    _buildProfileDetails(),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                    _buildExtraPhotos(),
                  ],
                ),
              ),
            ),
    );
  }
}

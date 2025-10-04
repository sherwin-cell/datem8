import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/setting_widget.dart';

class ProfilePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;
  const ProfilePage({super.key, required this.cloudinaryService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _firstName;
  String? _lastName;
  String? _bio;
  int? _age;
  String? _profilePicUrl;
  bool _isLoading = true;

  final currentUser = FirebaseAuth.instance.currentUser;
  final List<File?> _extraImages = [null, null, null]; // 3 slots for photos

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (!mounted || !doc.exists) return;

    final data = doc.data()!;
    setState(() {
      _firstName = data['firstName'] ?? '';
      _lastName = data['lastName'] ?? '';
      _bio = data['bio'] ?? '';
      _age = data['age'] ?? 0;
      _profilePicUrl = data['profilePic'];
      _isLoading = false;
    });
  }

  Future<void> _pickExtraImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _extraImages[index] = File(pickedFile.path);
    });
  }

  Widget _buildProfileImage() {
    final imageProvider = _profilePicUrl != null && _profilePicUrl!.isNotEmpty
        ? NetworkImage(_profilePicUrl!)
        : null;

    return Stack(
      children: [
        CircleAvatar(
          radius: 40, // smaller size
          backgroundImage: imageProvider,
          child:
              imageProvider == null ? const Icon(Icons.person, size: 40) : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 14,
            backgroundColor: Colors.blue,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.edit, size: 14, color: Colors.white),
              onPressed: () {
                // TODO: Add navigation to Edit Profile page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Edit profile coming soon")),
                );
              },
            ),
          ),
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
                      image: FileImage(imageFile),
                      fit: BoxFit.cover,
                    )
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
        actions: const [
          SettingsIconButton(),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 16),
                  Text(
                    "${_firstName ?? ''} ${_lastName ?? ''}".trim(),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _age != null && _age! > 0 ? "Age: $_age" : "",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _bio ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  _buildExtraPhotos(), // 3 photo upload boxes
                ],
              ),
            ),
    );
  }
}

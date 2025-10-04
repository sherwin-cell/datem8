import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:datem8/services/cloudinary_service.dart';

class NewPostPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const NewPostPage({super.key, required this.cloudinaryService});

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage> {
  File? _image;
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return; // Prevent using context if disposed
      if (pickedFile != null) {
        setState(() => _image = File(pickedFile.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  Future<void> _submitPost() async {
    if (_image == null && _captionController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add an image or caption")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = '';

      if (_image != null) {
        final uploadedUrl = await widget.cloudinaryService.uploadImage(
          _image!,
          folder: 'posts',
        );
        imageUrl = uploadedUrl ?? '';
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('posts').add({
          'userId': user.uid,
          'caption': _captionController.text.trim(),
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to post: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Post")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _image != null
                    ? Image.file(_image!, height: 200, fit: BoxFit.cover)
                    : Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.add_a_photo,
                              size: 50, color: Colors.black54),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Caption',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitPost,
                        child: const Text("Post"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

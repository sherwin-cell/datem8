import 'dart:async';
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
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<File> _images = [];

  final List<String> _prompts = [
    "What's on your mind?",
    "Share your thoughts...",
    "Say something fun...",
    "Write something inspiring..."
  ];
  int _currentPromptIndex = 0;
  String _currentPrompt = "What's on your mind?";
  Timer? _placeholderTimer;

  @override
  void initState() {
    super.initState();
    _placeholderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_captionController.text.isEmpty) {
        setState(() {
          _currentPromptIndex = (_currentPromptIndex + 1) % _prompts.length;
          _currentPrompt = _prompts[_currentPromptIndex];
        });
      }
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _placeholderTimer?.cancel();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImagesFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (!mounted || pickedFiles.isEmpty) return;
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking images: $e")),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted || pickedFile == null) return;
      setState(() {
        _images.add(File(pickedFile.path));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error taking photo: $e")),
      );
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Discard Post?"),
        content: const Text("Are you sure you want to discard this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (discard == true) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitPost() async {
    if (_images.isEmpty && _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add an image or caption")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final profilePic = userDoc.data()?['profilePic'] ?? '';
      final name = userDoc.data()?['name'] ?? 'Unknown';

      List<String> imageUrls = [];
      for (var image in _images) {
        final uploadedUrl =
            await widget.cloudinaryService.uploadImage(image, folder: 'posts');
        if (uploadedUrl != null) imageUrls.add(uploadedUrl);
      }

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'name': name,
        'profilePic': profilePic,
        'caption': _captionController.text.trim(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to post: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    if (_images.isEmpty) {
      return GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
            ],
          ),
          child: const Center(
            child: Icon(Icons.add_a_photo, size: 50, color: Colors.black45),
          ),
        ),
      );
    }

    return Column(
      children: _images.map((image) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              image,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async {
          await _confirmDiscard();
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("New Post"),
            elevation: 1,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            actions: [
              TextButton(
                onPressed: _confirmDiscard,
                child: const Text(
                  "Discard",
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Only caption input now
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLines: null,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: _currentPrompt,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildImagePreview(),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitPost,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              backgroundColor:
                                  const Color.fromARGB(255, 165, 172, 193),
                              elevation: 2,
                            ),
                            child: const Text(
                              "Post",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

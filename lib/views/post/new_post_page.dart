// new_post_page.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:google_fonts/google_fonts.dart';

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
    _startPlaceholderTimer();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _placeholderTimer?.cancel();
    super.dispose();
  }

  void _startPlaceholderTimer() {
    _placeholderTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_captionController.text.isEmpty) {
        setState(() {
          _currentPromptIndex = (_currentPromptIndex + 1) % _prompts.length;
          _currentPrompt = _prompts[_currentPromptIndex];
        });
      }
    });
  }

  Future<void> _showImageSourceDialog() async {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            _buildImageSourceTile(
              icon: Icons.photo_library,
              label: "Gallery",
              onTap: _pickImagesFromGallery,
            ),
            _buildImageSourceTile(
              icon: Icons.camera_alt,
              label: "Camera",
              onTap: _pickImageFromCamera,
            ),
          ],
        ),
      ),
    );
  }

  ListTile _buildImageSourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(label, style: theme.textTheme.bodyMedium),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
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
      _showSnack("Error picking images: $e");
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted || pickedFile == null) return;

      setState(() => _images.add(File(pickedFile.path)));
    } catch (e) {
      _showSnack("Error taking photo: $e");
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDiscard() async {
    final theme = Theme.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.background,
        title: Text("Discard Post?", style: theme.textTheme.titleMedium),
        content: Text(
          "Are you sure you want to discard this post?",
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("No", style: const TextStyle(color: Colors.pinkAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (discard == true && mounted) Navigator.of(context).pop();
  }

  Future<void> _submitPost() async {
    if (_images.isEmpty && _captionController.text.trim().isEmpty) {
      _showSnack("Please add an image or caption");
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
      final userData = userDoc.data() ?? {};
      final profilePic = userData['profilePic'] ?? '';
      final name = userData['name'] ?? 'Unknown';

      // Upload images to Cloudinary
      List<String> imageUrls = [];
      for (var image in _images) {
        final url =
            await widget.cloudinaryService.uploadImage(image, folder: 'posts');
        if (url != null) imageUrls.add(url);
      }

      // Create post
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'name': name,
        'profilePic': profilePic,
        'caption': _captionController.text.trim(),
        'imageUrls': imageUrls,
        'createdAt': FieldValue.serverTimestamp(),
        'reactions': {},
      });

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showSnack("Failed to post: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildImagePreview() {
    final theme = Theme.of(context);

    if (_images.isEmpty) {
      return GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            color: theme.colorScheme.onBackground.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Icon(
              Icons.add_a_photo,
              size: 50,
              color: theme.colorScheme.onBackground.withOpacity(0.5),
            ),
          ),
        ),
      );
    }

    return Column(
      children: _images
          .map((image) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    image,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                  ),
                ),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async {
          await _confirmDiscard();
          return false;
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.background,
          appBar: AppBar(
            title: Text("New Post",
                style: GoogleFonts.readexPro(
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: theme.colorScheme.onBackground,
            actions: [
              TextButton(
                onPressed: _confirmDiscard,
                child:
                    const Text("Discard", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Caption input
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onBackground.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      controller: _captionController,
                      maxLines: null,
                      style: GoogleFonts.readexPro(
                          color: theme.colorScheme.onBackground, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: _currentPrompt,
                        hintStyle: GoogleFonts.readexPro(
                            color: theme.hintColor, fontSize: 16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image preview
                  _buildImagePreview(),
                  const SizedBox(height: 24),

                  // Post button
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color.fromARGB(255, 18, 16, 17)))
                      : SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitPost,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40)),
                              backgroundColor:
                                  const Color.fromARGB(255, 225, 217, 223),
                              elevation: 2,
                            ),
                            child: Text("Post",
                                style: GoogleFonts.readexPro(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
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

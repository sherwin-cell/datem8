import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/setting_widget.dart';
import 'edit_profile.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const ProfilePage({super.key, required this.cloudinaryService});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!doc.exists) return setState(() => _isLoading = false);

      final data = doc.data()!;
      final firstName = (data['firstName'] ?? '').toString();
      final lastName = (data['lastName'] ?? '').toString();
      final nameField = (data['name'] ?? '').toString();

      setState(() {
        _fullName = nameField.isNotEmpty ? nameField : '$firstName $lastName';
        _bio = data['bio'] ?? '';
        _age = data['age'] ?? 0;
        _profilePic = data['profilePic'] ?? '';
        _course = data['course'] ?? '';
        _department = data['department'] ?? '';
        _gender = data['gender'] ?? '';
        _interestedIn = data['interestedIn'] ?? '';
        _createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        _interests = (data['interests'] is List)
            ? List<String>.from(data['interests'])
            : [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------- PROFILE HEADER ----------------
  Widget _buildProfileHeader() {
    final hasImage = _profilePic.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: hasImage
                      ? Image.network(
                          _profilePic,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
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
          ),
          const SizedBox(height: 12),
          Text(
            _fullName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (_age > 0)
            Text("Age: $_age",
                style: const TextStyle(color: Colors.white70, fontSize: 15)),
          if (_course.isNotEmpty)
            Text("$_course • $_department",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  // ---------------- INFO SECTIONS ----------------
  Widget _buildInfoCard(IconData icon, String label) => Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
        ],
      );

  Widget _buildProfileDetails() {
    final items = [
      if (_gender.isNotEmpty) _buildInfoCard(Icons.wc, "Gender: $_gender"),
      if (_interestedIn.isNotEmpty)
        _buildInfoCard(Icons.favorite, "Interested in: $_interestedIn"),
      if (_createdAt != null)
        _buildInfoCard(Icons.calendar_today,
            "Joined: ${_createdAt!.toLocal().toString().split(' ')[0]}"),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: items),
      ),
    );
  }

  Widget _buildBioSection() => _bio.isEmpty
      ? const SizedBox.shrink()
      : Card(
          margin: const EdgeInsets.symmetric(vertical: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("About Me",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_bio, style: const TextStyle(fontSize: 16, height: 1.4)),
              ],
            ),
          ),
        );

  Widget _buildInterests() => _interests.isEmpty
      ? const SizedBox.shrink()
      : Card(
          margin: const EdgeInsets.symmetric(vertical: 12),
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Interests",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children:
                      _interests.map((e) => Chip(label: Text(e))).toList(),
                ),
              ],
            ),
          ),
        );

  // ---------------- USER POSTS ----------------
  Widget _buildUserPosts() {
    if (currentUser == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: Text("You haven’t posted anything yet.")),
          );
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;
            final caption = data['caption'] ?? '';
            final createdAt =
                (data['createdAt'] ?? data['timestamp']) is Timestamp
                    ? ((data['createdAt'] ?? data['timestamp']) as Timestamp)
                        .toDate()
                    : null;

            final imageUrls = (data['imageUrls'] is List)
                ? List<String>.from(data['imageUrls'])
                : (data['imageUrl'] != null
                    ? [data['imageUrl'].toString()]
                    : <String>[]);

            return _buildSwipeablePost(imageUrls, caption, createdAt);
          },
        );
      },
    );
  }

  // ---------------- SWIPEABLE POST ----------------
  Widget _buildSwipeablePost(
      List<String> imageUrls, String caption, DateTime? createdAt) {
    final pageController = PageController();
    final currentIndex = ValueNotifier<int>(0);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: imageUrls.length,
                      onPageChanged: (index) => currentIndex.value = index,
                      itemBuilder: (context, index) => Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) =>
                            progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                  // ✅ Simple clean dots
                  if (imageUrls.length > 1)
                    Positioned(
                      bottom: 10,
                      child: ValueListenableBuilder<int>(
                        valueListenable: currentIndex,
                        builder: (context, value, _) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            imageUrls.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: value == i ? 20 : 8,
                              decoration: BoxDecoration(
                                color: value == i
                                    ? Colors.deepPurple
                                    : Colors.grey[400],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption.isNotEmpty)
                  Text(caption,
                      style: const TextStyle(fontSize: 15, height: 1.4)),
                if (createdAt != null)
                  Text(
                    DateFormat.yMMMd().add_jm().format(createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- MAIN BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        actions: [
          if (currentUser != null)
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
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildProfileHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildProfileDetails(),
                        _buildBioSection(),
                        _buildInterests(),
                        const SizedBox(height: 12),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "My Posts",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildUserPosts(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

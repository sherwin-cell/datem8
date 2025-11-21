import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/darkmode.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final CloudinaryService cloudinaryService;
  final String? avatarUrl;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.cloudinaryService,
    this.avatarUrl,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String _profilePic = '';

  @override
  void initState() {
    super.initState();
    _profilePic = widget.avatarUrl ?? '';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;
      setState(() {
        _userData = data;
        _profilePic =
            _profilePic.isNotEmpty ? _profilePic : data['profilePic'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: DarkModeController.themeModeNotifier,
      builder: (context, themeMode, _) {
        final isDark = themeMode == ThemeMode.dark;
        final backgroundColor = isDark ? Colors.black : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black;
        final subTextColor = isDark ? Colors.white70 : Colors.black54;
        final containerColor =
            isDark ? Colors.grey.shade900 : Colors.grey.withOpacity(0.1);
        final iconColor = isDark ? Colors.white : Colors.black;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(widget.userName,
                style: GoogleFonts.readexPro(color: textColor)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: iconColor),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildProfileHeader(
                          containerColor, textColor, subTextColor, iconColor),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildInfoContainer(containerColor, textColor,
                                subTextColor, iconColor),
                            const SizedBox(height: 30),
                            Text("My Posts",
                                style: GoogleFonts.readexPro(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor)),
                            const SizedBox(height: 10),
                            _buildUserPosts(
                                containerColor, textColor, subTextColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Color containerColor, Color textColor,
      Color subTextColor, Color iconColor) {
    final fullName =
        "${_userData['firstName'] ?? ''} ${_userData['lastName'] ?? ''}";
    final age = _userData['age'] ?? 0;
    final course = _userData['course'] ?? '';
    final department = _userData['department'] ?? '';

    return Container(
      padding: const EdgeInsets.only(top: 140, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 70,
            backgroundColor: Colors.grey.withOpacity(0.3),
            backgroundImage:
                _profilePic.isNotEmpty ? NetworkImage(_profilePic) : null,
            child: _profilePic.isEmpty
                ? Icon(Icons.person,
                    size: 70, color: iconColor.withOpacity(0.6))
                : null,
          ),
          const SizedBox(height: 16),
          Text(fullName,
              style: GoogleFonts.readexPro(
                  color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          if (age > 0)
            Text("Age: $age",
                style:
                    GoogleFonts.readexPro(color: subTextColor, fontSize: 12)),
          if (course.isNotEmpty)
            Text("$course • $department",
                style:
                    GoogleFonts.readexPro(color: subTextColor, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoContainer(Color containerColor, Color textColor,
      Color subTextColor, Color iconColor) {
    final gender = _userData['gender'] ?? '';
    final interestedIn = _userData['interestedIn'] ?? '';
    final createdAt = (_userData['createdAt'] as Timestamp?)?.toDate();
    final bio = _userData['bio'] ?? '';
    final interests = List<String>.from(_userData['interests'] ?? []);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: containerColor, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gender.isNotEmpty)
            _infoItem(Icons.wc, "Gender: $gender", subTextColor, iconColor,
                small: true),
          if (interestedIn.isNotEmpty)
            _infoItem(Icons.favorite, "Interested in: $interestedIn",
                subTextColor, iconColor,
                small: true),
          if (createdAt != null)
            _infoItem(
                Icons.calendar_today,
                "Joined: ${DateFormat.yMMMd().format(createdAt)}",
                subTextColor,
                iconColor,
                small: true),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text("About Me",
                style: GoogleFonts.readexPro(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(bio,
                style:
                    GoogleFonts.readexPro(color: subTextColor, fontSize: 12)),
          ],
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Hobbies & Interests",
                style: GoogleFonts.readexPro(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(interests.join(', '),
                style:
                    GoogleFonts.readexPro(color: subTextColor, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text, Color textColor, Color iconColor,
      {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: small ? 14 : 18),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: GoogleFonts.readexPro(
                      color: textColor,
                      fontSize: small ? 12 : 14,
                      fontWeight: small ? FontWeight.w400 : FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildUserPosts(
      Color containerColor, Color textColor, Color subTextColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final posts = snapshot.data!.docs;
        if (posts.isEmpty)
          return Padding(
              padding: const EdgeInsets.all(20),
              child:
                  Text("No posts yet.", style: TextStyle(color: subTextColor)));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final caption = post['caption'] ?? '';
            final createdAt = (post['createdAt'] as Timestamp?)?.toDate();
            final imageUrls = <String>[];
            if (post.containsKey('imageUrls'))
              imageUrls.addAll(List<String>.from(post['imageUrls']));
            else if (post.containsKey('imageUrl'))
              imageUrls.add(post['imageUrl']);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrls.isNotEmpty) _buildPostImages(imageUrls),
                    if (caption.isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(caption,
                              style:
                                  TextStyle(color: textColor, fontSize: 14))),
                    if (createdAt != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                              DateFormat.yMMMd().add_jm().format(createdAt),
                              style: TextStyle(
                                  color: subTextColor, fontSize: 12))),
                  ]),
            );
          },
        );
      },
    );
  }

  Widget _buildPostImages(List<String> images) {
    if (images.length == 1) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(images[0],
              fit: BoxFit.cover, width: double.infinity, height: 250));
    }
    return _PostPageView(images: images);
  }
}

class _PostPageView extends StatefulWidget {
  final List<String> images;
  const _PostPageView({required this.images});

  @override
  State<_PostPageView> createState() => _PostPageViewState();
}

class _PostPageViewState extends State<_PostPageView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(widget.images[index],
                  fit: BoxFit.cover, width: double.infinity),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.images.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentIndex == index ? 12 : 8,
              height: _currentIndex == index ? 12 : 8,
              decoration: BoxDecoration(
                color: _currentIndex == index ? Colors.black : Colors.black26,
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

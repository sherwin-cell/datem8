import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'edit_profile.dart';
import 'package:datem8/widgets/setting_widget.dart';

class ProfilePage extends StatelessWidget {
  final CloudinaryService cloudinaryService;

  const ProfilePage({super.key, required this.cloudinaryService});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.white, // Optional: background white
      appBar: AppBar(
        title: Text(
          "Profile",
          style: GoogleFonts.readexPro(
              fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          SettingsIconButton(
            cloudinaryService: cloudinaryService,
            userId: currentUser.uid,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final profilePic = (data['profilePic'] ?? '').toString().trim();
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final bio = data['bio'] ?? '';
          final age = data['age'] ?? 0;
          final course = data['course'] ?? '';
          final department = data['department'] ?? '';
          final gender = data['gender'] ?? '';
          final interestedIn = data['interestedIn'] ?? '';
          final interests = List<String>.from(data['interests'] ?? []);
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

          return ListView(
            children: [
              _buildProfileHeader(
                context,
                profilePic,
                firstName,
                lastName,
                age,
                course,
                department,
                gender,
                interestedIn,
                createdAt,
                bio,
                interests,
                currentUser.uid,
              ),
              // === User's Posts Section ===
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "My Posts",
                  style: GoogleFonts.readexPro(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              _buildUserPosts(currentUser.uid),
            ],
          );
        },
      ),
    );
  }

  // ------------------- Profile Header -------------------
  Widget _buildProfileHeader(
    BuildContext context,
    String profilePic,
    String firstName,
    String lastName,
    int age,
    String course,
    String department,
    String gender,
    String interestedIn,
    DateTime? createdAt,
    String bio,
    List<String> interests,
    String userId,
  ) {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.only(top: 140, bottom: 20, left: 20, right: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey.withOpacity(0.3),
                backgroundImage:
                    profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                child: profilePic.isEmpty
                    ? const Icon(Icons.person, size: 70, color: Colors.black45)
                    : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(
                        cloudinaryService: cloudinaryService,
                        userId: userId,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black26, width: 1),
                  ),
                  child: Text(
                    "Edit Profile",
                    style: GoogleFonts.readexPro(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "$firstName $lastName",
                style: GoogleFonts.readexPro(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              if (age > 0)
                Text("Age: $age",
                    style: GoogleFonts.readexPro(
                        color: Colors.black54, fontSize: 12)),
              if (course.isNotEmpty)
                Text("$course • $department",
                    style: GoogleFonts.readexPro(
                        color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 10),
              // Info, Bio & Hobbies/Interests Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (gender.isNotEmpty)
                      _infoItem(Icons.wc, "Gender: $gender", small: true),
                    if (interestedIn.isNotEmpty)
                      _infoItem(Icons.favorite, "Interested in: $interestedIn",
                          small: true),
                    if (createdAt != null)
                      _infoItem(Icons.calendar_today,
                          "Joined: ${DateFormat.yMMMd().format(createdAt)}",
                          small: true),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        "About Me",
                        style: GoogleFonts.readexPro(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: GoogleFonts.readexPro(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (interests.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Hobbies & Interests",
                        style: GoogleFonts.readexPro(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        interests.join(', '),
                        style: GoogleFonts.readexPro(
                          color: Colors.black87,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------- Info Item -------------------
  Widget _infoItem(IconData icon, String text, {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.black, size: small ? 14 : 18),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.readexPro(
                  color: Colors.black,
                  fontSize: small ? 12 : 14,
                  fontWeight: small ? FontWeight.w400 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- User Posts -------------------
  Widget _buildUserPosts(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child:
                Text("No posts yet.", style: TextStyle(color: Colors.black54)),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data() as Map<String, dynamic>;
            final caption = post['caption'] ?? '';
            final createdAt = (post['createdAt'] as Timestamp?)?.toDate();
            final imageUrls = <String>[];
            if (post.containsKey('imageUrls')) {
              imageUrls.addAll(List<String>.from(post['imageUrls']));
            } else if (post.containsKey('imageUrl')) {
              imageUrls.add(post['imageUrl']);
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrls.isNotEmpty) _buildPostImages(imageUrls),
                  if (caption.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(caption,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14)),
                    ),
                  if (createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(DateFormat.yMMMd().add_jm().format(createdAt),
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 12)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------- Post Images -------------------
  Widget _buildPostImages(List<String> images) {
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          images[0],
          fit: BoxFit.cover,
          width: double.infinity,
          height: 250,
        ),
      );
    }
    return _PostPageView(images: images);
  }
}

// ------------------- PageView with indicators -------------------
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
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              );
            },
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'edit_profile.dart';
import 'package:datem8/widgets/setting_widget.dart';
import 'package:datem8/widgets/darkmode.dart';

class ProfilePage extends StatelessWidget {
  final CloudinaryService cloudinaryService;

  const ProfilePage({super.key, required this.cloudinaryService});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox.shrink();

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
            automaticallyImplyLeading: false, // removes back arrow
            title: Text(
              "Profile",
              style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.bold, color: textColor),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: iconColor),
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
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
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
                    containerColor,
                    textColor,
                    subTextColor,
                    iconColor,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Text(
                        "My Posts",
                        style: GoogleFonts.readexPro(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildUserPosts(
                      currentUser.uid, containerColor, textColor, subTextColor),
                ],
              );
            },
          ),
        );
      },
    );
  }

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
      Color containerColor,
      Color textColor,
      Color subTextColor,
      Color iconColor) {
    return Container(
      padding: const EdgeInsets.only(top: 140, bottom: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey.withOpacity(0.3),
                backgroundImage:
                    profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                child: profilePic.isEmpty
                    ? Icon(Icons.person,
                        size: 70, color: iconColor.withOpacity(0.6))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 4,
                child: InkWell(
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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: containerColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 1),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "$firstName $lastName",
            style: GoogleFonts.readexPro(
                color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          if (age > 0)
            Text("Age: $age",
                style:
                    GoogleFonts.readexPro(color: subTextColor, fontSize: 12)),
          if (course.isNotEmpty)
            Text("$course • $department",
                style:
                    GoogleFonts.readexPro(color: subTextColor, fontSize: 12)),
          const SizedBox(height: 10),
          _buildInfoContainer(gender, interestedIn, createdAt, bio, interests,
              containerColor, textColor, subTextColor, iconColor),
        ],
      ),
    );
  }

  Widget _buildInfoContainer(
      String gender,
      String interestedIn,
      DateTime? createdAt,
      String bio,
      List<String> interests,
      Color containerColor,
      Color textColor,
      Color subTextColor,
      Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
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
            Text(
              "About Me",
              style: GoogleFonts.readexPro(
                  color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(bio,
                style:
                    GoogleFonts.readexPro(color: subTextColor, fontSize: 12)),
          ],
          if (interests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Hobbies & Interests",
              style: GoogleFonts.readexPro(
                  color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
            ),
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
            child: Text(
              text,
              style: GoogleFonts.readexPro(
                  color: textColor,
                  fontSize: small ? 12 : 14,
                  fontWeight: small ? FontWeight.w400 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPosts(String userId, Color containerColor, Color textColor,
      Color subTextColor) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text("No posts yet.", style: TextStyle(color: subTextColor)),
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
            if (post.containsKey('imageUrls'))
              imageUrls.addAll(List<String>.from(post['imageUrls']));
            else if (post.containsKey('imageUrl'))
              imageUrls.add(post['imageUrl']);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: containerColor,
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
                          style: TextStyle(color: textColor, fontSize: 14)),
                    ),
                  if (createdAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat.yMMMd().add_jm().format(createdAt),
                        style: TextStyle(color: subTextColor, fontSize: 12),
                      ),
                    ),
                ],
              ),
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
              child: Image.network(
                widget.images[index],
                fit: BoxFit.cover,
                width: double.infinity,
              ),
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

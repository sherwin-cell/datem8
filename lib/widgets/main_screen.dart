import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/views/home/home_page.dart';
import 'package:datem8/views/friends/friends_page.dart';
import 'package:datem8/views/profile/profile_page.dart';
import 'package:datem8/views/explore/explore_page.dart';
import 'package:datem8/views/chat/chat_page.dart';

class MainScreen extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const MainScreen({super.key, required this.cloudinaryService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<Widget> _buildPages() {
    return [
      HomePage(cloudinaryService: widget.cloudinaryService),
      ChatPage(cloudinaryService: widget.cloudinaryService),
      ExplorePage(cloudinaryService: widget.cloudinaryService),
      FriendsPage(cloudinaryService: widget.cloudinaryService),
      ProfilePage(cloudinaryService: widget.cloudinaryService),
    ];
  }

  Widget _buildNavItem({
    required String asset,
    required int index,
    double size = 24,
  }) {
    final bool isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.purple.shade900 : Colors.purple.shade100)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Image.asset(
          asset,
          width: size,
          height: size,
          color: isSelected
              ? Colors.purple
              : (isDark ? Colors.grey.shade400 : Colors.grey),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? profileImage;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final imageUrl = data?['profilePic'] as String?;
          if (imageUrl != null && imageUrl.isNotEmpty) {
            profileImage = imageUrl;
          } else if (_currentUser?.photoURL != null &&
              _currentUser!.photoURL!.isNotEmpty) {
            profileImage = _currentUser!.photoURL;
          }
        }

        final pages = _buildPages();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(child: pages[_currentIndex]),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  if (!isDark)
                    const BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                      asset: 'assets/icons/home.png', index: 0, size: 22),
                  _buildNavItem(
                      asset: 'assets/icons/chat.png', index: 1, size: 22),
                  _buildNavItem(
                      asset: 'assets/icons/explore.png', index: 2, size: 26),
                  _buildNavItem(
                      asset: 'assets/icons/friends.png', index: 3, size: 22),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 4),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _currentIndex == 4
                            ? (isDark
                                ? Colors.purple.shade900
                                : Colors.purple.shade100)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: profileImage != null
                          ? CircleAvatar(
                              key: ValueKey(profileImage),
                              radius: 16,
                              backgroundImage: NetworkImage(profileImage),
                              backgroundColor: Colors.transparent,
                            )
                          : CircleAvatar(
                              radius: 16,
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color:
                                    isDark ? Colors.grey.shade300 : Colors.grey,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

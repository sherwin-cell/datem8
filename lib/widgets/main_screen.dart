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

  Widget _buildNavItem(String asset, int index) {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: _currentIndex == index
              ? Colors.blue.shade100
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30), // pill shape
        ),
        child: Image.asset(
          asset,
          width: 24,
          height: 24,
          color: _currentIndex == index ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          body: SafeArea(child: pages[_currentIndex]),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem('assets/icons/home.png', 0),
                  _buildNavItem('assets/icons/chat.png', 1),
                  _buildNavItem('assets/icons/explore.png', 2),
                  _buildNavItem('assets/icons/friends.png', 3),
                  GestureDetector(
                    onTap: () => setState(() => _currentIndex = 4),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _currentIndex == 4
                            ? Colors.blue.shade100
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: profileImage != null
                          ? CircleAvatar(
                              key: ValueKey(profileImage),
                              radius: 14,
                              backgroundImage: NetworkImage(profileImage),
                              backgroundColor: Colors.transparent,
                            )
                          : Image.asset(
                              'assets/icons/profile.png',
                              width: 24,
                              height: 24,
                              color: _currentIndex == 4
                                  ? Colors.blue
                                  : Colors.grey,
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

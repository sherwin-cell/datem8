import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/views/home/home_page.dart';
import 'package:datem8/views/chat/chat_page.dart';
import 'package:datem8/views/friends/friends_page.dart';
import 'package:datem8/views/profile/profile_page.dart';
import 'package:datem8/views/explore/explore_page.dart';
import 'package:datem8/helper/app.icons.dart';

class MainScreen extends StatefulWidget {
  final CloudinaryService cloudinaryService;
  const MainScreen({super.key, required this.cloudinaryService});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  final String defaultProfilePic =
      "https://res.cloudinary.com/dlk8chosr/image/upload/v1759763607/datem8/kegd8r0qpifrhv8wmvxu.jpg";

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(cloudinaryService: widget.cloudinaryService),
      ChatPage(cloudinaryService: widget.cloudinaryService),
      ExplorePage(cloudinaryService: widget.cloudinaryService),
      FriendsPage(cloudinaryService: widget.cloudinaryService),
      ProfilePage(cloudinaryService: widget.cloudinaryService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("No user logged in")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Default to placeholder avatar
        String imageToShow = defaultProfilePic;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final profileImageUrl = data?['profileImageUrl'] as String?;
          if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
            imageToShow = profileImageUrl;
          }
        }

        return Scaffold(
          body: SafeArea(child: _pages[_currentIndex]),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(AppIcons.home), label: ''),
              const BottomNavigationBarItem(
                  icon: Icon(AppIcons.chat), label: ''),
              const BottomNavigationBarItem(
                  icon: Icon(AppIcons.explore), label: ''),
              const BottomNavigationBarItem(
                  icon: Icon(AppIcons.friends), label: ''),
              BottomNavigationBarItem(
                icon: CircleAvatar(
                  // Use UniqueKey when showing default avatar to prevent Flutter from caching the old image
                  key: imageToShow == defaultProfilePic
                      ? UniqueKey()
                      : ValueKey(imageToShow),
                  radius: 12,
                  backgroundImage: imageToShow != defaultProfilePic
                      ? NetworkImage(imageToShow)
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: imageToShow == defaultProfilePic
                      ? const Icon(Icons.person, size: 16, color: Colors.white)
                      : null,
                ),
                label: '',
              ),
            ],
          ),
        );
      },
    );
  }
}

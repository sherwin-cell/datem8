import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/views/home/home_page.dart';
import 'package:datem8/views/friends/friends_page.dart';
import 'package:datem8/views/profile/profile_page.dart';
import 'package:datem8/views/explore/explore_page.dart';
import 'package:datem8/views/chat/chat_page.dart';
import 'package:datem8/helper/app.icons.dart';

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
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (index) => setState(() => _currentIndex = index),
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
                icon: profileImage != null
                    ? CircleAvatar(
                        key: ValueKey(profileImage),
                        radius: 12,
                        backgroundImage: NetworkImage(profileImage),
                        backgroundColor: Colors.transparent,
                      )
                    : CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white,
                        ),
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

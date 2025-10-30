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

  Future<String?> _getProfilePic() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data()?['profilePic'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getProfilePic(),
      builder: (context, snapshot) {
        final profilePic = snapshot.data;
        final imageToShow = (profilePic != null && profilePic.isNotEmpty)
            ? profilePic
            : "https://res.cloudinary.com/dlk8chosr/image/upload/v1759763607/datem8/kegd8r0qpifrhv8wmvxu.jpg";

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
                  radius: 12,
                  backgroundImage: NetworkImage(imageToShow),
                  backgroundColor: Colors.grey[300],
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

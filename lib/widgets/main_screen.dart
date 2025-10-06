import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false, // hides selected label
        showUnselectedLabels: false, // hides unselected labels
        items: const [
          BottomNavigationBarItem(icon: Icon(AppIcons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(AppIcons.chat), label: ''),
          BottomNavigationBarItem(icon: Icon(AppIcons.explore), label: ''),
          BottomNavigationBarItem(icon: Icon(AppIcons.friends), label: ''),
          BottomNavigationBarItem(icon: Icon(AppIcons.profile), label: ''),
        ],
      ),
    );
  }
}

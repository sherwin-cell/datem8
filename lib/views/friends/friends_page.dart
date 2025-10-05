import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'friends_list_tab.dart';
import 'friend_requests_tab.dart';
import 'people_you_may_know_tab.dart';

class FriendsPage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const FriendsPage({super.key, required this.cloudinaryService});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final String currentUserId;

  final List<Tab> _tabs = const [
    Tab(text: "Friends List"),
    Tab(text: "Friend Requests"),
    Tab(text: "People You May Know"),
  ];

  late final List<Widget> _tabViews;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabViews = [
      FriendsListTab(currentUserId: currentUserId),
      FriendRequestsTab(currentUserId: currentUserId),
      PeopleYouMayKnowTab(currentUserId: currentUserId),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Friends",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF342F2F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 20),
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.black54,
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(width: 3.0, color: Colors.redAccent),
            insets: const EdgeInsets.symmetric(horizontal: 16),
          ),
          labelStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: _tabs,
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: TabBarView(
          key: ValueKey<int>(_tabController.index),
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: _tabViews,
        ),
      ),
    );
  }
}

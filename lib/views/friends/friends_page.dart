import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'friends_list_tab.dart';
import 'friend_requests_and_people_tab.dart';

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
  ];

  late final List<Widget> _tabViews;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabViews = [
      FriendsListTab(currentUserId: currentUserId),
      FriendsRequestsAndPeopleTab(currentUserId: currentUserId),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //nal theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        automaticallyImplyLeading: false, // removes the back button
        title: const Text(
          "Friends",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.grey[850],
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey[400],
          indicator: const UnderlineTabIndicator(
            borderSide: BorderSide(width: 3.0, color: Colors.redAccent),
            insets: EdgeInsets.symmetric(horizontal: 16),
          ),
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabViews.map((tabView) {
          return Container(
            color: Colors.grey[900],
            child: tabView,
          );
        }).toList(),
      ),
    );
  }
}

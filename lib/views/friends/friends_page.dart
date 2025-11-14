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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          "Friends",
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: isDark ? Colors.redAccent : Colors.red,
          unselectedLabelColor: isDark
              ? Colors.white70
              : Colors.black54, // contrast for unselected tabs
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
                width: 3.0,
                color: isDark
                    ? const Color.fromARGB(255, 160, 26, 107)
                    : const Color.fromARGB(255, 200, 55, 156)),
            insets: const EdgeInsets.symmetric(horizontal: 16),
          ),
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabViews.map((tabView) {
          return Container(
            color: theme.scaffoldBackgroundColor,
            child: tabView,
          );
        }).toList(),
      ),
    );
  }
}

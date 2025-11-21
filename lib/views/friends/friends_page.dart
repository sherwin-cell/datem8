import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'friends_list_tab.dart';
import 'friend_requests_and_people_tab.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:datem8/widgets/darkmode.dart';
import 'package:datem8/widgets/setting_widget.dart';

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
  final List<String> _tabTitles = ["Friends List", "Friend Requests"];
  late final List<Widget> _tabViews;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _tabController = TabController(length: _tabTitles.length, vsync: this);
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
    final isDark = DarkModeController.themeModeNotifier.value == ThemeMode.dark;

    final bgColor = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final appBarTextColor = isDark ? Colors.white : Colors.black;
    final tabBg = isDark ? Colors.grey.shade900 : Colors.grey.shade200;
    final selectedLabelColor = isDark ? Colors.white : Colors.black;
    final unselectedLabelColor = isDark ? Colors.white70 : Colors.black54;
    // ignore: unused_local_variable
    final indicatorColor =
        isDark ? Colors.white24 : Colors.grey.withOpacity(0.3);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          "Friends",
          style: GoogleFonts.readexPro(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: appBarTextColor,
          ),
        ),
        actions: [
          SettingsIconButton(
            cloudinaryService: widget.cloudinaryService,
            userId: currentUserId,
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: tabBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              labelColor: selectedLabelColor,
              unselectedLabelColor: unselectedLabelColor,
              labelStyle: GoogleFonts.readexPro(
                  fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.readexPro(
                  fontWeight: FontWeight.w500, fontSize: 14),
              tabs: _tabTitles
                  .map(
                    (title) => Tab(
                      child: Center(child: Text(title)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabViews,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/profile_modal.dart';
import 'package:datem8/widgets/setting_widget.dart';

// Department pages
import 'package:datem8/views/home/cbe_users.dart';
import 'package:datem8/views/home/ccs_users.dart';
import 'package:datem8/views/home/cte_users.dart';

class HomePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;

  const HomePage({super.key, required this.cloudinaryService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  final Set<String> _friends = {};
  final Set<String> _sentRequests = {};
  final Set<String> _receivedRequests = {};

  final List<Map<String, dynamic>> departments = [
    {"name": "CBE", "image": "assets/images/cbe.jpg"},
    {"name": "CCS", "image": "assets/images/ccs.jpg"},
    {"name": "CTE", "image": "assets/images/cte.jpg"},
  ];

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    if (currentUser == null) return;

    final uid = currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    // Load friends
    final friendSnap =
        await firestore.collection('friends').doc(uid).collection('list').get();
    _friends.addAll(friendSnap.docs.map((e) => e.id));

    // Sent requests
    final sentSnap = await firestore
        .collection('friend_requests')
        .where('from', isEqualTo: uid)
        .get();
    _sentRequests.addAll(sentSnap.docs.map((e) => e['to'] as String));

    // Received requests
    final recvSnap = await firestore
        .collection('friend_requests')
        .where('to', isEqualTo: uid)
        .get();
    _receivedRequests.addAll(recvSnap.docs.map((e) => e['from'] as String));

    setState(() {});
  }

  void _openDepartmentPage(String dept) {
    late Widget page;
    switch (dept) {
      case "CBE":
        page = const CBEPage();
        break;
      case "CCS":
        page = const CCSPage();
        break;
      case "CTE":
        page = const CTEPage();
        break;
      default:
        return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: 2,
        automaticallyImplyLeading: false,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String greeting = "Hello 👋";
            Widget avatar = CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            );

            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final firstName = userData?['firstName'] ?? "User";
              greeting = "Hello, $firstName 👋";

              final profilePic = userData?['profilePic'] ?? '';
              if (profilePic.isNotEmpty) {
                avatar = CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(profilePic),
                );
              }
            }

            return Row(
              children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    greeting,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          SettingsIconButton(
            cloudinaryService: widget.cloudinaryService,
            userId: currentUser!.uid,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFriendData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Departments Section
              Text(
                "Departments",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: departments.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final dept = departments[index];
                    return GestureDetector(
                      onTap: () => _openDepartmentPage(dept["name"]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          children: [
                            Image.asset(
                              dept["image"],
                              width: 220,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              width: 220,
                              height: 160,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    isDark ? Colors.black54 : Colors.black26,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 25),

              // People You May Know
              Text(
                "People You May Know",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        "No users found 😕",
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  final users = snapshot.data!.docs.where((doc) {
                    final id = doc.id;
                    return id != currentUser!.uid &&
                        !_friends.contains(id) &&
                        !_sentRequests.contains(id) &&
                        !_receivedRequests.contains(id);
                  }).toList();

                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          "No new people to suggest 😎",
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final data = users[index].data() as Map<String, dynamic>;
                      final name =
                          "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}"
                              .trim();
                      final profilePic = data['profilePic'] ?? '';
                      final course = data['course'] ?? '';

                      return Card(
                        color: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : null,
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            child: profilePic.isEmpty
                                ? Icon(Icons.person,
                                    color: theme.colorScheme.onSurface)
                                : null,
                          ),
                          title: Text(
                            name,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle:
                              Text(course, style: theme.textTheme.bodyMedium),
                          onTap: () => showProfileModal(
                            context,
                            userData: {...data, 'uid': users[index].id},
                            cloudinaryService: widget.cloudinaryService,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

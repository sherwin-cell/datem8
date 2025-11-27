import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/profile_modal.dart';
import 'package:datem8/widgets/setting_widget.dart';
import 'package:google_fonts/google_fonts.dart';

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

    final friendSnap =
        await firestore.collection('friends').doc(uid).collection('list').get();
    _friends.addAll(friendSnap.docs.map((e) => e.id));

    final sentSnap = await firestore
        .collection('friend_requests')
        .where('from', isEqualTo: uid)
        .get();
    _sentRequests.addAll(sentSnap.docs.map((e) => e['to'] as String));

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
        page = CBEPage(cloudinaryService: widget.cloudinaryService);
        break;
      case "CCS":
        page = CCSPage(cloudinaryService: widget.cloudinaryService);
        break;
      case "CTE":
        page = CTEPage(cloudinaryService: widget.cloudinaryService);
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
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              backgroundColor: Theme.of(context).colorScheme.primary,
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
                    style: GoogleFonts.readexPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 22, // updated font size
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
          const SizedBox(width: 12),
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
                style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
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
                "People May You Know",
                style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
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
                        "No users found ",
                        style: GoogleFonts.readexPro(fontSize: 14),
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
                          "No new people to suggest ",
                          style: GoogleFonts.readexPro(fontSize: 14),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
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
                            style: GoogleFonts.readexPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            course,
                            style: GoogleFonts.readexPro(fontSize: 14),
                          ),
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

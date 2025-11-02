import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/widgets/profile_modal.dart';

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
    final uid = currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    // Friends list
    final friendSnap =
        await firestore.collection('friends').doc(uid).collection('list').get();
    _friends.addAll(friendSnap.docs.map((e) => e.id));

    // Sent friend requests
    final sentSnap = await firestore
        .collection('friend_requests')
        .where('from', isEqualTo: uid)
        .get();
    _sentRequests.addAll(sentSnap.docs.map((e) => e['to'] as String));

    // Received friend requests
    final recvSnap = await firestore
        .collection('friend_requests')
        .where('to', isEqualTo: uid)
        .get();
    _receivedRequests.addAll(recvSnap.docs.map((e) => e['from'] as String));

    setState(() {});
  }

  void _openDepartmentPage(String dept) {
    Widget? page;
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
    }

    if (page != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            String greeting = "Hello 👋";
            Widget avatar = const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, color: Colors.white, size: 18),
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
                Text(
                  greeting,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFriendData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Department section
              const Text(
                "Departments",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black26,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            // 🔻 Removed the Text label here
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 🔹 People You May Know section
              const SizedBox(height: 25),
              const Text(
                "People You May Know",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                    return const Center(child: Text("No users found 😕"));
                  }

                  final users = snapshot.data!.docs.where((doc) {
                    final id = doc.id;
                    if (id == currentUser!.uid) return false;
                    if (_friends.contains(id)) return false;
                    if (_sentRequests.contains(id)) return false;
                    if (_receivedRequests.contains(id)) return false;
                    return true;
                  }).toList();

                  if (users.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text("No new people to suggest 😎"),
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
                            child: profilePic.isEmpty
                                ? const Icon(Icons.person, color: Colors.white)
                                : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(course),
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

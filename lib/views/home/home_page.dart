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
  final List<Map<String, dynamic>> departments = [
    {"name": "CBE", "image": "assets/images/cbe.jpg"},
    {"name": "CCS", "image": "assets/images/ccs.jpg"},
    {"name": "CTE", "image": "assets/images/cte.jpg"},
  ];

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

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 900),
        reverseTransitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            Widget avatar = const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            );
            String greetingText = "Hello 👋";

            if (snapshot.hasData && snapshot.data!.exists) {
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final firstName = (userData?['firstName'] ?? 'User') as String;
              greetingText = "Hello, $firstName 👋";

              final profilePic = (userData?['profilePic'] ?? '') as String;
              if (profilePic.isNotEmpty) {
                avatar = CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(profilePic),
                );
              }
            }

            return InkWell(
              onTap: () => showProfileModal(context),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    avatar,
                    const SizedBox(width: 10),
                    Text(
                      greetingText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // Main Body
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📍 Departments section
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
                      child: Hero(
                        tag: dept["name"],
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
                              // subtle overlay only — no text
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // 👥 All Users Section
              const Text(
                "All Users",
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
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text("No users found 😕")),
                    );
                  }

                  final users = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;

                      if (userId == currentUser?.uid) return const SizedBox();

                      final firstName = user['firstName'] ?? '';
                      final lastName = user['lastName'] ?? '';
                      final course = user['course'] ?? '';
                      final profilePic = user['profilePic'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: profilePic.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(profilePic),
                                  radius: 25,
                                )
                              : const CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey,
                                  child:
                                      Icon(Icons.person, color: Colors.white),
                                ),
                          title: Text(
                            "$firstName $lastName",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            course,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          onTap: () =>
                              showProfileModal(context, userData: user),
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

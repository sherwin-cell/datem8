import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datem8/services/cloudinary_service.dart';

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
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Home",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                const Text(
                  "Departments",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal list of departments
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
                                // Department image
                                Image.asset(
                                  dept["image"],
                                  width: 220,
                                  height: 160,
                                  fit: BoxFit.cover,
                                ),

                                // Gradient overlay (optional for readability)
                                Container(
                                  width: 220,
                                  height: 160,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black38
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

                // All Users Section
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
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
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
                        child: Center(
                          child: Text("No users found 😕"),
                        ),
                      );
                    }

                    final users = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user =
                            users[index].data() as Map<String, dynamic>;
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
      ),
    );
  }
}

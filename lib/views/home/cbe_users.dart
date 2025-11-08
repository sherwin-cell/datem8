import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CBEPage extends StatelessWidget {
  const CBEPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 🔹 AppBar with Hero image + gradient overlay
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // ✅ Hero animation
                  Hero(
                    tag: "CBE",
                    child: Image.asset(
                      "assets/images/cbe.jpg",
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 🔹 Gradient overlay
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x99000000),
                          Color(0x00000000),
                          Color(0xCCF57C00),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 20,
                    bottom: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Icons.business_center,
                            color: Colors.white, size: 36),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                "Meet our CBE students below 👇",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFFF57C00),
          ),

          // 🔹 Firestore users list for CBE department
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('department', isEqualTo: 'CBE')
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
                      child: Text(
                        "No CBE users found 😕",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final firstName = user['firstName'] ?? '';
                    final lastName = user['lastName'] ?? '';
                    final course = user['course'] ?? '';
                    final profilePic = user['profilePic'] ?? '';

                    return AnimatedScale(
                      scale: 1.0,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      child: Card(
                        color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: profilePic.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(profilePic),
                                  radius: 25,
                                )
                              : CircleAvatar(
                                  radius: 25,
                                  backgroundColor: isDark
                                      ? const Color(0xFFB5731A)
                                      : const Color.fromARGB(255, 61, 38, 3),
                                  child: const Icon(Icons.person,
                                      color: Colors.white),
                                ),
                          title: Text(
                            "$firstName $lastName",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            course,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

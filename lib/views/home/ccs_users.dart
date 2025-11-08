import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CCSPage extends StatelessWidget {
  const CCSPage({super.key});

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
                  // 🔹 Hero department image
                  Hero(
                    tag: "CCS",
                    child: Image.asset(
                      "assets/images/ccs.jpg",
                      fit: BoxFit.cover,
                    ),
                  ),

                  // 🔹 Gradient overlay for clarity
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          const Color(0xCC1976D2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // 🔹 Department title and subtitle
                  const Positioned(
                    left: 20,
                    bottom: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Icons.computer, color: Colors.white, size: 36),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "College of Computer Studies",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Meet our CCS students below 👇",
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
            backgroundColor: const Color(0xFF1976D2),
          ),

          // 🔹 Firestore users list for CCS department
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('department', isEqualTo: 'CCS')
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
                        "No CCS users found 😕",
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
                                      ? const Color(0xFF64B5F6)
                                      : const Color(0xFF90CAF9),
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

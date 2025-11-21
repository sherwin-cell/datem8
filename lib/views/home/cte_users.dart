import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class CTEPage extends StatelessWidget {
  const CTEPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with Hero image + gradient overlay
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: "CTE",
                    child: Image.asset(
                      "assets/images/cte.jpg",
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                          const Color(0xCC7E57C2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                "Meet our CTE students below ",
                                style: GoogleFonts.readexPro(
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
            backgroundColor: const Color(0xFF7E57C2),
          ),

          // Firestore users list
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('department', isEqualTo: 'CTE')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        "No CTE users found 😕",
                        style: GoogleFonts.readexPro(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                final users = snapshot.data!.docs;

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final firstName = user['firstName'] ?? '';
                    final lastName = user['lastName'] ?? '';
                    final course = user['course'] ?? '';
                    final profilePic = user['profilePic'] ?? '';

                    return Card(
                      color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      shadowColor: Colors.black26,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        leading: profilePic.isNotEmpty
                            ? CircleAvatar(
                                radius: 26,
                                backgroundImage: NetworkImage(profilePic),
                              )
                            : CircleAvatar(
                                radius: 26,
                                backgroundColor: isDark
                                    ? const Color(0xFF9575CD)
                                    : const Color(0xFFB39DDB),
                                child: const Icon(Icons.person,
                                    color: Colors.white),
                              ),
                        title: Text(
                          "$firstName $lastName",
                          style: GoogleFonts.readexPro(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          course,
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
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

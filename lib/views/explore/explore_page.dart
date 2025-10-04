import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/helper/app_colors.dart';
import 'package:datem8/views/post/new_post_page.dart';

class ExplorePage extends StatefulWidget {
  final CloudinaryService cloudinaryService;
  const ExplorePage({super.key, required this.cloudinaryService});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _openNewPost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            NewPostPage(cloudinaryService: widget.cloudinaryService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postsRef =
        _firestore.collection("posts").orderBy("createdAt", descending: true);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Explore"),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false, // removes back arrow if any
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: postsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount:
                posts.length + 1, // +1 for the "What's on your mind?" card
            itemBuilder: (context, index) {
              if (index == 0) {
                // Top card for new post
                return GestureDetector(
                  onTap: _openNewPost,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      "What's on your mind?",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ),
                );
              }

              final post = posts[index - 1].data() as Map<String, dynamic>;
              final imageUrl = post['imageUrl'] ?? '';
              final caption = post['caption'] ?? '';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (caption.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          caption,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

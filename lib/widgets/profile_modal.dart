import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:datem8/views/profile/other_profile_page.dart';
import 'package:datem8/services/friends_service.dart';

class ProfileModal extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final CloudinaryService cloudinaryService;

  const ProfileModal({
    super.key,
    this.userData,
    required this.cloudinaryService,
  });

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> {
  final FriendsService _friendsService = FriendsService();
  bool _isLoading = false;
  String _friendStatus = "none"; // none | pending | friends | received

  @override
  void initState() {
    super.initState();
    _checkFriendStatus();
  }

  Future<void> _checkFriendStatus() async {
    final targetId = widget.userData?['uid'];
    if (targetId == null) return;

    final status = await _friendsService.getFriendStatus(targetId);
    setState(() => _friendStatus = status);
  }

  Future<void> _sendFriendRequest() async {
    final targetId = widget.userData?['uid'];
    if (targetId == null) return;

    setState(() => _isLoading = true);
    try {
      await _friendsService.sendFriendRequest(targetId);
      setState(() => _friendStatus = "pending");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request sent ✅")),
      );
    } catch (e) {
      debugPrint("❌ Error sending friend request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptFriendRequest() async {
    final targetId = widget.userData?['uid'];
    if (targetId == null) return;

    setState(() => _isLoading = true);
    try {
      await _friendsService.acceptFriendRequest(targetId);
      setState(() => _friendStatus = "friends");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend added successfully 🎉")),
      );
    } catch (e) {
      debugPrint("❌ Error accepting friend request: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleFriendAction() {
    if (_friendStatus == "none") {
      _sendFriendRequest();
    } else if (_friendStatus == "received") {
      _acceptFriendRequest();
    }
  }

  Widget _buildFriendButton() {
    switch (_friendStatus) {
      case "friends":
        return const Text("Friends ✅");
      case "pending":
        return const Text("Pending ⏳");
      case "received":
        return const Text("Accept Request");
      default:
        return const Text("+ Add Friend");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final data = widget.userData ?? {};
    final String displayName = (data['firstName'] != null)
        ? "${data['firstName']} ${data['lastName']}"
        : currentUser?.displayName ?? "Guest User";

    final String course = data['course'] ?? '';
    final String department = data['department'] ?? '';
    final String bio = data['bio'] ?? "Hi, I'm using this app";
    final int followers = data['followers'] ?? 0;
    final int following = data['following'] ?? 0;
    final String? profilePic = data['profilePic'] ?? currentUser?.photoURL;
    final bool isCurrentUser = data['uid'] == currentUser?.uid;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                ? CachedNetworkImageProvider(profilePic)
                : null,
            child: (profilePic == null || profilePic.isEmpty)
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(displayName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(height: 4),
          Text("$course - $department",
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatWidget(label: "Followers", count: followers),
              const SizedBox(width: 24),
              _StatWidget(label: "Following", count: following),
            ],
          ),
          const SizedBox(height: 16),
          Text(bio,
              style: const TextStyle(color: Colors.black87),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (isCurrentUser) {
                      Navigator.pushNamed(context, '/profile');
                    } else if (data['uid'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtherUserProfilePage(
                            userId: data['uid'],
                            userName: displayName,
                            cloudinaryService: widget.cloudinaryService,
                            avatarUrl: profilePic,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text("View Profile"),
                ),
              ),
              const SizedBox(width: 10),
              if (!isCurrentUser)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleFriendAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : _buildFriendButton(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String label;
  final int count;

  const _StatWidget({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("$count",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }
}

void showProfileModal(
  BuildContext context, {
  Map<String, dynamic>? userData,
  required CloudinaryService cloudinaryService,
}) {
  final Map<String, dynamic>? dataWithUid = userData != null
      ? {...userData, 'uid': userData['uid'] ?? userData['id']}
      : null;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProfileModal(
      userData: dataWithUid,
      cloudinaryService: cloudinaryService,
    ),
  );
}

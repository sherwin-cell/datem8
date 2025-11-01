import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datem8/services/cloudinary_service.dart';
import 'package:intl/intl.dart';

class OtherUserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final CloudinaryService cloudinaryService;
  final String? avatarUrl;

  const OtherUserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.cloudinaryService,
    this.avatarUrl,
  });

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = true;

  String _fullName = '';
  String _bio = '';
  int _age = 0;
  String _profilePic = '';
  String _course = '';
  String _department = '';
  String _gender = '';
  String _interestedIn = '';
  DateTime? _createdAt;
  List<String> _interests = [];

  @override
  void initState() {
    super.initState();
    _profilePic = widget.avatarUrl ?? '';
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final data = doc.data()!;
      setState(() {
        _fullName = (data['name'] ??
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
            .toString();
        _bio = data['bio'] ?? '';
        _age = data['age'] ?? 0;
        _profilePic =
            _profilePic.isNotEmpty ? _profilePic : data['profilePic'] ?? '';
        _course = data['course'] ?? '';
        _department = data['department'] ?? '';
        _gender = data['gender'] ?? '';
        _interestedIn = data['interestedIn'] ?? '';
        _createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        _interests =
            (data['interests'] as List?)?.map((e) => e.toString()).toList() ??
                [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error loading profile: $e");
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.white,
            child: ClipOval(
              child: _profilePic.isNotEmpty
                  ? Image.network(
                      _profilePic,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.person, size: 60, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 12),
          Text(_fullName,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          if (_age > 0)
            Text("Age: $_age",
                style: const TextStyle(color: Colors.white70, fontSize: 15)),
          if (_course.isNotEmpty)
            Text("$_course • $_department",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String text) => Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      );

  Widget _buildProfileDetails() {
    final details = <Widget>[
      if (_gender.isNotEmpty) _buildInfoCard(Icons.wc, "Gender: $_gender"),
      if (_interestedIn.isNotEmpty)
        _buildInfoCard(Icons.favorite, "Interested in: $_interestedIn"),
      if (_createdAt != null)
        _buildInfoCard(
          Icons.calendar_today,
          "Joined: ${DateFormat('yyyy-MM-dd').format(_createdAt!)}",
        ),
    ];
    if (details.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: details),
      ),
    );
  }

  Widget _buildBioSection() {
    if (_bio.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("About Me",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_bio, style: const TextStyle(fontSize: 16, height: 1.4)),
        ]),
      ),
    );
  }

  Widget _buildInterests() {
    if (_interests.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Interests",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _interests.map((e) => Chip(label: Text(e))).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.userName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfile,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _buildProfileHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildProfileDetails(),
                        _buildBioSection(),
                        _buildInterests(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

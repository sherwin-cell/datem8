import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  /// 🔹 Check current friendship status
  /// Returns one of: "friends", "pending", "received", "none"
  Future<String> getFriendStatus(String otherUserId) async {
    final myId = currentUserId;

    // ✅ Already friends
    final friendDoc = await _firestore
        .collection('friends')
        .doc(myId)
        .collection('list')
        .doc(otherUserId)
        .get();
    if (friendDoc.exists) return "friends";

    // ✅ Sent request
    final sent = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: myId)
        .where('to', isEqualTo: otherUserId)
        .limit(1)
        .get();
    if (sent.docs.isNotEmpty) return "pending";

    // ✅ Received request
    final received = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: otherUserId)
        .where('to', isEqualTo: myId)
        .limit(1)
        .get();
    if (received.docs.isNotEmpty) return "received";

    return "none";
  }

  /// 🔹 Send a friend request
  Future<void> sendFriendRequest(String toUserId) async {
    final myId = currentUserId;

    // Prevent duplicates
    final existing = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: myId)
        .where('to', isEqualTo: toUserId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return;

    await _firestore.collection('friend_requests').add({
      'from': myId,
      'to': toUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Accept a friend request and create friendship
  Future<void> acceptFriendRequest(String fromUserId) async {
    final myId = currentUserId;
    final batch = _firestore.batch();

    // Delete the request
    final reqSnap = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: fromUserId)
        .where('to', isEqualTo: myId)
        .limit(1)
        .get();

    if (reqSnap.docs.isNotEmpty) {
      batch.delete(reqSnap.docs.first.reference);
    }

    // Add both as friends
    final myRef = _firestore
        .collection('friends')
        .doc(myId)
        .collection('list')
        .doc(fromUserId);
    final theirRef = _firestore
        .collection('friends')
        .doc(fromUserId)
        .collection('list')
        .doc(myId);

    batch.set(myRef, {'timestamp': FieldValue.serverTimestamp()});
    batch.set(theirRef, {'timestamp': FieldValue.serverTimestamp()});

    await batch.commit();
  }

  /// 🔹 Remove a friend or cancel a pending request
  Future<void> removeFriendOrRequest(String otherUserId) async {
    final myId = currentUserId;

    // Try removing from friends
    final myFriendRef = _firestore
        .collection('friends')
        .doc(myId)
        .collection('list')
        .doc(otherUserId);
    final theirFriendRef = _firestore
        .collection('friends')
        .doc(otherUserId)
        .collection('list')
        .doc(myId);

    final myFriendSnap = await myFriendRef.get();
    if (myFriendSnap.exists) {
      await myFriendRef.delete();
      await theirFriendRef.delete();
      return;
    }

    // Otherwise remove request (sent or received)
    final reqs = await _firestore
        .collection('friend_requests')
        .where('from', whereIn: [myId, otherUserId]).where('to',
            whereIn: [myId, otherUserId]).get();

    for (final doc in reqs.docs) {
      await doc.reference.delete();
    }
  }

  /// 🔹 Stream of "People You May Know" (not friends + no pending requests)
  Stream<List<Map<String, dynamic>>> peopleYouMayKnow() async* {
    final myId = currentUserId;

    // Get all IDs to exclude
    final friendsSnap = await _firestore
        .collection('friends')
        .doc(myId)
        .collection('list')
        .get();
    final friends = friendsSnap.docs.map((e) => e.id).toSet();

    final sentSnap = await _firestore
        .collection('friend_requests')
        .where('from', isEqualTo: myId)
        .get();
    final sent = sentSnap.docs.map((e) => e['to'] as String).toSet();

    final recvSnap = await _firestore
        .collection('friend_requests')
        .where('to', isEqualTo: myId)
        .get();
    final received = recvSnap.docs.map((e) => e['from'] as String).toSet();

    // ✅ Real-time updates from users collection
    yield* _firestore.collection('users').snapshots().map((snap) {
      return snap.docs
          .where((doc) {
            final id = doc.id;
            return id != myId &&
                !friends.contains(id) &&
                !sent.contains(id) &&
                !received.contains(id);
          })
          .map((doc) => {...doc.data(), 'uid': doc.id})
          .toList();
    });
  }
}

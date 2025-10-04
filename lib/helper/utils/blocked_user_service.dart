import 'package:firebase_database/firebase_database.dart';

class BlockedUserService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Blocks [otherUserId] for [currentUserId].
  Future<void> blockUser(String currentUserId, String otherUserId) async {
    await _dbRef.child('users/$currentUserId/blocked/$otherUserId').set(true);
  }

  /// Unblocks [otherUserId] for [currentUserId].
  Future<void> unblockUser(String currentUserId, String otherUserId) async {
    await _dbRef.child('users/$currentUserId/blocked/$otherUserId').remove();
  }

  /// Checks if [currentUserId] has blocked [otherUserId].
  Future<bool> isUserBlocked(String currentUserId, String otherUserId) async {
    final snapshot =
        await _dbRef.child('users/$currentUserId/blocked/$otherUserId').get();
    return snapshot.exists && snapshot.value == true;
  }

  /// Checks if either [currentUserId] or [otherUserId] has blocked the other.
  Future<bool> isBlocked(String currentUserId, String otherUserId) async {
    final blockedByMe = await isUserBlocked(currentUserId, otherUserId);
    final blockedByOther = await isUserBlocked(otherUserId, currentUserId);
    return blockedByMe || blockedByOther;
  }
}

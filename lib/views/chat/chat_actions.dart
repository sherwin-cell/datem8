import 'package:firebase_database/firebase_database.dart';

class ChatActions {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// ---------------- Unsend a Message ----------------
  Future<void> unsendMessage({
    required String chatId,
    required String messageKey,
  }) async {
    try {
      await _dbRef.child('chats/$chatId/messages/$messageKey').remove();
    } catch (e) {
      throw Exception('Failed to unsend message: $e');
    }
  }

  /// ---------------- Delete Conversation ----------------
  /// Soft delete for current user. Hard delete if all participants have deleted.
  Future<void> deleteConversation({
    required String chatId,
    required String currentUserId,
    required List<String> participantIds,
  }) async {
    final chatRef = _dbRef.child('chats/$chatId');

    try {
      // Mark as deleted for current user
      await chatRef.child('deletedFor/$currentUserId').set(true);

      // Check who else deleted the chat
      final snapshot = await chatRef.child('deletedFor').get();
      final deletedFor =
          Map<String, dynamic>.from(snapshot.value as Map? ?? {});

      // If all participants have deleted, remove the chat completely
      final allDeleted = participantIds.every((id) => deletedFor[id] == true);

      if (allDeleted) {
        await chatRef.remove();
      }
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// ---------------- Block User ----------------
  Future<void> blockUser({
    required String currentUserId,
    required String otherUserId,
    required String chatId,
  }) async {
    try {
      // Block in users node
      await _dbRef.child('users/$currentUserId/blocked/$otherUserId').set(true);
      // Mark chat as blocked for the blocker
      await _dbRef.child('chats/$chatId/blockedFor/$currentUserId').set(true);
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  /// ---------------- Unblock User ----------------
  Future<void> unblockUser({
    required String currentUserId,
    required String otherUserId,
    required String chatId,
  }) async {
    try {
      await _dbRef.child('users/$currentUserId/blocked/$otherUserId').remove();
      await _dbRef.child('chats/$chatId/blockedFor/$currentUserId').remove();
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  /// ---------------- Check if blocked ----------------
  Future<bool> isBlocked({
    required String currentUserId,
    required String chatId,
  }) async {
    try {
      final snapshot =
          await _dbRef.child('chats/$chatId/blockedFor/$currentUserId').get();
      return snapshot.exists && snapshot.value == true;
    } catch (e) {
      throw Exception('Failed to check block status: $e');
    }
  }
}

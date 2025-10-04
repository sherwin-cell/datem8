import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-auth-5b553-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  /// Expose raw database access if needed
  FirebaseDatabase get database => _database;

  /// Quick reference to any path
  DatabaseReference ref(String path) => _database.ref(path);

  // -----------------------
  // CHAT
  // -----------------------

  /// Reference to a specific chat
  DatabaseReference getChatRef(String chatId) => ref("chats/$chatId");

  /// Send a message to a chat
  Future<void> sendMessage(String chatId, Map<String, dynamic> message) async {
    await getChatRef(chatId).child("messages").push().set({
      ...message,
      "timestamp": ServerValue.timestamp,
    });
  }

  /// Stream messages for a chat
  Stream<DatabaseEvent> messagesStream(String chatId) {
    return getChatRef(chatId).child("messages").onValue;
  }

  // -----------------------
  // USER STATUS
  // -----------------------

  /// Set user online
  Future<void> setUserOnline(String uid) async {
    await ref('status/$uid').set({
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Set user offline
  Future<void> setUserOffline(String uid) async {
    await ref('status/$uid').set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Stream user online status
  Stream<DatabaseEvent> userStatusStream(String uid) {
    return ref('status/$uid').onValue;
  }

  // -----------------------
  // FRIENDS / REQUESTS
  // -----------------------

  /// Reference to a user's friends
  DatabaseReference friendsRef(String uid) => ref("friends/$uid");

  /// Reference to friend requests
  DatabaseReference friendRequestsRef(String requestId) =>
      ref("friend_requests/$requestId");

  // -----------------------
  // GENERAL HELPERS
  // -----------------------

  /// Server timestamp helper
  static Map<String, String> get serverTimestamp => ServerValue.timestamp;

  /// Add a test message (optional)
  Future<void> addTestMessage(String text) async {
    await ref("messages").push().set({
      "text": text,
      "timestamp": ServerValue.timestamp,
    });
  }

  /// Listen for messages at root messages node (optional)
  void listenMessages(Function(dynamic) onData) {
    ref("messages").onValue.listen((event) {
      final data = event.snapshot.value;
      onData(data);
    });
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeDBService {
  final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://fir-auth-5b553-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  /// Expose the database if you ever need raw access
  FirebaseDatabase get database => _database;

  /// Quick reference to any path
  DatabaseReference ref(String path) => _database.ref(path);

  /// ✅ Chat-specific reference
  DatabaseReference getChatRef(String chatId) => _database.ref("chats/$chatId");

  /// ✅ Server timestamp helper
  static Map<String, String> get serverTimestamp => ServerValue.timestamp;

  /// Example: Messages node (optional)
  DatabaseReference get messagesRef => _database.ref("messages");

  /// Example: Add a test message
  Future<void> addMessage(String text) async {
    await messagesRef.push().set({
      "text": text,
      "timestamp": ServerValue.timestamp,
    });
  }

  /// Example: Listen for messages
  void listenMessages(Function(dynamic) onData) {
    messagesRef.onValue.listen((event) {
      final data = event.snapshot.value;
      onData(data);
    });
  }
}

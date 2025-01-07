import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessagePage extends StatefulWidget {
  final String userId; // 상대방의 사용자 ID

  MessagePage({required this.userId});

  @override
  _MessagePageState createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      try {
        final chatId = _getChatId(currentUser.uid, widget.userId);
        final messageData = {
          'senderId': currentUser.uid,
          'receiverId': widget.userId,
          'message': _messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add(messageData);

        _messageController.clear();
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  String _getChatId(String userId1, String userId2) {
    return (userId1.hashCode <= userId2.hashCode)
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final chatId = _getChatId(currentUser.uid, widget.userId);

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(
                'Loading...',
                style: TextStyle(color: Colors.black),
              );
            }

            final userDoc = snapshot.data!;
            final userName = userDoc['name'] ?? 'Unknown';

            return Text(
              userName,
              style: TextStyle(color: Colors.black),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSelf = message['senderId'] == currentUser.uid;

                    return Align(
                      alignment:
                        isSelf ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelf ? Color(0xFF001A72) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['message'],
                          style: TextStyle(
                            color: isSelf ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: "Type your message...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              SizedBox(
                width: 48,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF001A72),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: _sendMessage,
                  child: Icon(Icons.send),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

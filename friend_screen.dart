import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart';

class FriendsPage extends StatefulWidget {
  final String userId; // 친구 목록을 조회할 사용자의 ID

  FriendsPage({required this.userId});

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "친구 목록",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId) // 전달받은 userId 기준으로 친구 목록 조회
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final userDoc = snapshot.data!;
          final friends = List<String>.from(userDoc['friends'] ?? []);

          if (friends.isEmpty) {
            return Center(
              child: Text(
                "아직 친구가 없습니다.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendId = friends[index];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(friendId)
                    .get(),
                builder: (context, friendSnapshot) {
                  if (!friendSnapshot.hasData) {
                    return ListTile(
                      title: Text("Loading..."),
                    );
                  }

                  final friendData = friendSnapshot.data!;
                  final friendName = friendData['name'] ?? "Unknown";
                  final profilePicture = Icons.person; // 기본 아이콘

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade300,
                      child: Icon(profilePicture, color: Colors.white),
                    ),
                    title: Text(
                      friendName,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing:
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            userId: friendId,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

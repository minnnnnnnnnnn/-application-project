import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'message_screen.dart';
import 'friend_screen.dart';
import 'fix_profile_screen.dart';

class ProfilePage extends StatefulWidget {
  final String userId; // 프로필 사용자 ID

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isMyProfile = false;
  bool isFriend = false;

  @override
  void initState() {
    super.initState();
    _checkIfMyProfile(); // 본인 프로필 여부 확인
    _checkFriendStatus(); // 친구 여부 확인
  }

  void _checkIfMyProfile() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == widget.userId) {
      setState(() {
        isMyProfile = true;
      });
    }
  }

  Future<void> _checkFriendStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final currentUserDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        final friends = List<String>.from(currentUserDoc['friends'] ?? []);
        setState(() {
          isFriend = friends.contains(widget.userId);
        });
      }
    } catch (e) {
      print('Error checking friend status: $e');
    }
  }

  Future<void> _addFriend() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final currentUserDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      final targetUserDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      await currentUserDoc.update({
        'friends': FieldValue.arrayUnion([widget.userId]),
      });

      await targetUserDoc.update({
        'friends': FieldValue.arrayUnion([currentUser.uid]),
      });

      setState(() {
        isFriend = true;
      });
    } catch (e) {
      print('Error adding friend: $e');
    }
  }

  Future<void> _deleteFriend() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final currentUserDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid);
      final targetUserDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);

      await currentUserDoc.update({
        'friends': FieldValue.arrayRemove([widget.userId]),
      });

      await targetUserDoc.update({
        'friends': FieldValue.arrayRemove([currentUser.uid]),
      });

      setState(() {
        isFriend = false;
      });
    } catch (e) {
      print('Error deleting friend: $e');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Text(
                'Loading...',
                style: TextStyle(color: Colors.black),
              );
            }

            final userDoc = snapshot.data!;
            final userName = userDoc['name'] ?? '익명';

            return Text(
              userName,
              style: TextStyle(color: Colors.black),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          if (!isMyProfile)
            TextButton(
              onPressed: () async {
                if (isFriend) {
                  await _deleteFriend();
                } else {
                  await _addFriend();
                }
              },
              child: Text(
                isFriend ? "Delete Friend" : "Add Friend",
                style: TextStyle(
                  color: isFriend ? Colors.red : Color(0xFF001A72),
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFF001A72),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      }
                      final userDoc = snapshot.data!;
                      final profileImageUrl = userDoc['profile'];

                      return GestureDetector(
                        onTap: () {
                          if (isMyProfile) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FixProfilePage(userID: widget.userId),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFF001A72),
                          backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                              : null,
                          child: profileImageUrl == null || profileImageUrl.isEmpty
                              ? Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          )
                              : null,
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF001A72),
                          side: BorderSide(color: Color(0xFF001A72)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessagePage(userId: widget.userId),
                            ),
                          );
                        },
                        child: Text("Message"),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Color(0xFF001A72),
                          side: BorderSide(color: Color(0xFF001A72)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FriendsPage(userId: widget.userId),
                            ),
                          );
                        },
                        child: Text("Friends"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('post')
                  .where('userID', isEqualTo: widget.userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No posts available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final posts = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final imagePath = post['imagePath'];

                    return Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}
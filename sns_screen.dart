import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_screen.dart';
import 'home_screen.dart';
import 'mypage_screen.dart';
import 'sns_upload_screen.dart';
import 'favorite_screen.dart';

class SNSHomePage extends StatefulWidget {
  @override
  _SNSHomePageState createState() => _SNSHomePageState();
}

class _SNSHomePageState extends State<SNSHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Stream<List<DocumentSnapshot>> _getFilteredPosts() async* {
    if (_searchQuery.isEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('post')
          .orderBy('timestamp', descending: true)
          .get();
      yield snapshot.docs;
    } else {
      final contentQuery = FirebaseFirestore.instance
          .collection('post')
          .where('content', isGreaterThanOrEqualTo: _searchQuery)
          .where('content', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .get();

      final placeQuery = FirebaseFirestore.instance
          .collection('post')
          .where('place', isGreaterThanOrEqualTo: _searchQuery)
          .where('place', isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .get();

      final results = await Future.wait([contentQuery, placeQuery]);

      // 중복 제거
      final allDocs = results.expand((result) => result.docs).toSet().toList();
      yield allDocs;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        title: Row(
          children: [
            // 로고 이미지 추가
            Image.asset(
              'assets/vicon.png',
              height: 32,
              width: 32,
              fit: BoxFit.cover,
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "이곳저곳 찾아보기",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0, // AppBar 그림자 제거
        scrolledUnderElevation: 0, // 스크롤 시 elevation 제거
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            color: Colors.grey.shade300,
            thickness: 1,
            height: 1,
          ),
        ),
      ),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: _getFilteredPosts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!;

          if (posts.isEmpty) {
            return Center(child: Text('검색 결과가 없습니다.'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostWidget(
                postId: post.id,
                content: post['content'],
                place: post['place'],
                imagePath: post['imagePath'],
                like: post['like'],
                userId: post['userID'],
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: '장소',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feed),
            label: '피드',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/vicon_grey.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
            label: '부이',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내정보',
          ),
        ],
        currentIndex: 1,
        selectedItemColor: Color(0xFF001A72),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) { // "홈화면" 버튼
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()), // MyPageScreen으로 이동
            );
          }
          else if (index == 2) { // "내정보" 버튼
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoritesPage()), // FavoriteScreen으로 이동
            );
          }
          else if (index == 3) { // "내정보" 버튼
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MyPageScreen()), // MyPageScreen으로 이동
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 이미지 선택 및 업로드 페이지 연결
          await _navigateToUploadPage(context);
        },
        child: Icon(Icons.add),
        backgroundColor: Color(0xFF001A72),
        foregroundColor: Colors.white,
      ),
    );
  }
  Future<void> _navigateToUploadPage(BuildContext context) async {
    // 업로드 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadPage()),
    );
  }
}

class PostWidget extends StatefulWidget {
  final String postId;
  final String content;
  final String place;
  final String imagePath;
  final int like;
  final String userId;

  PostWidget({
    required this.postId,
    required this.content,
    required this.place,
    required this.imagePath,
    required this.like,
    required this.userId,
  });

  @override
  _PostWidgetState createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {

  String username = ''; // username 저장
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    fetchUsername(); // username 가져오기
    checkIfLiked();
  }

  Future<void> fetchUsername() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) { // mounted 상태 확인
        setState(() {
          username = userDoc['name'];
        });
      }
    } catch (e) {
      if (mounted) { // mounted 상태에서만 오류 출력
        print('Error fetching username: $e');
      }
    }
  }

  Future<void> checkIfLiked() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('post')
          .doc(widget.postId)
          .get();

      if (postDoc.exists) {
        // likedUsers 필드가 없으면 기본값으로 빈 배열을 사용
        final likedUsers = postDoc.data()?['likedUsers'] != null
            ? List<String>.from(postDoc.data()!['likedUsers'])
            : [];
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null && likedUsers.contains(userId)) {
          setState(() {
            isLiked = true;
          });
        } else{
          setState(() {
            isLiked = false;
          });
        }
      }else{
        setState(() {
          isLiked = false;
        });
      }
    } catch (e) {
      print('Error checking like status: $e');
      setState(() {
        isLiked = false; // 오류가 발생해도 기본값으로 초기화
      });
    }
  }

  void toggleLike() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final postRef =
      FirebaseFirestore.instance.collection('post').doc(widget.postId);
      final postDoc = await postRef.get();

      if (postDoc.exists) {
        // likedUsers 필드가 없으면 빈 배열로 초기화
        final likedUsers = postDoc.data()?['likedUsers'] != null
            ? List<String>.from(postDoc.data()!['likedUsers'])
            : [];

        if (likedUsers.contains(userId)) {
          // 좋아요 취소
          await postRef.update({
            'likedUsers': FieldValue.arrayRemove([userId]),
            'like': FieldValue.increment(-1),
          });
          setState(() {
            isLiked = false;
          });
        } else {
          // 좋아요 추가
          await postRef.update({
            'likedUsers': FieldValue.arrayUnion([userId]),
            'like': FieldValue.increment(1),
          });
          setState(() {
            isLiked = true;
          });
        }
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // 전체 정렬
      children: [
        // 프로필 아이콘, 사용자 이름, 좋아요/댓글/공유 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 좌우 정렬
          crossAxisAlignment: CrossAxisAlignment.center, // 수직 정렬
          children: [
            // 왼쪽: 프로필 아이콘과 사용자 이름
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // 프로필 아이콘을 눌렀을 때 ProfilePage로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userId: widget.userId), // 게시물 작성자의 ID
                      ),
                    );
                  },
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade300,
                          child: Icon(
                            Icons.person, // 기본 프로필 아이콘
                            color: Colors.white,
                          ),
                        );
                      }

                      final userDoc = snapshot.data!;
                      final profileImageUrl = userDoc['profile'];

                      return CircleAvatar(
                        radius: 20, // 동그라미 크기
                        backgroundColor: Colors.grey.shade300, // 기본 배경색
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl) // Firestore에서 가져온 프로필 사진 URL
                            : null, // 프로필 사진이 없을 경우 기본 배경색만 표시
                        child: profileImageUrl == null || profileImageUrl.isEmpty
                            ? Icon(
                          Icons.person, // 기본 아이콘
                          color: Colors.white,
                        )
                            : null,
                      );
                    },
                  ),
                ),
                SizedBox(width: 10), // 아이콘과 텍스트 간 간격
                Text(
                  username.isEmpty ? 'Loading...' : username, // 로딩 중일 때는 'Loading...' 표시
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // 오른쪽: 좋아요, 댓글, 공유 버튼
            Padding(
              padding: const EdgeInsets.only(right: 10.0), // 오른쪽 여백 추가
              child: Row(
                children: [
                  GestureDetector(
                    onTap: toggleLike,
                    child: Image.asset(
                      isLiked ? 'assets/vicon.png' : 'assets/vicon_grey.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: 4), // 좋아요 아이콘과 숫자 간 간격
                  Text('${widget.like}'), // 좋아요 수
                  SizedBox(width: 10), // 좋아요와 댓글 아이콘 간 간격
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('post')
                        .doc(widget.postId)
                        .collection('comments')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int commentCount = 0;
                      if (snapshot.hasData) {
                        commentCount = snapshot.data!.docs.length;
                      }
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CommentPage(postId: widget.postId),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline),
                            SizedBox(width: 4), // 아이콘과 숫자 간 간격
                            Text('$commentCount'), // 댓글 수 표시
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      print('공유 버튼 클릭');
                    },
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 2), // 버튼과 텍스트 간 간격
                        Text(
                          '4', // 텍스트 추가
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 10), // 프로필과 이미지 간 간격
        // 게시물 이미지
        Image.network(widget.imagePath),
        SizedBox(height: 5), // 이미지와 장소 태그 간 간격
        // 장소 태그
        Row(
          children: [
            Icon(
              Icons.place, // Flutter에서 제공하는 장소 아이콘
              color: Colors.grey, // 아이콘 색상
              size: 16, // 아이콘 크기
            ),
            SizedBox(width: 5),
            Text(
              widget.place, // place 필드 값 표시
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 10), // 장소 태그와 게시물 내용 간 간격
        // 게시물 내용
        Text(
          widget.content, // Firestore에서 받아온 content 표시
          style: TextStyle(fontSize: 14), // 원하는 스타일 설정
        ),
        SizedBox(height: 10), // content와 버튼 행 간 간격
        // 게시물 경계선 추가
        Divider(
          color: Colors.grey.shade300,
          thickness: 1,
          height: 20, // 위젯 간 간격 설정
        ),
      ],
    );
  }


}

class CommentPage extends StatelessWidget {
  final String postId;

  CommentPage({required this.postId});

  @override
  Widget build(BuildContext context) {
    final TextEditingController commentController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser; // 현재 로그인된 사용자

    Future<String> fetchUserName(String userId) async {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        return userDoc['name'] ?? '익명';
      } catch (e) {
        print('Error fetching username: $e');
        return '익명';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '댓글',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white, // AppBar 배경색 흰색으로 설정
        elevation: 0, // AppBar 그림자 제거 (선택 사항)
        iconTheme: IconThemeData(color: Colors.black), // 아이콘 색상 설정
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('post')
                  .doc(postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true) // 최신 댓글 우선
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return FutureBuilder<String>(
                      future: fetchUserName(comment['userID']),
                      builder: (context, nameSnapshot) {
                        final username = nameSnapshot.data ?? '익명';
                        return Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                child: Icon(Icons.person,), // 프로필 아이콘
                                backgroundColor: Colors.grey.shade300, // 프로필 아이콘 배경색
                              ),
                              title: Text(username), // 작성자 이름
                              subtitle: Text(comment['comment']), // 댓글 내용
                            ),
                            Divider(
                              color: Colors.grey.shade300, // 경계선 색상
                              thickness: 1, // 경계선 두께
                              height: 1, // 경계선 높이
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      hintText: '댓글 입력...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // 내부 여백 조정
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () async {
                    final comment = commentController.text.trim();
                    if (comment.isNotEmpty && user != null) {
                      try {
                        final userDoc = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get();

                        final username = userDoc['name'] ?? '익명';

                        // Firestore에 댓글 저장
                        await FirebaseFirestore.instance
                            .collection('post')
                            .doc(postId)
                            .collection('comments')
                            .add({
                          'userID': user.uid, // 로그인된 사용자의 ID
                          'username': username, // Firestore에서 가져온 사용자 이름
                          'comment': comment, // 댓글 내용
                          'timestamp': FieldValue.serverTimestamp(), // 작성 시간
                        });
                        commentController.clear(); // 입력 필드 초기화
                      } catch (e) {
                        print('Error adding comment: $e');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

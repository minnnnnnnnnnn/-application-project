import 'package:first/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'notice_screen.dart';
import 'fix_profile_screen.dart';
import 'login_screen.dart';
import 'sns_screen.dart';
import 'friend_screen.dart';
import 'profile_screen.dart';
import 'favorite_screen.dart';

void _showUserInfoDialog(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('로그인 정보'),
          content: Text('로그인된 사용자가 없습니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 다이얼로그 닫기
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
    return;
  }

  // Firestore에서 사용자 이름 가져오기
  String userName = '알 수 없음';
  try {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (userDoc.exists) {
      userName = userDoc['name'] ?? '알 수 없음';
    }
  } catch (e) {
    print('Error fetching user name: $e');
  }

  // 팝업창 표시
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('로그인 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, // 텍스트를 왼쪽으로 정렬
          children: [
            Text(
              '이름: $userName',
              textAlign: TextAlign.left, // 텍스트 왼쪽 정렬
            ),
            Text(
              '이메일: ${user.email ?? '알 수 없음'}',
              textAlign: TextAlign.left, // 텍스트 왼쪽 정렬
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
            },
            child: Text('확인'),
          ),
        ],
      );
    },
  );
}

void _showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('로그아웃'),
        content: Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
            },
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 다이얼로그 닫기
              await FirebaseAuth.instance.signOut(); // 로그아웃 처리
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()), // 로그인 화면으로 이동
              );
            },
            child: Text('예'),
          ),
        ],
      );
    },
  );
}

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String userName = 'Loading...'; // 초기값 설정
  int postCount = 0; // 게시물 수 초기값
  int friendCount = 0;
  String? profileImageUrl;
  User? currentUser; // FirebaseAuth의 현재 사용자 저장

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchUserData(); // Firestore에서 사용자 이름과 게시물 수 가져오기
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          userName = '로그인 정보 없음';
        });
        return;
      }

      // Firestore에서 users 컬렉션의 name 필드 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // 현재 사용자의 userID로 문서 참조
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name']; // name 필드 값을 가져와 설정
          profileImageUrl = userDoc['profile']; // 프로필 이미지 경로 설정
        });
      } else {
        setState(() {
          userName = '사용자 정보 없음';
        });
      }

      // 친구 수 가져오기
      friendCount = (userDoc['friends'] as List<dynamic>?)?.length ?? 0;
      // Firestore에서 현재 사용자의 게시물 수 가져오기
      final postsQuery = await FirebaseFirestore.instance
          .collection('post') // 게시물 컬렉션 이름
          .where('userID', isEqualTo: user.uid) // userId가 현재 사용자와 같은 게시물 필터링
          .get();

      setState(() {
        postCount = postsQuery.docs.length; // 게시물 수 설정
      });
    } catch (e) {
      print('Error fetching user name: $e');
      setState(() {
        userName = '오류 발생';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // 현재 사용자 가져오기

    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경색
      appBar: AppBar(
        title: const Text(
          '내 정보 관리',
          style: TextStyle(
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // 수평 가운데 정렬
            children: [
              GestureDetector(
                onTap: () {
                  if(currentUser != null){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FixProfilePage(userID: currentUser!.uid), // fix_profile 페이지로 이동
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('로그인된 사용자가 없습니다.')),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? NetworkImage(profileImageUrl!)
                      : null,
                  child: profileImageUrl == null || profileImageUrl!.isEmpty
                      ? Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 16), // 이미지와 이름 간 간격
              // 사용자 이름
              Text(
                userName.isNotEmpty ? '$userName 님' : '로그인 정보 없음',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(userId: user.uid),
                            ),
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Text(
                            postCount.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '내 게시물',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FriendsPage(userId: user.uid),
                            ),
                          );
                        }
                      },
                      child: Column(
                        children: [
                          Text(
                            friendCount.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '친구',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              _buildListTile(
                '로그인 정보',
                Icons.chevron_right,
                onTap: () {
                  _showUserInfoDialog(context);
                },
              ),
              _buildListTile(
                '로그아웃',
                Icons.chevron_right,
                onTap: () {
                  _showLogoutDialog(context); // 로그아웃 다이얼로그 호출
                },
              ),
              const Divider(),
              _buildListTile('공지사항',
                  Icons.chevron_right,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoticePage(),
                      ),
                    );
                  }),
              _buildListTile('고객센터', Icons.chevron_right, onTap: () {}),
              _buildListTile('알림설정', Icons.chevron_right, onTap: () {}),
              _buildListTile('1:1 문의', Icons.chevron_right, onTap: () {}),
              _buildListTile(
                '탈퇴하기 ㅠ',
                Icons.chevron_right,
                onTap: () {},
                textStyle: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
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
            ),
            label: '부이',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내정보',
          ),
        ],
        currentIndex: 3,
        selectedItemColor: Color(0xFF001A72),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SNSHomePage()),
            );
          }
          else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FavoritesPage()),
            );
          }
          else if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
          print('선택된 탭: $index');
        },
      ),
    );
  }


  Widget _buildInfoItem(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon,
      {VoidCallback? onTap, TextStyle? textStyle}) {
    return ListTile(
      title: Text(
        title,
        style: textStyle ?? const TextStyle(fontSize: 16),
      ),
      trailing: Icon(icon),
      onTap: onTap,
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_find_screen.dart';

import 'home_screen.dart';
import 'sns_screen.dart';
import 'mypage_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color navyColor = Color(0xFF001A72); // 남색 컬러 정의

  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication 인스턴스
  final TextEditingController _emailController = TextEditingController(); // 이메일 입력 필드
  final TextEditingController _passwordController = TextEditingController(); // 비밀번호 입력 필드

  Future<void> _login() async {
    try {
      // Firebase 로그인 요청
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 로그인 성공 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 성공! 환영합니다 ${userCredential.user?.email}')),
      );

      // 성공 시 home_screen으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );

      // Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 배경색 흰색
      body: SingleChildScrollView( // 스크롤 가능하도록 설정
        child: Container(
          height: MediaQuery.of(context).size.height, // 화면 전체 높이 설정
          padding: const EdgeInsets.fromLTRB(20.0, 180.0, 20.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 가로 방향으로 요소 확장
            children: [
              // Title Section
              Column(
                children: [
                  Text(
                    '부산의',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: navyColor, // 남색
                    ),
                  ),
                  Text(
                    '이곳저곳',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // 검정색
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30), // 제목과 입력 필드 간격

              // Email Input
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: '아이디 (이메일)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0), // 둥근 모서리
                    borderSide: BorderSide(color: navyColor, width: 2), // 남색 테두리
                  ),
                ),
              ),
              SizedBox(height: 15), // 입력 필드 간격

              // Password Input
              TextField(
                controller: _passwordController,
                obscureText: true, // 비밀번호 숨김 처리
                decoration: InputDecoration(
                  hintText: '비밀번호',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25.0), // 둥근 모서리
                    borderSide: BorderSide(color: navyColor, width: 2), // 남색 테두리
                  ),
                ),
              ),
              SizedBox(height: 20), // 입력 필드와 버튼 간격

              // Login Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyColor, // 남색 배경
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0), // 둥근 모서리
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.0), // 버튼 높이 조정
                ),
                onPressed: _login, // 로그인 함수 호출
                child: Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // 흰색 텍스트
                  ),
                ),
              ),
              SizedBox(height: 10), // 로그인 버튼과 아이디/비밀번호 찾기 간격

              // Forgot Password
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    print('비밀번호를 잊어버리셨나요? 클릭됨');
                    // login_find_screen.dart로 이동
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => LoginFindScreen(),
                      ),
                    );
                  },
                  child: Text(
                    '비밀번호를 잊어버리셨나요?',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              Spacer(), // 남은 공간을 차지하여 아래의 위젯을 화면 하단으로 밀어냄

              // Register Link
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup'); // '/signup' 경로로 이동
                  },
                  child: Text(
                    '회원이 아니신가요?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black, // 텍스트 색상
                      decoration: TextDecoration.underline, // 밑줄 추가
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

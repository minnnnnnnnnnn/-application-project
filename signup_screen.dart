import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Authentication 패키지
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final Color navyColor = Color(0xFF001A72); // 남색 컬러 정의

  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Authentication 인스턴스
  final TextEditingController _nameController = TextEditingController(); // 이름 입력 필드
  final TextEditingController _emailController = TextEditingController(); // 이메일 입력 필드
  final TextEditingController _passwordController = TextEditingController(); // 비밀번호 입력 필드
  final TextEditingController _confirmPasswordController = TextEditingController(); // 비밀번호 확인 필드

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      // 비밀번호와 확인 비밀번호가 일치하지 않을 때
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    try {
      // Firebase 회원가입 요청
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),

      );

      // Firestore에 사용자 정보 저장
      String uid = userCredential.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(), // 입력받은 이름 저장
        'email': _emailController.text.trim(), // 이메일 저장
        'createdAt': FieldValue.serverTimestamp(), // 가입 시간 저장
        'favorite': [], // 빈 배열로 초기화
        'friends': [], // 빈 배열로 초기화
        'profile': [], // 빈 배열로 초기화

      });

      // 회원가입 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입이 완료되었습니다!')),
      );

      // 회원가입 완료 후 이전 화면으로 이동
      await Future.delayed(Duration(seconds: 2)); // 2초 지연
      Navigator.pop(context);
    } catch (e) {
      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // 키보드에 의한 화면 조정 활성화
      backgroundColor: Colors.white, // 배경색 흰색
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 150.0, 20.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 가로 방향으로 요소 확장
            children: [
              // Title Section
              Center(
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: navyColor, // 남색
                  ),
                ),
              ),
              SizedBox(height: 30), // 제목과 입력 필드 간격

              // Username Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이름',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: navyColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              // Email Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이메일',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: navyColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              // Password Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비밀번호',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: navyColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),

              // Confirm Password Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비밀번호 확인',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: navyColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Sign Up Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: navyColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                ),
                onPressed: _signUp,
                child: Text(
                  '가입하기',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Already have an account
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context); // 이전 화면으로 이동
                  },
                  child: Text(
                    '이미 계정이 있으신가요? 로그인',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
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

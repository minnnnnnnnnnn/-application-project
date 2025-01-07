import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io'; // File 클래스를 사용하기 위해 import

class FixProfilePage extends StatefulWidget {
  final String userID; // userID를 받는 변수

  const FixProfilePage({Key? key, required this.userID}) : super(key: key);


  @override
  _FixProfilePageState createState() => _FixProfilePageState();
}

class _FixProfilePageState extends State<FixProfilePage> {

  @override
  void initState() {
    super.initState();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc['profile'] != null) {
          setState(() {
            _uploadedImageUrl = userDoc.data()?['profile'];
          });
        }
      } catch (e) {
        print('Error fetching profile data: $e');
      }
    }
  }

  final TextEditingController _nameController = TextEditingController(); // 사용자 이름 수정 컨트롤러
  final ImagePicker _picker = ImagePicker(); // 이미지 선택기
  String? _profileImagePath; // 프로필 이미지 경로
  String? _uploadedImageUrl; // Firebase Storage에 업로드된 이미지 URL

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImagePath = pickedFile.path; // 선택된 이미지 경로 저장
      });
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_profileImagePath == null) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final file = File(_profileImagePath!);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${user.uid}.jpg');

        // Firebase Storage에 이미지 업로드
        await storageRef.putFile(file);

        // 업로드한 이미지의 URL 가져오기
        final imageUrl = await storageRef.getDownloadURL();

        setState(() {
          _uploadedImageUrl = imageUrl; // 이미지 URL 저장
        });

        // Firestore에 프로필 이미지 URL 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profile': imageUrl});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필 사진이 저장되었습니다.')),
        );
      }
    } catch (e) {
      print('Error uploading profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 사진 업로드 중 오류가 발생했습니다.')),
      );
    }
  }

  void _saveProfile() async {
    String updatedName = _nameController.text.trim();
    // 프로필 저장 로직 추가 가능 (예: 서버 업데이트)
    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사용자 이름을 입력해주세요.')),
      );
      return;
    }
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Firestore에 사용자 이름 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid) // 현재 사용자의 UID를 사용
            .update({'name': updatedName});

        // 프로필 이미지 업로드 호출
        await _uploadProfileImage();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('프로필이 저장되었습니다.')),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('프로필 저장 중 오류가 발생했습니다.')),
      );
    }

    Navigator.pop(context); // 수정 완료 후 이전 페이지로 돌아가기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("프로필 수정"),
        backgroundColor: Colors.white, // AppBar 배경색 흰색
        foregroundColor: Colors.black, // AppBar 텍스트 색상 검정
        elevation: 0,
      ),
      backgroundColor: Colors.white, // Scaffold 배경색 흰색
      body: Container(
        color: Colors.white, // 전체 배경색 흰색
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => _buildImageSourceSelector(),
                  );
                },
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Color(0xFF001A72),
                  backgroundImage: _profileImagePath != null
                    ? FileImage(File(_profileImagePath!))
                      : (_uploadedImageUrl != null
                      ? NetworkImage(_uploadedImageUrl!) as ImageProvider
                      : null),
                  child: _profileImagePath == null && _uploadedImageUrl == null
                      ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      )
                      : null,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "사용자 이름 변경하기",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text("저장"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF001A72),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceSelector() {
    return SafeArea(
      child: Container(
        color: Colors.white, // 모달 배경 흰색
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo),
              title: Text("갤러리에서 선택"),
              onTap: () {
                Navigator.pop(context); // 모달 닫기
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text("카메라로 촬영"),
              onTap: () {
                Navigator.pop(context); // 모달 닫기
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }
}

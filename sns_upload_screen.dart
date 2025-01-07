import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool isImageSelected = false;
  String? selectedPlace; // 선택된 장소

  // Firestore 및 Storage 참조
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<void> _requestPermission() async {
    PermissionStatus status = await Permission.camera.request();
    if (!status.isGranted) return;
    status = await Permission.photos.request();
    if (!status.isGranted) return;
  }

  Future<void> _pickImage(ImageSource source) async {
    await _requestPermission();
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        isImageSelected = true;
      });
    }
  }

  // Firebase Storage에 이미지 업로드
  Future<String?> _uploadImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('uploads/$fileName');
      UploadTask uploadTask = ref.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL(); // 업로드된 이미지 URL
    } catch (e) {
      print("이미지 업로드 오류: $e");
      return null;
    }
  }

  // Firestore에 데이터 저장
  Future<void> _uploadData() async {
    String content = _contentController.text;

    if (content.isEmpty || _image == null || selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모든 정보를 입력해주세요')),
      );
      return;
    }

    // 이미지 업로드
    String? imageUrl = await _uploadImage(_image!);
    if (imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 업로드 실패')),
      );
      return;
    }

    // Firestore에 데이터 저장
    await _firestore.collection('post').add({
      'userID': FirebaseAuth.instance.currentUser?.uid, // 실제 사용자 ID를 여기로 추가
      'content': content,
      'place': selectedPlace,
      'imagePath': imageUrl,
      'like': 0, // 초기 좋아요 수
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('업로드 완료!')),
    );
    Navigator.pop(context);
  }

  void _showPlaceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('부이 추가하기'),
          content: TextField(
            controller: _placeController,
            decoration: InputDecoration(hintText: '장소를 입력하세요'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                String place = _placeController.text.trim();
                if (place.isNotEmpty) {
                  setState(() {
                    selectedPlace = place;
                  });
                  _placeController.clear();
                }
                Navigator.pop(context);
              },
              child: Text('추가'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _removePlace() {
    setState(() {
      selectedPlace = null; // 장소 삭제
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF001A72),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _uploadData,
            child: Text(
              '업로드',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(50, 40),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(Icons.photo_library, size: 24),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(50, 40),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(Icons.camera_alt, size: 24),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: '내용을 입력하세요.',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              if (isImageSelected)
                Image.file(
                  _image!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 10),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add, size: 30),
                    onPressed: _showPlaceDialog,
                  ),
                  Text('부이 추가하기'),
                ],
              ),
              if (selectedPlace != null)
                Row(
                  children: [
                    Image.asset('assets/vicon.png', width: 24, height: 24),
                    SizedBox(width: 8),
                    Text(selectedPlace!, style: TextStyle(fontSize: 16)),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: _removePlace,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

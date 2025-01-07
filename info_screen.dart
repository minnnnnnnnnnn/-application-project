import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InfoScreen extends StatefulWidget {
  final String title;
  final String address;
  final String imagePath;
  final bool parkingAvailable;

  const InfoScreen({
    Key? key,
    required this.title,
    required this.address,
    required this.imagePath,
    required this.parkingAvailable,
  }) : super(key: key);

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  late bool isFavorited;

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final Color navyColor = Color(0xFF001A72);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "가게정보",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: navyColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.width * 0.6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: widget.imagePath.startsWith('http')
                          ? Image.network(
                        widget.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text('이미지를 불러올 수 없습니다'),
                          );
                        },
                      )
                          : Image.asset(
                        widget.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text('이미지를 불러올 수 없습니다'),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.width * 0.53,
                    right: 20,
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data == null) {
                          return CircularProgressIndicator(); // 로딩 중 상태
                        }

                        // 찜 여부 확인
                        final List<String> favorites =
                        List<String>.from((snapshot.data!.data() as Map<String, dynamic>)['favorite'] ?? []);
                        final bool isFavorited = favorites.contains(widget.title);

                        return GestureDetector(
                          onTap: () async {
                            if (userId != null) {
                              final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
                              if (isFavorited) {
                                await userDoc.update({
                                  'favorite': FieldValue.arrayRemove([widget.title]),
                                });
                              } else {
                                await userDoc.update({
                                  'favorite': FieldValue.arrayUnion([widget.title]),
                                });
                              }
                            }
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                isFavorited ? 'assets/vicon.png' : 'assets/vicon_grey.png',
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),
              Text(
                widget.title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.location_on, color: navyColor),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      widget.address,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildInfoRow(Icons.access_time, "영업중 * 22:30에 라스트 오더", navyColor),
              SizedBox(height: 20),
              _buildInfoRow(
                Icons.local_parking,
                widget.parkingAvailable ? "주차 가능" : "주차 불가능",
                navyColor,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, color: iconColor),
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }
}

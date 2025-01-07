import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'info_screen.dart';
import 'home_screen.dart';
import 'sns_screen.dart';
import 'mypage_screen.dart';

Future<String> getDownloadURL(String imagePath) async {
  if (imagePath == null || imagePath.isEmpty) return '';
  try {
    // "gs://" 경로에서 실제 경로 추출
    if (imagePath.startsWith('gs://')) {
      final bucketIndex = imagePath.indexOf('/', 5);
      imagePath = imagePath.substring(bucketIndex + 1);
    }
    final ref = FirebaseStorage.instance.ref(imagePath);
    return await ref.getDownloadURL();
  } catch (e) {
    print('Firebase Storage URL 가져오기 실패: $e');
    return '';
  }
}

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> favoritePlaces = [];
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    fetchFavoritePlaces();
  }

  Future<void> fetchFavoritePlaces() async {
    if (userId == null) return;

    try {
      // 사용자 문서에서 찜한 장소 목록 가져오기
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final List<String> favoriteIds = List<String>.from(userDoc.data()?['favorite'] ?? []);

      final List<String> categories = ['cafe', 'restaurant', 'observatory', 'selectShop'];
      final List<Map<String, dynamic>> tempPlaces = [];

      // 각 카테고리를 순회하며 찜한 장소 검색
      for (String category in categories) {
        for (String id in favoriteIds) {
          final doc = await FirebaseFirestore.instance.collection(category).doc(id).get();
          if (doc.exists) {
            final data = doc.data()!;
            final String rawImagePath = data['imagePath'] ?? '';
            final String imageUrl = rawImagePath.startsWith('gs://')
                ? await getDownloadURL(rawImagePath)
                : rawImagePath;

            tempPlaces.add({
              'id': id,
              'imagePath': imageUrl, // 변환된 URL 사용
              '주소': data['주소'] ?? '주소 정보 없음',
              '주차장': data['주차장'] ?? false,
            });
          }
        }
      }

      setState(() {
        favoritePlaces = tempPlaces;
      });
    } catch (e) {
      print('찜한 장소 가져오기 실패: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('찜 목록', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: favoritePlaces.isEmpty
          ? Center(child: Text('찜한 장소가 없습니다.'))
          : GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        padding: EdgeInsets.all(10),
        children: favoritePlaces.map((place) {
          return _buildPlaceCard(
            context,
            place['id']?.toString() ?? 'unknown_id', // id
            place['imagePath']?.toString() ?? '', // imagePath
            place['주소']?.toString() ?? '주소 정보 없음', // address
            place['주차장'] == true, // parkingAvailable
            place['isFavorited'] == true, // isFavorited
            FirebaseAuth.instance.currentUser?.uid, // userId
          );
        }).toList(),
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
            icon: Image.asset('assets/vicon.png', width: 24, height: 24),
            label: '부이',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내정보',
          ),
        ],
        currentIndex: 2,
        selectedItemColor: Color(0xFF001A72),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          }
          else if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SNSHomePage()));
          }
          else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyPageScreen()));
          }
        },
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, String id, String imagePath, String address, bool parkingAvailable,
      bool isFavorited, String? userId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InfoScreen(
              title: id,
              address: address,
              imagePath: imagePath,
              parkingAvailable: parkingAvailable,
            ),
          ),
        ).then((_) {
          fetchFavoritePlaces();
        });
      },
      child: Card(
        color: Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                    child: imagePath.isNotEmpty
                        ? Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(child: Text('이미지를 불러올 수 없습니다.'));
                      },
                    )
                        : Center(child: Text('이미지가 없습니다.')),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        id,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        address,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  if (userId != null) {
                    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
                    if (isFavorited) {
                      // 찜 해제
                      await userDoc.update({
                        'favorite': FieldValue.arrayRemove([id]),
                      });
                    } else {
                      // 찜 추가
                      await userDoc.update({
                        'favorite': FieldValue.arrayUnion([id]),
                      });
                    }
                    // Firestore 업데이트 후 UI 갱신
                    setState(() {
                      isFavorited = !isFavorited;
                    });
                  }
                },
                child: Image.asset(
                  'assets/vicon.png',
                  width: 30,
                  height: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

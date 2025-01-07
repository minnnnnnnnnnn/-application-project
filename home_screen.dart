import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'sns_screen.dart';
import 'mypage_screen.dart';
import 'info_screen.dart';
import 'favorite_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

Future<String> getDownloadURL(String imagePath) async {
  if (imagePath == null || imagePath.isEmpty) return '';
  try {
    if (imagePath.startsWith('gs://')) {
      final bucketIndex = imagePath.indexOf('/', 5);
      imagePath = imagePath.substring(bucketIndex + 1);
    }
    final encodedPath = Uri.encodeFull(imagePath);
    final ref = FirebaseStorage.instance.ref(encodedPath);
    return await ref.getDownloadURL();
  } catch (e) {
    print('Firebase Storage URL 가져오기 실패: $e');
    return '';
  }
}

class _HomeScreenState extends State<HomeScreen> {
  final Color navyColor = Color(0xFF001A72);
  String selectedCategory = 'cafe';
  String selectedRegion = '가야동';
  String searchQuery = '';
  List<Map<String, dynamic>> places = [];
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

  @override
  void initState() {
    super.initState();
    fetchPlaces();

    // 스크롤 상태 감지
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = true;
        });
      } else if (_scrollController.offset <= 200 && _showScrollToTopButton) {
        setState(() {
          _showScrollToTopButton = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchPlaces() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('사용자 ID를 찾을 수 없습니다.');
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final List<String> favorites = List<String>.from(userDoc.data()?['favorite'] ?? []);

      final snapshot = await FirebaseFirestore.instance
          .collection(selectedCategory)
          .where('지역', isEqualTo: selectedRegion) // 선택된 지역 필터링
          .get();
      final List<Map<String, dynamic>> tempPlaces = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String id = doc.id;

        // 검색어가 포함된 문서만 필터링
        if (searchQuery.isEmpty || id.toLowerCase().contains(searchQuery.toLowerCase())) {
          final String imagePath = (data['imagePath'] as String?) ?? '';
          final String address = (data['주소'] as String?) ?? '주소 정보 없음';
          final bool parking = (data['주차장'] as bool?) ?? false;

          tempPlaces.add({
            'id': id,
            'imagePath': imagePath.isNotEmpty
                ? await getDownloadURL(imagePath)
                : '',
            '주소': address,
            '주차장': parking,
            'isFavorited': favorites.contains(id),
          });
        }
      }

      setState(() {
        places = tempPlaces;
      });
    } catch (e) {
      print('Firestore 데이터 가져오기 실패: $e');
    }
  }

  Future<List<String>> fetchRegions() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(selectedCategory).get();
      final Set<String> regions = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String? region = data['지역'] as String?;
        if (region != null) {
          regions.add(region);
        }
      }

      return regions.toList();
    } catch (e) {
      print('Firestore 지역 데이터 가져오기 실패: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController, // 스크롤 컨트롤러 추가
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30),
                  Row(
                    children: [
                      Image.asset('assets/vicon.png', width: 30, height: 30),
                      SizedBox(width: 8),
                      Text(
                        '부이',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value; // 검색어 업데이트
                              });
                              fetchPlaces(); // 검색어 변경 시 데이터 갱신
                            },
                            decoration: InputDecoration(
                              hintText: '이곳저곳 찾아보기',
                              prefixIcon: Icon(Icons.search, color: navyColor),
                              fillColor: Colors.white,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Colors.black,
                                  width: 2.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () async {
                          final regions = await fetchRegions();
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return ListView(
                                  children: regions.map((region) {
                                    return ListTile(
                                      title: Text(region),
                                      onTap: () {
                                        setState(() {
                                          selectedRegion = region;
                                        });
                                        fetchPlaces();
                                        Navigator.pop(context);
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedRegion,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 1),
                            Icon(
                              Icons.expand_more,
                              size: 30,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          print('더보기 버튼 클릭됨');
                        },
                        icon: Icon(Icons.menu, size: 35, color: Colors.black),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryButton('카페', 'cafe'),
                              _buildCategoryButton('음식점', 'restaurant'),
                              _buildCategoryButton('전망대', 'observatory'),
                              _buildCategoryButton('소품샵', 'selectShop'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || userSnapshot.data == null) {
                        return Center(child: CircularProgressIndicator());
                      }

                      final favoriteIds = List<String>.from(
                        (userSnapshot.data!.data() as Map<String, dynamic>)['favorite'] ?? [],
                      );

                      return GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        children: places.map((place) {
                          final bool isFavorited = favoriteIds.contains(place['id']);
                          return _buildPlaceCard(
                            context,
                            place['id'],
                            place['imagePath'],
                            place['주소'],
                            place['주차장'],
                            isFavorited,
                            userId,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_showScrollToTopButton)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: () {
                  _scrollController.animateTo(
                    0, // 맨 위로 이동
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                backgroundColor: navyColor,
                child: Icon(Icons.arrow_upward, color: Colors.white),
              ),
            ),
        ],
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
            icon: Image.asset('assets/vicon_grey.png', width: 24, height: 24),
            label: '부이',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내정보',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: navyColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SNSHomePage()));
          }
          else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FavoritesPage()));
          }
          else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MyPageScreen()));
          }
        },
      ),
    );
  }

  Widget _buildCategoryButton(String title, String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            selectedCategory = category;
          });
          fetchPlaces();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.black),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
        ),
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
        );
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
                        : Center(child: Text('이미지를 불러올 수 없습니다.')),
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
                      await userDoc.update({
                        'favorite': FieldValue.arrayRemove([id]),
                      });
                    } else {
                      await userDoc.update({
                        'favorite': FieldValue.arrayUnion([id]),
                      });
                    }
                  }
                },
                child: Image.asset(
                  isFavorited ? 'assets/vicon.png' : 'assets/vicon_grey.png',
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

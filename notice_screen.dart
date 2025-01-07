import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 상태바 스타일 변경을 위한 패키지

class NoticeApp extends StatelessWidget {
  NoticeApp() {
    // 상태바 배경색 설정
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.white, // 상태바 배경색 흰색
        statusBarIconBrightness: Brightness.light, // 상태바 아이콘 색상 어두운 색
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notice Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: NoticePage(),
    );
  }
}

class NoticePage extends StatefulWidget {
  @override
  _NoticePageState createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  final List<Map<String, dynamic>> notices = [
    {'title': '서버 점검 안내', 'content': '서버 점검이 12월 15일 00시부터 06시까지 진행될 예정입니다.', 'isNew': true},
    {'title': '앱 업데이트', 'content': '앱 업데이트 버전 1.2.0이 출시되었습니다. 새로운 기능을 확인하세요.', 'isNew': true},
    {'title': '연말 이벤트', 'content': '연말 이벤트가 시작되었습니다! 많은 참여 부탁드립니다.', 'isNew': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '공지사항',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF001A72),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Container(
        color: Color(0xFFF5F5F5), // 배경색을 약간 회색으로 설정
        child: ListView.builder(
          itemCount: notices.length,
          itemBuilder: (context, index) {
            return Card(
              color: Colors.white,
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                leading: Icon(
                  Icons.announcement,
                  color: notices[index]['isNew'] ? Colors.red : Colors.grey,
                ),
                title: Row(
                  children: [
                    Text(notices[index]['title']!),
                    if (notices[index]['isNew'])
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'NEW!',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(notices[index]['content']!),
                onTap: () {
                  setState(() {
                    notices[index]['isNew'] = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoticeDetailPage(
                        title: notices[index]['title']!,
                        content: notices[index]['content']!,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class NoticeDetailPage extends StatelessWidget {
  final String title;
  final String content;

  NoticeDetailPage({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF001A72),
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(content),
      ),
      backgroundColor: Colors.white,
    );
  }
}

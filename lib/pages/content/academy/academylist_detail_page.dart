import 'package:flutter/material.dart';
import 'package:searcademy/services/academy_service.dart';
import 'package:searcademy/services/firebase_service.dart';

class AcademylistDetailPage extends StatefulWidget {
  final String academyId;

  const AcademylistDetailPage({super.key, required this.academyId});

  @override
  State<AcademylistDetailPage> createState() => _AcademyListDetailPageState();
}

class _AcademyListDetailPageState extends State<AcademylistDetailPage> {
  late Future<Map<String, dynamic>?> academyData;

  @override
  void initState() {
    super.initState();
    academyData = loadAcademyDetailData(widget.academyId);
    // Analytics 화면 뷰 로깅
    _logAnalytics(); // 비동기 함수는 따로 처리
    print("Anaytics: AcademylistDetailPage");
  }

  Future<void> _logAnalytics() async {
    await FirebaseService.logScreenView(screenName: 'AcademylistDetailPage');
    print("Analytics: AcademylistDetailPage");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('학원 상세 정보'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: academyData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('데이터 로드 실패'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('학원을 찾을 수 없습니다.'));
          } else {
            final academy = snapshot.data!;
            return ListView(
              children: [
                ListTile(
                  title: Text("학원명: ${academy['학원명'] ?? '알 수 없음'}"),
                  subtitle: Text("학원교습소명: ${academy['학원교습소명'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("시도교육청명: ${academy['시도교육청명'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("행정구역명: ${academy['행정구역명'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text(
                      "학원지정번호: ${academy['학원지정번호']?.toString().trim() ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("개설일자: ${academy['개설일자'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("등록일자: ${academy['등록일자'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("등록상태명: ${academy['등록상태명'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("휴원시작일자: ${academy['휴원시작일자'].trim() ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("휴원종료일자: ${academy['휴원종료일자'].trim() ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("정원합계: ${academy['정원합계'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title:
                      Text("일시수용능력인원합계: ${academy['일시수용능력인원합계'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("분야명: ${academy['분야명'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("교습계열명: ${academy['교습계열명'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("교습과정목록명: ${academy['교습과정목록명'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("교습과정명: ${academy['교습과정명'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("인당수강료: ${academy['인당수강료'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("수강료공개여부: ${academy['수강료공개여부'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("기숙사학원여부: ${academy['기숙사학원여부'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("도로명주소: ${academy['도로명주소'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("도로명상세주소: ${academy['도로명상세주소'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("도로명우편번호: ${academy['도로명우편번호'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("전화번호: ${academy['전화번호'] ?? '정보 없음'}"),
                ),
                ListTile(
                  title: Text("수정일자: ${academy['수정일자'] ?? '정보 없음'}"),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

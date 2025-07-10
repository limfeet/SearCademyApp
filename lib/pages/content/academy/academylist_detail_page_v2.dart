import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AcademyDetailPageV2 extends StatefulWidget {
  final String baseId;
  final String academyId;

  const AcademyDetailPageV2({
    super.key, 
    required this.baseId, 
    required this.academyId
  });

  @override
  State<AcademyDetailPageV2> createState() => _AcademyDetailPageV2State();
}

class _AcademyDetailPageV2State extends State<AcademyDetailPageV2> {
  Map<String, dynamic>? academyData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAcademyDetail();
  }

  Future<void> _loadAcademyDetail() async {
    try {
      final baseUrl = dotenv.env['ES_DETAIL_API_URL'] ?? 
                     'http://10.0.2.2:18181/academies';
      final apiKey = dotenv.env['API_KEY'];
      
      if (apiKey == null) {
        throw Exception('API_KEY가 설정되지 않았습니다.');
      }

      final url = '$baseUrl/${widget.baseId}/${widget.academyId}';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-api-key': apiKey,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          academyData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('상세 정보 로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(academyData?['ACA_NM'] ?? '학원 상세'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('오류가 발생했습니다'),
                      SizedBox(height: 8),
                      Text(errorMessage!, style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          _loadAcademyDetail();
                        },
                        child: Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 학원 기본 정보 카드
                      _buildInfoCard(
                        '기본 정보',
                        Icons.school,
                        [
                          _buildInfoRow('학원명', academyData!['ACA_NM']),
                          _buildInfoRow('주소', academyData!['FA_RDNMA']),
                          _buildInfoRow('학원번호', academyData!['ACA_ASNUM']),
                          _buildInfoRow('교육청코드', academyData!['ATPT_OFCDC_SC_CODE']),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // 위치 정보 카드
                      if (academyData!['location'] != null)
                        _buildLocationCard(),
                      
                      SizedBox(height: 16),
                      
                      // 과정 정보 카드
                      if (academyData!['subjects_info_list_1'] != null && 
                          academyData!['subjects_info_list_1'].isNotEmpty)
                        _buildSubjectsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '정보 없음',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = academyData!['location'];
    final coordinates = location['coordinates'];
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '위치 정보',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow('경도', coordinates[0].toStringAsFixed(6)),
            _buildInfoRow('위도', coordinates[1].toStringAsFixed(6)),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                // 지도 앱으로 이동하는 기능 추가 가능
              },
              icon: Icon(Icons.map),
              label: Text('지도에서 보기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsCard() {
    final subjects = academyData!['subjects_info_list_1'] as List;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.book, color: Colors.green[700]),
                SizedBox(width: 8),
                Text(
                  '교습 과정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...subjects.map((subject) => _buildSubjectItem(subject)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectItem(Map<String, dynamic> subject) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject['subject'] ?? '과정명 없음',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subject['price_time'] ?? '가격 정보 없음',
            style: TextStyle(
              color: Colors.blue[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subject['reg_date'] != null)
            Text(
              '등록일: ${subject['reg_date']}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
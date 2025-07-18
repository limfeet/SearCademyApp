import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:searcademy/services/api_client_service.dart';
import 'package:searcademy/utils/error_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AcademyDetailPageV2 extends StatefulWidget {
  final String baseId;
  final String academyId;

  const AcademyDetailPageV2(
      {super.key, required this.baseId, required this.academyId});

  @override
  State<AcademyDetailPageV2> createState() => _AcademyDetailPageV2State();
}

class _AcademyDetailPageV2State extends State<AcademyDetailPageV2> {
  final ApiClientService _apiClient = ApiClientService();

  Map<String, dynamic>? academyData;
  bool isLoading = true;
  String? errorMessage;
  bool showMap = false;

  @override
  void initState() {
    super.initState();
    _loadAcademyDetail();
  }

  Future<String> _getActiveApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('custom_api_enabled') ?? false;

    if (isEnabled) {
      final customUrl = prefs.getString('custom_api_url') ?? '';
      if (customUrl.isNotEmpty) {
        return customUrl;
      }
    }

    return dotenv.env['API_BASE_URL'] ?? dotenv.env['ES_DETAIL_API_URL'] ?? '';
  }

  Future<void> _loadAcademyDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final baseUrl = await _getActiveApiBaseUrl();
      if (baseUrl.isEmpty) {
        throw Exception('API 서버 URL이 설정되지 않았습니다.');
      }

      // 기존 방식과 새로운 방식 모두 지원
      String url;
      if (baseUrl.contains('/academies')) {
        // 기존 전체 URL 방식
        url = '$baseUrl/${widget.baseId}/${widget.academyId}';
      } else {
        // 새로운 베이스 URL 방식
        url = '$baseUrl/academies/${widget.baseId}/${widget.academyId}';
      }

      final response = await _apiClient.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          academyData = jsonData;
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

      if (mounted) {
        ErrorHandler.handleApiError(context, e);
      }
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
              ? _buildErrorWidget()
              : academyData == null
                  ? const Center(child: Text('데이터를 불러올 수 없습니다'))
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
                              _buildInfoRow(
                                  '교육청코드', academyData!['ATPT_OFCDC_SC_CODE']),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // 위치 정보 카드
                          if (_hasValidLocation()) _buildLocationCard(),

                          const SizedBox(height: 16),

                          // 과정 정보 카드
                          if (_hasValidSubjects()) _buildSubjectsCard(),

                          const SizedBox(height: 24),

                          // 공공데이터 고지사항
                          _buildDisclaimerCard(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('오류가 발생했습니다'),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAcademyDetail,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  bool _hasValidLocation() {
    return academyData!['location'] != null &&
        academyData!['location']['coordinates'] != null &&
        academyData!['location']['coordinates'].length >= 2;
  }

  bool _hasValidSubjects() {
    return academyData!['subjects_info_list_1'] != null &&
        academyData!['subjects_info_list_1'] is List &&
        (academyData!['subjects_info_list_1'] as List).isNotEmpty;
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
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
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
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = academyData!['location'];
    final coordinates = location['coordinates'];

    // 안전한 타입 변환
    double lat, lng;
    try {
      lat = (coordinates[1] as num).toDouble();
      lng = (coordinates[0] as num).toDouble();
    } catch (e) {
      return const SizedBox(); // 좌표 변환 실패 시 아무것도 표시하지 않음
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
            _buildInfoRow('경도', lng.toStringAsFixed(6)),
            _buildInfoRow('위도', lat.toStringAsFixed(6)),
            const SizedBox(height: 12),

            // 지도 표시 버튼 또는 실제 지도
            if (!showMap)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      showMap = true;
                    });
                  },
                  icon: const Icon(Icons.map),
                  label: const Text('지도 표시'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else
              Column(
                children: [
                  // 지도 숨기기 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            showMap = false;
                          });
                        },
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('지도 숨기기'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 실제 Google Maps
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(lat, lng),
                          zoom: 16.0,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('academy'),
                            position: LatLng(lat, lng),
                            infoWindow: InfoWindow(
                              title: academyData!['ACA_NM'] ?? '학원',
                              snippet: academyData!['FA_RDNMA'] ?? '주소 정보 없음',
                            ),
                          ),
                        },
                        mapType: MapType.normal,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        onMapCreated: (GoogleMapController controller) {
                          // 지도 생성 완료 시 추가 설정이 필요하면 여기에 작성
                        },
                      ),
                    ),
                  ),
                ],
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
                const SizedBox(width: 8),
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
            const SizedBox(height: 12),
            ...subjects.map((subject) => _buildSubjectItem(subject)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectItem(dynamic subject) {
    // 안전한 타입 체크
    if (subject is! Map<String, dynamic>) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subject['subject']?.toString() ?? '과정명 없음',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subject['price_time']?.toString() ?? '가격 정보 없음',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subject['reg_date'] != null)
            Text(
              '등록일: ${subject['reg_date']}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard() {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline,
                    color: Theme.of(context).colorScheme.secondary, size: 20),
                const SizedBox(width: 8),
                Text(
                  '정보 고지사항',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• 본 정보는 공공데이터포털에서 제공하는 데이터를 기반으로 합니다.\n'
              '• 실제 학원 정보와 다를 수 있으니 방문 전 해당 학원에 직접 확인하시기 바랍니다.\n'
              '• 수강료, 과정 내용 등은 변경될 수 있습니다.\n'
              '• 정확한 정보는 해당 학원에 문의해 주세요.',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/pages/content/setting/developer_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeveloperPage extends ConsumerStatefulWidget {
  const DeveloperPage({super.key});

  @override
  ConsumerState<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends ConsumerState<DeveloperPage> {
  bool _isCustomApiEnabled = false;
  String _customApiUrl = '';
  final _apiUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomApiSettings();
  }

  Future<void> _loadCustomApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('custom_api_enabled') ?? false;
    final customUrl = prefs.getString('custom_api_url') ?? '';

    setState(() {
      _isCustomApiEnabled = isEnabled;
      _customApiUrl = customUrl;
      _apiUrlController.text = customUrl;
    });
  }

  Future<void> _saveCustomApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('custom_api_enabled', _isCustomApiEnabled);
    await prefs.setString('custom_api_url', _customApiUrl);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 설정이 저장되었습니다.')),
      );
    }
  }

  Future<String> _getActiveApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('custom_api_enabled') ?? false;

    if (isEnabled) {
      final customUrl = prefs.getString('custom_api_url') ?? '';
      if (customUrl.isNotEmpty) {
        return customUrl;
      }
    }

    // .env에서 베이스 URL 가져오기
    return dotenv.env['API_BASE_URL'] ?? '설정되지 않음';
  }

  void _showApiUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API 서버 URL 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('사용할 API 서버 URL을 입력하세요:'),
            const SizedBox(height: 16),
            TextField(
              controller: _apiUrlController,
              decoration: const InputDecoration(
                labelText: 'API Server URL',
                hintText: 'https://api.example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '예시:\n• 개발: http://x.x.x.x:your-port\n• 운영: https://your-doamin',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customApiUrl = _apiUrlController.text;
              });
              Navigator.pop(context);
              _saveCustomApiSettings();
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개발자 페이지'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API 서버 설정
            const Text(
              '🔧 API 서버 설정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('수동 API 서버 지정'),
                    subtitle: Text(_isCustomApiEnabled ? '활성화됨' : '비활성화됨'),
                    value: _isCustomApiEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _isCustomApiEnabled = value;
                      });
                      _saveCustomApiSettings();
                    },
                  ),
                  if (_isCustomApiEnabled)
                    ListTile(
                      title: const Text('현재 API 서버'),
                      subtitle: Text(
                          _customApiUrl.isEmpty ? '설정되지 않음' : _customApiUrl),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _showApiUrlDialog,
                      ),
                    ),
                  if (_isCustomApiEnabled && _customApiUrl.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _showApiUrlDialog,
                        child: const Text('API 서버 URL 설정'),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 현재 사용 중인 API 정보
            FutureBuilder<String>(
              future: _getActiveApiUrl(),
              builder: (context, snapshot) {
                return Card(
                  child: ListTile(
                    title: const Text('현재 사용 중인 API'),
                    subtitle: Text(snapshot.data ?? '로딩 중...'),
                    leading: Icon(
                      _isCustomApiEnabled ? Icons.developer_mode : Icons.cloud,
                      color: _isCustomApiEnabled ? Colors.orange : Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:searcademy/services/academy_service.dart';

class AcademyListPage extends StatefulWidget {
  const AcademyListPage({super.key});

  @override
  State<AcademyListPage> createState() => _AcademyListPageState();
}

class _AcademyListPageState extends State<AcademyListPage> {
  late Future<List<Map<String, dynamic>>> _academyFuture;

  @override
  void initState() {
    super.initState();
    _academyFuture = loadAcademyData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('학원 리스트')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _academyFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final academy = data[index];
              return ListTile(
                title: Text(academy["학원명"] ?? "이름 없음"),
                subtitle: Text(academy["도로명주소"] ?? "주소 없음"),
              );
            },
          );
        },
      ),
    );
  }
}

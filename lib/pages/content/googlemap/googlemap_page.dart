import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapWithLocationInput extends StatefulWidget {
  const MapWithLocationInput({super.key}); // ✨ 이렇게 super 키워드만 남기기!

  @override
  State<MapWithLocationInput> createState() => _MapWithLocationInputState();
}

class _MapWithLocationInputState extends State<MapWithLocationInput> {
  late GoogleMapController _mapController;
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // 위치 권한 요청 + 현재 위치 받아오기
  Future<void> _initLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 켜져있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ 위치 서비스 꺼져있음');
      return;
    }

    // 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ 위치 권한 거부됨');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ 위치 권한 영구 거부됨');
      return;
    }

    // 현재 위치 받아오기
    Position pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });

    // 지도 이동
    _mapController.animateCamera(
      CameraUpdate.newLatLng(_currentPosition!),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text('Map + Location + Input')),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? LatLng(37.5665, 126.9780), // 서울 기본
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white.withValues(alpha: (0.8 * 255)),
              padding: EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Please enter a location....',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

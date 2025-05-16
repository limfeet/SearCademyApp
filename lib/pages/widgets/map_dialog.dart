import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:searcademy/services/geocoding_service.dart';

class LocationSettingDialog extends StatefulWidget {
  final void Function(LatLng latLng) onLocationSelected;

  const LocationSettingDialog({super.key, required this.onLocationSelected});

  @override
  State<LocationSettingDialog> createState() => _LocationSettingDialogState();
}

class _LocationSettingDialogState extends State<LocationSettingDialog> {
  LatLng? selectedLatLng;
  GoogleMapController? _mapController;

  final TextEditingController _addressController = TextEditingController();

  Future<Position?> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 서비스를 켜주세요!')),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치 권한이 필요합니다.')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해주세요.')),
      );
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return AlertDialog(
  //     title: Text('위치 설정'),
  //     content: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         ElevatedButton(
  //           onPressed: () async {
  //             final position = await _determinePosition(context); // ← 수정된 부분
  //             if (position != null) {
  //               final latLng = LatLng(position.latitude, position.longitude);
  //               setState(() {
  //                 selectedLatLng = latLng;
  //               });
  //               // 지도 이동!
  //               _mapController?.animateCamera(
  //                 CameraUpdate.newLatLng(latLng),
  //               );
  //             }
  //           },
  //           child: Text('현재 위치로 설정'),
  //         ),
  //         TextField(
  //           controller: _addressController,
  //           decoration: InputDecoration(hintText: '주소를 입력하세요'),
  //           onSubmitted: (value) async {
  //             // Geocoding으로 주소 → LatLng 변환
  //             final latLng = await geocodeAddress(value);
  //             setState(() {
  //               selectedLatLng = latLng;
  //             });
  //           },
  //         ),
  //         SizedBox(height: 8),
  //         SizedBox(
  //           width: double.infinity,
  //           height: 200,
  //           child: GoogleMap(
  //             initialCameraPosition: CameraPosition(
  //               target: selectedLatLng ?? LatLng(37.5665, 126.9780), // 서울 중심
  //               zoom: 14,
  //             ),
  //             onCameraMove: (position) {
  //               selectedLatLng = position.target;
  //             },
  //             onMapCreated: (controller) {
  //               _mapController = controller;
  //             },
  //             markers: {
  //               if (selectedLatLng != null)
  //                 Marker(
  //                     markerId: MarkerId('selected'),
  //                     position: selectedLatLng!),
  //             },
  //           ),
  //         )
  //       ],
  //     ),
  //     actions: [
  //       TextButton(
  //         onPressed: () => Navigator.pop(context),
  //         child: Text('취소'),
  //       ),
  //       TextButton(
  //         onPressed: () {
  //           if (selectedLatLng != null) {
  //             widget.onLocationSelected(selectedLatLng!);
  //           }
  //           Navigator.pop(context);
  //         },
  //         child: Text('확인'),
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.infinity,
        height: 500, // 전체 팝업 높이
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('위치 설정', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final position = await _determinePosition(context);
                if (position != null) {
                  final latLng = LatLng(position.latitude, position.longitude);
                  setState(() {
                    selectedLatLng = latLng;
                  });
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(latLng),
                  );
                }
              },
              child: const Text('현재 위치로 설정'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(hintText: '주소를 입력하세요'),
              onSubmitted: (value) async {
                //final latLng = await geocodeAddress(value);
                final LatLng? latLng =
                    await GeocodingService.geocodeAddress(value);

                if (latLng != null) {
                  print('주소 좌표: ${latLng.latitude}, ${latLng.longitude}');
                } else {
                  print('주소를 찾을 수 없습니다.');
                }

                if (latLng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주소를 찾을 수 없습니다.')),
                  );
                  return;
                }
                setState(() {
                  selectedLatLng = latLng;
                });
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(latLng),
                );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: selectedLatLng ?? const LatLng(37.5665, 126.9780),
                  zoom: 14,
                ),
                onCameraMove: (position) {
                  selectedLatLng = position.target;
                },
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: {
                  if (selectedLatLng != null)
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: selectedLatLng!,
                    ),
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedLatLng != null) {
                      widget.onLocationSelected(selectedLatLng!);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('확인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

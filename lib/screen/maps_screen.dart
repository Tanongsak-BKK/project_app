// lib/screen/maps_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// ผลลัพธ์ที่ส่งกลับไปยังหน้าก่อนหน้า
class MapPickResult {
  final double lat;
  final double lng;
  final String address;
  const MapPickResult({required this.lat, required this.lng, required this.address});
}

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key, this.initial});
  final LatLng? initial;

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  static const _bkk = LatLng(13.7563, 100.5018);
  GoogleMapController? _map;
  LatLng? _picked;
  String _addr = '';
  bool _loadingAddr = false;

  CameraPosition get _initialCam => CameraPosition(
        target: widget.initial ?? _bkk,
        zoom: widget.initial != null ? 15 : 12,
      );

  Future<void> _ensureLocationPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปรดอนุญาตการเข้าถึงตำแหน่ง')),
      );
      throw Exception('no-permission');
    }
  }

  Future<void> _goMyLocation() async {
    try {
      await _ensureLocationPermission();
      final p = await Geolocator.getCurrentPosition();
      final ll = LatLng(p.latitude, p.longitude);

      // ปักหมุดที่ตำแหน่งฉัน + หา address (ถ้าเป็น mobile)
      setState(() {
        _picked = ll;
        _addr = '';
        _loadingAddr = true;
      });
      _map?.animateCamera(CameraUpdate.newLatLngZoom(ll, 16));

      await _reverseGeocode(ll); // บนเว็บจะข้ามไปเอง (ใช้ lat,lng แทน)
    } catch (_) {
      // เงียบไว้พอ
    }
  }

  Future<void> _reverseGeocode(LatLng ll) async {
    if (kIsWeb) {
      // บนเว็บ: ข้าม geocoding package (บางเคสไม่เสถียร) ใช้ lat,lng แทน
      setState(() {
        _addr = '';
        _loadingAddr = false;
      });
      return;
    }
    setState(() {
      _loadingAddr = true;
      _addr = '';
    });
    try {
      final placemarks = await placemarkFromCoordinates(ll.latitude, ll.longitude);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final parts = [
          pm.name,
          pm.subLocality,
          pm.locality,
          pm.administrativeArea,
          pm.postalCode,
          pm.country
        ].where((e) => (e != null && e!.trim().isNotEmpty)).map((e) => e!.trim()).toList();
        setState(() {
          _addr = parts.join(', ');
        });
      }
    } catch (_) {
      setState(() {
        _addr = '';
      });
    } finally {
      setState(() {
        _loadingAddr = false;
      });
    }
  }

  void _onMapTap(LatLng ll) {
    setState(() {
      _picked = ll;
      _addr = '';
    });
    _reverseGeocode(ll);
  }

  void _confirm() {
    if (_picked == null) return;
    final ll = _picked!;
    Navigator.pop(
      context,
      MapPickResult(
        lat: ll.latitude,
        lng: ll.longitude,
        address: _addr, // อาจว่างถ้าเป็นเว็บ/หาไม่ได้
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markerSet = <Marker>{};
    if (_picked != null) {
      markerSet.add(
        Marker(
          markerId: const MarkerId('picked'),
          position: _picked!,
          infoWindow: InfoWindow(
            title: 'ตำแหน่งที่เลือก',
            snippet: _addr.isNotEmpty
                ? _addr
                : '${_picked!.latitude.toStringAsFixed(6)}, ${_picked!.longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('เลือกตำแหน่งบนแผนที่'),
        actions: [
          IconButton(
            onPressed: _goMyLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'ไปตำแหน่งฉัน (ปักหมุดให้)',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCam,
            onMapCreated: (c) => _map = c,
            onTap: _onMapTap,
            markers: markerSet,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.pin_drop_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _picked == null
                                ? 'แตะบนแผนที่เพื่อเลือกตำแหน่ง หรือกดไอคอนเป้าเพื่อใช้ตำแหน่งฉัน'
                                : _loadingAddr
                                    ? 'กำลังค้นหาที่อยู่…'
                                    : (_addr.isNotEmpty
                                        ? _addr
                                        : '${_picked!.latitude.toStringAsFixed(6)}, ${_picked!.longitude.toStringAsFixed(6)}'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _picked == null ? null : _confirm,
                        icon: const Icon(Icons.check),
                        label: const Text('ยืนยันตำแหน่งนี้'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_app/screen/setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // Mock data – ปรับจาก backend ได้ตามต้องการ
  String _name = 'Tanongsak B';
  String _email = 'jateva01@gmail.com';

  final _picker = ImagePicker();
  Uint8List? _avatarBytes;

  static const _bg = Color(0xFFE7F3EE);
  static const _teal = Color(0xFF1CA8A4);

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() async {
      _avatarBytes = await x.readAsBytes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          title: const Text('โปรไฟล์'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                // TODO: ไปหน้า settings
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingScreen()),
                );
              },
            )
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: const SizedBox.shrink(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              // Avatar + camera
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white,
                    child: ClipOval(
                      child: SizedBox(
                        width: 88,
                        height: 88,
                        child: _avatarBytes == null
                            ? const Icon(Icons.account_circle, size: 88, color: Colors.black26)
                            : Image.memory(_avatarBytes!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Material(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: _pickAvatar,
                        borderRadius: BorderRadius.circular(18),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 8),

              // Edit name pill
              
              const SizedBox(height: 6),
              // Stats row (comment / like)
              const SizedBox(height: 12),
              // Tabs
              Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.black12)),
                ),
                child: const TabBar(
                  indicatorColor: _teal,
                  labelColor: _teal,
                  unselectedLabelColor: Colors.black54,
                  tabs: [
                    Tab(text: 'โพสต์ของฉัน'),
                    
                  ],
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  children: [
                    const _EmptyArea(),
                    
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// --- Widgets ---
class _EmptyArea extends StatelessWidget {
  const _EmptyArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE7F3EE),
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.eco_rounded, size: 48, color: Colors.black26),
            SizedBox(height: 8),
            Text('รายการว่างเปล่า', style: TextStyle(color: Colors.black45)),
            SizedBox(height: 2),
            Text('ลองโพสต์เรื่องราวของคุณดูสิ', style: TextStyle(color: Colors.black38)),
          ],
        ),
      ),
    );
  }
}

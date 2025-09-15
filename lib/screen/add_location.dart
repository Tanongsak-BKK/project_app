import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({
    super.key,
    required this.provinceId,
    required this.provinceName,
  });

  final String provinceId;
  final String provinceName;

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final _picker = ImagePicker();
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    // default: จังหวัดที่มาจากหน้าแผนที่
    _placeCtrl.text = widget.provinceName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _placeCtrl.dispose();
    _dateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDate: now,
      helpText: 'เลือกวันที่',
    );
    if (picked != null) {
      _dateCtrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // ตอนนี้ MapScreenVector รับเป็น String อยู่
    // เลยส่งชื่อสถานที่กลับไปเหมือนเดิม
    Navigator.pop(context, _nameCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFE7F3EE); // เขียวอ่อนตามภาพ
    final primary = const Color(0xFF1CA8A4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('บันทึกการท่องเที่ยว'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('บันทึก'),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // รูปภาพ
                InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(24),
                  child: Ink(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                    ),
                    child: _imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.image_outlined, size: 48, color: Colors.black38),
                              SizedBox(height: 8),
                              Text('กดเพื่อเพิ่มรูปภาพ', style: TextStyle(color: Colors.black45)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ชื่อสถานที่
                _RoundedField(
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: _inputDec(
                      icon: Icons.edit_outlined,
                      hint: 'ใส่ชื่อสถานที่',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'โปรดกรอกชื่อสถานที่' : null,
                  ),
                ),
                const SizedBox(height: 12),

                // เลือกสถานที่ (กดไม่ได้พิมพ์เอง เพื่อเลียนแบบ UI "เลือกสถานที่")
                _RoundedField(
                  child: TextFormField(
                    controller: _placeCtrl,
                    readOnly: true,
                    onTap: () => _openPlacePicker(),
                    decoration: _inputDec(
                      icon: Icons.place_outlined,
                      hint: 'เลือกสถานที่',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // วันที่
                _RoundedField(
                  child: TextFormField(
                    controller: _dateCtrl,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: _inputDec(
                      icon: Icons.calendar_today_outlined,
                      hint: 'วันที่',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ข้อความ
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextFormField(
                    controller: _noteCtrl,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'ใส่ข้อความของคุณที่นี่',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // mock place picker (คุณสามารถเปลี่ยนไปหน้าเลือกตำแหน่งจริงได้)
  Future<void> _openPlacePicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final style = Theme.of(ctx).textTheme.bodyLarge;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.my_location_outlined),
                title: Text('ใช้จังหวัดจากแผนที่: ${widget.provinceName}', style: style),
                onTap: () => Navigator.pop(ctx, widget.provinceName),
              ),
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text('พิมพ์ชื่อสถานที่เอง', style: style),
                onTap: () => Navigator.pop(ctx, '__manual__'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    if (result == '__manual__') {
      final manual = await _askManualPlace();
      if (manual != null && manual.trim().isNotEmpty) {
        _placeCtrl.text = manual.trim();
      }
    } else {
      _placeCtrl.text = result;
    }
    setState(() {});
  }

  Future<String?> _askManualPlace() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('กรอกสถานที่'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'เช่น วัดดัง จุดเช็คอิน'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('ตกลง')),
        ],
      ),
    );
  }

  InputDecoration _inputDec({required IconData icon, required String hint}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.black54),
      hintText: hint,
      border: InputBorder.none,
    );
  }
}

// กล่องขาวโค้งมนเงานุ่ม ๆ ตามภาพ
class _RoundedField extends StatelessWidget {
  const _RoundedField({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: child,
    );
  }
}

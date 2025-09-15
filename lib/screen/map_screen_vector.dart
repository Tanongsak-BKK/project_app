import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart' as xml;

import 'package:project_app/screen/add_location.dart';
import 'package:project_app/screen/list_location.dart';



/// Single tap = zoom to province + show panel
/// Long press = add point at press location
/// Double tap anywhere = reset to full country
class MapScreenVector extends StatefulWidget {
  const MapScreenVector({
    super.key,
    this.svgAsset = 'lib/maps/Province_of_Thailand_Blank_Map.svg',
  });
  final String svgAsset;

  @override
  State<MapScreenVector> createState() => _MapScreenVectorState();
}

class _MapScreenVectorState extends State<MapScreenVector>
    with SingleTickerProviderStateMixin {
  final TransformationController _tc = TransformationController();
  Future<_MapData>? _loader;

  // provinceId -> user-added points (viewBox coords)
  final Map<String, List<Offset>> _locations = {};
  String? _selectedProvinceId;
  String? _selectedProvinceName;

  Matrix4 _fitMatrix = Matrix4.identity(); // viewBox -> screen
  Size _viewportSize = Size.zero;

  late final AnimationController _anim;
  static const double _kMinScale = 0.2;
  static const double _kMaxScale = 12;

  Offset? _lastTapDownGlobal;
  bool _showPanel = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _loader = _loadSvg(widget.svgAsset);
  }

  @override
  void dispose() {
    _anim.dispose();
    _tc.dispose();
    super.dispose();
  }

  // screen global -> viewBox space
  Offset _toMapSpace(Offset global, RenderBox box) {
    final local = box.globalToLocal(global);
    final invInteractive = Matrix4.inverted(_tc.value);
    final p1 = MatrixUtils.transformPoint(invInteractive, local);
    final invFit = Matrix4.inverted(_fitMatrix);
    return MatrixUtils.transformPoint(invFit, p1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EAF7),
      body: SafeArea(
        top: true, bottom: false,
        child: FutureBuilder<_MapData>(
          future: _loader,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData) {
              return const Center(child: Text('Failed to load map. Check SVG asset path.'));
            }
            final data = snap.data!;

            return LayoutBuilder(builder: (context, c) {
              _viewportSize = Size(c.maxWidth, c.maxHeight);
              _fitMatrix = _computeFitMatrix(
                canvasSize: _viewportSize,
                viewBox: data.viewBox,
                fit: BoxFit.contain,
              );

              final selectedCount =
                  _selectedProvinceId == null ? 0 : (_locations[_selectedProvinceId!] ?? []).length;

              return Stack(
                children: [
                  const Positioned.fill(child: _GridBackground()),

                  // Map (tap/long-press)
                  Positioned.fill(
                    child: InteractiveViewer(
                      constrained: false,
                      transformationController: _tc,
                      minScale: _kMinScale,
                      maxScale: _kMaxScale,
                      boundaryMargin: const EdgeInsets.all(800),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => _lastTapDownGlobal = d.globalPosition,
                        onTap: () => _onSingleTap(data),
                        onLongPressStart: (d) => _onLongPressStart(d, data),
                        child: CustomPaint(
                          size: _viewportSize,
                          painter: _MapPainter(
                            data: data,
                            selectedProvinceId: _selectedProvinceId,
                            locations: _locations,
                            fitMatrix: _fitMatrix,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Double-tap ANYWHERE resets
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: _resetZoom,
                    ),
                  ),

                  // Province panel
                  if (_showPanel && _selectedProvinceId != null)
                    _ProvincePanel(
                      provinceName: _selectedProvinceName ?? '',
                      locationsCount: selectedCount,
                      onAdd: () => _goToAddLocation(data),
                      onView: () => _goToListLocation(),
                      onClose: () => setState(() => _showPanel = false),
                    ),
                ],
              );
            });
          },
        ),
      ),
    );
  }

  // ---------- Tap handlers ----------
  void _onSingleTap(_MapData data) {
    if (_lastTapDownGlobal == null) return;
    final box = context.findRenderObject() as RenderBox;
    final p = _toMapSpace(_lastTapDownGlobal!, box);

    for (final province in data.provinces.values.toList().reversed) {
      if (province.path.contains(p)) {
        setState(() {
          _selectedProvinceId = province.id;
          _selectedProvinceName = province.displayName;
          _showPanel = true;
        });
        _zoomToProvince(province.path);
        return;
      }
    }
  }

  void _onLongPressStart(LongPressStartDetails d, _MapData data) async {
    final box = context.findRenderObject() as RenderBox;
    final p = _toMapSpace(d.globalPosition, box);

    for (final province in data.provinces.values.toList().reversed) {
      if (province.path.contains(p)) {
        final name = await _askLocationName(context, province.displayName);
        if (name == null || name.trim().isEmpty) return;
        setState(() {
          _locations.putIfAbsent(province.id, () => []);
          _locations[province.id]!.add(p);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "$name" in ${province.displayName}')),
        );
        return;
      }
    }
  }

  Future<String?> _askLocationName(BuildContext context, String province) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add location in $province'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Location name (optional)'), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Add')),
        ],
      ),
    );
  }

  // ---------- Navigation ----------
  Future<void> _goToAddLocation(_MapData data) async {
    if (_selectedProvinceId == null) return;
    final pid = _selectedProvinceId!;
    final pname = _selectedProvinceName ?? '';
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AddLocationPage(provinceId: pid, provinceName: pname),
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      // add a point at province center (or plug into your real save flow)
      final center = data.provinces[pid]!.path.getBounds().center;
      setState(() {
        _locations.putIfAbsent(pid, () => []);
        _locations[pid]!.add(center);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "$result" in $pname')),
      );
    }
  }

  void _goToListLocation() {
    if (_selectedProvinceId == null) return;
    final pid = _selectedProvinceId!;
    final pname = _selectedProvinceName ?? '';
    final points = List<Offset>.from(_locations[pid] ?? []);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListLocationPage(
          provinceId: pid,
          provinceName: pname,
          points: points,
        ),
      ),
    );
  }

  // ---------- Zoom helpers ----------
  void _zoomRectInScreenSpace(Rect vbRect, {double padding = 24}) {
    if (_viewportSize.isEmpty) return;

    final screenRect = _transformRect(_fitMatrix, vbRect);
    final target = Rect.fromLTWH(
      padding, padding,
      _viewportSize.width - padding * 2,
      _viewportSize.height - padding * 2,
    );

    double s = [
      target.width / screenRect.width,
      target.height / screenRect.height,
    ].reduce((a, b) => a < b ? a : b);
    s = s.clamp(_kMinScale, _kMaxScale);

    final c0 = screenRect.center;
    final cd = _viewportSize.center(Offset.zero);

    final targetMatrix = Matrix4.identity()
      ..translate(cd.dx, cd.dy)
      ..scale(s, s)
      ..translate(-c0.dx, -c0.dy);

    _animateTo(targetMatrix);
  }

  void _zoomToProvince(Path provincePath) {
    final vb = provincePath.getBounds();
    if (vb.isEmpty) return;
    _zoomRectInScreenSpace(vb, padding: 28);
  }

  void _resetZoom() {
    setState(() => _showPanel = false);
    _animateTo(Matrix4.identity());
  }

  void _animateTo(Matrix4 target) {
    final anim = Matrix4Tween(begin: _tc.value, end: target).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic),
    );
    void listener() => _tc.value = anim.value;
    void status(AnimationStatus s) {
      if (s == AnimationStatus.completed || s == AnimationStatus.dismissed) {
        _anim..removeListener(listener)..removeStatusListener(status);
      }
    }
    _anim
      ..removeListener(listener)
      ..removeStatusListener(status)
      ..addListener(listener)
      ..addStatusListener(status)
      ..forward(from: 0);
  }

  Rect _transformRect(Matrix4 m, Rect r) {
    final tl = MatrixUtils.transformPoint(m, Offset(r.left, r.top));
    final tr = MatrixUtils.transformPoint(m, Offset(r.right, r.top));
    final bl = MatrixUtils.transformPoint(m, Offset(r.left, r.bottom));
    final br = MatrixUtils.transformPoint(m, Offset(r.right, r.bottom));
    final left = [tl.dx, tr.dx, bl.dx, br.dx].reduce((a, b) => a < b ? a : b);
    final right = [tl.dx, tr.dx, bl.dx, br.dx].reduce((a, b) => a > b ? a : b);
    final top = [tl.dy, tr.dy, bl.dy, br.dy].reduce((a, b) => a < b ? a : b);
    final bottom = [tl.dy, tr.dy, bl.dy, br.dy].reduce((a, b) => a > b ? a : b);
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

// ---------------- Floating Panel ----------------
class _ProvincePanel extends StatelessWidget {
  const _ProvincePanel({
    required this.provinceName,
    required this.locationsCount,
    required this.onAdd,
    required this.onView,
    required this.onClose,
  });

  final String provinceName;
  final int locationsCount;
  final VoidCallback onAdd;
  final VoidCallback onView;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final teal = const Color(0xFF1CA8A4);
    return Positioned(
      left: 16, right: 16, bottom: 16,
      child: Material(
        color: Colors.white,
        elevation: 10,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFFE85D75)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          provinceName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('เพิ่มสถานที่ของคุณ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          Container(
                            height: 26, width: 26, alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: const Icon(Icons.add, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onView,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: teal, width: 1.2),
                        foregroundColor: teal,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('สถานที่ของคุณ $locationsCount รายการ',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Container(
                            height: 26, width: 26, alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: teal, width: 1),
                            ),
                            child: Icon(Icons.arrow_forward_rounded, size: 16, color: teal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0, top: 0,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    height: 24, width: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Painter ----------------
class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.data,
    required this.selectedProvinceId,
    required this.locations,
    required this.fitMatrix,
  });

  final _MapData data;
  final String? selectedProvinceId;
  final Map<String, List<Offset>> locations;
  final Matrix4 fitMatrix;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.transform(fitMatrix.storage);

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final province in data.provinces.values) {
      final isSelected = province.id == selectedProvinceId;
      fill.color = isSelected ? const Color(0xFFFFE083) : const Color(0xFFF7EBD3);
      canvas.drawPath(province.path, fill);
      canvas.drawPath(province.path, stroke);
    }

    final markerFill = Paint()..color = Colors.redAccent;
    final markerStroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final entry in locations.entries) {
      for (final p in entry.value) {
        canvas.drawCircle(p, 4.5, markerFill);
        canvas.drawCircle(p, 4.5, markerStroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.selectedProvinceId != selectedProvinceId ||
      old.fitMatrix != fitMatrix ||
      old.locations.length != locations.length;
}

// ---------------- Data structures & loader ----------------
class _MapData {
  _MapData({required this.viewBox, required this.provinces});
  final Rect viewBox;
  final Map<String, _Province> provinces;
}

class _Province {
  _Province({required this.id, required this.displayName, required this.path});
  final String id;
  final String displayName;
  final Path path;
}

// SVG loader (same as before)
Future<_MapData> _loadSvg(String asset) async {
  final str = await rootBundle.loadString(asset);
  final doc = xml.XmlDocument.parse(str);
  final svg = doc.findElements('svg').first;

  final vbRaw = svg.getAttribute('viewBox') ?? svg.getAttribute('viewbox');
  late final Rect viewBox;
  if (vbRaw != null) {
    final p = vbRaw.trim().split(RegExp(r'\s+'));
    viewBox = Rect.fromLTWH(double.parse(p[0]), double.parse(p[1]), double.parse(p[2]), double.parse(p[3]));
  } else {
    final w = double.tryParse(svg.getAttribute('width') ?? '') ?? 1000;
    final h = double.tryParse(svg.getAttribute('height') ?? '') ?? 1000;
    final x = double.tryParse(svg.getAttribute('x') ?? '') ?? 0;
    final y = double.tryParse(svg.getAttribute('y') ?? '') ?? 0;
    viewBox = Rect.fromLTWH(x, y, w, h);
  }

  final provinces = <String, _Province>{};

  void walk(xml.XmlElement node, Matrix4 parent, {String? inheritId, String? inheritName}) {
    Matrix4 transform = parent.clone();
    final tAttr = node.getAttribute('transform');
    if (tAttr != null) transform = parent.multiplied(_parseTransform(tAttr));

    final groupId = node.getAttribute('id') ?? inheritId;
    final groupName = node.getAttribute('name') ?? node.getAttribute('title') ?? inheritName;

    for (final child in node.children.whereType<xml.XmlElement>()) {
      if (child.name.local == 'g') {
        walk(child, transform, inheritId: groupId, inheritName: groupName);
      } else if (child.name.local == 'path') {
        final id = child.getAttribute('id') ?? groupId ?? 'id_${provinces.length + 1}';
        final rawName = child.getAttribute('name') ?? child.getAttribute('title') ?? groupName ?? '';
        if (rawName.trim().isEmpty) continue;

        final d = child.getAttribute('d');
        if (d == null) continue;

        Path pth = parseSvgPathData(d).transform(transform.storage);
        pth.fillType = PathFillType.nonZero;

        final existing = provinces[id];
        if (existing == null) {
          provinces[id] = _Province(id: id, displayName: rawName, path: pth);
        } else {
          final merged = Path()
            ..addPath(existing.path, Offset.zero)
            ..addPath(pth, Offset.zero);
          provinces[id] = _Province(id: id, displayName: existing.displayName, path: merged);
        }
      }
    }
  }

  walk(svg, Matrix4.identity());
  return _MapData(viewBox: viewBox, provinces: provinces);
}

Matrix4 _parseTransform(String raw) {
  Matrix4 m = Matrix4.identity();
  final re = RegExp(r'(matrix|translate|scale)\s*\(([^)]+)\)');
  for (final match in re.allMatches(raw)) {
    final type = match.group(1)!;
    final params = match.group(2)!
        .split(RegExp(r'[\s,]+'))
        .where((e) => e.trim().isNotEmpty)
        .map((e) => double.tryParse(e.trim()) ?? 0.0)
        .toList();
    switch (type) {
      case 'translate':
        m = m.multiplied(Matrix4.translationValues(
          params.isNotEmpty ? params[0] : 0.0,
          params.length > 1 ? params[1] : 0.0,
          0,
        ));
        break;
      case 'scale':
        final sx = params.isNotEmpty ? params[0] : 1.0;
        final sy = params.length > 1 ? params[1] : sx;
        m = m.multiplied(Matrix4.diagonal3Values(sx, sy, 1));
        break;
      case 'matrix':
        if (params.length >= 6) {
          final a = params[0], b = params[1], c = params[2], d = params[3], e = params[4], f = params[5];
          m = m.multiplied(Matrix4(
            a, b, 0, 0,
            c, d, 0, 0,
            0, 0, 1, 0,
            e, f, 0, 1,
          ));
        }
        break;
    }
  }
  return m;
}

Matrix4 _computeFitMatrix({
  required Size canvasSize,
  required Rect viewBox,
  BoxFit fit = BoxFit.contain,
}) {
  final sx = canvasSize.width / viewBox.width;
  final sy = canvasSize.height / viewBox.height;
  final scale = (fit == BoxFit.cover) ? (sx > sy ? sx : sy) : (sx < sy ? sx : sy);
  final dx = (canvasSize.width - viewBox.width * scale) / 2 - viewBox.left * scale;
  final dy = (canvasSize.height - viewBox.height * scale) / 2 - viewBox.top * scale;
  return Matrix4.identity()..translate(dx, dy)..scale(scale, scale);
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter(lineColor: const Color(0xFF8FBAD6).withOpacity(0.6), cellSize: 48));
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.lineColor, required this.cellSize});
  final Color lineColor;
  final double cellSize;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = lineColor..strokeWidth = 1;
    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.lineColor != lineColor || old.cellSize != cellSize;
}

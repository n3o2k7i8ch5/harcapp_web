import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_bar.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/comm_widgets/simple_button.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:web/web.dart' as web;

import 'cover_processing.dart';

Future<Uint8List?> showCoverCropDialog(BuildContext context, Uint8List imageBytes) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _CropDialog(imageBytes: imageBytes),
  );
}

class _CropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  const _CropDialog({required this.imageBytes});

  @override
  State<_CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<_CropDialog> {
  String? _blobUrl;
  Size _imageSize = Size.zero;
  Rect _cropRect = Rect.zero;
  bool _loading = true;
  bool _cropping = false;

  // Drag state
  Offset? _dragStart;
  Rect _dragStartRect = Rect.zero;
  _DragMode _dragMode = _DragMode.none;

  double get _minCropSize => math.min(_imageSize.width * 0.1, 100);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    if (_blobUrl != null) web.URL.revokeObjectURL(_blobUrl!);
    super.dispose();
  }

  Future<void> _loadImage() async {
    final blob = web.Blob([widget.imageBytes.toJS].toJS);
    final url = web.URL.createObjectURL(blob);

    try {
      final img = await _loadHtmlImage(url);
      _imageSize = Size(img.naturalWidth.toDouble(), img.naturalHeight.toDouble());
      _initCropRect();
      setState(() {
        _blobUrl = url;
        _loading = false;
      });
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<web.HTMLImageElement> _loadHtmlImage(String url) async {
    final img = web.HTMLImageElement()..src = url;
    final completer = Completer<void>();
    img.onLoad.first.then((_) => completer.complete());
    img.onError.first.then((_) => completer.completeError('Failed'));
    await completer.future;
    return img;
  }

  void _initCropRect() {
    final imgRatio = _imageSize.width / _imageSize.height;
    double w, h;

    if (imgRatio > coverAspectRatio) {
      h = _imageSize.height;
      w = h * coverAspectRatio;
    } else {
      w = _imageSize.width;
      h = w / coverAspectRatio;
    }

    _cropRect = Rect.fromLTWH(
      (_imageSize.width - w) / 2,
      (_imageSize.height - h) / 2,
      w,
      h,
    );
  }

  Future<void> _crop() async {
    setState(() => _cropping = true);

    try {
      final result = await _cropNative();
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        setState(() => _cropping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd przycinania: $e')),
        );
      }
    }
  }

  Future<Uint8List> _cropNative() async {
    final img = await _loadHtmlImage(_blobUrl!);

    final canvas = web.HTMLCanvasElement()
      ..width = _cropRect.width.round()
      ..height = _cropRect.height.round();

    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    ctx.drawImage(
      img,
      _cropRect.left, _cropRect.top, _cropRect.width, _cropRect.height,
      0, 0, _cropRect.width, _cropRect.height,
    );

    final completer = Completer<web.Blob?>();
    canvas.toBlob(((web.Blob? b) => completer.complete(b)).toJS, 'image/png');

    final blob = await completer.future;
    if (blob == null) throw StateError('Failed to encode');

    final arrayBuffer = await blob.arrayBuffer().toDart;
    return arrayBuffer.toDart.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = math.min(MediaQuery.of(context).size.width * 0.9, 900.0);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: dialogWidth),
        padding: const EdgeInsets.all(Dimen.sideMarg),
        child: Material(
          elevation: 6.0,
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          color: background_(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAppBar(),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(Dimen.sideMarg * 2),
                  child: CircularProgressIndicator(),
                )
              else
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(Dimen.sideMarg),
                    child: AspectRatio(
                      aspectRatio: _imageSize.width / _imageSize.height,
                      child: _buildCropper(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() => AppBarX(
    title: 'Dopasuj kadr okładki',
    clipBehavior: Clip.none,
    leading: SimpleButton.from(
      context: context,
      icon: MdiIcons.close,
      onTap: _cropping || _loading ? null : () => Navigator.of(context).pop(),
    ),
    actions: [
      SimpleButton.from(
        context: context,
        icon: MdiIcons.check,
        text: 'Przytnij',
        onTap: _cropping || _loading ? null : _crop,
      ),
    ],
  );

  Widget _buildCropper() => LayoutBuilder(
    builder: (context, constraints) {
      final displaySize = Size(constraints.maxWidth, constraints.maxHeight);
      final displayCropRect = _toDisplayRect(_cropRect, displaySize);

      return MouseRegion(
        cursor: SystemMouseCursors.move,
        child: GestureDetector(
          onPanStart: (d) => _onPanStart(d, displaySize, displayCropRect),
          onPanUpdate: (d) => _onPanUpdate(d, displaySize),
          onPanEnd: (_) => _dragStart = null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppCard.defRadius),
                child: Image.network(_blobUrl!, fit: BoxFit.contain),
              ),
              CustomPaint(painter: _OverlayPainter(displayCropRect)),
              ..._buildHandles(displayCropRect),
            ],
          ),
        ),
      );
    },
  );

  Rect _toDisplayRect(Rect imageRect, Size displaySize) => Rect.fromLTWH(
    imageRect.left / _imageSize.width * displaySize.width,
    imageRect.top / _imageSize.height * displaySize.height,
    imageRect.width / _imageSize.width * displaySize.width,
    imageRect.height / _imageSize.height * displaySize.height,
  );

  List<Widget> _buildHandles(Rect rect) {
    const size = 16.0;
    final positions = [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight];

    return positions.map((pos) => Positioned(
      left: pos.dx - size / 2,
      top: pos.dy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: iconEnab_(context), width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    )).toList();
  }

  void _onPanStart(DragStartDetails details, Size displaySize, Rect displayCropRect) {
    _dragMode = _detectDragMode(details.localPosition, displayCropRect);
    if (_dragMode == _DragMode.none) return;

    _dragStart = details.localPosition;
    _dragStartRect = _cropRect;
  }

  _DragMode _detectDragMode(Offset pos, Rect rect) {
    const handleRadius = 24.0;
    final corners = [
      (rect.topLeft, _DragMode.resizeTL),
      (rect.topRight, _DragMode.resizeTR),
      (rect.bottomLeft, _DragMode.resizeBL),
      (rect.bottomRight, _DragMode.resizeBR),
    ];

    for (final (corner, mode) in corners) {
      if ((pos - corner).distance < handleRadius) return mode;
    }

    return rect.contains(pos) ? _DragMode.move : _DragMode.none;
  }

  void _onPanUpdate(DragUpdateDetails details, Size displaySize) {
    if (_dragStart == null || _dragMode == _DragMode.none) return;

    final scale = Size(_imageSize.width / displaySize.width, _imageSize.height / displaySize.height);
    final delta = Offset(
      (details.localPosition.dx - _dragStart!.dx) * scale.width,
      (details.localPosition.dy - _dragStart!.dy) * scale.height,
    );

    setState(() {
      switch (_dragMode) {
        case _DragMode.move:
          _cropRect = _clampRect(_dragStartRect.shift(delta));
        case _DragMode.resizeBR:
          _resizeFromCorner(delta, anchorTopLeft: true);
        case _DragMode.resizeTL:
          _resizeFromCorner(delta, anchorTopLeft: false);
        case _DragMode.resizeTR:
          _resizeFromCorner(Offset(delta.dx, -delta.dy), anchorBottomLeft: true);
        case _DragMode.resizeBL:
          _resizeFromCorner(Offset(-delta.dx, delta.dy), anchorTopRight: true);
        case _DragMode.none:
          break;
      }
    });
  }

  void _resizeFromCorner(Offset delta, {bool anchorTopLeft = false, bool anchorBottomLeft = false, bool anchorTopRight = false}) {
    var newW = (_dragStartRect.width + delta.dx).clamp(_minCropSize, _imageSize.width);
    var newH = newW / coverAspectRatio;

    if (newH > _imageSize.height) {
      newH = _imageSize.height;
      newW = newH * coverAspectRatio;
    }

    double newX, newY;

    if (anchorTopLeft) {
      newX = _dragStartRect.left;
      newY = _dragStartRect.top;
    } else if (anchorBottomLeft) {
      newX = _dragStartRect.left;
      newY = _dragStartRect.bottom - newH;
    } else if (anchorTopRight) {
      newX = _dragStartRect.right - newW;
      newY = _dragStartRect.top;
    } else {
      newX = _dragStartRect.right - newW;
      newY = _dragStartRect.bottom - newH;
    }

    final newRect = _clampRect(Rect.fromLTWH(newX, newY, newW, newH));
    if (newRect.width >= _minCropSize) _cropRect = newRect;
  }
  Rect _clampRect(Rect r) {
    var x = r.left.clamp(0.0, _imageSize.width - r.width);
    var y = r.top.clamp(0.0, _imageSize.height - r.height);
    return Rect.fromLTWH(x, y, r.width, r.height);
  }
}

enum _DragMode { none, move, resizeTL, resizeTR, resizeBL, resizeBR }

class _OverlayPainter extends CustomPainter {
  final Rect cropRect;
  _OverlayPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()..color = Colors.black54;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, cropRect.top), overlay);
    canvas.drawRect(Rect.fromLTRB(0, cropRect.bottom, size.width, size.height), overlay);
    canvas.drawRect(Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom), overlay);
    canvas.drawRect(Rect.fromLTRB(cropRect.right, cropRect.top, size.width, cropRect.bottom), overlay);

    final border = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(cropRect, border);

    final grid = Paint()..color = Colors.white38..style = PaintingStyle.stroke..strokeWidth = 1;
    final w3 = cropRect.width / 3, h3 = cropRect.height / 3;
    for (var i = 1; i <= 2; i++) {
      canvas.drawLine(Offset(cropRect.left + w3 * i, cropRect.top), Offset(cropRect.left + w3 * i, cropRect.bottom), grid);
      canvas.drawLine(Offset(cropRect.left, cropRect.top + h3 * i), Offset(cropRect.right, cropRect.top + h3 * i), grid);
    }
  }

  @override
  bool shouldRepaint(_OverlayPainter old) => cropRect != old.cropRect;
}

import 'dart:js_interop';
import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:harcapp_core/comm_classes/app_text_style.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:harcapp_core/comm_widgets/app_card.dart';
import 'package:harcapp_core/values/dimen.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:web/web.dart' as web;

const String songFileExtension = 'hrcpsng';

/// Obszar, na który można upuścić plik .hrcpsng, by od razu zaimportować piosenki.
/// Gdy plik jest przeciągany nad tym obszarem, obszar zostaje podświetlony.
class SongFileDropTarget extends StatefulWidget{

  final Widget child;
  final void Function(List<Uint8List> filesBytes) onFilesDropped;

  const SongFileDropTarget({required this.child, required this.onFilesDropped, super.key});

  @override
  State<StatefulWidget> createState() => SongFileDropTargetState();

}

class SongFileDropTargetState extends State<SongFileDropTarget>{

  final GlobalKey _areaKey = GlobalKey();

  late final JSFunction _onDragEnter;
  late final JSFunction _onDragOver;
  late final JSFunction _onDragLeave;
  late final JSFunction _onDrop;

  bool _hovered = false;

  @override
  void initState() {
    super.initState();

    _onDragEnter = ((web.Event event) => _handleDragMove(event)).toJS;
    _onDragOver = ((web.Event event) => _handleDragMove(event)).toJS;
    _onDragLeave = ((web.Event event) => _handleDragLeave(event)).toJS;
    _onDrop = ((web.Event event){ _handleDrop(event); }).toJS;

    web.document.addEventListener('dragenter', _onDragEnter);
    web.document.addEventListener('dragover', _onDragOver);
    web.document.addEventListener('dragleave', _onDragLeave);
    web.document.addEventListener('drop', _onDrop);
  }

  @override
  void dispose() {
    web.document.removeEventListener('dragenter', _onDragEnter);
    web.document.removeEventListener('dragover', _onDragOver);
    web.document.removeEventListener('dragleave', _onDragLeave);
    web.document.removeEventListener('drop', _onDrop);
    super.dispose();
  }

  bool _isFileDrag(web.DataTransfer? dataTransfer){
    if(dataTransfer == null) return false;
    for(int i = 0; i < dataTransfer.types.length; i++)
      if(dataTransfer.types[i].toDart == 'Files') return true;
    return false;
  }

  bool _isWithinArea(num clientX, num clientY){
    RenderBox? renderBox = _areaKey.currentContext?.findRenderObject() as RenderBox?;
    if(renderBox == null || !renderBox.hasSize) return false;
    Offset topLeft = renderBox.localToGlobal(Offset.zero);
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, renderBox.size.width, renderBox.size.height)
        .contains(Offset(clientX.toDouble(), clientY.toDouble()));
  }

  void _setHovered(bool hovered){
    if(_hovered == hovered) return;
    setState(() => _hovered = hovered);
  }

  void _handleDragMove(web.Event event){
    web.DragEvent dragEvent = event as web.DragEvent;
    if(!_isFileDrag(dragEvent.dataTransfer)) return;

    // Bez tego przeglądarka po upuszczeniu pliku otworzy go zamiast oddać go aplikacji.
    dragEvent.preventDefault();

    bool within = _isWithinArea(dragEvent.clientX, dragEvent.clientY);
    dragEvent.dataTransfer?.dropEffect = within? 'copy': 'none';
    _setHovered(within);
  }

  void _handleDragLeave(web.Event event){
    web.DragEvent dragEvent = event as web.DragEvent;
    if(!_isFileDrag(dragEvent.dataTransfer)) return;
    // relatedTarget == null oznacza, że kursor opuścił okno przeglądarki.
    if(dragEvent.relatedTarget == null) _setHovered(false);
  }

  Future<void> _handleDrop(web.Event event) async {
    web.DragEvent dragEvent = event as web.DragEvent;
    if(!_isFileDrag(dragEvent.dataTransfer)) return;

    dragEvent.preventDefault();
    bool within = _isWithinArea(dragEvent.clientX, dragEvent.clientY);
    _setHovered(false);

    if(!within) return;

    web.FileList? fileList = dragEvent.dataTransfer?.files;
    if(fileList == null) return;

    List<Uint8List> filesBytes = [];
    for(int i = 0; i < fileList.length; i++){
      web.File? file = fileList.item(i);
      if(file == null) continue;
      if(!file.name.toLowerCase().endsWith('.$songFileExtension')) continue;
      JSArrayBuffer buffer = await file.arrayBuffer().toDart;
      filesBytes.add(buffer.toDart.asUint8List());
    }

    if(filesBytes.isEmpty) return;
    if(!mounted) return;
    widget.onFilesDropped(filesBytes);
  }

  @override
  Widget build(BuildContext context) => Stack(
    key: _areaKey,
    fit: StackFit.passthrough,
    children: [

      widget.child,

      Positioned.fill(
        child: IgnorePointer(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _hovered? const _DropHint(): const SizedBox.shrink(),
          ),
        ),
      )

    ],
  );

}

class _DropHint extends StatelessWidget{

  const _DropHint();

  // Bez elewacji: cień rzucany **na** półprzezroczystą, rozmytą warstwę robił
  // się brudną plamą zamiast uniesienia. Kafelek odcina się samym kolorem
  // i obwódką — tak samo jak belka „taki tytuł już jest”.
  @override
  Widget build(BuildContext context) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
    child: Container(
      color: background_(context).withValues(alpha: .6),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(Dimen.sideMarg),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundIcon_(context),
          borderRadius: BorderRadius.circular(AppCard.bigRadius),
          border: Border.all(
            color: iconEnab_(context).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(Dimen.sideMarg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Icon(MdiIcons.trayArrowDown, size: 32.0, color: iconEnab_(context)),

              const SizedBox(height: Dimen.iconMarg),

              Text(
                'Upuść, by zaimportować',
                textAlign: TextAlign.center,
                style: AppTextStyle(
                  fontSize: Dimen.textSizeBig,
                  fontWeight: weightHalfBold,
                  color: iconEnab_(context),
                ),
              ),

            ],
          ),
        ),
      ),
    ),
  );

}

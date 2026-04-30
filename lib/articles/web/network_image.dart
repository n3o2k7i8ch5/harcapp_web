import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:harcapp_core/comm_classes/color_pack.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:web/web.dart' as web;

bool _platformViewStyleInjected = false;

/// Flutter web wraps every [HtmlElementView] in a `<flt-platform-view>` host
/// element with `pointer-events: auto` by default. That host swallows taps
/// even if the inner element has `pointer-events: none`. Inject a CSS rule
/// that turns the entire platform-view subtree transparent to events.
///
/// In addition we wrap the [HtmlElementView] with an [IgnorePointer] at the
/// Flutter widget level so Flutter's hit-testing skips the cover when
/// looking for tap targets — taps then bubble up to the surrounding
/// clickable widget (e.g. an article card's button).
void _ensurePlatformViewClickThroughStyle() {
  if (_platformViewStyleInjected) return;
  _platformViewStyleInjected = true;
  final style = web.HTMLStyleElement()
    ..textContent = 'flt-platform-view { pointer-events: none !important; }';
  web.document.head!.appendChild(style);
}

int _viewTypeCounter = 0;

/// Renders a network image on Flutter web by embedding a raw `<img>`
/// HTMLImageElement via [HtmlElementView]. Browser loads and decodes it
/// natively (off the main isolate) and — crucially for hosts that do not
/// send CORS headers (e.g. ZHR's WordPress) — does not require CORS for
/// `<img>` display the way Flutter's [Image.network] / [CachedNetworkImage]
/// (which use XHR) does.
///
/// Adapts its aspect ratio to the image's natural dimensions once it has
/// loaded, falling back to 16:9 while loading.
class WebNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const WebNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  @override
  State<WebNetworkImage> createState() => _WebNetworkImageState();
}

class _WebNetworkImageState extends State<WebNetworkImage> {
  late final String _viewType;
  double? _aspectRatio;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ensurePlatformViewClickThroughStyle();
    _viewType = 'web-img-${_viewTypeCounter++}';
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final container = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.pointerEvents = 'none';
      final img = web.HTMLImageElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _cssFit(widget.fit)
        ..style.display = 'block'
        ..style.pointerEvents = 'none';
      img.onLoad.listen((_) {
        if (!mounted) return;
        final w = img.naturalWidth;
        final h = img.naturalHeight;
        if (w > 0 && h > 0) {
          final ratio = w / h;
          if (_aspectRatio != ratio) {
            setState(() => _aspectRatio = ratio);
          }
        }
      });
      img.onError.listen((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
      container.appendChild(img);
      return container;
    });
  }

  static String _cssFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
      case BoxFit.fitWidth:
      case BoxFit.fitHeight:
      case BoxFit.scaleDown:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return AspectRatio(
        aspectRatio: _aspectRatio ?? 16 / 9,
        child: Container(
          color: cardEnab_(context),
          alignment: Alignment.center,
          child: Icon(MdiIcons.imageBroken, color: iconEnab_(context)),
        ),
      );
    }

    final view = IgnorePointer(child: HtmlElementView(viewType: _viewType));

    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.hasBoundedHeight) return view;
        return AspectRatio(
          aspectRatio: _aspectRatio ?? 16 / 9,
          child: view,
        );
      },
    );
  }
}

/// Themed loading spinner that mirrors `_LoadingWidget` in
/// `harcapp_core`'s `article_cover_widget.dart`.
class WebImageLoadingPlaceholder extends StatelessWidget {
  const WebImageLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: SpinKitCubeGrid(
          size: 64.0,
          color: iconDisab_(context),
        ),
      );
}

import 'package:flutter/widgets.dart';
import 'package:harcapp_core/values/dimen.dart';

/// Layout constants for the app.
class AppLayout {
  AppLayout._();

  static const double defPageWidth = 1200;
  static const double appDialogMaxWidth = 900;
  static const double songDialogWidth = 700;
  static const double drawerWidth = 480;
  static const double songPreviewWidth = 400;

  /// Below this width, a page's side panel collapses into a drawer.
  static const double collapseWidth = 920;

  /// Space between a page's content and the screen's edges (and between its
  /// panels) — see [pageMargin].
  static const double pageMarginWide = 32;
  static const double pageMarginNarrow = Dimen.sideMarg;
}

/// The page margin — between a page's content and the screen's edges: wide on
/// wide screens, narrower once side panels collapse, never none. Every page
/// takes its outer margin from here; spacing inside a page is its own.
double pageMargin(BuildContext context) =>
    MediaQuery.sizeOf(context).width > AppLayout.collapseWidth
        ? AppLayout.pageMarginWide
        : AppLayout.pageMarginNarrow;

// Legacy top-level constants for backward compatibility
const double defPageWidth = AppLayout.defPageWidth;
const double appDialogMaxWidth = AppLayout.appDialogMaxWidth;
const double songDialogWidth = AppLayout.songDialogWidth;
const double drawerWidth = AppLayout.drawerWidth;
const double songPreviewWidth = AppLayout.songPreviewWidth;

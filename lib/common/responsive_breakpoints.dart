import 'package:flutter/material.dart';

/// Responsive breakpoints for the app layout.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Width below which top navigation labels are hidden (only icons shown).
  static const double topNavDense = 920;

  /// Width below which top navigation moves to bottom navigation bar.
  static const double topNavToBottom = 520;

  /// Check if top navigation should be shown at bottom.
  static bool shouldShowTopNavAtBottom(BuildContext context) =>
      MediaQuery.of(context).size.width < topNavToBottom;
}

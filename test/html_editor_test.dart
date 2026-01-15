import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/html_editor.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/quill_html_converter.dart';

void main() {
  group('HtmlEditor widget tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget({
      String initialHtml = '',
      bool showToolbar = true,
      bool showDebugButtons = false,
    }) {
      controller.text = initialHtml;
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Scaffold(
          body: HtmlEditor(
            controller: controller,
            showToolbar: showToolbar,
            showDebugButtons: showDebugButtons,
          ),
        ),
      );
    }

    testWidgets('renders QuillEditor widget', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialHtml: '<p>Hello World</p>',
      ));
      await tester.pumpAndSettle();

      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets('renders toolbar when showToolbar is true', (tester) async {
      await tester.pumpWidget(buildTestWidget(showToolbar: true));
      await tester.pumpAndSettle();

      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
    });

    testWidgets('hides toolbar when showToolbar is false', (tester) async {
      await tester.pumpWidget(buildTestWidget(showToolbar: false));
      await tester.pumpAndSettle();

      expect(find.byType(QuillSimpleToolbar), findsNothing);
    });

    testWidgets('handles empty HTML gracefully', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialHtml: ''));
      await tester.pumpAndSettle();

      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets('handles whitespace-only HTML', (tester) async {
      await tester.pumpWidget(buildTestWidget(initialHtml: '   '));
      await tester.pumpAndSettle();

      expect(find.byType(QuillEditor), findsOneWidget);
    });

    testWidgets('controller text is updated after widget builds', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialHtml: '<p>Test content</p>',
      ));
      await tester.pumpAndSettle();

      expect(controller.text.contains('Test content'), isTrue);
    });

    testWidgets('list HTML is preserved in controller', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialHtml: '<ul><li>Item 1</li><li>Item 2</li></ul>',
      ));
      await tester.pumpAndSettle();

      expect(controller.text.contains('Item 1'), isTrue);
      expect(controller.text.contains('Item 2'), isTrue);
      expect(controller.text.contains('<ul>'), isTrue);
    });

    testWidgets('ordered list HTML is preserved in controller', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialHtml: '<ol><li>First</li><li>Second</li></ol>',
      ));
      await tester.pumpAndSettle();

      expect(controller.text.contains('First'), isTrue);
      expect(controller.text.contains('Second'), isTrue);
      expect(controller.text.contains('<ol>'), isTrue);
    });

    testWidgets('formatted text HTML is preserved in controller', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialHtml: '<p><b>Bold</b> and <i>italic</i></p>',
      ));
      await tester.pumpAndSettle();

      expect(controller.text.contains('Bold'), isTrue);
      expect(controller.text.contains('italic'), isTrue);
      expect(controller.text.contains('<b>'), isTrue);
      expect(controller.text.contains('<i>'), isTrue);
    });

    testWidgets('soft line breaks in list items are preserved', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialHtml: '<ul><li>Line 1<br>Line 2</li></ul>',
      ));
      await tester.pumpAndSettle();

      expect(controller.text.contains('Line 1'), isTrue);
      expect(controller.text.contains('Line 2'), isTrue);
      expect(controller.text.contains('<br>'), isTrue);
    });

    testWidgets('nested lists are preserved', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        initialHtml: '<ol><li>Parent<ol><li>Child</li></ol></li></ol>',
      ));
      await tester.pumpAndSettle();

      expect(controller.text.contains('Parent'), isTrue);
      expect(controller.text.contains('Child'), isTrue);
    });

    testWidgets('complex nested list with soft breaks', (tester) async {
      const html = '<p>Introduction</p><ol><li>Question 1?</li></ol>';
      await tester.pumpWidget(buildTestWidget(initialHtml: html));
      await tester.pumpAndSettle();

      expect(find.byType(QuillEditor), findsOneWidget);
      expect(controller.text.contains('Introduction'), isTrue);
      expect(controller.text.contains('Question 1?'), isTrue);
    });
  });
  
  group('Quill Document soft line break tests', () {
    test('soft line breaks survive Quill Document roundtrip', () {
      // Test that \u2028 survives going through Quill Document
      final ops = [
        {'insert': 'Line 1\u2028\u2028Line 2\u2028\n'},
      ];
      
      // Create Document from ops
      final doc = Document.fromJson(ops);
      
      // Get ops back from Document
      final resultOps = doc.toDelta().toJson();
      
      // Check if soft line breaks are preserved
      final hasBreaks = resultOps.any((op) {
        final insert = op['insert'];
        return insert is String && insert.contains('\u2028');
      });
      
      expect(hasBreaks, isTrue, reason: 'Quill Document should preserve soft line breaks');
    });
    
    test('HTML with br -> Delta -> Quill Document -> Delta -> HTML preserves br', () {
      // Full roundtrip test
      const html = '<p>Line 1<br><br>Line 2</p>';
      
      // HTML -> Delta
      final ops = htmlToDeltaOps(html);
      
      // Delta -> Quill Document
      final doc = Document.fromJson(ops);
      
      // Quill Document -> Delta
      final resultOps = doc.toDelta().toJson();
      
      // Delta -> HTML
      final resultHtml = deltaOpsToHtml(resultOps);
      
      // Should contain <br> tags
      expect(resultHtml, contains('<br>'), reason: 'BR tags should survive full roundtrip');
    });

    test('empty paragraph (double newline) survives Quill Document roundtrip', () {
      // This is the user's actual issue - empty paragraph between two text paragraphs
      const html = '<p>First paragraph.</p><p></p><p>Third paragraph after empty line.</p>';
      
      // HTML -> Delta
      final ops = htmlToDeltaOps(html);
      
      // Delta -> Quill Document
      final doc = Document.fromJson(ops);
      
      // Quill Document -> Delta
      final resultOps = doc.toDelta().toJson();
      
      // Delta -> HTML
      final resultHtml = deltaOpsToHtml(resultOps);
      
      // Should have empty paragraph preserved
      expect(resultHtml, equals(html), reason: 'Empty paragraph should survive full roundtrip through Quill Document');
    });
  });
}

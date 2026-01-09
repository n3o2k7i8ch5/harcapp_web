import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/quill_html_converter.dart';

void main() {
  group('htmlToDeltaOps', () {
    test('simple ordered list', () {
      const html = '<ol><li><p>first</p></li><li><p>second</p></li></ol>';
      final ops = htmlToDeltaOps(html);

      expect(ops, [
        {'insert': 'first'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'second'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ]);
    });

    test('nested ordered list preserves indent', () {
      // HTML with nested list:
      // 1. cośtam
      //    a) podpunkt
      const html = '''
<ol>
  <li><p>cośtam</p>
    <ol>
      <li><p>podpunkt</p></li>
    </ol>
  </li>
</ol>''';

      final ops = htmlToDeltaOps(html);

      // Expected Delta with indent attribute for nested item
      expect(ops, [
        {'insert': 'cośtam'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'podpunkt'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
      ]);
    });

    test('deeply nested list preserves multiple indent levels', () {
      const html = '''
<ol>
  <li><p>level 0</p>
    <ol>
      <li><p>level 1</p>
        <ol>
          <li><p>level 2</p></li>
        </ol>
      </li>
    </ol>
  </li>
</ol>''';

      final ops = htmlToDeltaOps(html);

      expect(ops, [
        {'insert': 'level 0'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'level 1'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'level 2'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 2}},
      ]);
    });

    test('mixed nested lists (ol inside ul)', () {
      const html = '''
<ul>
  <li><p>bullet item</p>
    <ol>
      <li><p>numbered sub-item</p></li>
    </ol>
  </li>
</ul>''';

      final ops = htmlToDeltaOps(html);

      expect(ops, [
        {'insert': 'bullet item'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'numbered sub-item'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
      ]);
    });
  });

  group('deltaOpsToHtml', () {
    test('simple ordered list', () {
      final ops = [
        {'insert': 'first'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'second'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];

      final html = deltaOpsToHtml(ops);

      expect(html, contains('<ol>'));
      expect(html, contains('<li>'));
      expect(html, contains('first'));
      expect(html, contains('second'));
      expect(html, contains('</ol>'));
    });

    test('nested ordered list produces nested HTML', () {
      final ops = [
        {'insert': 'cośtam'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'podpunkt'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
      ];

      final html = deltaOpsToHtml(ops);

      // Should produce nested <ol> structure
      expect(html, contains('<ol>'));
      expect(html, contains('cośtam'));
      expect(html, contains('podpunkt'));
      // The nested item should be in a nested <ol>
      expect(html, matches(RegExp(r'<ol>.*<li>.*<ol>.*<li>.*podpunkt.*</li>.*</ol>.*</li>.*</ol>', dotAll: true)));
    });
  });

  group('newline handling', () {
    test('newline in text should produce br tag not new paragraph', () {
      // When user presses Enter in Quill editor (not Shift+Enter),
      // the Delta contains a plain \n. This should become <br> in HTML,
      // not a new <p> tag.
      //
      // Delta representing: "Line one\nLine two" (single paragraph with line break)
      final ops = [
        {'insert': 'Line one\nLine two'},
        {'insert': '\n'},
      ];

      final html = deltaOpsToHtml(ops);

      // Should produce a single paragraph with <br> between lines
      expect(html, equals('<p>Line one<br>Line two</p>'));
    });

    test('soft line break should produce br tag', () {
      // Soft line break (Shift+Enter) uses Unicode \u2028
      final ops = [
        {'insert': 'Line one${softLineBreak}Line two'},
        {'insert': '\n'},
      ];

      final html = deltaOpsToHtml(ops);

      expect(html, equals('<p>Line one<br>Line two</p>'));
    });
  });

  group('list with preceding text and soft breaks', () {
    test('text ending with soft break before list item should not add extra br after p', () {
      // This is the problematic case from the user:
      // Text with soft break at end, followed by list item
      final ops = [
        {'insert': 'Intro text:\nSztywniaki$softLineBreak'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Bardzo dużo papierologii$softLineBreak'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ];

      final html = deltaOpsToHtml(ops);

      // Expected: no <br> AFTER </p> (i.e., </p><br></li> is wrong)
      // But <br></p></li> is OK - that's trailing soft break inside the paragraph
      expect(html, isNot(contains('</p><br></li>')));
      expect(html, contains('<ul>'));
      expect(html, contains('Intro text:'));
      expect(html, contains('Sztywniaki'));
    });

    test('trailing soft break inside list item is preserved as br before closing p', () {
      final ops = [
        {'insert': 'Item one$softLineBreak'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Item two'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ];

      final html = deltaOpsToHtml(ops);

      // Trailing soft break is preserved as <br> inside <p>
      // <p>Item one<br></p> is correct
      expect(html, contains('<br></p></li>'));
      expect(html, contains('<ul>'));
    });
  });

  group('roundtrip', () {
    test('nested list roundtrip preserves structure', () {
      final originalOps = [
        {'insert': 'cośtam'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'podpunkt'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
      ];

      final html = deltaOpsToHtml(originalOps);
      final roundtripOps = htmlToDeltaOps(html);

      expect(roundtripOps, originalOps);
    });

    test('deeply nested list roundtrip', () {
      final originalOps = [
        {'insert': 'level 0'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'level 1'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'level 2'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 2}},
        {'insert': 'back to level 1'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'back to level 0'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];

      final html = deltaOpsToHtml(originalOps);
      final roundtripOps = htmlToDeltaOps(html);

      expect(roundtripOps, originalOps);
    });
  });
}

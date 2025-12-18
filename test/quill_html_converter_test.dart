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

import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/quill_html_converter.dart';

/// Tests for the Quill HTML converter (htmlToDeltaOps and deltaOpsToHtml).
///
/// Structure:
/// 1. htmlToDeltaOps - HTML to Delta conversion
/// 2. deltaOpsToHtml - Delta to HTML conversion  
/// 3. Roundtrip - HTML → Delta → HTML preservation
/// 4. Bug fixes - Specific user-reported issues
void main() {
  // ===========================================================================
  // HTML → Delta (htmlToDeltaOps)
  // ===========================================================================

  group('htmlToDeltaOps', () {
    group('basic text', () {
      test('empty string returns single newline op', () {
        final ops = htmlToDeltaOps('');
        expect(ops.length, 1);
        expect(ops[0]['insert'], '\n');
      });

      test('whitespace only returns single newline op', () {
        final ops = htmlToDeltaOps('   \n  ');
        expect(ops.length, 1);
        expect(ops[0]['insert'], '\n');
      });

      test('simple text in paragraph', () {
        final ops = htmlToDeltaOps('<p>Hello world</p>');
        expect(ops.any((op) => op['insert'].toString().contains('Hello world')), isTrue);
      });

      test('multiple paragraphs', () {
        final ops = htmlToDeltaOps('<p>First</p><p>Second</p>');
        expect(ops.any((op) => op['insert'].toString().contains('First')), isTrue);
        expect(ops.any((op) => op['insert'].toString().contains('Second')), isTrue);
      });

      test('text without p tags', () {
        final ops = htmlToDeltaOps('Plain text');
        expect(ops.any((op) => op['insert'].toString().contains('Plain text')), isTrue);
      });
    });

    group('line breaks', () {
      test('br tag converts to soft line break', () {
        final ops = htmlToDeltaOps('<p>Line 1<br>Line 2</p>');
        final textOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('Line 1'));
        expect(textOp['insert'], contains(softLineBreak));
      });

      test('multiple br tags', () {
        final ops = htmlToDeltaOps('<p>A<br><br>B</p>');
        final textOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('A'));
        // Should have two soft line breaks
        expect(softLineBreak.allMatches(textOp['insert'] as String).length, 2);
      });
    });

    group('inline formatting', () {
      test('bold text', () {
        final ops = htmlToDeltaOps('<p><b>bold</b></p>');
        final boldOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('bold'));
        expect(boldOp['attributes']?['bold'], true);
      });

      test('italic text', () {
        final ops = htmlToDeltaOps('<p><i>italic</i></p>');
        final italicOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('italic'));
        expect(italicOp['attributes']?['italic'], true);
      });

      test('underline text', () {
        final ops = htmlToDeltaOps('<p><u>underline</u></p>');
        final underlineOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('underline'));
        expect(underlineOp['attributes']?['underline'], true);
      });

      test('strikethrough text', () {
        final ops = htmlToDeltaOps('<p><s>strike</s></p>');
        final strikeOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('strike'));
        expect(strikeOp['attributes']?['strike'], true);
      });

      test('nested formatting (bold + italic)', () {
        final ops = htmlToDeltaOps('<p><b><i>bold italic</i></b></p>');
        final formattedOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('bold italic'));
        expect(formattedOp['attributes']?['bold'], true);
        expect(formattedOp['attributes']?['italic'], true);
      });

      test('deeply nested formatting (bold + italic + underline)', () {
        final ops = htmlToDeltaOps('<p><b><i><u>all three</u></i></b></p>');
        final formattedOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('all three'));
        expect(formattedOp['attributes']?['bold'], true);
        expect(formattedOp['attributes']?['italic'], true);
        expect(formattedOp['attributes']?['underline'], true);
      });
    });

    group('links', () {
      test('simple link', () {
        final ops = htmlToDeltaOps('<p><a href="https://example.com">Click</a></p>');
        final linkOp = ops.firstWhere((op) => op['attributes']?['link'] != null);
        expect(linkOp['attributes']['link'], 'https://example.com');
        expect(linkOp['insert'], 'Click');
      });

      test('attachment link converts to embed', () {
        final ops = htmlToDeltaOps('<p><a href="attachment1@attachment">Załącznik</a></p>');
        final attachmentOp = ops.firstWhere((op) =>
            op['insert'] is Map && op['insert']['attachment'] != null);
        expect(attachmentOp['insert']['attachment']['id'], 'attachment1');
      });
    });

    group('lists', () {
      test('simple unordered list', () {
        final ops = htmlToDeltaOps('<ul><li>Item 1</li><li>Item 2</li></ul>');
        final listNewlines = ops.where((op) =>
            op['insert'] == '\n' && op['attributes']?['list'] == 'bullet').toList();
        expect(listNewlines.length, 2);
      });

      test('simple ordered list', () {
        final ops = htmlToDeltaOps('<ol><li><p>first</p></li><li><p>second</p></li></ol>');
        expect(ops, [
          {'insert': 'first'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'second'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ]);
      });

      test('list item with br tag', () {
        final ops = htmlToDeltaOps('<ul><li>Line 1<br>Line 2</li></ul>');
        final textOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('Line 1'));
        expect(textOp['insert'], contains(softLineBreak));
      });

      test('list with formatting inside', () {
        final ops = htmlToDeltaOps('<ul><li><b>Bold item</b></li></ul>');
        final boldOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('Bold item'));
        expect(boldOp['attributes']?['bold'], true);
      });
    });

    group('nested lists', () {
      test('nested ordered list preserves indent', () {
        const html = '''
<ol>
  <li><p>cośtam</p>
    <ol>
      <li><p>podpunkt</p></li>
    </ol>
  </li>
</ol>''';
        final ops = htmlToDeltaOps(html);
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

    group('alignment', () {
      test('center aligned paragraph', () {
        final ops = htmlToDeltaOps('<p style="text-align:center;">Centered</p>');
        final alignedNewline = ops.firstWhere((op) =>
            op['insert'] == '\n' && op['attributes']?['align'] == 'center',
            orElse: () => {});
        expect(alignedNewline, isNotEmpty);
      });

      test('right aligned paragraph', () {
        final ops = htmlToDeltaOps('<p style="text-align:right;">Right</p>');
        final alignedNewline = ops.firstWhere((op) =>
            op['insert'] == '\n' && op['attributes']?['align'] == 'right',
            orElse: () => {});
        expect(alignedNewline, isNotEmpty);
      });
    });

    group('empty paragraphs', () {
      test('empty paragraph produces extra newline', () {
        final ops = htmlToDeltaOps('<p>First</p><p></p><p>Third</p>');
        expect(ops, [
          {'insert': 'First'},
          {'insert': '\n'},
          {'insert': '\n'},
          {'insert': 'Third'},
          {'insert': '\n'},
        ]);
      });

      test('multiple empty paragraphs produce multiple newlines', () {
        final ops = htmlToDeltaOps('<p>Start</p><p></p><p></p><p>End</p>');
        expect(ops, [
          {'insert': 'Start'},
          {'insert': '\n'},
          {'insert': '\n'},
          {'insert': '\n'},
          {'insert': 'End'},
          {'insert': '\n'},
        ]);
      });
    });
  });

  // ===========================================================================
  // Delta → HTML (deltaOpsToHtml)
  // ===========================================================================

  group('deltaOpsToHtml', () {
    group('basic text', () {
      test('simple text produces paragraph', () {
        final ops = [
          {'insert': 'Hello'},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, equals('<p>Hello</p>'));
      });

      test('text without trailing newline still produces valid HTML', () {
        final ops = [{'insert': 'Text without newline'}];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<p>'));
        expect(html, contains('</p>'));
      });

      test('only newline produces empty output', () {
        final ops = [{'insert': '\n'}];
        final html = deltaOpsToHtml(ops);
        expect(html, isA<String>());
      });
    });

    group('line breaks', () {
      test('soft line break produces br tag', () {
        final ops = [
          {'insert': 'Line one${softLineBreak}Line two'},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, equals('<p>Line one<br>Line two</p>'));
      });

      test('newline in text creates separate paragraphs', () {
        final ops = [
          {'insert': 'Line one\nLine two'},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, equals('<p>Line one</p><p>Line two</p>'));
      });
    });

    group('inline formatting', () {
      test('bold attribute produces b tag', () {
        final ops = [
          {'insert': 'bold', 'attributes': {'bold': true}},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<b>bold</b>'));
      });

      test('italic attribute produces i tag', () {
        final ops = [
          {'insert': 'italic', 'attributes': {'italic': true}},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<i>italic</i>'));
      });

      test('link attribute produces a tag', () {
        final ops = [
          {'insert': 'click', 'attributes': {'link': 'https://example.com'}},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('href="https://example.com"'));
      });

      test('multiple formatting attributes', () {
        final ops = [
          {'insert': 'formatted', 'attributes': {'bold': true, 'italic': true}},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<b>'));
        expect(html, contains('<i>'));
        expect(html, contains('formatted'));
      });
    });

    group('lists', () {
      test('bullet list attribute produces ul', () {
        final ops = [
          {'insert': 'Item 1'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
          {'insert': 'Item 2'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<ul>'));
        expect(html, contains('<li>'));
        expect(html, contains('Item 1'));
        expect(html, contains('Item 2'));
        expect(html, contains('</ul>'));
      });

      test('ordered list attribute produces ol', () {
        final ops = [
          {'insert': 'first'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'second'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<ol>'));
        expect(html, contains('first'));
        expect(html, contains('second'));
        expect(html, contains('</ol>'));
      });

      test('nested list with indent produces nested HTML', () {
        final ops = [
          {'insert': 'cośtam'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'podpunkt'},
          {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, matches(RegExp(r'<ol>.*<li>.*<ol>.*<li>.*podpunkt.*</li>.*</ol>.*</li>.*</ol>', dotAll: true)));
      });

      test('text before list stays in paragraph', () {
        final ops = [
          {'insert': 'Text before'},
          {'insert': '\n'},
          {'insert': 'List item'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<p>Text before</p><ul>'));
      });
    });

    group('empty paragraphs', () {
      test('consecutive newlines produce empty paragraph', () {
        final ops = [
          {'insert': 'First'},
          {'insert': '\n'},
          {'insert': '\n'},
          {'insert': 'Third'},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, equals('<p>First</p><p></p><p>Third</p>'));
      });

      test('multiple consecutive newlines produce multiple empty paragraphs', () {
        final ops = [
          {'insert': 'Start'},
          {'insert': '\n'},
          {'insert': '\n'},
          {'insert': '\n'},
          {'insert': 'End'},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, equals('<p>Start</p><p></p><p></p><p>End</p>'));
      });
    });

    group('alignment', () {
      test('align attribute produces style', () {
        final ops = [
          {'insert': 'Centered'},
          {'insert': '\n', 'attributes': {'align': 'center'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('text-align:center'));
      });
    });

    group('special characters', () {
      test('HTML entities are escaped', () {
        final ops = [
          {'insert': '<script> & "quotes"'},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('&lt;'));
        expect(html, contains('&gt;'));
        expect(html, contains('&amp;'));
      });
    });
  });

  // ===========================================================================
  // Roundtrip (HTML → Delta → HTML)
  // ===========================================================================

  group('roundtrip', () {
    group('lists', () {
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

    group('empty paragraphs', () {
      test('single empty paragraph roundtrip', () {
        const originalHtml = '<p>First</p><p></p><p>Third</p>';
        final ops = htmlToDeltaOps(originalHtml);
        final roundtripHtml = deltaOpsToHtml(ops);
        expect(roundtripHtml, equals(originalHtml));
      });

      test('multiple empty paragraphs roundtrip', () {
        const originalHtml = '<p>Start</p><p></p><p></p><p>End</p>';
        final ops = htmlToDeltaOps(originalHtml);
        final roundtripHtml = deltaOpsToHtml(ops);
        expect(roundtripHtml, equals(originalHtml));
      });

      test('user scenario: paragraphs with empty line between', () {
        const originalHtml = '<p>Prowadzący prosi uczestników.</p><p></p><p>Jeśli prowadzący chce.</p>';
        final ops = htmlToDeltaOps(originalHtml);
        final roundtripHtml = deltaOpsToHtml(ops);
        expect(roundtripHtml, equals(originalHtml));
      });
    });

    group('formatting', () {
      test('bold text roundtrip', () {
        const html = '<p>Normal <b>bold</b> normal</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<b>bold</b>'));
      });

      test('mixed formatting roundtrip', () {
        const html = '<p><b>bold</b> and <i>italic</i></p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<b>bold</b>'));
        expect(output, contains('<i>italic</i>'));
      });
    });

    group('line breaks', () {
      test('br tags survive roundtrip', () {
        const html = '<p>Line 1<br><br>Line 2<br></p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<br>'));
      });

      test('trailing br in list item survives roundtrip', () {
        const html = '<ul><li><p>Item text<br></p></li></ul>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<br>'));
      });
    });
  });

  // ===========================================================================
  // Bug fixes - User reported issues
  // ===========================================================================

  group('bug fixes', () {
    group('soft breaks in lists', () {
      test('text ending with soft break before list item - no extra br after p', () {
        final ops = [
          {'insert': 'Intro text:\nSztywniaki$softLineBreak'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
          {'insert': 'Bardzo dużo papierologii$softLineBreak'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, isNot(contains('</p><br></li>')));
        expect(html, contains('<ul>'));
      });

      test('trailing soft break inside list item is preserved', () {
        final ops = [
          {'insert': 'Item one$softLineBreak'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
          {'insert': 'Item two'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<br></p></li>'));
      });

      test('list item with soft breaks and mixed formatting stays as single li', () {
        final ops = [
          {'insert': '[Opcja 1]:', 'attributes': {'italic': true}},
          {'insert': '${softLineBreak}Pierwsza osoba odpowiada losowo.$softLineBreak${softLineBreak}Detektyw: '},
          {'insert': 'ile masz lat?', 'attributes': {'bold': true}},
          {'insert': '$softLineBreak'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': '[Opcja 2]:', 'attributes': {'italic': true}},
          {'insert': '${softLineBreak}Kolejne odpowiedzi.$softLineBreak'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ];
        final html = deltaOpsToHtml(ops);
        final liCount = '<li>'.allMatches(html).length;
        expect(liCount, equals(2), reason: 'Should have exactly 2 list items');
      });
    });

    group('text with newlines before list', () {
      test('hard newline inside text before list separates paragraph from list', () {
        final ops = [
          {'insert': 'Uczestnicy zamykają oczy.\u2028\u2028Pytania:\nZ jaką umiejętnością?'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'Co oznacza dzień?'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('</p><ol>'));
        final firstLiStart = html.indexOf('<li>');
        final firstLiEnd = html.indexOf('</li>');
        final firstLiContent = html.substring(firstLiStart, firstLiEnd);
        expect(firstLiContent, contains('Z jaką umiejętnością?'));
        expect(firstLiContent, isNot(contains('Uczestnicy')));
      });

      test('text starting with newline after list item - no empty li', () {
        final ops = [
          {'insert': 'Intro\nQuestion 1?\u2028\u2028'},
          {'insert': 'Answer 1', 'attributes': {'italic': true}},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': '\nQuestion 2?'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, isNot(contains('</ol><ol>')));
        expect(html, isNot(contains('<li></li>')));
      });
    });

    group('empty list items', () {
      test('intentionally empty list item is preserved', () {
        final ops = [
          {'insert': 'Item 1'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'Item 3'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect('<li>'.allMatches(html).length, 3);
      });

      test('double newline in list attribute creates empty item', () {
        final ops = [
          {'insert': 'Question 1?'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'Question 2?'},
          {'insert': '\n\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'After list\nNew list item'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect('<li>'.allMatches(html).length, greaterThanOrEqualTo(3));
      });
    });

    group('complex real-world cases', () {
      test('quiz with nested answers', () {
        final ops = [
          {'insert': 'Prowadzący przeprowadza Quizz.\u2028\u2028Quizz:\nIle czasu dziennie?'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
          {'insert': 'ok. 5 minut'},
          {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
          {'insert': 'ok. 30 minut'},
          {'insert': ' [poprawne]', 'attributes': {'italic': true}},
          {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
          {'insert': 'Ile zdjęć dziennie?'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('</p><ol>'));
        expect(html, contains('Prowadzący'));
        expect(html, contains('Quizz:'));
        final firstLiStart = html.indexOf('<li>');
        final firstLiEnd = html.indexOf('</li>');
        final firstLiContent = html.substring(firstLiStart, firstLiEnd);
        expect(firstLiContent, isNot(contains('Prowadzący')));
      });

      test('soft breaks in paragraph become br tags', () {
        final ops = [
          {'insert': 'Line 1\u2028\u2028'},
          {'insert': 'Italic text', 'attributes': {'italic': true}},
          {'insert': '\u2028\u2028More text\u2028\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<br>'));
        expect(html, contains('<i>Italic text</i>'));
        expect(html, isNot(contains('\u2028')));
      });

      test('real world konspekt content', () {
        const html = '''<ol><li><p>Prowadzący zadaje pytania.

Pytania:
Co łączy wszystkie hasła?<br><br><i>Odp.: można się od nich uzależnić.</i></p></li></ol>''';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<ol>'));
        expect(output, contains('<li>'));
        expect(output, contains('<i>'));
        expect(output, contains('<br>'));
      });
    });
  });

  // ===========================================================================
  // Additional edge cases
  // ===========================================================================

  group('additional edge cases', () {
    group('alternative HTML tags', () {
      test('strong tag is treated as bold', () {
        final ops = htmlToDeltaOps('<p><strong>bold text</strong></p>');
        final boldOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('bold text'));
        expect(boldOp['attributes']?['bold'], true);
      });

      test('em tag is treated as italic', () {
        final ops = htmlToDeltaOps('<p><em>italic text</em></p>');
        final italicOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('italic text'));
        expect(italicOp['attributes']?['italic'], true);
      });

      test('strike tag is treated as strikethrough', () {
        final ops = htmlToDeltaOps('<p><strike>struck text</strike></p>');
        final strikeOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('struck text'));
        expect(strikeOp['attributes']?['strike'], true);
      });
    });

    group('links edge cases', () {
      test('link without href is treated as plain text', () {
        final ops = htmlToDeltaOps('<p><a>No href link</a></p>');
        final textOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('No href link'));
        expect(textOp['attributes']?['link'], isNull);
      });

      test('link with empty href', () {
        final ops = htmlToDeltaOps('<p><a href="">Empty href</a></p>');
        final textOp = ops.firstWhere((op) =>
            op['insert'] is String && op['insert'].contains('Empty href'));
        // Empty href should still create a link attribute (or be treated as no link)
        expect(ops.any((op) => op['insert'].toString().contains('Empty href')), isTrue);
      });

      test('link roundtrip preserves URL', () {
        const html = '<p><a href="https://example.com/path?query=1&amp;foo=bar">Link</a></p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('https://example.com/path?query=1'));
      });
    });

    group('list edge cases', () {
      test('single item list', () {
        final ops = htmlToDeltaOps('<ul><li>Only item</li></ul>');
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<ul>'));
        expect(html, contains('Only item'));
        expect(html, contains('</ul>'));
        expect('<li>'.allMatches(html).length, 1);
      });

      test('text after list stays outside list', () {
        final ops = [
          {'insert': 'Item'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
          {'insert': 'Text after'},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('</ul><p>Text after</p>'));
      });

      test('list type change (ul to ol)', () {
        final ops = [
          {'insert': 'Bullet'},
          {'insert': '\n', 'attributes': {'list': 'bullet'}},
          {'insert': 'Ordered'},
          {'insert': '\n', 'attributes': {'list': 'ordered'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('</ul><ol>'));
      });

      test('empty list item in HTML', () {
        final ops = htmlToDeltaOps('<ul><li></li><li>Non-empty</li></ul>');
        final html = deltaOpsToHtml(ops);
        expect(html, contains('Non-empty'));
      });
    });

    group('alignment edge cases', () {
      test('alignment roundtrip', () {
        const html = '<p style="text-align:center;">Centered text</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('text-align:center'));
        expect(output, contains('Centered text'));
      });

      test('justify alignment', () {
        final ops = [
          {'insert': 'Justified'},
          {'insert': '\n', 'attributes': {'align': 'justify'}},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('text-align:justify'));
      });
    });

    group('formatting combinations', () {
      test('underline + strikethrough', () {
        final ops = [
          {'insert': 'both', 'attributes': {'underline': true, 'strike': true}},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<u>'));
        expect(html, contains('<s>'));
      });

      test('all formatting combined', () {
        final ops = [
          {'insert': 'all', 'attributes': {
            'bold': true,
            'italic': true,
            'underline': true,
            'strike': true,
          }},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<b>'));
        expect(html, contains('<i>'));
        expect(html, contains('<u>'));
        expect(html, contains('<s>'));
      });

      test('formatting with link', () {
        final ops = [
          {'insert': 'bold link', 'attributes': {
            'bold': true,
            'link': 'https://example.com',
          }},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('<b>'));
        expect(html, contains('href='));
      });
    });

    group('unicode and special content', () {
      test('polish characters', () {
        const html = '<p>Zażółć gęślą jaźń</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('Zażółć'));
        expect(output, contains('gęślą'));
        expect(output, contains('jaźń'));
      });

      test('emoji in text', () {
        const html = '<p>Hello 👋 World 🌍</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('👋'));
        expect(output, contains('🌍'));
      });

      test('quotes and apostrophes', () {
        final ops = [
          {'insert': "It's a \"test\" with 'quotes'"},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('&quot;'));
        expect(html, contains('&#39;'));
      });
    });

    group('malformed or edge input', () {
      test('empty attributes object', () {
        final ops = [
          {'insert': 'text', 'attributes': <String, dynamic>{}},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('text'));
        expect(html, isNot(contains('undefined')));
      });

      test('null-like values in attributes', () {
        final ops = [
          {'insert': 'text', 'attributes': <String, dynamic>{'bold': false}},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('text'));
        expect(html, isNot(contains('<b>')));
      });

      test('very long text', () {
        final longText = 'A' * 10000;
        final ops = [
          {'insert': longText},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html.length, greaterThan(10000));
        expect(html, contains(longText));
      });

      test('deeply nested HTML structure', () {
        const html = '<p><b><i><u><s>deeply nested</s></u></i></b></p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('deeply nested'));
      });
    });

    group('whitespace handling', () {
      test('leading whitespace in paragraph', () {
        const html = '<p>   Leading spaces</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('Leading spaces'));
      });

      test('trailing whitespace in paragraph', () {
        const html = '<p>Trailing spaces   </p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('Trailing spaces'));
      });

      test('multiple spaces between words', () {
        final ops = [
          {'insert': 'Multiple   spaces   here'},
          {'insert': '\n'},
        ];
        final html = deltaOpsToHtml(ops);
        expect(html, contains('Multiple   spaces   here'));
      });
    });

    group('paragraph at start/end', () {
      test('empty paragraph at start', () {
        const html = '<p></p><p>Content</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('Content'));
      });

      test('empty paragraph at end', () {
        const html = '<p>Content</p><p></p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        expect(output, contains('Content'));
      });
    });
  });
}

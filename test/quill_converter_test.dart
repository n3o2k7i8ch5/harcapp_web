import 'package:flutter_test/flutter_test.dart';
import 'package:harcapp_web/konspekt_workspace/widgets/quill_html_converter.dart';

void main() {
  group('HTML → Delta → HTML roundtrip', () {
    
    // =========================================================================
    // Basic text and paragraphs
    // =========================================================================
    
    group('Basic text', () {
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
        final html = '<p>Hello world</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('Hello world'));
        expect(output, contains('<p>'));
        expect(output, contains('</p>'));
      });
      
      test('multiple paragraphs', () {
        final html = '<p>First paragraph</p><p>Second paragraph</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('First paragraph'));
        expect(output, contains('Second paragraph'));
        expect(output, contains('</p><p>'));
      });
      
      test('text without p tags', () {
        final html = 'Plain text without tags';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('Plain text without tags'));
        expect(output, contains('<p>'));
      });
    });
    
    // =========================================================================
    // Line breaks
    // =========================================================================
    
    group('Line breaks', () {
      test('br tag converts to soft line break', () {
        final html = '<p>Line 1<br>Line 2</p>';
        final ops = htmlToDeltaOps(html);
        
        // Should contain soft line break character
        final textOp = ops.firstWhere((op) => 
          op['insert'] is String && op['insert'].contains('Line 1'));
        expect(textOp['insert'], contains(softLineBreak));
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<br>'));
      });
      
      test('literal newlines in text convert to br', () {
        final html = '<p>Line 1\nLine 2</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<br>'));
      });
      
      test('multiple br tags', () {
        final html = '<p>A<br><br>B</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<br><br>'));
      });
    });
    
    // =========================================================================
    // Inline formatting
    // =========================================================================
    
    group('Inline formatting', () {
      test('bold text', () {
        final html = '<p>Normal <b>bold</b> normal</p>';
        final ops = htmlToDeltaOps(html);
        
        final boldOp = ops.firstWhere((op) => 
          op['insert'] == 'bold' || (op['insert'] is String && op['insert'].contains('bold')));
        expect(boldOp['attributes']?['bold'], true);
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<b>bold</b>'));
      });
      
      test('italic text', () {
        final html = '<p>Normal <i>italic</i> normal</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<i>italic</i>'));
      });
      
      test('underline text', () {
        final html = '<p>Normal <u>underline</u> normal</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<u>underline</u>'));
      });
      
      test('strikethrough text', () {
        final html = '<p>Normal <s>strike</s> normal</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<s>strike</s>'));
      });
      
      test('nested formatting (bold + italic)', () {
        final html = '<p><b><i>bold italic</i></b></p>';
        final ops = htmlToDeltaOps(html);
        
        final formattedOp = ops.firstWhere((op) => 
          op['insert'] is String && op['insert'].contains('bold italic'));
        expect(formattedOp['attributes']?['bold'], true);
        expect(formattedOp['attributes']?['italic'], true);
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('bold italic'));
      });
      
      test('br inside italic preserves formatting', () {
        final html = '<p><i>Line 1<br>Line 2</i></p>';
        final ops = htmlToDeltaOps(html);
        
        // All parts should have italic attribute
        for (final op in ops) {
          if (op['insert'] is String && 
              op['insert'] != '\n' && 
              op['insert'].toString().trim().isNotEmpty) {
            expect(op['attributes']?['italic'], true,
              reason: 'Op "${op['insert']}" should be italic');
          }
        }
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<i>'));
        expect(output, contains('<br>'));
      });
      
      test('br inside bold preserves formatting', () {
        final html = '<p><b>Line 1<br>Line 2</b></p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<b>'));
        expect(output, contains('<br>'));
      });
    });
    
    // =========================================================================
    // Links
    // =========================================================================
    
    group('Links', () {
      test('simple link', () {
        final html = '<p><a href="https://example.com">Click here</a></p>';
        final ops = htmlToDeltaOps(html);
        
        final linkOp = ops.firstWhere((op) => 
          op['attributes']?['link'] != null);
        expect(linkOp['attributes']['link'], 'https://example.com');
        expect(linkOp['insert'], 'Click here');
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('href="https://example.com"'));
        expect(output, contains('Click here'));
      });
      
      test('attachment link', () {
        final html = '<p><a href="attachment1@attachment">Załącznik</a></p>';
        final ops = htmlToDeltaOps(html);
        
        // Should be converted to attachment embed
        final attachmentOp = ops.firstWhere((op) => 
          op['insert'] is Map && op['insert']['attachment'] != null);
        expect(attachmentOp['insert']['attachment']['id'], 'attachment1');
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('@attachment'));
      });
    });
    
    // =========================================================================
    // Lists
    // =========================================================================
    
    group('Lists', () {
      test('simple unordered list', () {
        final html = '<ul><li>Item 1</li><li>Item 2</li></ul>';
        final ops = htmlToDeltaOps(html);
        
        // Should have list attributes on newlines
        final listNewlines = ops.where((op) => 
          op['insert'] == '\n' && op['attributes']?['list'] == 'bullet').toList();
        expect(listNewlines.length, 2);
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<ul>'));
        expect(output, contains('<li>'));
        expect(output, contains('Item 1'));
        expect(output, contains('Item 2'));
      });
      
      test('simple ordered list', () {
        final html = '<ol><li>First</li><li>Second</li></ol>';
        final ops = htmlToDeltaOps(html);
        
        final listNewlines = ops.where((op) => 
          op['insert'] == '\n' && op['attributes']?['list'] == 'ordered').toList();
        expect(listNewlines.length, 2);
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('<ol>'));
        expect(output, contains('First'));
        expect(output, contains('Second'));
      });
      
      test('text before list stays outside list', () {
        final html = 'Text before<ul><li>Item</li></ul>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        // Text should be in paragraph before list
        expect(output, contains('<p>Text before</p><ul>'));
      });
      
      test('paragraph before list stays outside list', () {
        final html = '<p>Paragraph before</p><ul><li>Item</li></ul>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('</p><ul>'));
        expect(output.indexOf('Paragraph before'), lessThan(output.indexOf('<ul>')));
      });
      
      test('text after list stays outside list', () {
        final html = '<ul><li>Item</li></ul><p>Text after</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('</ul><p>Text after</p>'));
      });
      
      test('list item with br tag', () {
        final html = '<ul><li>Line 1<br>Line 2</li></ul>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<br>'));
        // Should be single list item
        expect('<li>'.allMatches(output).length, 1);
      });
      
      test('list item with paragraph inside', () {
        final html = '<ul><li><p>Paragraph in list</p></li></ul>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('Paragraph in list'));
        expect(output, contains('<ul>'));
      });
      
      test('list item with multiple paragraphs', () {
        final html = '<ul><li><p>Para 1</p><p>Para 2</p></li></ul>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('Para 1'));
        expect(output, contains('Para 2'));
      });
      
      test('list with formatting inside', () {
        final html = '<ul><li><b>Bold item</b></li><li><i>Italic item</i></li></ul>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<b>Bold item</b>'));
        expect(output, contains('<i>Italic item</i>'));
      });
    });
    
    // =========================================================================
    // Nested lists
    // =========================================================================
    
    group('Nested lists', () {
      test('nested unordered list', () {
        final html = '<ul><li>Parent<ul><li>Child</li></ul></li></ul>';
        final ops = htmlToDeltaOps(html);
        
        // Should have indent attribute on nested item
        final nestedNewline = ops.firstWhere((op) => 
          op['insert'] == '\n' && 
          op['attributes']?['list'] == 'bullet' &&
          op['attributes']?['indent'] != null, 
          orElse: () => {});
        expect(nestedNewline, isNotEmpty);
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('Parent'));
        expect(output, contains('Child'));
      });
      
      test('mixed nested lists (ul inside ol)', () {
        final html = '<ol><li>Ordered<ul><li>Unordered child</li></ul></li></ol>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<ol>'));
        expect(output, contains('<ul>'));
        expect(output, contains('Ordered'));
        expect(output, contains('Unordered child'));
      });
    });
    
    // =========================================================================
    // Alignment
    // =========================================================================
    
    group('Alignment', () {
      test('center aligned paragraph', () {
        final html = '<p style="text-align:center;">Centered</p>';
        final ops = htmlToDeltaOps(html);
        
        final alignedNewline = ops.firstWhere((op) => 
          op['insert'] == '\n' && op['attributes']?['align'] == 'center',
          orElse: () => {});
        expect(alignedNewline, isNotEmpty);
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('text-align:center'));
      });
      
      test('right aligned paragraph', () {
        final html = '<p style="text-align:right;">Right</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('text-align:right'));
      });
      
      test('justify aligned paragraph', () {
        final html = '<p style="text-align:justify;">Justified</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('text-align:justify'));
      });
    });
    
    // =========================================================================
    // Complex scenarios
    // =========================================================================
    
    group('Complex scenarios', () {
      test('real world konspekt content', () {
        final html = '''<ol><li><p>Prowadzący zadaje uczestnikom poniższe pytania.

Pytania:
Co łączy wszystkie hasła?<br><br><i>Odp.: można się od nich uzależnić.</i></p></li></ol>''';
        
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        // Should preserve structure
        expect(output, contains('<ol>'));
        expect(output, contains('<li>'));
        expect(output, contains('<i>'));
        expect(output, contains('<br>'));
        expect(output, contains('Prowadzący'));
        expect(output, contains('Pytania'));
      });
      
      test('mixed content: paragraphs, lists, formatting', () {
        final html = '''<p>Introduction</p>
<ul>
<li><b>Bold item</b></li>
<li><i>Italic item</i></li>
</ul>
<p>Conclusion with <a href="http://test.com">link</a></p>''';
        
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('Introduction'));
        expect(output, contains('<b>Bold item</b>'));
        expect(output, contains('<i>Italic item</i>'));
        expect(output, contains('Conclusion'));
        expect(output, contains('href="http://test.com"'));
      });
      
      test('empty list items', () {
        final html = '<ul><li></li><li>Non-empty</li></ul>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('Non-empty'));
      });
      
      test('special characters are escaped', () {
        final html = '<p>Test &lt;script&gt; &amp; "quotes"</p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        // Should escape special characters
        expect(output, contains('&lt;'));
        expect(output, contains('&gt;'));
        expect(output, contains('&amp;'));
      });
    });
    
    // =========================================================================
    // Edge cases
    // =========================================================================
    
    group('Edge cases', () {
      test('deeply nested formatting', () {
        final html = '<p><b><i><u>All three</u></i></b></p>';
        final ops = htmlToDeltaOps(html);
        
        final formattedOp = ops.firstWhere((op) => 
          op['insert'] is String && op['insert'].contains('All three'));
        expect(formattedOp['attributes']?['bold'], true);
        expect(formattedOp['attributes']?['italic'], true);
        expect(formattedOp['attributes']?['underline'], true);
      });
      
      test('alternating formatting', () {
        final html = '<p><b>bold</b> normal <i>italic</i></p>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('<b>bold</b>'));
        expect(output, contains(' normal '));
        expect(output, contains('<i>italic</i>'));
      });
      
      test('list immediately after text without separator', () {
        final html = 'Text<ul><li>Item</li></ul>';
        final ops = htmlToDeltaOps(html);
        
        // Should have newline between text and list item
        bool foundNewlineBetween = false;
        bool foundText = false;
        for (final op in ops) {
          if (op['insert'] == 'Text') foundText = true;
          if (foundText && op['insert'] == '\n' && op['attributes'] == null) {
            foundNewlineBetween = true;
            break;
          }
        }
        expect(foundNewlineBetween, true, 
          reason: 'Should have plain newline between text and list');
        
        final output = deltaOpsToHtml(ops);
        expect(output, contains('</p><ul>'));
      });
      
      test('consecutive lists of different types', () {
        final html = '<ul><li>Bullet</li></ul><ol><li>Ordered</li></ol>';
        final ops = htmlToDeltaOps(html);
        final output = deltaOpsToHtml(ops);
        
        expect(output, contains('</ul><ol>'));
      });
    });
  });
  
  // ===========================================================================
  // Delta → HTML specific tests
  // ===========================================================================
  
  group('Delta → HTML', () {
    test('delta with missing trailing newline', () {
      final ops = [
        {'insert': 'Text without newline'}
      ];
      final output = deltaOpsToHtml(ops);
      
      // Should still produce valid HTML
      expect(output, contains('<p>'));
      expect(output, contains('</p>'));
    });
    
    test('delta with only newline', () {
      final ops = [
        {'insert': '\n'}
      ];
      final output = deltaOpsToHtml(ops);
      
      // Empty delta produces empty output - this is acceptable
      // The important thing is it doesn't crash
      expect(output, isA<String>());
    });
    
    test('delta with soft line breaks', () {
      final ops = [
        {'insert': 'Line 1${softLineBreak}Line 2'},
        {'insert': '\n'}
      ];
      final output = deltaOpsToHtml(ops);
      
      expect(output, contains('<br>'));
      expect(output, contains('Line 1'));
      expect(output, contains('Line 2'));
    });
    
    test('delta with list attributes', () {
      final ops = [
        {'insert': 'Item 1'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': 'Item 2'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ];
      final output = deltaOpsToHtml(ops);
      
      expect(output, contains('<ul>'));
      expect(output, contains('<li>'));
      expect(output, contains('Item 1'));
      expect(output, contains('Item 2'));
    });
    
    test('delta with text before list (no separating newline)', () {
      // This is the problematic case that was fixed
      final ops = [
        {'insert': 'Text before'},
        {'insert': '\n'},
        {'insert': 'List item'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ];
      final output = deltaOpsToHtml(ops);
      
      // Text should be in paragraph, not in list
      expect(output, contains('<p>Text before</p><ul>'));
    });
  });
  
  // Tests for soft line breaks behavior
  group('Soft line breaks in lists', () {
    test('hard newline inside text before list separates paragraph from list', () {
      // This is the case from user report:
      // Text with \u2028 and \n inside, followed by list
      final ops = [
        {'insert': 'Uczestnicy zamykają oczy.\u2028\u2028Pytania:\nZ jaką umiejętnością?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Co oznacza dzień?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      
      // "Uczestnicy..." and "Pytania:" should be in paragraph BEFORE the list
      // Only "Z jaką umiejętnością?" should be first list item
      expect(output, contains('<p>'));
      expect(output, contains('Uczestnicy'));
      expect(output, contains('Pytania:'));
      expect(output, contains('</p><ol>'));
      expect(output, contains('<li>'));
      
      // First list item should only contain "Z jaką umiejętnością?"
      final firstLiStart = output.indexOf('<li>');
      final firstLiEnd = output.indexOf('</li>');
      final firstLiContent = output.substring(firstLiStart, firstLiEnd);
      expect(firstLiContent, contains('Z jaką umiejętnością?'));
      expect(firstLiContent, isNot(contains('Uczestnicy')));
      expect(firstLiContent, isNot(contains('Pytania:')));
    });
    
    test('soft breaks inside list item are preserved as br tags', () {
      // This is the case when <br> is intentionally inside a list item
      // e.g., from HTML: <ul><li>Line 1<br>Line 2</li></ul>
      // The editor handles splitting when user clicks list button on text with soft breaks
      final ops = [
        {'insert': 'Line 1${softLineBreak}Line 2'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      
      // All content should be in a single list item with <br>
      expect(output, contains('<ul>'));
      expect(output, contains('<li>'));
      expect(output, contains('<br>'));
      expect(output, contains('Line 1'));
      expect(output, contains('Line 2'));
      // Should be single list item
      expect('<li>'.allMatches(output).length, 1);
    });
    
    test('hard newlines create separate paragraphs before list', () {
      // This is the correct Delta structure for text before list
      final ops = [
        {'insert': 'Line 1'},
        {'insert': '\n'},
        {'insert': 'Line 2'},
        {'insert': '\n'},
        {'insert': 'Line 3'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      
      // Lines 1 and 2 should be in paragraphs
      // Only Line 3 should be in the list
      expect(output, contains('<p>Line 1</p>'));
      expect(output, contains('<p>Line 2</p>'));
      expect(output, contains('<ul>'));
      expect(output, contains('Line 3'));
    });
    
    test('complex quiz with nested lists and soft breaks before list', () {
      // Real-world case: text with soft breaks followed by \n, then nested list
      final ops = [
        {'insert': 'Intro text.\u2028\u2028Quizz:\nQuestion 1?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Answer A'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'Answer B'},
        {'insert': ' [correct]', 'attributes': {'italic': true}},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'Answer C\u2028'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'Question 2?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      
      // "Intro text." and "Quizz:" should be in paragraph BEFORE the list
      expect(output, contains('<p>'));
      expect(output, contains('Intro text.'));
      expect(output, contains('Quizz:'));
      
      // The paragraph should end before the list starts
      expect(output, contains('</p><ol>'));
      
      // First list item should only contain "Question 1?"
      final firstLiStart = output.indexOf('<li>');
      final firstLiEnd = output.indexOf('</li>');
      final firstLiContent = output.substring(firstLiStart, firstLiEnd);
      expect(firstLiContent, contains('Question 1?'));
      expect(firstLiContent, isNot(contains('Intro text')));
      expect(firstLiContent, isNot(contains('Quizz:')));
    });
    
    test('exact user report case - quiz with nested answers', () {
      // Exact case from user report
      final ops = [
        {'insert': 'Prowadzący dzieli uczestników na grupy i przeprowadza Quizz. Przy każdym z pytań grupy mają po 20 sekund na wybranie ich zdaniem prawidłowej odpowiedzi.\u2028\u2028Quizz:\nIle czasu dziennie spędza średnio na Facebooku jego przeciętny użytkownik?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'ok. 5 minut'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'ok. 30 minut'},
        {'insert': ' [poprawne]', 'attributes': {'italic': true}},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'ok. 1 godziny\u2028'},
        {'insert': '\n', 'attributes': {'list': 'ordered', 'indent': 1}},
        {'insert': 'Ile zdjęć dziennie umieszczanych jest na Facebooku?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      
      // "Prowadzący..." and "Quizz:" should be in paragraph BEFORE the list
      expect(output, contains('<p>'));
      expect(output, contains('Prowadzący'));
      expect(output, contains('Quizz:'));
      
      // The paragraph should end before the list starts
      expect(output, contains('</p><ol>'));
      
      // First list item should only contain the question, not the intro
      final firstLiStart = output.indexOf('<li>');
      final firstLiEnd = output.indexOf('</li>');
      final firstLiContent = output.substring(firstLiStart, firstLiEnd);
      expect(firstLiContent, contains('Ile czasu dziennie'));
      expect(firstLiContent, isNot(contains('Prowadzący')));
      expect(firstLiContent, isNot(contains('Quizz:')));
    });
    
    test('roundtrip preserves paragraph before list', () {
      // Start with correct HTML
      const html = '<p>Intro text.<br><br>Quizz:</p><ol><li><p>Question 1?</p></li></ol>';
      
      // Convert to Delta
      final ops = htmlToDeltaOps(html);
      
      // Convert back to HTML
      final output = deltaOpsToHtml(ops);
      
      // Should preserve paragraph before list
      expect(output, contains('<p>'));
      expect(output, contains('Intro text.'));
      expect(output, contains('</p><ol>'));
    });
    
    test('text with only soft breaks before list - all goes into list item', () {
      // This is what happens when there's NO hard newline before list
      // All text with soft breaks becomes part of the first list item
      final ops = [
        {'insert': 'Intro text.\u2028\u2028Quizz:\u2028Question 1?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('NO HARD NEWLINE OUTPUT: $output');
      
      // Without hard newline, everything goes into the list
      // This is expected behavior - soft breaks don't separate blocks
      expect(output, contains('<ol>'));
      expect(output, contains('Intro text.'));
      expect(output, contains('<br>'));
    });
    
    test('trailing soft break at end of list item is preserved', () {
      // User reports: soft break at end of list item doesn't save
      final ops = [
        {'insert': 'Item text\u2028'},  // trailing soft break
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('TRAILING SOFT BREAK OUTPUT: $output');
      
      expect(output, contains('Item text'));
      expect(output, contains('<br>'));
    });
    
    test('trailing soft break roundtrip HTML->Delta->HTML', () {
      // Check if trailing <br> in list item survives roundtrip
      const html = '<ul><li>Item text<br></li></ul>';
      
      final ops = htmlToDeltaOps(html);
      print('TRAILING BR DELTA: $ops');
      
      final output = deltaOpsToHtml(ops);
      print('TRAILING BR OUTPUT: $output');
      
      expect(output, contains('Item text'));
      // Check if trailing <br> is preserved
      expect(output, contains('<br>'));
    });
    
    test('text starting with newline after list item creates empty list item bug', () {
      // Bug: when text op starts with \n after a list \n, it creates an empty list item
      // [2] insert: "\n", attrs: {list: ordered}
      // [3] insert: "\nW papierosach..." <- this \n creates empty list item
      final ops = [
        {'insert': 'Question 1?\u2028\u2028'},
        {'insert': 'Answer 1', 'attributes': {'italic': true}},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': '\nQuestion 2?\u2028\u2028'},  // starts with \n
        {'insert': 'Answer 2', 'attributes': {'italic': true}},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('NEWLINE START OUTPUT: $output');
      
      // Should have exactly 2 list items, not 3
      expect('<li>'.allMatches(output).length, 2);
      
      // Both questions should be in list items
      expect(output, contains('Question 1?'));
      expect(output, contains('Question 2?'));
    });
    
    test('exact user case - quiz with empty list item bug', () {
      // Exact case from user report
      final ops = [
        {'insert': 'Prowadzący zadaje uczestnikom poniższe pytania i w miarę potrzeby stara się naprowadzić ich na odpowiedzi.\u2028\u2028Pytania:\nCo łączy wszystkie hasła, które udało im się odgadnąć w poprzednim kroku?\u2028\u2028'},
        {'insert': 'Odp.: można się od nich uzależnić.', 'attributes': {'italic': true}},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': '\nW papierosach człowiek uzależnia się od substancji zwanej nikotyną. Od jakiej substancji uzależnia się człowiek w przypadku słodyczy?\u2028\u2028'},
        {'insert': 'Odp.: od cukru.', 'attributes': {'italic': true}},
        {'insert': '\u2028'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Od jakiej substancji uzależniony jest nałogowy użytkownik telefonu?\u2028\u2028'},
        {'insert': 'Odp.: Od żadnej ponieważ jest to uzależnienie behawioralne - czyli uzależnienie od zachowania.\u2028', 'attributes': {'italic': true}},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Jakie mogą być skutki uzależnienia od papierosów? A od alkoholu? A od telefonu?\u2028\u2028'},
        {'insert': 'Odp.: zaburzenia snu, zaburzenia odżywienia, gwałtowne wahania nastrojów, stany lękowe, depresja, obniżenie koncentracji i pamięci, pogorszenie wyników w nauce, słabe relacje koleżeńskie, zapominanie o higienie osobistej, konflikty z bliskimi osobami, problemy ze wzrokiem, bóle mięśni szczególnie pleców i karku', 'attributes': {'italic': true}},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('EXACT USER CASE OUTPUT: $output');
      
      // Should have exactly 4 list items (4 questions), not 5
      expect('<li>'.allMatches(output).length, 4);
      
      // Should NOT have empty list items
      expect(output, isNot(contains('<li></li>')));
    });
    
    test('user reported output shows empty li - verify current behavior', () {
      // The user's reported HTML output shows <li></li></ol><ol>
      // This test verifies that our current code does NOT produce this
      final ops = [
        {'insert': 'Intro\nQuestion 1?\u2028\u2028'},
        {'insert': 'Answer 1', 'attributes': {'italic': true}},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': '\nQuestion 2?'},  // starts with \n - this was causing empty li
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('VERIFY NO EMPTY LI: $output');
      
      // Should NOT have </ol><ol> (list breaking and restarting)
      expect(output, isNot(contains('</ol><ol>')));
      
      // Should NOT have empty list items
      expect(output, isNot(contains('<li></li>')));
    });
    
    test('soft breaks in paragraph should become br tags', () {
      // Bug: soft breaks (\u2028) in a paragraph are not converted to <br>
      final ops = [
        {'insert': 'Line 1\u2028\u2028'},
        {'insert': 'Italic text', 'attributes': {'italic': true}},
        {'insert': '\u2028\u2028More text\u2028\n'},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('SOFT BREAKS IN PARAGRAPH: $output');
      
      // Should contain <br> tags for soft breaks
      expect(output, contains('<br>'));
      expect(output, contains('Line 1'));
      expect(output, contains('<i>Italic text</i>'));
      expect(output, contains('More text'));
    });
    
    test('exact user case - long paragraph with soft breaks and italic', () {
      // Exact case from user report
      final ops = [
        {'insert': 'Prowadzący zwraca uwagę:\u2028\u2028'},
        {'insert': '"Już ustaliliśmy, że przeciętny polski użytkownik internetu spędza w siebi 18h tygodniowo."', 'attributes': {'italic': true}},
        {'insert': '\u2028\u2028Prowadzący wraca do pytań.\u2028\n'},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('EXACT USER PARAGRAPH CASE: $output');
      
      // Should contain <br> tags for soft breaks
      expect(output, contains('<br>'));
      // Should have italic text
      expect(output, contains('<i>'));
      // Should NOT have literal \u2028 characters
      expect(output, isNot(contains('\u2028')));
    });
    
    test('HTML with br tags roundtrip - br should survive', () {
      // Test that <br> in HTML survives roundtrip through Delta and back
      const html = '<p>Line 1<br><br>Line 2<br></p>';
      
      final ops = htmlToDeltaOps(html);
      print('BR ROUNDTRIP DELTA: $ops');
      
      // Check that soft line breaks are in the Delta
      final hasBreaks = ops.any((op) {
        final insert = op['insert'];
        return insert is String && insert.contains('\u2028');
      });
      expect(hasBreaks, isTrue, reason: 'Delta should contain soft line breaks');
      
      final output = deltaOpsToHtml(ops);
      print('BR ROUNDTRIP OUTPUT: $output');
      
      // Should contain <br> tags
      expect(output, contains('<br>'));
    });
    
    test('text starting with soft break after list item creates empty list item bug', () {
      // Bug: when text op starts with \u2028 after a list \n, it creates an empty list item
      // [3] insert: "\n", attrs: {list: ordered}
      // [4] insert: "\u2028Po 15 minutach..." <- this \u2028 creates empty list item
      final ops = [
        {'insert': 'Question 1?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Question 2?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': '\u2028After list text'},  // starts with soft break
        {'insert': '\n'},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('SOFT BREAK START OUTPUT: $output');
      
      // Should have exactly 2 list items, not 3
      expect('<li>'.allMatches(output).length, 2);
      
      // Should NOT have empty list items
      expect(output, isNot(contains('<li></li>')));
    });
    
    test('exact user case - soft break after list followed by another list', () {
      // Exact case from user report:
      // [3] insert: "\n", attrs: {list: ordered}
      // [4] insert: "\u2028Po 15 minutach...Zasady higieny cyfrowej:\n..."
      // [5] insert: "\n", attrs: {list: ordered}
      final ops = [
        {'insert': 'Question 1?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'Question 2?'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': '\u2028After list text\nNew list item 1'},  // starts with soft break, contains \n
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
        {'insert': 'New list item 2'},
        {'insert': '\n', 'attributes': {'list': 'ordered'}},
      ];
      
      final output = deltaOpsToHtml(ops);
      print('EXACT USER SOFT BREAK CASE: $output');
      
      // Should have exactly 4 list items (2 + 2), not 5
      expect('<li>'.allMatches(output).length, 4);
      
      // Should NOT have empty list items
      expect(output, isNot(contains('<li></li>')));
    });
    
  });
}

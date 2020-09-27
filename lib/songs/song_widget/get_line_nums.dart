String getLineNums(String text){
  String lineNum = '';

  List<String> lines = text.split('\n');
  int count = 0;
  for (int i = 0; i < lines.length; i++)
    if (lines[i]
        .replaceAll(RegExp(r"\s+\b|\b\s"), '')
        .length == 0)
      lineNum += '\n';
    else
      lineNum += '\n${++count}';

  if (lineNum.length > 0) lineNum = lineNum.substring(1);

  return lineNum;
}
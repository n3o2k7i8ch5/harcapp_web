class SongBasicData1{
  final String title;
  final String author;
  final String performer;
  final String moderator;
  final String? youtubeLink;
  final List<String> tags;

  const SongBasicData1(
      this.title,
      this.author,
      this.performer,
      this.moderator,
      this.youtubeLink,
      this.tags,
    );

  static SongBasicData1 parse(String filePath, String code){

    List<String> parts = code.split("<");

    List<String> lines = parts[0].split("\n");

    if(lines.length<6)
      throw Exception("Wystąpił błąd kodowania: " + filePath);

    String title = lines[0];
    int.parse(lines[1]);

    String author = lines[2];
    String performer = lines[3];
    String moderator = lines[4];

    String? youtubeLink;
    if (lines[5].isNotEmpty)
      youtubeLink = lines[5];

    List<String> tags = lines[6].split(';');
    tags.removeWhere((tag) => tag.isEmpty);

    return SongBasicData1(
      title,
      author,
      performer,
      moderator,
      youtubeLink,
      tags,
    );
  }
}

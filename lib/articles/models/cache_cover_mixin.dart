import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'dart:typed_data';

import 'package:harcapp_web/idb.dart';
import 'package:harcapp_web/logger.dart';

mixin CacheCoverMixin on CoreArticle{

  @override
  Future<Uint8List?> loadCover() async {
    Uint8List? cachedCoverImage = await IDB.getCover(source, localId);
    if(cachedCoverImage != null) {
      logger.d("Cover for ${source.name} $localId loaded from cache.");
      return cachedCoverImage;
    }

    Uint8List? coverImage = await super.loadCover();
    if (coverImage == null) return null;

    await IDB.putCover(source, localId, coverImage);
    logger.d("Cover for ${source.name} $localId cached.");
    return coverImage;
  }

}
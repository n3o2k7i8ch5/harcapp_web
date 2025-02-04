import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:harcapp_core/harcthought/articles/model/article.dart';
import 'package:harcapp_core/logger.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

import 'package:harcapp_web/idb.dart';

mixin CacheCoverMixin on CoreArticle{

  @override
  FutureOr<void> onCoverDownloaded(img.Image? bigImage, img.Image? smallImage){
    IDB.putBigCover(source, localId, img.encodePng(bigImage!));
    IDB.putSmallCover(source, localId, img.encodePng(smallImage!));
  }

  @override
  Future<Uint8List?> loadCover(bool big) async {
    Uint8List? cachedCoverImage = await IDB.getCover(source, localId, big);
    if(cachedCoverImage != null) {
      logger.d("Cover for ${source.name} $localId loaded from cache.");
      return cachedCoverImage;
    }

    Uint8List? coverImage = await super.loadCover(big);
    if (coverImage == null) return null;

    await IDB.putCover(source, localId, coverImage, big);
    logger.d("Cover for ${source.name} $localId cached.");
    return coverImage;
  }

}
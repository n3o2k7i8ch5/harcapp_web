import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:idb_shim/idb_browser.dart';

class IDB{

  static const String dbName = 'articleDB.db';
  static String storeNameContent(ArticleSource source) => "content_${source.name}";
  static String storeNameBigCover(ArticleSource source) => "cover_big_${source.name}";
  static String storeNameSmallCover(ArticleSource source) => "cover_small_${source.name}";
  static String storeNameNewestSeenLocalId(ArticleSource source) => "newestLocalId_${source.name}";
  static const String newestSeenLocalIdKey = 'newestSeenLocalId';

  static late Database database;

  static Future<void> init() async {
    IdbFactory idbFactory = idbFactoryBrowser;

    database = await idbFactory.open(
        dbName,
        version: 1,
        onUpgradeNeeded: (VersionChangeEvent event) {
          Database db = event.database;
          for (ArticleSource source in ArticleSource.values){
            db.createObjectStore(storeNameContent(source), autoIncrement: true);
            db.createObjectStore(storeNameBigCover(source), autoIncrement: true);
            db.createObjectStore(storeNameSmallCover(source), autoIncrement: true);
            db.createObjectStore(storeNameNewestSeenLocalId(source), autoIncrement: true);
          }
        }
    );

  }

  static Future<void> _put((String storeName, String key, dynamic value) args) async {
    var (storeName, key, value) = args;
    Transaction txn = database.transaction(storeName, "readwrite");
    ObjectStore store = txn.objectStore(storeName);
    await store.put(value, key);
    await txn.completed;
  }

  static Future<void> put(String storeName, String key, dynamic value) async {
    await compute(_put, (storeName, key, value));
  }

  static Future<dynamic> _get((String storeName, String key) args) async {
    var (storeName, key) = args;
    Transaction txn = database.transaction(storeName, "readonly");
    ObjectStore store = txn.objectStore(storeName);
    Object? value = await store.getObject(key);
    await txn.completed;
    return value;
  }

  static Future<dynamic> get(String storeName, String key) async {
    return await compute(_get, (storeName, key));
  }

  static Future<List<dynamic>> _getAllKeys(String storeName) async {
    Transaction txn = database.transaction(storeName, "readonly");
    ObjectStore store = txn.objectStore(storeName);
    List<Object> values = await store.getAllKeys();
    await txn.completed;
    return values;
  }

  static Future<List<dynamic>> getAllKeys(String storeName) async {
    return await compute(_getAllKeys, storeName);
  }

  // ---

  static Future<void> putContent(ArticleSource source, String key, dynamic value) => put(storeNameContent(source), key, value);
  static Future<dynamic> getContent(ArticleSource source, String key) => get(storeNameContent(source), key);
  static Future<List<String>> getAllContentKeys(ArticleSource source) async => (await getAllKeys(storeNameContent(source))).cast<String>();

  static Future<void> putBigCover(ArticleSource source, String key, Uint8List value) => put(storeNameBigCover(source), key, value);
  static Future<Uint8List?> getBigCover(ArticleSource source, String key) async => (await get(storeNameBigCover(source), key)) as Uint8List?;

  static Future<void> putSmallCover(ArticleSource source, String key, Uint8List value) => put(storeNameSmallCover(source), key, value);
  static Future<Uint8List?> getSmallCover(ArticleSource source, String key) async => (await get(storeNameSmallCover(source), key)) as Uint8List?;

  static Future<void> putCover(ArticleSource source, String key, Uint8List value, bool big) =>
      big ? putBigCover(source, key, value) : putSmallCover(source, key, value);
  static Future<Uint8List?> getCover(ArticleSource source, String key, bool big) async =>
      big ? getBigCover(source, key) : getSmallCover(source, key);

  static Future<void> putNewestSeenLocalId(ArticleSource source, String value) => put(storeNameNewestSeenLocalId(source), newestSeenLocalIdKey, value);
  static Future<String?> getNewestSeenLocalId(ArticleSource source) async => (await get(storeNameNewestSeenLocalId(source), newestSeenLocalIdKey)) as String?;
}
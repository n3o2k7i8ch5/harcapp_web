import 'dart:typed_data';

import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:idb_shim/idb_browser.dart';

class IDB{

  static const String dbName = 'articleDB.db';
  static String storeNameContent(ArticleSource source) => "content_${source.name}";
  static String storeNameCover(ArticleSource source) => "cover_${source.name}";
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
            db.createObjectStore(storeNameCover(source), autoIncrement: true);
            db.createObjectStore(storeNameNewestSeenLocalId(source), autoIncrement: true);
          }
        }
    );

  }

  static Future<void> put(String storeName, String key, dynamic value) async {
    Transaction txn = database.transaction(storeName, "readwrite");
    ObjectStore store = txn.objectStore(storeName);
    await store.put(value, key);
    await txn.completed;
  }

  static Future<dynamic> get(String storeName, String key) async {
    Transaction txn = database.transaction(storeName, "readonly");
    ObjectStore store = txn.objectStore(storeName);
    Object? value = await store.getObject(key);
    await txn.completed;
    return value;
  }

  static Future<List<dynamic>> getAllKeys(String storeName) async {
    Transaction txn = database.transaction(storeName, "readonly");
    ObjectStore store = txn.objectStore(storeName);
    List<Object> values = await store.getAllKeys();
    await txn.completed;
    return values;
  }

  // ---

  static Future<void> putContent(ArticleSource source, String key, dynamic value) => put(storeNameContent(source), key, value);
  static Future<dynamic> getContent(ArticleSource source, String key) => get(storeNameContent(source), key);
  static Future<List<String>> getAllContentKeys(ArticleSource source) async => (await getAllKeys(storeNameContent(source))).cast<String>();

  static Future<void> putCover(ArticleSource source, String key, Uint8List value) => put(storeNameCover(source), key, value);
  static Future<Uint8List?> getCover(ArticleSource source, String key) async => (await get(storeNameCover(source), key)) as Uint8List?;

  static Future<void> putNewestSeenLocalId(ArticleSource source, String value) => put(storeNameNewestSeenLocalId(source), newestSeenLocalIdKey, value);
  static Future<String?> getNewestSeenLocalId(ArticleSource source) async => (await get(storeNameNewestSeenLocalId(source), newestSeenLocalIdKey)) as String?;
}
import 'package:flutter/foundation.dart';
import 'package:harcapp_core/harcthought/articles/model/article_source.dart';
import 'package:idb_shim/idb_browser.dart';

class IDB{

  static const String dbName = 'articleDB.db';
  static String storeNameContent(ArticleSource source) => "content_${source.name}";
  static String storeNameBigCover(ArticleSource source) => "cover_big_${source.name}";
  static String storeNameSmallCover(ArticleSource source) => "cover_small_${source.name}";
  static String storeNameNewestSeenLocalId(ArticleSource source) => "newestLocalId_${source.name}";
  static String storeNameOldestSeenLocalId(ArticleSource source) => "oldestLocalId_${source.name}";
  static String storeNameIsAllHistoryLoaded(ArticleSource source) => "isAllHistoryLoaded_${source.name}";
  static const String storeNameKonspektDraft = 'konspekt_draft';
  static const String newestSeenLocalIdKey = 'newestSeenLocalId';
  static const String oldestSeenLocalIdKey = 'oldestSeenLocalId';
  static const String isAllHistoryLoadedKey = 'isAllHistoryLoaded';
  static const String konspektDraftKey = 'draft';

  static late Database database;

  static Future<void> init() async {
    IdbFactory idbFactory = idbFactoryBrowser;

    database = await idbFactory.open(
        dbName,
        version: 2,
        onUpgradeNeeded: (VersionChangeEvent event) {
          Database db = event.database;
          int oldVersion = event.oldVersion;
          
          if (oldVersion < 1) {
            for (ArticleSource source in ArticleSource.values){
              db.createObjectStore(storeNameContent(source), autoIncrement: true);
              db.createObjectStore(storeNameBigCover(source), autoIncrement: true);
              db.createObjectStore(storeNameSmallCover(source), autoIncrement: true);
              db.createObjectStore(storeNameNewestSeenLocalId(source), autoIncrement: true);
              db.createObjectStore(storeNameOldestSeenLocalId(source), autoIncrement: true);
              db.createObjectStore(storeNameIsAllHistoryLoaded(source), autoIncrement: true);
            }
          }
          
          if (oldVersion < 2) {
            db.createObjectStore(storeNameKonspektDraft, autoIncrement: true);
          }
        }
    );

  }

  static Future<Object> _put((String storeName, String key, dynamic value) args) async {
    var (storeName, key, value) = args;
    Transaction txn = database.transaction(storeName, "readwrite");
    ObjectStore store = txn.objectStore(storeName);
    Object result = await store.put(value, key);
    await txn.completed;
    return result;
  }

  static Future<Object> put(String storeName, String key, dynamic value) =>
      compute(_put, (storeName, key, value));

  static Future<void> _putAll((String storeName, Map<String, dynamic> data) args) async {
    var (storeName, data) = args;
    Transaction txn = database.transaction(storeName, "readwrite");
    ObjectStore store = txn.objectStore(storeName);
    for(String key in data.keys)
      await store.put(data[key], key);
    await txn.completed;
  }

  static Future<void> putAll(String storeName, Map<String, dynamic> data) =>
    compute(_putAll, (storeName, data));

  static Future<dynamic> _get((String storeName, String key) args) async {
    var (storeName, key) = args;
    Transaction txn = database.transaction(storeName, "readonly");
    ObjectStore store = txn.objectStore(storeName);
    Object? value = await store.getObject(key);
    await txn.completed;
    return value;
  }

  static Future<dynamic> get(String storeName, String key) =>
    compute(_get, (storeName, key));

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

  static Future<void> putAllContent(ArticleSource source, Map<String, dynamic> data) => putAll(storeNameContent(source), data);

  static Future<void> putContent(ArticleSource source, String key, dynamic value) => put(storeNameContent(source), key, value);
  static Future<dynamic> getContent(ArticleSource source, String key) => get(storeNameContent(source), key);
  static Future<List<String>> getAllContentKeys(ArticleSource source) async => (await getAllKeys(storeNameContent(source))).cast<String>();

  static Future<Object> putBigCover(ArticleSource source, String key, Uint8List value) => put(storeNameBigCover(source), key, value);
  static Future<Uint8List?> getBigCover(ArticleSource source, String key) async => (await get(storeNameBigCover(source), key)) as Uint8List?;

  static Future<Object> putSmallCover(ArticleSource source, String key, Uint8List value) => put(storeNameSmallCover(source), key, value);
  static Future<Uint8List?> getSmallCover(ArticleSource source, String key) async => (await get(storeNameSmallCover(source), key)) as Uint8List?;

  static Future<Object> putCover(ArticleSource source, String key, Uint8List value, bool big) =>
      big ? putBigCover(source, key, value) : putSmallCover(source, key, value);
  static Future<Uint8List?> getCover(ArticleSource source, String key, bool big) async =>
      big ? getBigCover(source, key) : getSmallCover(source, key);

  static Future<Object> putNewestSeenLocalId(ArticleSource source, String value) => put(storeNameNewestSeenLocalId(source), newestSeenLocalIdKey, value);
  static Future<String?> getNewestSeenLocalId(ArticleSource source) async => (await get(storeNameNewestSeenLocalId(source), newestSeenLocalIdKey)) as String?;

  static Future<Object> putOldestSeenLocalId(ArticleSource source, String value) => put(storeNameOldestSeenLocalId(source), oldestSeenLocalIdKey, value);
  static Future<String?> getOldestSeenLocalId(ArticleSource source) async => (await get(storeNameOldestSeenLocalId(source), oldestSeenLocalIdKey)) as String?;

  static Future<Object> saveIsAllHistoryLoaded(ArticleSource source, bool value) => put(storeNameIsAllHistoryLoaded(source), isAllHistoryLoadedKey, value);
  static Future<bool> getIsAllHistoryLoaded(ArticleSource source) async => (await get(storeNameIsAllHistoryLoaded(source), isAllHistoryLoadedKey)) as bool? ?? false;

  // Konspekt draft
  static Future<Object> saveKonspektDraft(Uint8List bytes) => put(storeNameKonspektDraft, konspektDraftKey, bytes);
  static Future<Uint8List?> getKonspektDraft() async => (await get(storeNameKonspektDraft, konspektDraftKey)) as Uint8List?;
  static Future<void> clearKonspektDraft() async {
    Transaction txn = database.transaction(storeNameKonspektDraft, "readwrite");
    ObjectStore store = txn.objectStore(storeNameKonspektDraft);
    await store.delete(konspektDraftKey);
    await txn.completed;
  }
}
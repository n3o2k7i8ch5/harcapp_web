import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:harcapp_web/firebase_options.dart';
import 'package:harcapp_core/logger.dart';

FirebaseAnalytics? analytics;

Future<void> initFirebase() async {
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    analytics = FirebaseAnalytics.instance;
  } catch (e, st) {
    // firebase_options.dart nie wypełnione dla web — aplikacja działa bez analytics.
    // Po uruchomieniu `flutterfire configure --project=harcapp --platforms=web`
    // ten log zniknie, a analytics zacznie logować automatycznie.
    logger.w('Firebase not initialized: $e', stackTrace: st);
  }
}

void logAnalyticsEvent(String name, Map<String, Object> parameters) {
  final a = analytics;
  if (a == null) return;
  a.logEvent(name: name, parameters: parameters);
}

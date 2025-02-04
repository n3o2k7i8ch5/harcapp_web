import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:harcapp_core/logger.dart' as global_logger;

void initLogger() => global_logger.initLogger(
    Logger(
        printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 8,
            lineLength: 0,
            colors: kDebugMode,
            printEmojis: false,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
            noBoxingByDefault: true
        ),
    )
);
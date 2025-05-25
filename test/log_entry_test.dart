import 'package:test/test.dart';
import 'package:opentelemetry_logging/src/model/log_entry.dart';
import 'package:opentelemetry_logging/src/model/log_level.dart';

void main() {
  group('LogEntry', () {
    test('constructor sets fields and timestamp', () {
      final entry = LogEntry(LogLevel.info, 'msg', traceId: 'a' * 32);
      expect(entry.level, LogLevel.info);
      expect(entry.message, 'msg');
      expect(entry.traceId, 'a' * 32);
      expect(entry.timestamp, isA<DateTime>());
    });

    test('toJson includes all fields and correct mappings', () {
      final entry = LogEntry(LogLevel.warn, 'body', traceId: 'b' * 32);
      final json = entry.toJson();
      expect(json['severityNumber'], 13);
      expect(json['severityText'], 'WARNING');
      expect(json['body'], {'stringValue': 'body'});
      expect(json['traceId'], 'b' * 32);
      expect(json['timeUnixNano'], isA<String>());
      expect(json['observedTimeUnixNano'], isA<String>());
    });

    test('toJson omits traceId if not set', () {
      final entry = LogEntry(LogLevel.debug, 'x');
      final json = entry.toJson();
      expect(json.containsKey('traceId'), isFalse);
    });
  });

  group('LogLevel', () {
    test('severityText returns correct string', () {
      expect(severityText(LogLevel.debug), 'DEBUG');
      expect(severityText(LogLevel.info), 'INFO');
      expect(severityText(LogLevel.warn), 'WARNING');
      expect(severityText(LogLevel.error), 'ERROR');
    });
  });
}


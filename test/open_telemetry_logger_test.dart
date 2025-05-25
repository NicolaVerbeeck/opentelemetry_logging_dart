import 'dart:async';
import 'package:test/test.dart';
import 'package:opentelemetry_logging/opentelemetry_logging.dart';
import 'package:opentelemetry_logging/src/model/log_entry.dart';
import 'package:opentelemetry_logging/src/model/log_level.dart';

class MockOpenTelemetryBackend implements OpenTelemetryBackend {
  List<List<LogEntry>> sentBatches = [];
  bool disposed = false;
  bool throwOnSend = false;

  @override
  Future<void> sendLogs(List<LogEntry> entries) async {
    if (throwOnSend) throw Exception('sendLogs error');
    sentBatches.add(List.from(entries));
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  group('OpenTelemetryLogger', () {
    late MockOpenTelemetryBackend backend;
    late OpenTelemetryLogger logger;

    setUp(() {
      backend = MockOpenTelemetryBackend();
      logger = OpenTelemetryLogger(
        backend: backend,
        flushInterval: const Duration(milliseconds: 50),
        batchSize: 3,
      );
    });

    tearDown(() async {
      await logger.close();
    });

    test('logs are batched and sent when batch size is reached', () async {
      logger.info('msg1');
      logger.info('msg2');
      logger.info('msg3');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(backend.sentBatches.length, 1);
      expect(backend.sentBatches[0].length, 3);
    });

    test('logs are sent on flush interval', () async {
      logger.info('msg1');
      await Future.delayed(const Duration(milliseconds: 70));
      expect(backend.sentBatches.length, 1);
      expect(backend.sentBatches[0][0].message, 'msg1');
    });

    test('debug, info, warn, error methods add correct log levels', () async {
      logger.debug('d');
      logger.info('i');
      logger.warn('w');
      logger.error('e');
      await logger.flush();
      final all = backend.sentBatches.expand((b) => b).toList();
      expect(all.map((e) => e.level), [LogLevel.debug, LogLevel.info, LogLevel.warn, LogLevel.error]);
    });

    test('traceId is validated and passed to LogEntry', () async {
      final traceId = 'a' * 32;
      logger.info('msg', traceId: traceId);
      await logger.flush();
      expect(backend.sentBatches[0][0].traceId, traceId);
    });

    test('throws on invalid traceId', () {
      expect(() => OpenTelemetryLogger(
        backend: backend,
        flushInterval: const Duration(seconds: 1),
        batchSize: 1,
        traceId: 'short',
      ), throwsArgumentError);
      expect(() => logger.info('msg', traceId: 'short'), throwsArgumentError);
    });

    test('close flushes all logs and disposes backend', () async {
      logger.info('msg1');
      await logger.close();
      expect(backend.sentBatches.expand((b) => b).any((e) => e.message == 'msg1'), isTrue);
      expect(backend.disposed, isTrue);
    });

    test('flush handles backend errors gracefully', () async {
      backend.throwOnSend = true;
      logger.info('msg');
      await logger.flush();
      // Should not throw
    });
  });
}


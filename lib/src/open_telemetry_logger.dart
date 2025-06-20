import 'dart:async';

import 'package:opentelemetry_logging/src/backend/open_telemetry_backend.dart';
import 'package:opentelemetry_logging/src/model/log_entry.dart';
import 'package:opentelemetry_logging/src/model/log_level.dart';

/// A logger that batches log entries and sends them to an OpenTelemetry backend.
class OpenTelemetryLogger {
  final OpenTelemetryBackend _backend;
  final String? _traceId;
  final List<LogEntry> _batch = [];
  final int _batchSize;
  late final Timer _timer;
  final Map<String, String>? _attributes;

  /// Creates an OpenTelemetry logger that sends logs to the specified [backend]
  /// The logs are sent either when the batch reaches the specified [batchSize]
  /// or after the [flushInterval] has passed.
  /// An optional [traceId] can be provided to associate logs with a specific trace.
  /// Optional [attributes] can be provided that are added as attributes to each log entry.
  OpenTelemetryLogger({
    required OpenTelemetryBackend backend,
    required Duration flushInterval,
    required int batchSize,
    String? traceId,
    Map<String, String>? attributes,
  })  : _backend = backend,
        _traceId = traceId,
        _batchSize = batchSize,
        _attributes = attributes {
    if (traceId != null && traceId.length != 32) {
      throw ArgumentError.value(
        traceId,
        'traceId',
        'Trace ID must be a 32-character hexadecimal string.',
      );
    }
    _timer = Timer.periodic(
      flushInterval,
      (_) => unawaited(flush()),
    );
  }

  /// Logs a debug message. [log] will be serialized to string using [toString].
  /// The [traceId] can be used to associate the log with a specific trace. If
  /// not provided, the logger's default traceId will be used.
  void debug(Object? log, {String? traceId}) =>
      _add(LogLevel.debug, log, traceId: traceId ?? _traceId);

  /// Logs an error message. [log] will be serialized to string using [toString].
  /// The [traceId] can be used to associate the log with a specific trace. If
  /// not provided, the logger's default traceId will be used.
  void error(Object? log, {String? traceId}) =>
      _add(LogLevel.error, log, traceId: traceId ?? _traceId);

  /// Logs an info message. [log] will be serialized to string using [toString].
  /// The [traceId] can be used to associate the log with a specific trace. If
  /// not provided, the logger's default traceId will be used.
  void info(Object? log, {String? traceId}) =>
      _add(LogLevel.info, log, traceId: traceId ?? _traceId);

  /// Logs a warning message. [log] will be serialized to string using [toString].
  /// The [traceId] can be used to associate the log with a specific trace. If
  /// not provided, the logger's default traceId will be used.
  void warn(Object? log, {String? traceId}) =>
      _add(LogLevel.warn, log, traceId: traceId ?? _traceId);

  void _add(
    LogLevel level,
    Object? message, {
    required String? traceId,
  }) {
    if (traceId != null && traceId.length != 32) {
      throw ArgumentError.value(
        traceId,
        'traceId',
        'Trace ID must be a 32-character hexadecimal string.',
      );
    }
    _batch.add(
      LogEntry(
        level,
        message?.toString(),
        traceId: traceId,
        attributes: _attributes,
      ),
    );
    if (_batch.length >= _batchSize) {
      unawaited(flush());
    }
  }

  /// Closes the logger, flushing any remaining logs to the backend. The logger
  /// cannot be used after it has been closed. The provided [backend] will be
  /// disposed of as well.
  Future<void> close() async {
    _timer.cancel();

    await flush();
    await _backend.dispose();
  }

  /// Flushes the current batch of logs to the backend if none are currently
  /// being sent.
  Future<void> flush() async {
    if (_batch.isEmpty) {
      return;
    }

    final entries = List<LogEntry>.from(_batch, growable: false);
    _batch.clear();
    try {
      await _backend.sendLogs(entries);
    } catch (_) {}
  }
}

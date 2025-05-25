import 'package:opentelemetry_logging/src/model/log_level.dart';

class LogEntry {
  final LogLevel level;
  final String? message;
  final DateTime timestamp;
  final String? traceId;

  LogEntry(
    this.level,
    this.message, {
    this.traceId,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    final timeUnixNano = (timestamp.microsecondsSinceEpoch * 1000).toString();
    final map = {
      'timeUnixNano': timeUnixNano,
      'observedTimeUnixNano': timeUnixNano,
      'severityNumber': _severityNumber(level),
      'severityText': severityText(level),
      'body': {'stringValue': message},
    };
    if (traceId != null) {
      map['traceId'] = traceId!;
    }
    return map;
  }
}

// OpenTelemetry severity text mapping
String severityText(LogLevel level) => switch (level) {
      LogLevel.debug => 'DEBUG',
      LogLevel.info => 'INFO',
      LogLevel.warn => 'WARNING',
      LogLevel.error => 'ERROR',
    };

// OpenTelemetry severity number mapping
int _severityNumber(LogLevel level) => switch (level) {
      LogLevel.debug => 5,
      LogLevel.info => 9,
      LogLevel.warn => 13,
      LogLevel.error => 17,
    };

import 'package:opentelemetry_logging/src/model/log_entry.dart';

abstract class OpenTelemetryBackend {
  Future<void> sendLogs(List<LogEntry> entries);

  Future<void> dispose();
}
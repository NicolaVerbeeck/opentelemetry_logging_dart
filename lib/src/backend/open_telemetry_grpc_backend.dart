import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:opentelemetry_logging/src/backend/open_telemetry_backend.dart';
import 'package:opentelemetry_logging/src/model/log_entry.dart';
import 'package:opentelemetry_logging/src/model/log_level.dart';

import 'grpc/gen/opentelemetry/proto/collector/logs/v1/logs_service.pbgrpc.dart';
import 'grpc/gen/opentelemetry/proto/common/v1/common.pb.dart' as otlp_common;
import 'grpc/gen/opentelemetry/proto/logs/v1/logs.pb.dart' as otlp;
import 'grpc/gen/opentelemetry/proto/logs/v1/logs.pbenum.dart' as otlp_enum;
import 'grpc/gen/opentelemetry/proto/resource/v1/resource.pb.dart'
    as otlp_resource;

/// An OpenTelemetry backend that sends logs to a specified gRPC endpoint.
class OpenTelemetryGrpcBackend implements OpenTelemetryBackend {
  final ClientChannel? _channel;
  late final LogsServiceClient _client;
  final bool _ownChannel;
  final CallOptions? _callOptions;
  final Future<void> Function(Object error)? _onSubmitError;

  /// Creates an OpenTelemetry backend that sends logs to a specified gRPC endpoint.
  /// It connects to the specified [host] and [port] with optional [credentials], using
  /// [options] for the gRPC channel.
  OpenTelemetryGrpcBackend({
    required String host,
    int port = 4317,
    ChannelOptions options = const ChannelOptions(),
    CallOptions? callOptions,
    Future<void> Function(
        Object error,
    )? onSubmitError,
  })  : _channel = ClientChannel(
          host,
          port: port,
          options: options,
        ),
        _ownChannel = true,
        _callOptions = callOptions,
        _onSubmitError = onSubmitError {
    _client = LogsServiceClient(
      _channel!,
    );
  }

  /// Creates an OpenTelemetry backend that uses an existing [channel].
  /// The channel will not be closed automatically upon [dispose].
  OpenTelemetryGrpcBackend.withChannel({
    required ClientChannel channel,
    CallOptions? callOptions,
    Future<void> Function(
        Object error,
    )? onSubmitError,
  })  : _channel = channel,
        _client = LogsServiceClient(channel),
        _ownChannel = false,
        _callOptions = callOptions,
        _onSubmitError = onSubmitError;

  /// Creates an OpenTelemetry backend that uses an existing [client].
  /// The client will not be closed automatically upon [dispose].
  OpenTelemetryGrpcBackend.withClient({
    required LogsServiceClient client,
    CallOptions? callOptions,
    Future<void> Function(
        Object error,
    )? onSubmitError,
  })  : _client = client,
        _ownChannel = false,
        _channel = null,
        _callOptions = callOptions,
        _onSubmitError = onSubmitError;

  @override
  Future<void> sendLogs(List<LogEntry> entries) async {
    final logRecords = entries.map(_logEntryToLogRecord).toList();
    final scopeLogs = otlp.ScopeLogs()..logRecords.addAll(logRecords);
    final resourceLogs = otlp.ResourceLogs()
      ..resource = otlp_resource.Resource()
      ..scopeLogs.add(scopeLogs);
    final request = ExportLogsServiceRequest()..resourceLogs.add(resourceLogs);
    try {
      await _client.export(request, options: _callOptions);
    } catch (e) {
      _onSubmitError?.call(e);
    }
  }

  static otlp.LogRecord _logEntryToLogRecord(LogEntry entry) {
    final timeUnixNano = Int64(entry.timestamp.microsecondsSinceEpoch * 1000);
    return otlp.LogRecord()
      ..timeUnixNano = timeUnixNano
      ..observedTimeUnixNano = timeUnixNano
      ..severityNumber = _mapSeverityLevel(entry.level)
      ..severityText = severityText(entry.level)
      ..body = otlp_common.AnyValue(stringValue: entry.message ?? '')
      ..traceId = entry.traceId != null ? _hexToBytes(entry.traceId!) : [];
  }

  @override
  Future<void> dispose() async {
    if (_ownChannel) {
      await _channel?.shutdown();
    }
  }
}

List<int> _hexToBytes(String hex) {
  final len = hex.length;
  final result = List<int>.filled(len ~/ 2, 0, growable: false);
  for (var i = 0; i < len; i += 2) {
    final hi = hex.codeUnitAt(i);
    final lo = hex.codeUnitAt(i + 1);

    int parseHex(int c) {
      if (c >= 48 && c <= 57) return c - 48; // '0'-'9'
      if (c >= 65 && c <= 70) return c - 55; // 'A'-'F'
      if (c >= 97 && c <= 102) return c - 87; // 'a'-'f'
      throw FormatException('Invalid hex character: ${String.fromCharCode(c)}');
    }

    result[i ~/ 2] = (parseHex(hi) << 4) + parseHex(lo);
  }
  return result;
}

otlp.SeverityNumber _mapSeverityLevel(LogLevel level) => switch (level) {
      LogLevel.debug => otlp_enum.SeverityNumber.SEVERITY_NUMBER_DEBUG,
      LogLevel.info => otlp_enum.SeverityNumber.SEVERITY_NUMBER_INFO,
      LogLevel.warn => otlp_enum.SeverityNumber.SEVERITY_NUMBER_WARN,
      LogLevel.error => otlp_enum.SeverityNumber.SEVERITY_NUMBER_ERROR
    };

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:opentelemetry_logging/src/backend/open_telemetry_backend.dart';
import 'package:opentelemetry_logging/src/model/log_entry.dart';

/// An OpenTelemetry backend that sends logs to a specified HTTP endpoint.
class OpenTelemetryHttpBackend implements OpenTelemetryBackend {
  final Uri _endpoint;

  final HttpClient _client;
  final bool _ownClient;
  final FutureOr<void> Function({
    required int statusCode,
    required String body,
  })? _onPostError;

  /// Creates an OpenTelemetry backend that sends logs to a specified HTTP endpoint.
  /// If a [client] is provided, it will be used for sending requests;
  /// it will NOT be closed automatically upon [dispose].
  OpenTelemetryHttpBackend({
    required Uri endpoint,
    HttpClient? client,
    FutureOr<void> Function({
      required int statusCode,
      required String body,
    })? onPostError,
  })  : _endpoint = endpoint,
        _client = client ?? HttpClient(),
        _ownClient = client == null,
        _onPostError = onPostError;

  @override
  Future<void> dispose() async {
    if (_ownClient) {
      _client.close();
    }
  }

  @override
  Future<void> sendLogs(List<LogEntry> entries) async {
    final payload = jsonEncode({
      'resourceLogs': [
        {
          'resource': {},
          'scopeLogs': [
            {
              'logRecords': entries.map((e) => e.toJson()).toList(),
            }
          ]
        }
      ]
    });
    final req = await _client.postUrl(_endpoint);
    req.headers.contentType = ContentType.json;
    req.write(payload);
    final res = await req.close();

    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (_onPostError != null) {
        final responseBody = await res.transform(utf8.decoder).join();
        await _onPostError(
          statusCode: res.statusCode,
          body: responseBody,
        );
        return;
      }
    }
    await res.drain();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:opentelemetry_logging/src/backend/open_telemetry_backend.dart';
import 'package:opentelemetry_logging/src/model/log_entry.dart';

/// An OpenTelemetry backend that sends logs to a specified HTTP endpoint.
class OpenTelemetryHttpBackend implements OpenTelemetryBackend {
  final Uri _endpoint;
  final Map<String, Object?>? _resourceAttributes;

  final http.Client _client;
  final bool _ownClient;
  final Future<void> Function({
    required int statusCode,
    required String body,
  })? _onPostError;

  /// Creates an OpenTelemetry backend that sends logs to a specified HTTP endpoint.
  /// If a [client] is provided, it will be used for sending requests;
  /// it will NOT be closed automatically upon [dispose].
  OpenTelemetryHttpBackend({
    required Uri endpoint,
    Map<String, Object?>? resourceAttributes,
    http.Client? client,
    Future<void> Function({
      required int statusCode,
      required String body,
    })? onPostError,
  })  : _endpoint = endpoint,
        _resourceAttributes = resourceAttributes,
        _client = client ?? http.Client(),
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
          'resource': _buildResource(),
          'scopeLogs': [
            {
              'logRecords': entries.map((e) => e.toJson()).toList(),
            }
          ]
        }
      ]
    });
    final res = await _client.post(
      _endpoint,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (_onPostError != null) {
        await _onPostError(
          statusCode: res.statusCode,
          body: res.body,
        );
      }
    }
  }

  // ---- OTLP helpers ----

  Map<String, dynamic> _buildResource() {
    final attrs = _resourceAttributes;
    if (attrs == null || attrs.isEmpty) {
      return {};
    }

    return {
      'attributes': attrs.entries.map((e) {
        return {
          'key': e.key,
          'value': _convertAttributeValue(e.value),
        };
      }).toList(),
    };
  }

  Map<String, dynamic> _convertAttributeValue(Object? value) {
    return switch (value) {
      null => {'stringValue': 'null'},
      final String v => {'stringValue': v},
      final int v => {'intValue': v},
      final double v => {'doubleValue': v},
      final bool v => {'boolValue': v},
      final List v => {
          'arrayValue': {
            'values': v.map(_convertAttributeValue).toList(),
          },
        },
      final Map v => {
          'kvlistValue': {
            'values': v.entries.map((e) {
              return {
                'key': e.key.toString(),
                'value': _convertAttributeValue(e.value),
              };
            }).toList(),
          },
        },
      _ => {'stringValue': value.toString()},
    };
  }
}

import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:opentelemetry_logging/src/backend/open_telemetry_http_backend.dart';
import 'package:opentelemetry_logging/src/model/log_entry.dart';
import 'package:opentelemetry_logging/src/model/log_level.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('OpenTelemetryHttpBackend', () {
    final endpoint = Uri.parse('https://example.com/logs');
    late MockHttpClient mockClient;
    late List<LogEntry> entries;
    late LogEntry entry;

    setUp(() {
      mockClient = MockHttpClient();
      entry = LogEntry(
        LogLevel.info,
        'test',
        traceId: '1234567890abcdef1234567890abcdef',
      );
      entries = [entry];
    });

    test('sends logs successfully', () async {
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.body).thenReturn('');
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => mockResponse);

      final backend =
          OpenTelemetryHttpBackend(endpoint: endpoint, client: mockClient);
      await backend.sendLogs(entries);
      verify(() => mockClient.post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: any(named: 'body'),
          )).called(1);
    });

    test('calls onPostError on error response', () async {
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(400);
      when(() => mockResponse.body).thenReturn('bad request');
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => mockResponse);
      var called = false;
      Future<void> onPostError(
          {required int statusCode, required String body}) async {
        called = true;
        expect(statusCode, 400);
        expect(body, 'bad request');
      }

      final backend = OpenTelemetryHttpBackend(
        endpoint: endpoint,
        client: mockClient,
        onPostError: onPostError,
      );
      await backend.sendLogs(entries);
      expect(called, isTrue);
    });

    test('does not call onPostError if not provided', () async {
      final mockResponse = MockResponse();
      when(() => mockResponse.statusCode).thenReturn(500);
      when(() => mockResponse.body).thenReturn('server error');
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => mockResponse);
      final backend = OpenTelemetryHttpBackend(
        endpoint: endpoint,
        client: mockClient,
      );
      await backend.sendLogs(entries);
      // No exception thrown, just returns
    });

    test('closes client if owned', () async {
      final backend = OpenTelemetryHttpBackend(endpoint: endpoint);
      await backend.dispose();
      // No error means client closed
    });

    test('does not close client if not owned', () async {
      final backend =
          OpenTelemetryHttpBackend(endpoint: endpoint, client: mockClient);
      await backend.dispose();
      // No error means client not closed
    });
  });
}

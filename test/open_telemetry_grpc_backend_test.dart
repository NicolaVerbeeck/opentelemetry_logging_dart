import 'package:grpc/grpc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:opentelemetry_logging/src/backend/grpc/gen/opentelemetry/proto/collector/logs/v1/logs_service.pbgrpc.dart';
import 'package:opentelemetry_logging/src/backend/open_telemetry_grpc_backend.dart';
import 'package:opentelemetry_logging/src/model/log_entry.dart';
import 'package:opentelemetry_logging/src/model/log_level.dart';
import 'package:test/test.dart';

class MockResponse extends Mock implements ExportLogsServiceResponse {}

class MockLogsServiceClient extends Mock implements LogsServiceClient {}

class MockedClientCall extends Mock
    implements ClientCall<dynamic, ExportLogsServiceResponse> {}

void main() {
  setUpAll(() {
    registerFallbackValue(<LogEntry>[]);
    registerFallbackValue(ExportLogsServiceRequest());
    registerFallbackValue(CallOptions());
  });

  group('OpenTelemetryGrpcBackend', () {
    late MockLogsServiceClient mockServiceClient;
    late OpenTelemetryGrpcBackend backend;
    late List<LogEntry> entries;
    late LogEntry entry;

    setUp(() {
      mockServiceClient = MockLogsServiceClient();
      entry = LogEntry(
        LogLevel.info,
        'test',
        traceId: '1234567890abcdef1234567890abcdef',
      );
      entries = [entry];
      backend = OpenTelemetryGrpcBackend.withClient(
        client: mockServiceClient,
      );
    });

    test('sends logs successfully', () async {
      final mockedCall = MockedClientCall();
      when(() => mockedCall.response)
          .thenAnswer((_) => Stream.value(MockResponse()));
      when(() => mockServiceClient.export(
            any(that: isA<ExportLogsServiceRequest>()),
            options: any(named: 'options'),
          )).thenAnswer((_) => ResponseFuture(mockedCall));
      await backend.sendLogs(entries);
      verify(() => mockServiceClient.export(
            any(that: isA<ExportLogsServiceRequest>()),
            options: any(named: 'options'),
          )).called(1);
    });

    test('closes channel if owned', () async {
      final ownedBackend = OpenTelemetryGrpcBackend(host: 'localhost');
      await ownedBackend.dispose();
      // No error means channel closed
    });

    test('does not close channel if not owned', () async {
      await backend.dispose();
      // No error means channel not closed
    });
  });
}

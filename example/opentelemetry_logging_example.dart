import 'package:opentelemetry_logging/opentelemetry_logging.dart';

void main() async {
  final logger = OpenTelemetryLogger(
    backend: OpenTelemetryHttpBackend(
        endpoint: Uri.parse('http://localhost:4318/v1/logs')),
    batchSize: 10,
    flushInterval: const Duration(seconds: 5),
    traceId: '1234567890abcdef1234567890abcdef',
  );

  logger.debug('Hello!');
  logger.info('This is an info message.');
  logger.warn('This is a warning message.');
  logger.error('This is an error message.');
  await logger.close();
}

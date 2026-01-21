# OpenTelemetry Logging Dart

[![Pub Version](https://img.shields.io/pub/v/opentelemetry_logging.svg)](https://pub.dev/packages/opentelemetry_logging)
[![Coverage](https://codecov.io/gh/NicolaVerbeeck/opentelemetry_logging_dart/branch/main/graph/badge.svg)](https://codecov.io/gh/NicolaVerbeeck/opentelemetry_logging_dart)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/NicolaVerbeeck/opentelemetry_logging_dart/badge)](https://scorecard.dev/viewer/?uri=github.com/NicolaVerbeeck/opentelemetry_logging_dart)

A Dart package for logging with OpenTelemetry, supporting gRPC backends and seamless integration with observability platforms.

## Features

- Simple logging
- OpenTelemetry protocol support (gRPC and HTTP)

## Resource Attributes

You can attach OpenTelemetry resource attributes to your logs.  
These are used by observability backends (Grafana, Tempo, Loki, OTel Collector)
to identify the service emitting the logs.

Common attributes include:

- `service.name`
- `service.version`
- `deployment.environment`

Resource attributes support typed values (string, int, bool, arrays).

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  opentelemetry_logging: ^latest
```

Import and use in your Dart code:

```dart
import 'package:opentelemetry_logging/opentelemetry_logging_dart.dart';

// Create logger
final logger = OpenTelemetryLogger(
  backend: OpenTelemetryHttpBackend(
    endpoint: Uri.parse('http://localhost:4318/v1/logs'),
    resourceAttributes: {
      'service.name': 'example-app',
      'service.version': '1.0.0',
      'deployment.environment': 'dev',
      'build': 42,
      'isDebug': true,
    },
  ),
  batchSize: 10,
  flushInterval: const Duration(seconds: 5),
  traceId: '1234567890abcdef1234567890abcdef',
);

// Use logger
logger.debug('Hello!');
```

## Contributing

Contributions are welcome! Please open issues or pull requests on GitHub.

## License

This project is licensed under the MIT License.

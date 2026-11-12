import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/core/logging/crm_logger.dart';

class TestLogHandler implements LogHandler {
  final List<LogRecord> logs = [];

  @override
  void handle(LogRecord record) {
    logs.add(record);
  }
}

void main() {
  group('CrmLogger Enterprise Telemetry Tests', () {
    late TestLogHandler handler;

    setUp(() {
      CrmLogger.resetHandlers();
      handler = TestLogHandler();
      CrmLogger.addHandler(handler);
    });

    tearDown(() {
      CrmLogger.resetHandlers();
    });

    test('logs info, debug, warning, error, and fatal records', () {
      CrmLogger.debug('Auth', 'Debugging credentials');
      CrmLogger.info('Lead', 'Lead LD-101 created');
      CrmLogger.warning('Network', 'Slow response from server');
      CrmLogger.error('Storage', 'Failed to save', Exception('Disk full'));
      CrmLogger.fatal('App', 'Fatal memory exhaustion');

      expect(handler.logs.length, 5);
      expect(handler.logs[0].level, LogLevel.debug);
      expect(handler.logs[1].level, LogLevel.info);
      expect(handler.logs[2].level, LogLevel.warning);
      expect(handler.logs[3].level, LogLevel.error);
      expect(handler.logs[4].level, LogLevel.fatal);
    });

    test('maintains ring buffer history up to max limit', () {
      for (int i = 0; i < 120; i++) {
        CrmLogger.info('Tag', 'Message $i');
      }

      final recent = CrmLogger.getRecentLogs();
      expect(recent.length, CrmLogger.maxHistorySize);
      expect(recent.last.message, 'Message 119');
    });

    test('formats log record with timestamp and error details', () {
      final ex = Exception('Network error');
      CrmLogger.error('Api', 'Endpoint failed', ex);

      final log = handler.logs.first;
      expect(log.tag, 'Api');
      expect(log.message, 'Endpoint failed');
      expect(log.error, ex);
      expect(log.toString(), contains('[ERROR] [Api] Endpoint failed'));
      expect(log.toString(), contains('Exception: Network error'));
    });
  });
}


import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Severity levels for enterprise CRM logging.
enum LogLevel { debug, info, warning, error, fatal }

/// Structured log record holding telemetry metadata.
class LogRecord {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const LogRecord({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final buffer = StringBuffer(
      '[${timestamp.toIso8601String()}] [${level.name.toUpperCase()}] [$tag] $message',
    );
    if (error != null) buffer.write(' | Error: $error');
    return buffer.toString();
  }
}

/// Pluggable consumer for forwarding logs to telemetry APMs (Sentry, Datadog).
abstract interface class LogHandler {
  void handle(LogRecord record);
}

/// Console handler for development and standard output.
class ConsoleLogHandler implements LogHandler {
  const ConsoleLogHandler();

  @override
  void handle(LogRecord record) {
    if (kDebugMode) {
      debugPrint(record.toString());
      if (record.stackTrace != null) {
        debugPrint(record.stackTrace.toString());
      }
    }
  }
}

/// Centralized Enterprise Telemetry and Structured Logging service.
class CrmLogger {
  CrmLogger._();

  static final List<LogHandler> _handlers = [const ConsoleLogHandler()];
  static final Queue<LogRecord> _history = Queue<LogRecord>();
  static const int maxHistorySize = 100;

  /// Registers a custom telemetry forwarder (e.g. Sentry/Datadog handler).
  static void addHandler(LogHandler handler) {
    _handlers.add(handler);
  }

  /// Removes a registered log handler.
  static void removeHandler(LogHandler handler) {
    _handlers.remove(handler);
  }

  /// Clears all registered handlers (useful in test teardown).
  static void resetHandlers() {
    _handlers
      ..clear()
      ..add(const ConsoleLogHandler());
    _history.clear();
  }

  /// Returns recent in-memory log history for diagnostics or support export.
  static List<LogRecord> getRecentLogs() => List.unmodifiable(_history);

  static void _log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final record = LogRecord(
      timestamp: DateTime.now().toUtc(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stackTrace: stackTrace,
    );

    if (_history.length >= maxHistorySize) {
      _history.removeFirst();
    }
    _history.addLast(record);

    for (final handler in _handlers) {
      handler.handle(record);
    }
  }

  static void debug(String tag, String message) =>
      _log(LogLevel.debug, tag, message);

  static void info(String tag, String message) =>
      _log(LogLevel.info, tag, message);

  static void warning(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) =>
      _log(LogLevel.warning, tag, message, error, stackTrace);

  static void error(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) =>
      _log(LogLevel.error, tag, message, error, stackTrace);

  static void fatal(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) =>
      _log(LogLevel.fatal, tag, message, error, stackTrace);
}


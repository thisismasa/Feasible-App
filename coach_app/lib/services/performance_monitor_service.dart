// PERFORMANCE MONITORING SERVICE
// Track and monitor performance metrics for authentication flows

import 'dart:async';
import 'analytics_service.dart';

class PerformanceMonitor {
  static final Map<String, PerformanceMetric> _metrics = {};
  static final Map<String, List<int>> _metricHistory = {};

  // Performance thresholds (in milliseconds)
  static const int slowOperationThreshold = 3000;
  static const int warningThreshold = 2000;
  static const int excellentThreshold = 500;

  /// Start tracking a performance metric
  static void startTrace(String name) {
    _metrics[name] = PerformanceMetric(
      name: name,
      startTime: DateTime.now(),
    );
    print('[PERF] Started trace: $name');
  }

  /// End tracking and report metric
  static void endTrace(String name, {Map<String, dynamic>? attributes}) {
    final metric = _metrics[name];
    if (metric == null) {
      print('[PERF] Warning: No trace found for $name');
      return;
    }

    metric.endTime = DateTime.now();
    metric.duration = metric.endTime!.difference(metric.startTime).inMilliseconds;
    metric.attributes = attributes;

    // Log performance level
    _logPerformanceLevel(metric);

    // Send to monitoring service
    _reportMetric(metric);

    // Store in history
    _addToHistory(name, metric.duration!);

    // Clean up
    _metrics.remove(name);
  }

  /// Log performance level based on duration
  static void _logPerformanceLevel(PerformanceMetric metric) {
    final duration = metric.duration!;
    String level;

    if (duration < excellentThreshold) {
      level = 'EXCELLENT';
    } else if (duration < warningThreshold) {
      level = 'GOOD';
    } else if (duration < slowOperationThreshold) {
      level = 'WARNING';
    } else {
      level = 'SLOW';
    }

    print('[PERF] $level: ${metric.name} completed in ${duration}ms');
  }

  /// Report metric to monitoring service
  static Future<void> _reportMetric(PerformanceMetric metric) async {
    try {
      // Log slow operations
      if (metric.duration! > slowOperationThreshold) {
        print('[PERF] SLOW OPERATION DETECTED: ${metric.name} took ${metric.duration}ms');

        // Send to error logging if available
        // await ErrorLoggingService.logPerformanceIssue(
        //   operation: metric.name,
        //   duration: metric.duration!,
        //   attributes: metric.attributes,
        // );
      }

      // Send to analytics
      await AnalyticsService.track(
        userId: 'system',
        event: 'performance_metric',
        properties: {
          'operation': metric.name,
          'duration_ms': metric.duration,
          'performance_level': _getPerformanceLevel(metric.duration!),
          ...?metric.attributes,
        },
      );
    } catch (e) {
      print('[PERF] Failed to report metric: $e');
    }
  }

  /// Add metric to history for trend analysis
  static void _addToHistory(String name, int duration) {
    if (!_metricHistory.containsKey(name)) {
      _metricHistory[name] = [];
    }

    _metricHistory[name]!.add(duration);

    // Keep only last 50 measurements
    if (_metricHistory[name]!.length > 50) {
      _metricHistory[name]!.removeAt(0);
    }
  }

  /// Get average duration for an operation
  static double? getAverageDuration(String name) {
    final history = _metricHistory[name];
    if (history == null || history.isEmpty) return null;

    final sum = history.reduce((a, b) => a + b);
    return sum / history.length;
  }

  /// Get performance statistics for an operation
  static PerformanceStats? getStats(String name) {
    final history = _metricHistory[name];
    if (history == null || history.isEmpty) return null;

    final sorted = List<int>.from(history)..sort();
    final min = sorted.first;
    final max = sorted.last;
    final avg = sorted.reduce((a, b) => a + b) / sorted.length;
    final median = sorted[sorted.length ~/ 2];

    return PerformanceStats(
      operation: name,
      min: min,
      max: max,
      average: avg,
      median: median,
      sampleCount: sorted.length,
    );
  }

  /// Get performance level description
  static String _getPerformanceLevel(int duration) {
    if (duration < excellentThreshold) return 'excellent';
    if (duration < warningThreshold) return 'good';
    if (duration < slowOperationThreshold) return 'warning';
    return 'slow';
  }

  /// Clear all metrics and history
  static void clearAll() {
    _metrics.clear();
    _metricHistory.clear();
    print('[PERF] All metrics cleared');
  }

  /// Print performance summary for all operations
  static void printSummary() {
    print('\n===== PERFORMANCE SUMMARY =====');

    for (final name in _metricHistory.keys) {
      final stats = getStats(name);
      if (stats != null) {
        print('\n${stats.operation}:');
        print('  Samples: ${stats.sampleCount}');
        print('  Average: ${stats.average.toStringAsFixed(1)}ms');
        print('  Median:  ${stats.median}ms');
        print('  Min:     ${stats.min}ms');
        print('  Max:     ${stats.max}ms');
      }
    }

    print('\n===============================\n');
  }

  /// Track an async operation
  static Future<T> trackOperation<T>(
    String name,
    Future<T> Function() operation, {
    Map<String, dynamic>? attributes,
  }) async {
    startTrace(name);
    try {
      final result = await operation();
      endTrace(name, attributes: attributes);
      return result;
    } catch (e) {
      endTrace(name, attributes: {
        ...?attributes,
        'error': e.toString(),
      });
      rethrow;
    }
  }
}

/// Performance metric data
class PerformanceMetric {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  int? duration;
  Map<String, dynamic>? attributes;

  PerformanceMetric({
    required this.name,
    required this.startTime,
  });

  @override
  String toString() => 'PerformanceMetric($name: ${duration}ms)';
}

/// Performance statistics
class PerformanceStats {
  final String operation;
  final int min;
  final int max;
  final double average;
  final int median;
  final int sampleCount;

  PerformanceStats({
    required this.operation,
    required this.min,
    required this.max,
    required this.average,
    required this.median,
    required this.sampleCount,
  });

  @override
  String toString() {
    return 'PerformanceStats($operation: avg=${average.toStringAsFixed(1)}ms, '
           'median=${median}ms, min=${min}ms, max=${max}ms, samples=$sampleCount)';
  }

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'min': min,
    'max': max,
    'average': average,
    'median': median,
    'sample_count': sampleCount,
  };
}

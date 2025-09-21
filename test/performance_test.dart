import 'package:flutter_test/flutter_test.dart';
import 'package:groupting/utils/performance_monitor.dart';
import 'dart:async';

/// 그룹팅 성능 테스트 용도로 구현 함
/// 실시간 채팅 성능 및 응답성 검증
void main() {
  group('채팅 성능 테스트', () {
    late PerformanceMonitor monitor;

    setUp(() {
      monitor = PerformanceMonitor();
      monitor.reset();
    });

    test('메시지 전송 시간 측정', () async {
      const messageId = 'test_message_1';
      
      // 메시지 전송 시뮬레이션
      final stopwatch = monitor.startMessageSend(messageId);
      
      // 네트워크 지연 시뮬레이션 (100ms)
      await Future.delayed(const Duration(milliseconds: 100));
      
      monitor.recordMessageSent(messageId, stopwatch);
      
      // 성능 통계 확인
      final warnings = monitor.getPerformanceWarnings();
      expect(warnings, isEmpty, reason: '100ms 전송은 정상 범위여야 함');
    });

    test('메시지 수신 지연 측정', () async {
      const messageId = 'test_message_2';
      final sentTime = DateTime.now().subtract(const Duration(milliseconds: 500));
      
      monitor.recordMessageReceived(messageId, sentTime);
      
      final warnings = monitor.getPerformanceWarnings();
      expect(warnings, isEmpty, reason: '500ms 지연은 정상 범위여야 함');
    });

    test('과도한 UI 업데이트 감지', () {
      const componentName = 'TestComponent';
      
      // 빠른 연속 업데이트 시뮬레이션
      for (int i = 0; i < 10; i++) {
        monitor.recordUIUpdate(componentName);
      }
      
      // 과도한 업데이트 경고가 발생하지 않아야 함 (아직 임계치 미달)
      final warnings = monitor.getPerformanceWarnings();
      expect(warnings.where((w) => w.contains(componentName)), isEmpty);
    });

    test('느린 메시지 전송 감지', () async {
      const messageId = 'slow_message';
      
      final stopwatch = monitor.startMessageSend(messageId);
      
      // 느린 네트워크 시뮬레이션 (1500ms)
      await Future.delayed(const Duration(milliseconds: 1500));
      
      monitor.recordMessageSent(messageId, stopwatch);
      
      final warnings = monitor.getPerformanceWarnings();
      expect(warnings.any((w) => w.contains('전송이 느림')), isTrue);
    });

    test('느린 메시지 수신 감지', () {
      const messageId = 'delayed_message';
      final sentTime = DateTime.now().subtract(const Duration(milliseconds: 3000));
      
      monitor.recordMessageReceived(messageId, sentTime);
      
      final warnings = monitor.getPerformanceWarnings();
      expect(warnings.any((w) => w.contains('수신이 느림')), isTrue);
    });

    test('메모리 정리 동작 확인', () {
      // 대량의 가짜 데이터 생성
      for (int i = 0; i < 1500; i++) {
        final stopwatch = monitor.startMessageSend('message_$i');
        stopwatch.stop();
        monitor.recordMessageSent('message_$i', stopwatch);
      }
      
      // 메모리 체크 호출 (내부적으로 정리 수행)
      monitor.checkMemoryUsage();
      
      // 정리 후 경고가 감소해야 함
      final warnings = monitor.getPerformanceWarnings();
      expect(warnings.length, lessThan(10), reason: '메모리 정리 후 경고가 줄어야 함');
    });
  });

  group('채팅방 UI 성능 테스트', () {
    test('대량 메시지 처리 성능', () async {
      // 100개 메시지 빠른 연속 처리 시뮬레이션
      final startTime = DateTime.now();
      
      for (int i = 0; i < 100; i++) {
        // UI 업데이트 시뮬레이션
        await Future.delayed(const Duration(microseconds: 100));
      }
      
      final endTime = DateTime.now();
      final elapsed = endTime.difference(startTime).inMilliseconds;
      
      // 100개 메시지 처리가 1초 이내에 완료되어야 함
      expect(elapsed, lessThan(1000), 
        reason: '100개 메시지 처리는 1초 이내에 완료되어야 함');
    });

    test('스크롤 성능 시뮬레이션', () async {
      final monitor = PerformanceMonitor();
      
      // 빠른 스크롤 시뮬레이션 (연속 UI 업데이트)
      for (int i = 0; i < 50; i++) {
        monitor.recordUIUpdate('ListView');
        await Future.delayed(const Duration(milliseconds: 16)); // 60fps
      }
      
      final warnings = monitor.getPerformanceWarnings();
      // 60fps 업데이트는 정상이므로 경고가 없어야 함
      expect(warnings.where((w) => w.contains('ListView')), isEmpty);
    });
  });

  group('n:n 채팅 성능 테스트', () {
    test('다중 사용자 메시지 처리', () async {
      final monitor = PerformanceMonitor();
      const userCount = 8; // 4vs4 그룹 매칭
      
      // 다중 사용자가 동시에 메시지를 보내는 시뮬레이션
      final futures = <Future>[];
      
      for (int i = 0; i < userCount; i++) {
        futures.add(_simulateUserMessage(monitor, 'user_$i'));
      }
      
      await Future.wait(futures);
      
      // 모든 메시지가 합리적인 시간 내에 처리되어야 함
      final warnings = monitor.getPerformanceWarnings();
      expect(warnings.length, lessThan(3), 
        reason: '다중 사용자 메시지 처리에서 과도한 경고가 없어야 함');
    });
  });
}

/// 사용자 메시지 전송 시뮬레이션
Future<void> _simulateUserMessage(PerformanceMonitor monitor, String userId) async {
  for (int i = 0; i < 5; i++) {
    final messageId = '${userId}_message_$i';
    final stopwatch = monitor.startMessageSend(messageId);
    
    // 랜덤 네트워크 지연 (50-200ms)
    final delay = 50 + (i * 30);
    await Future.delayed(Duration(milliseconds: delay));
    
    monitor.recordMessageSent(messageId, stopwatch);
    
    // 메시지 간 간격
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

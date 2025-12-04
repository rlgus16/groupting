import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class VersionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<VersionCheckResult> checkVersion() async {
    try {
      // 1. 현재 앱 버전 가져오기
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // 예: "1.0.0"

      // 2. Firestore에서 최소 지원 버전 가져오기
      final doc = await _firestore.collection('config').doc('version_info').get();

      if (!doc.exists) {
        return VersionCheckResult(needsUpdate: false);
      }

      final data = doc.data()!;
      String minVersion = '0.0.0';
      String storeUrl = '';

      if (Platform.isAndroid) {
        minVersion = data['min_version_android'] ?? '0.0.0';
        storeUrl = data['store_url_android'] ?? '';
      } else if (Platform.isIOS) {
        minVersion = data['min_version_ios'] ?? '0.0.0';
        storeUrl = data['store_url_ios'] ?? '';
      }

      // 3. 버전 비교
      if (_isUpdateRequired(currentVersion, minVersion)) {
        return VersionCheckResult(
          needsUpdate: true,
          storeUrl: storeUrl,
          message: '안정적인 서비스 이용을 위해\n최신 버전으로 업데이트가 필요합니다.',
        );
      }

      return VersionCheckResult(needsUpdate: false);
    } catch (e) {
      debugPrint('버전 체크 실패: $e');
      // 에러 발생 시 일단 통과 (앱 사용 차단 방지)
      return VersionCheckResult(needsUpdate: false);
    }
  }

  // 버전 문자열 비교 (예: 1.0.0 vs 1.0.1)
  bool _isUpdateRequired(String current, String min) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> minParts = min.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        int c = i < currentParts.length ? currentParts[i] : 0;
        int m = i < minParts.length ? minParts[i] : 0;

        if (c < m) return true; // 현재 버전이 더 낮으면 업데이트 필요
        if (c > m) return false; // 현재 버전이 더 높으면 통과
      }
      return false; // 같으면 통과
    } catch (e) {
      return false;
    }
  }
}

class VersionCheckResult {
  final bool needsUpdate;
  final String? storeUrl;
  final String? message;

  VersionCheckResult({required this.needsUpdate, this.storeUrl, this.message});
}
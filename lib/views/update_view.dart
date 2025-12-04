import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';

class UpdateView extends StatelessWidget {
  final String storeUrl;
  final String message;

  const UpdateView({
    super.key,
    required this.storeUrl,
    required this.message,
  });

  Future<void> _launchStore() async {
    final Uri uri = Uri.parse(storeUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // 스토어 URL을 열 수 없는 경우 (에러 처리)
        throw 'Could not launch $storeUrl';
      }
    } catch (e) {
      debugPrint('스토어 이동 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 뒤로가기 방지 (WillPopScope는 deprecated 되었으므로 PopScope 사용)
    return PopScope(
      canPop: false, // 뒤로가기 버튼 비활성화
      onPopInvoked: (didPop) {
        if (!didPop) {
          // 필요 시 앱 종료 안내 등을 추가할 수 있습니다.
          // SystemNavigator.pop(); // 앱 종료
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update_alt, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              const Text(
                '업데이트 안내',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _launchStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('지금 업데이트', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
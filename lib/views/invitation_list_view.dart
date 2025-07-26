import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/group_controller.dart';
import '../utils/app_theme.dart';

class InvitationListView extends StatefulWidget {
  const InvitationListView({super.key});

  @override
  State<InvitationListView> createState() => _InvitationListViewState();
}

class _InvitationListViewState extends State<InvitationListView> {
  Future<void> _handleInvitation(String invitationId, bool accept) async {
    final groupController = context.read<GroupController>();

    final success = accept
        ? await groupController.acceptInvitation(invitationId)
        : await groupController.rejectInvitation(invitationId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? '초대를 수락했습니다.' : '초대를 거절했습니다.')),
      );

      if (accept) {
        // 초대 수락 시 홈으로 이동
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } else if (mounted && groupController.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(groupController.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('받은 초대')),
      body: Consumer<GroupController>(
        builder: (context, groupController, _) {
          if (groupController.receivedInvitations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: AppTheme.gray400),
                  const SizedBox(height: 16),
                  Text(
                    '받은 초대가 없습니다',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupController.receivedInvitations.length,
            itemBuilder: (context, index) {
              final invitation = groupController.receivedInvitations[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 보낸 사람 정보
                      Row(
                        children: [
                          // 프로필 이미지
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.gray200,
                            ),
                            child: ClipOval(
                              child: invitation.fromUserProfileImage != null
                                  ? CachedNetworkImage(
                                      imageUrl:
                                          invitation.fromUserProfileImage!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                            Icons.person,
                                            color: AppTheme.textSecondary,
                                          ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      color: AppTheme.textSecondary,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 이름과 시간
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${invitation.fromUserNickname}님의 초대',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(invitation.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // 초대 메시지 (있는 경우)
                      if (invitation.message != null &&
                          invitation.message!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.gray100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            invitation.message!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],

                      // 유효 기간 표시
                      if (!invitation.isValid) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_off,
                                size: 16,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '초대가 만료되었습니다',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppTheme.errorColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 버튼들
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: invitation.canRespond
                                  ? () =>
                                        _handleInvitation(invitation.id, false)
                                  : null,
                              child: const Text('거절'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: invitation.canRespond
                                  ? () => _handleInvitation(invitation.id, true)
                                  : null,
                              child: const Text('수락'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }
}

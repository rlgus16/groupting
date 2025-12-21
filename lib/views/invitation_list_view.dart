import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/member_avatar.dart';
import '../widgets/custom_toast.dart';

class InvitationListView extends StatefulWidget {
  const InvitationListView({super.key});

  @override
  State<InvitationListView> createState() => _InvitationListViewState();
}

class _InvitationListViewState extends State<InvitationListView> {
  final Set<String> _processingInvitations = <String>{};

  Future<void> _handleInvitation(String invitationId, bool accept) async {
    if (_processingInvitations.contains(invitationId)) return;

    final groupController = context.read<GroupController>();

    if (accept && groupController.currentGroup != null) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('그룹 이동'),
          content: const Text('현재 그룹을 떠나고 새 그룹으로 이동하시겠습니까?'),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: AppTheme.gray600),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                // [수정] fontWeight는 textStyle 안에서 설정해야 합니다.
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
              child: const Text('이동하기'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() {
      _processingInvitations.add(invitationId);
    });

    try {
      final success = accept
          ? await groupController.acceptInvitation(invitationId)
          : await groupController.rejectInvitation(invitationId);

      if (mounted) {
        if (success) {
          if (accept) {
            CustomToast.showSuccess(context, '그룹에 참여했어요!');
            await Future.delayed(const Duration(milliseconds: 1200));
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            }
          } else {
            CustomToast.showInfo(context, '초대를 거절했어요');
          }
        } else if (groupController.errorMessage != null) {
          CustomToast.showError(context, groupController.errorMessage!);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingInvitations.remove(invitationId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: const Text('받은 초대'),
        backgroundColor: AppTheme.gray50,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<GroupController>(
        builder: (context, groupController, _) {
          if (groupController.receivedInvitations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            itemCount: groupController.receivedInvitations.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final invitation = groupController.receivedInvitations[index];
              final isProcessing = _processingInvitations.contains(invitation.id);

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(color: AppTheme.gray100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Avatar + Info + Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MemberAvatar(
                            imageUrl: invitation.fromUserProfileImage,
                            name: invitation.fromUserNickname,
                            size: 52,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${invitation.fromUserNickname}님의 초대',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                          fontFamily: 'Pretendard',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(invitation.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.gray500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  '새로운 그룹에 초대되었어요!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Message Bubble
                      if (invitation.message != null &&
                          invitation.message!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${invitation.message}"',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.gray800,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Expired Label
                      if (!invitation.isValid) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppTheme.errorColor.withValues(alpha: 0.2)),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.timer_off_outlined,
                                  size: 14,
                                  color: AppTheme.errorColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '유효기간이 만료된 초대입니다',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.errorColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: (invitation.canRespond && !isProcessing)
                                    ? () => _handleInvitation(invitation.id, false)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.gray300),
                                  foregroundColor: AppTheme.textSecondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isProcessing
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.textSecondary,
                                    ),
                                  ),
                                )
                                    : const Text('거절'),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: (invitation.canRespond && !isProcessing)
                                    ? () => _handleInvitation(invitation.id, true)
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isProcessing
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                    : const Text(
                                  '수락',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '아직 받은 초대가 없어요',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontFamily: 'Pretendard',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '친구가 초대를 보내면 여기에 표시됩니다',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
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
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }
}
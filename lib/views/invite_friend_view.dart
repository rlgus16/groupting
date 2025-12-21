import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_controller.dart';
import '../models/invitation_model.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_toast.dart';

class InviteFriendView extends StatefulWidget {
  const InviteFriendView({super.key});

  @override
  State<InviteFriendView> createState() => _InviteFriendViewState();
}

class _InviteFriendViewState extends State<InviteFriendView> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _inviteFriend() async {
    if (!_formKey.currentState!.validate()) return;

    final groupController = context.read<GroupController>();

    try {
      await groupController.inviteFriend(
        nickname: _nicknameController.text.trim(),
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      if (mounted) {
        CustomToast.showSuccess(context, '초대를 보냈어요!');
        _nicknameController.clear();
        _messageController.clear();
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('친구 초대'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // 안내 메시지
                _buildGuideBox(context),
                const SizedBox(height: 24),

                // 그룹 현황 카드
                _buildGroupStatusCard(),
                const SizedBox(height: 24),

                // 입력 폼
                Text(
                  '누구를 초대할까요?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    hintText: '친구의 닉네임을 입력해주세요',
                    prefixIcon: Icon(Icons.person_search_rounded),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '닉네임을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: '메세지 (선택)',
                    hintText: '같이 그룹팅하자!',
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  maxLines: 1,
                  maxLength: 50,
                ),
                const SizedBox(height: 32),

                // 4. 초대 버튼
                Consumer<GroupController>(
                  builder: (context, groupController, _) {
                    return ElevatedButton(
                      onPressed: groupController.isLoading ? null : _inviteFriend,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                      child: groupController.isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text('초대장 보내기'),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // 보낸 초대 목록
                Consumer<GroupController>(
                  builder: (context, groupController, _) {
                    if (groupController.sentInvitations.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '보낸 초대',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.gray200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${groupController.sentInvitations.length}',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...groupController.sentInvitations.map((invitation) {
                          return _buildInvitationCard(context, invitation);
                        }),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 위젯: 안내 박스
  Widget _buildGuideBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '친구 초대는 이렇게 하세요',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• 친구의 닉네임을 정확히 입력해주세요.\n• 최대 5명까지 그룹을 구성할 수 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.gray700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 위젯: 그룹 인원 현황 (점 형태로 시각화)
  Widget _buildGroupStatusCard() {
    return Consumer<GroupController>(
      builder: (context, groupController, _) {
        final currentCount = groupController.currentGroup?.memberCount ?? 1;
        const maxCount = 5;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
            border: Border.all(color: AppTheme.gray100),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '현재 그룹 인원',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$currentCount',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: ' / $maxCount명',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 인원수 시각화 (Dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(maxCount, (index) {
                  final bool isFilled = index < currentCount;
                  return Expanded(
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isFilled ? AppTheme.primaryColor : AppTheme.gray200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  // 위젯: 초대 리스트 카드
  Widget _buildInvitationCard(BuildContext context, InvitationModel invitation) {
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    switch (invitation.status) {
      case InvitationStatus.pending:
        statusColor = const Color(0xFFFFB74D); // Orange
        statusBgColor = const Color(0xFFFFF3E0);
        statusText = '대기 중';
        statusIcon = Icons.access_time_rounded;
        break;
      case InvitationStatus.accepted:
        statusColor = AppTheme.successColor;
        statusBgColor = AppTheme.successColor.withValues(alpha: 0.1);
        statusText = '수락됨';
        statusIcon = Icons.check_circle_outline_rounded;
        break;
      case InvitationStatus.rejected:
        statusColor = AppTheme.errorColor;
        statusBgColor = AppTheme.errorColor.withValues(alpha: 0.1);
        statusText = '거절됨';
        statusIcon = Icons.highlight_off_rounded;
        break;
      default:
        statusColor = AppTheme.gray500;
        statusBgColor = AppTheme.gray200;
        statusText = '만료됨';
        statusIcon = Icons.timer_off_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.gray100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.gray100,
          radius: 22,
          child: const Icon(
            Icons.mail_outline_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          invitation.toUserNickname,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          invitation.message ?? '메세지 없음',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusBgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
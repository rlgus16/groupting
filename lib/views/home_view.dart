import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/group_controller.dart';
import '../controllers/chat_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/member_avatar.dart';
import '../models/invitation_model.dart';
import 'invite_friend_view.dart';
import 'invitation_list_view.dart';
import 'profile_detail_view.dart';
import 'group_members_view.dart';
import 'my_page_view.dart';
import 'chat_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // 앱 생명주기 감지 시작
    WidgetsBinding.instance.addObserver(this);

    // 그룹 컨트롤러 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final groupController = context.read<GroupController>();
      groupController.initialize();

      // 매칭 완료 콜백 설정
      groupController.onMatchingCompleted = _onMatchingCompleted;
    });
  }

  @override
  void dispose() {
    // 매칭 완료 콜백 제거
    final groupController = context.read<GroupController>();
    groupController.onMatchingCompleted = null;
    
    // 앱 생명주기 감지 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아왔을 때 자동 새로고침
      final groupController = context.read<GroupController>();
      groupController.onAppResumed();
    }
  }

  // 매칭 완료 시 처리
  void _onMatchingCompleted() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.celebration, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('매칭 완료!'),
          ],
        ),
        content: const Text('상대방 그룹과 매칭되었습니다!\n채팅방으로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('나중에'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToChat();
            },
            child: const Text('채팅방으로 이동'),
          ),
        ],
      ),
    );
  }

  // 채팅방으로 이동
  void _navigateToChat() {
    final groupController = context.read<GroupController>();
    final chatController = context.read<ChatController>();

    if (groupController.currentGroup != null) {
      String chatRoomId;

      // 매칭된 경우 통합 채팅방 ID 사용
      if (groupController.isMatched &&
          groupController.currentGroup!.matchedGroupId != null) {
        // 두 그룹 ID 중 작은 것을 채팅방 ID로 사용 (일관성 보장)
        final currentGroupId = groupController.currentGroup!.id;
        final matchedGroupId = groupController.currentGroup!.matchedGroupId!;
        chatRoomId = currentGroupId.compareTo(matchedGroupId) < 0
            ? '${currentGroupId}_${matchedGroupId}'
            : '${matchedGroupId}_${currentGroupId}';
        print('매칭된 그룹 통합 채팅방 ID: $chatRoomId');
      } else {
        // 매칭되지 않은 경우 기존 그룹 ID 사용
        chatRoomId = groupController.currentGroup!.id;
        print('일반 그룹 채팅방 ID: $chatRoomId');
      }

      chatController.startMessageStream(chatRoomId);
      Navigator.pushNamed(context, '/chat');
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final authController = context.read<AuthController>();
        final groupController = context.read<GroupController>();

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들 바
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 메뉴 아이템들
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('받은 초대'),
                trailing: groupController.receivedInvitations.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${groupController.receivedInvitations.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InvitationListView(),
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.send_outlined),
                title: const Text('보낸 초대'),
                trailing: groupController.sentInvitations.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${groupController.sentInvitations.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _showSentInvitationsDialog();
                },
              ),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('마이페이지'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyPageView()),
                  );
                },
              ),

              const Divider(height: 1),

              ListTile(
                leading: const Icon(
                  Icons.exit_to_app,
                  color: AppTheme.errorColor,
                ),
                title: const Text(
                  '그룹 나가기',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showLeaveGroupDialog();
                  if (confirmed) {
                    final success = await groupController.leaveGroup();
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('그룹에서 나왔습니다.')),
                      );
                      // UI 새로고침을 위해 setState 호출
                      setState(() {});
                    } else if (mounted &&
                        groupController.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(groupController.errorMessage!)),
                      );
                    }
                  }
                },
              ),

              ListTile(
                leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                title: const Text(
                  '로그아웃',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await _showLogoutDialog();
                  if (confirmed) {
                    await authController.signOut();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _showLeaveGroupDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('그룹 나가기'),
            content: const Text('정말로 그룹을 나가시겠습니까?\n나간 후에는 다시 초대를 받아야 합니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('나가기'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('로그아웃'),
            content: const Text('정말로 로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSentInvitationsDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<GroupController>(
        builder: (context, groupController, _) => AlertDialog(
          title: const Text('보낸 초대'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: groupController.sentInvitations.isEmpty
                ? const Center(child: Text('보낸 초대가 없습니다.'))
                : ListView.builder(
                    itemCount: groupController.sentInvitations.length,
                    itemBuilder: (context, index) {
                      final invitation = groupController.sentInvitations[index];
                      return Card(
                        child: ListTile(
                          title: Text(invitation.toUserNickname),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('상태: ${_getStatusText(invitation.status)}'),
                              Text(
                                '보낸 시간: ${_formatDate(invitation.createdAt)}',
                              ),
                              if (invitation.message != null)
                                Text('메시지: ${invitation.message}'),
                            ],
                          ),
                          trailing:
                              invitation.status == InvitationStatus.pending
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: AppTheme.errorColor,
                                  ),
                                  onPressed: () async {
                                    final success = await groupController
                                        .cancelSentInvitation(invitation.id);
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('초대를 취소했습니다.'),
                                        ),
                                      );
                                    }
                                  },
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.pending:
        return '대기 중';
      case InvitationStatus.accepted:
        return '수락됨';
      case InvitationStatus.rejected:
        return '거절됨';
      case InvitationStatus.expired:
        return '만료됨';
      default:
        return '알 수 없음';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹팅'),
        actions: [
          // 초대 알림
          Consumer<GroupController>(
            builder: (context, groupController, _) {
              if (groupController.receivedInvitations.isNotEmpty) {
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.errorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InvitationListView(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // 새로고침 버튼
          Consumer<GroupController>(
            builder: (context, groupController, _) {
              return IconButton(
                icon: groupController.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: groupController.isLoading
                    ? null
                    : () async {
                        await groupController.refreshData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('데이터를 새로고침했습니다'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                tooltip: '새로고침',
              );
            },
          ),

          // 더보기 메뉴
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // 홈 화면이므로 0
        onTap: (index) {
          switch (index) {
            case 0:
              // 이미 홈 화면이므로 아무것도 하지 않음
              break;
            case 1:
              // 받은 초대
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvitationListView(),
                ),
              );
              break;
            case 2:
              // 마이페이지
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPageView()),
              );
              break;
            case 3:
              // 로그아웃
              _showMoreOptions();
              break;
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: Consumer<GroupController>(
              builder: (context, groupController, _) {
                if (groupController.receivedInvitations.isNotEmpty) {
                  return Stack(
                    children: [
                      const Icon(Icons.mail),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.errorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const Icon(Icons.mail_outline);
              },
            ),
            label: '초대',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '마이페이지',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: '더보기',
          ),
        ],
      ),
      body: Consumer<GroupController>(
        builder: (context, groupController, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 현재 그룹 상태 카드
                if (groupController.currentGroup != null) ...[
                  _buildGroupStatusCard(groupController),
                  const SizedBox(height: 16),
                  _buildGroupMembersSection(groupController),
                  const SizedBox(height: 16),
                  _buildActionButtons(groupController),
                ] else ...[
                  _buildNoGroupCard(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoGroupCard() {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_add, size: 64, color: AppTheme.gray400),
              const SizedBox(height: 16),
              Text(
                '그룹이 없습니다',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                '새로운 그룹을 만들어 친구들과 함께하세요!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final groupController = context.read<GroupController>();
                  await groupController.createGroup();
                },
                icon: const Icon(Icons.add),
                label: const Text('그룹 만들기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupStatusCard(GroupController groupController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  groupController.isMatched
                      ? Icons.favorite
                      : groupController.isMatching
                      ? Icons.hourglass_empty
                      : Icons.group,
                  color: groupController.isMatched
                      ? AppTheme.successColor
                      : groupController.isMatching
                      ? Colors.orange
                      : AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  groupController.isMatched
                      ? '매칭 완료!'
                      : groupController.isMatching
                      ? '매칭 중...'
                      : '그룹 대기',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: groupController.isMatched
                        ? AppTheme.successColor
                        : groupController.isMatching
                        ? Colors.orange
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '멤버 수: ${groupController.groupMembers.length}/5',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            // 채팅 버튼 (매칭 전/후 모두 표시) -> 요청 사항 반영
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                String chatRoomId;

                // 매칭된 경우 통합 채팅방 ID 사용
                if (groupController.isMatched &&
                    groupController.currentGroup!.matchedGroupId != null) {
                  // 두 그룹 ID 중 작은 것을 채팅방 ID로 사용 (일관성 보장)
                  final currentGroupId = groupController.currentGroup!.id;
                  final matchedGroupId =
                      groupController.currentGroup!.matchedGroupId!;
                  chatRoomId = currentGroupId.compareTo(matchedGroupId) < 0
                      ? '${currentGroupId}_${matchedGroupId}'
                      : '${matchedGroupId}_${currentGroupId}';
                  print('매칭된 그룹 통합 채팅방 ID: $chatRoomId');
                } else {
                  // 매칭되지 않은 경우 그룹 ID 사용
                  chatRoomId = groupController.currentGroup!.id;
                  print('그룹 채팅방 ID: $chatRoomId');
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatView(groupId: chatRoomId),
                  ),
                );
              },
              icon: Icon(groupController.isMatched ? Icons.chat : Icons.group_outlined),
              label: Text(groupController.isMatched ? '매칭 채팅' : '그룹 채팅'),
              style: ElevatedButton.styleFrom(
                backgroundColor: groupController.isMatched 
                    ? AppTheme.successColor 
                    : AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupMembersSection(GroupController groupController) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '그룹 멤버',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (groupController.groupMembers.length > 3)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const GroupMembersView(),
                        ),
                      );
                    },
                    child: const Text('전체 보기'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: groupController.groupMembers.length,
                itemBuilder: (context, index) {
                  final member = groupController.groupMembers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProfileDetailView(user: member),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          MemberAvatar(
                            imageUrl: member.mainProfileImage,
                            name: member.nickname,
                            isOwner: groupController.currentGroup!.isOwner(
                              member.uid,
                            ),
                            size: 50,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member.nickname,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(GroupController groupController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 친구 초대 버튼 (방장만, 매칭 전)
        if (groupController.isOwner && !groupController.isMatched)
          ElevatedButton.icon(
            onPressed: groupController.currentGroup!.memberIds.length >= 5
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InviteFriendView(),
                      ),
                    );
                  },
            icon: const Icon(Icons.person_add),
            label: Text(
              groupController.currentGroup!.memberIds.length >= 5
                  ? '인원 가득 참'
                  : '친구 초대하기',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gray600,
              foregroundColor: Colors.white,
            ),
          ),

        if (groupController.isOwner && !groupController.isMatched)
          const SizedBox(height: 12),

        // 매칭 버튼 (방장만, 매칭 전)
        if (groupController.isOwner && !groupController.isMatched)
          ElevatedButton.icon(
            onPressed: groupController.currentGroup!.memberIds.length < 1
                ? null
                : groupController.isMatching
                ? groupController.cancelMatching
                : groupController.startMatching,
            icon: Icon(
              groupController.isMatching ? Icons.close : Icons.favorite,
            ),
            label: Text(
              groupController.currentGroup!.memberIds.length < 1
                  ? '최소 1명 필요'
                  : groupController.isMatching
                  ? '매칭 취소'
                  : groupController.currentGroup!.memberIds.length == 1
                  ? '1:1 매칭 시작'
                  : '그룹 매칭 시작',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: groupController.isMatching
                  ? AppTheme.errorColor
                  : AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

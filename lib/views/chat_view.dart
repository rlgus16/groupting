import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/group_controller.dart';
import '../controllers/chat_controller.dart';
import '../utils/app_theme.dart';
import '../widgets/message_bubble.dart';
import '../widgets/member_avatar.dart';
import 'profile_detail_view.dart';

class ChatView extends StatefulWidget {
  final String groupId;

  const ChatView({super.key, required this.groupId});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatController = context.read<ChatController>();
      chatController.startMessageStream(widget.groupId);
    });
  }

  @override
  void dispose() {
    final chatController = context.read<ChatController>();
    chatController.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 채팅'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Consumer2<GroupController, ChatController>(
        builder: (context, groupController, chatController, _) {
          return Column(
            children: [
              // 매칭된 그룹 멤버 헤더
              if (groupController.isMatched)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    border: Border(bottom: BorderSide(color: AppTheme.gray200)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '매칭된 상대방',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: chatController.matchedGroupMembers.length,
                          itemBuilder: (context, index) {
                            final member =
                                chatController.matchedGroupMembers[index];
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
                                child: MemberAvatar(
                                  imageUrl: member.mainProfileImage,
                                  name: member.nickname,
                                  isMatched: true,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // 채팅 메시지 영역
              Expanded(
                child: chatController.messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: AppTheme.gray400,
                            ),
                            SizedBox(height: 16),
                            Text(
                              '매칭이 성공했습니다!\n대화를 시작해보세요!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatController.messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              chatController.messages[chatController
                                      .messages
                                      .length -
                                  1 -
                                  index];
                          final senderProfile = message.senderId != 'system'
                              ? chatController.matchedGroupMembers
                                    .where(
                                      (member) =>
                                          member.uid == message.senderId,
                                    )
                                    .firstOrNull
                              : null;

                          return MessageBubble(
                            message: message,
                            isMe: chatController.isMyMessage(message),
                            senderProfile: senderProfile,
                            onTap: message.senderId != 'system'
                                ? () {
                                    final member = groupController
                                        .getMemberById(message.senderId);
                                    if (member != null &&
                                        member.uid.isNotEmpty) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProfileDetailView(user: member),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                          );
                        },
                      ),
              ),

              // 메시지 입력 영역
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppTheme.gray200)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatController.messageController,
                          decoration: InputDecoration(
                            hintText: '메시지를 입력하세요',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: AppTheme.gray100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) async {
                            await chatController.sendMessage();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () async {
                          await chatController.sendMessage();
                        },
                        icon: const Icon(Icons.send),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

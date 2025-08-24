import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/message_model.dart';
import 'firebase_service.dart';
import 'user_service.dart';

class RealtimeChatService {
  final FirebaseService _firebaseService = FirebaseService();
  final UserService _userService = UserService();
  late final DatabaseReference _database;

  RealtimeChatService() {
    // Firebase Realtime Database 인스턴스 초기화
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      // Firebase Realtime Database URL
      databaseURL: 'https://groupting-aebab-default-rtdb.firebaseio.com',
    );
    _database = database.ref();
  }

  // 그룹 채팅방에 메시지 전송
  Future<void> sendMessage({
    required String groupId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    try {
      final currentUser = _firebaseService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      // print('메시지 전송 시작: $content');

      // 사용자 닉네임 가져오기
      final userModel = await _userService.getUserById(currentUser.uid);
      final senderNickname = userModel?.nickname ?? 'Unknown User';

      // print('발송자: $senderNickname');

      final messageRef = _database.child('chats').child(groupId).push();
      final message = MessageModel(
        id: messageRef.key!,
        senderId: currentUser.uid,
        senderNickname: senderNickname,
        content: content,
        type: type,
        createdAt: DateTime.now(),
        groupId: groupId,
        readBy: [],
      );

      // print('메시지 데이터: ${message.toMap()}');

      await messageRef.set(message.toMap());
      // print('메시지 전송 완료');
    } catch (e) {
      // print('메시지 전송 오류: $e');
      throw Exception('메시지 전송에 실패했습니다: $e');
    }
  }

  // 실시간 메시지 스트림
  Stream<List<MessageModel>> getMessagesStream(String groupId) {
    return _database
        .child('chats')
        .child(groupId)
        .orderByChild('timestamp')
        .onValue
        .map((event) {
          final data = event.snapshot.value;
          if (data == null) return <MessageModel>[];

          // print('받은 데이터: $data');

          final Map<String, dynamic> messagesMap;
          try {
            messagesMap = Map<String, dynamic>.from(data as Map);
          } catch (e) {
            // print('메시지 맵 변환 오류: $e');
            return <MessageModel>[];
          }

          final messages = messagesMap.entries
              .where(
                (entry) =>
                    entry.key != 'created_at' && entry.key != 'last_updated',
              ) // 메타데이터 제외
              .map((entry) {
                try {
                  if (entry.value is! Map) {
                    // print('잘못된 메시지 데이터 타입: ${entry.key} = ${entry.value}');
                    return null;
                  }

                  final messageData = Map<String, dynamic>.from(
                    entry.value as Map,
                  );
                  messageData['id'] = entry.key;

                  // print('파싱할 메시지 데이터: $messageData');
                  return MessageModel.fromMap(messageData);
                } catch (e) {
                  // print('메시지 파싱 오류 (${entry.key}): $e');
                  // print('문제가 된 데이터: ${entry.value}');
                  return null;
                }
              })
              .where((message) => message != null)
              .cast<MessageModel>()
              .toList();

          // 시간순으로 정렬
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          // print('파싱된 메시지 개수: ${messages.length}');
          return messages;
        });
  }

  // 그룹 채팅방 생성/초기화
  Future<void> initializeChatRoom(String groupId) async {
    try {
      final chatRef = _database.child('chats').child(groupId);
      final snapshot = await chatRef.get();

      if (!snapshot.exists) {
        // 채팅방이 존재하지 않으면 초기화
        await chatRef.set({
          'created_at': ServerValue.timestamp,
          'last_updated': ServerValue.timestamp,
        });
      }
    } catch (e) {
      throw Exception('채팅방 초기화에 실패했습니다: $e');
    }
  }

  // 채팅방의 마지막 메시지 시간 업데이트
  Future<void> updateLastActivity(String groupId) async {
    try {
      await _database.child('chats').child(groupId).update({
        'last_updated': ServerValue.timestamp,
      });
    } catch (e) {
      // print('마지막 활동 시간 업데이트 실패: $e');
    }
  }

  // 시스템 메시지 전송 (매칭 성공, 멤버 참가/탈퇴 등)
  Future<void> sendSystemMessage({
    required String groupId,
    required String content,
  }) async {
    try {
      final messageRef = _database.child('chats').child(groupId).push();
      final message = MessageModel(
        id: messageRef.key!,
        senderId: 'system',
        senderNickname: 'System',
        content: content,
        type: MessageType.system,
        createdAt: DateTime.now(),
        groupId: groupId,
        readBy: [],
      );

      await messageRef.set(message.toMap());
    } catch (e) {
      throw Exception('시스템 메시지 전송에 실패했습니다: $e');
    }
  }

  // 채팅방 삭제 (그룹 해체 시)
  Future<void> deleteChatRoom(String groupId) async {
    try {
      await _database.child('chats').child(groupId).remove();
    } catch (e) {
      throw Exception('채팅방 삭제에 실패했습니다: $e');
    }
  }

  // 사용자가 보낸 모든 메시지 삭제 (계정 삭제 시)
  Future<void> deleteUserMessages(String userId) async {
    try {
      // 모든 채팅방을 순회하며 해당 사용자의 메시지 찾기
      final chatsSnapshot = await _database.child('chats').get();
      
      if (!chatsSnapshot.exists) return;
      
      final chatsData = Map<String, dynamic>.from(chatsSnapshot.value as Map);
      
      for (final groupId in chatsData.keys) {
        await deleteUserMessagesFromGroup(groupId, userId);
      }
    } catch (e) {
      throw Exception('사용자 메시지 삭제에 실패했습니다: $e');
    }
  }

  // 특정 그룹에서 사용자가 보낸 메시지 삭제
  Future<void> deleteUserMessagesFromGroup(String groupId, String userId) async {
    try {
      final groupChatRef = _database.child('chats').child(groupId);
      final messagesSnapshot = await groupChatRef.get();
      
      if (!messagesSnapshot.exists) return;
      
      final messagesData = Map<String, dynamic>.from(messagesSnapshot.value as Map);
      
      for (final entry in messagesData.entries) {
        final messageKey = entry.key;
        final messageValue = entry.value;
        
        // 메타데이터(created_at, last_updated) 건너뛰기
        if (messageKey == 'created_at' || messageKey == 'last_updated') continue;
        
        if (messageValue is Map) {
          final messageData = Map<String, dynamic>.from(messageValue as Map);
          
          // 해당 사용자가 보낸 메시지이고 시스템 메시지가 아닌 경우 삭제
          if (messageData['senderId'] == userId && 
              messageData['type'] != 'system') {
            await groupChatRef.child(messageKey).remove();
          }
        }
      }
    } catch (e) {
      throw Exception('그룹 메시지 삭제에 실패했습니다: $e');
    }
  }

  // 온라인 사용자 상태 관리
  Future<void> setUserOnline(String groupId, String userId) async {
    try {
      await _database.child('presence').child(groupId).child(userId).set({
        'online': true,
        'last_seen': ServerValue.timestamp,
      });

      // 연결이 끊어지면 자동으로 오프라인 상태로 변경
      await _database
          .child('presence')
          .child(groupId)
          .child(userId)
          .onDisconnect()
          .update({'online': false, 'last_seen': ServerValue.timestamp});
    } catch (e) {
      // print('온라인 상태 설정 실패: $e');
    }
  }

  // 오프라인 상태로 변경
  Future<void> setUserOffline(String groupId, String userId) async {
    try {
      await _database.child('presence').child(groupId).child(userId).update({
        'online': false,
        'last_seen': ServerValue.timestamp,
      });
    } catch (e) {
      // print('오프라인 상태 설정 실패: $e');
    }
  }

  // 온라인 사용자 목록 스트림
  Stream<Map<String, bool>> getOnlineUsersStream(String groupId) {
    return _database.child('presence').child(groupId).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) return <String, bool>{};

      final presenceMap = Map<String, dynamic>.from(data as Map);
      final onlineUsers = <String, bool>{};

      presenceMap.forEach((userId, userData) {
        if (userData is Map) {
          final userMap = Map<String, dynamic>.from(userData);
          onlineUsers[userId] = userMap['online'] ?? false;
        }
      });

      return onlineUsers;
    });
  }
}

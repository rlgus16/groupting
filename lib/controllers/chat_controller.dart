import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/chatroom_service.dart';
import '../models/chatroom_model.dart';

class ChatController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();
  final ChatroomService _chatroomService = ChatroomService();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  List<ChatMessage> _messages = [];
  List<UserModel> _matchedGroupMembers = [];
  final TextEditingController _messageController = TextEditingController();
  bool _disposed = false;
  
  // 성능 최적화: 메시지 캐싱
  final Map<String, List<ChatMessage>> _messageCache = {};

  // Subscriptions
  StreamSubscription<ChatroomModel?>? _chatroomSubscription;
  StreamSubscription<GroupModel?>? _groupSubscription;
  String? _currentGroupId;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChatMessage> get messages => _messages;
  List<UserModel> get matchedGroupMembers => _matchedGroupMembers;
  TextEditingController get messageController => _messageController;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // 실시간 메시지 스트림 시작
  void startMessageStream(String groupId) {
    _setLoading(true);
    _currentGroupId = groupId;

    _startMessageStreamAsync(groupId);
  }

  // 비동기 메시지 스트림 시작 - 성능 최적화 버전
  Future<void> _startMessageStreamAsync(String groupId) async {
    try {
      debugPrint('채팅방 스트림 시작: $groupId');
      
      // 기존 구독 해제
      _chatroomSubscription?.cancel();
      _groupSubscription?.cancel();

      // 그룹 상태 실시간 감지 시작
      _startGroupStatusListener(groupId);

      // 그룹 멤버 로드 (매칭 전/후 구분)
      await _loadGroupMembers();

      // 실제 채팅방 ID 결정 (매칭된 경우 복합 ID 사용)
      final chatRoomId = await _getChatRoomId(groupId);
      
      // 현재 그룹 ID를 채팅방 ID로 업데이트
      _currentGroupId = chatRoomId;

      debugPrint('채팅방 ID 결정: $chatRoomId');

      // 1. 먼저 기존 채팅방 데이터 즉시 로드 (캐시된 데이터) - 제한된 개수
      try {
        final existingChatroom = await _chatroomService.getChatroomStream(chatRoomId).first;
        if (!_disposed && existingChatroom != null) {
          // 최근 30개 메시지만 로드 (성능 최적화)
          final recentMessages = existingChatroom.messages.length > 30 
              ? existingChatroom.messages.sublist(existingChatroom.messages.length - 30)
              : existingChatroom.messages;
          _messages = recentMessages;
          _setLoading(false);
          debugPrint('기존 메시지 즉시 로드: ${_messages.length}개 (최근 30개)');
        }
      } catch (initialLoadError) {
        debugPrint('초기 메시지 로드 실패 (스트림으로 재시도): $initialLoadError');
      }

      // 2. 실시간 스트림 구독 (새로운 메시지 업데이트) - 성능 최적화
      _startChatroomStream(chatRoomId);

      debugPrint('채팅방 스트림 구독 완료');
    } catch (e) {
      debugPrint('채팅방 스트림 시작 실패: $e');
      _setError('채팅방 스트림 시작에 실패했습니다: $e');
      _setLoading(false);
    }
  }

  // 채팅방 스트림 시작 (분리된 메서드)
  void _startChatroomStream(String chatRoomId) {
    debugPrint('채팅방 스트림 시작: $chatRoomId');
    
    _chatroomSubscription = _chatroomService
        .getChatroomStream(chatRoomId)
        .listen(
          (chatroom) {
            if (!_disposed) {
              if (chatroom != null) {
                final newMessageCount = chatroom.messages.length;
                final oldMessageCount = _messages.length;
                
                // 성능 최적화: 최근 50개 메시지만 유지
                final recentMessages = chatroom.messages.length > 50 
                    ? chatroom.messages.sublist(chatroom.messages.length - 50)
                    : chatroom.messages;
                _messages = recentMessages;
                
                if (newMessageCount > oldMessageCount) {
                  debugPrint('새 메시지 수신: ${newMessageCount - oldMessageCount}개');
                }
                
                debugPrint('총 메시지: ${_messages.length}개 (최근 50개 제한)');
              } else {
                _messages = [];
                debugPrint('빈 채팅방');
              }
              _setLoading(false);
              notifyListeners(); // 즉시 UI 업데이트
            }
          },
          onError: (error) {
            if (!_disposed) {
              debugPrint('채팅방 스트림 에러: $error');
              _setError('채팅방 로드에 실패했습니다: $error');
              _setLoading(false);
            }
          },
        );
  }

  // 실시간 메시지 전송
  Future<bool> sendMessage() async {
    final content = _messageController.text.trim();

    if (content.isEmpty) {
      return false;
    }

    if (_currentGroupId == null) {
      return false;
    }

    try {
      _setError(null);

      // 채팅방 서비스를 사용한 메시지 전송
      await _chatroomService.sendMessage(
        chatRoomId: _currentGroupId!,
        content: content,
      );

      _messageController.clear();

      return true;
    } catch (e) {
      _setError('메시지 전송에 실패했습니다: $e');
      return false;
    }
  }

  // 내 메시지인지 확인
  bool isMyMessage(ChatMessage message) {
    final currentUserId = _firebaseService.currentUserId;
    return currentUserId != null && message.senderId == currentUserId;
  }



  // 정리
  void clearData({bool fromDispose = false}) {
    try {
      _messages.clear();
      _matchedGroupMembers.clear();
      // _onlineUsers.clear(); // Deprecated: 온라인 상태 관리 비활성화
      _messageController.clear();

      // 구독 해제
      _chatroomSubscription?.cancel();
      _chatroomSubscription = null;
      _groupSubscription?.cancel();
      _groupSubscription = null;

      _currentGroupId = null;
      
      // dispose 중이 아닐 때만 UI 업데이트
      if (!_disposed && !fromDispose) {
        // 위젯 트리가 안정된 후 UI 업데이트
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_disposed) {
            notifyListeners();
          }
        });
      }
    } catch (e) {
      debugPrint('ChatController clearData 중 에러: $e');
    }
  }

  // 에러 클리어
  void clearError() {
    _setError(null);
  }

  // 그룹 나가기/앱 종료 시 호출
  void stopMessageStream() {
    try {
      _chatroomSubscription?.cancel();
      _chatroomSubscription = null;
      _groupSubscription?.cancel();
      _groupSubscription = null;

      // Firestore에서는 온라인 상태 관리를 별도로 처리하지 않음
      // (필요 시 별도 구현)
      if (_currentGroupId != null) {
        final currentUserId = _firebaseService.currentUserId;
        if (currentUserId != null) {
          // _realtimeChatService.setUserOffline(_currentGroupId!, currentUserId); // Deprecated: Firestore로 전환됨
        }
      }
    } catch (e) {
      // ChatController stopMessageStream 중 에러
    }
  }

  // 그룹 상태 실시간 감지 - 매칭 상태 변경 감지 개선
  void _startGroupStatusListener(String groupId) {
    try {
      _groupSubscription = _groupService.getGroupStream(groupId).listen(
        (group) async {
          if (!_disposed && group != null) {
            
            // 매칭 상태 변경 감지 - 채팅방 ID 재계산 및 스트림 재시작
            final newChatRoomId = await _getChatRoomId(groupId);
            
            if (_currentGroupId != newChatRoomId) {
              debugPrint('채팅방 ID 변경 감지: ${_currentGroupId} -> ${newChatRoomId}');
              
              // 기존 채팅방 스트림 중단
              _chatroomSubscription?.cancel();
              _currentGroupId = newChatRoomId;
              
              // 새로운 채팅방 스트림 시작
              _startChatroomStream(newChatRoomId);
            }
            
            // 그룹 멤버 변경 감지 시 멤버 목록 다시 로드
            await _loadGroupMembers();
          } else if (!_disposed && group == null) {
            // 그룹이 삭제된 경우 채팅 종료
            clearData();
          }
        },
        onError: (error) {
          debugPrint('ChatController: 그룹 상태 감지 오류 - $error');
        },
      );
    } catch (e) {
      debugPrint('ChatController: 그룹 상태 리스너 시작 실패 - $e');
    }
  }

  // 채팅방 ID 결정 (매칭된 경우 복합 ID 사용)
  Future<String> _getChatRoomId(String groupId) async {
    try {
      
      final currentUserId = _firebaseService.currentUserId;
      if (currentUserId == null) {
        return groupId;
      }

      // 현재 사용자의 그룹 찾기
      final currentGroup = await _groupService.getUserCurrentGroup(currentUserId);
      if (currentGroup == null) {
        return groupId;
      }

      // 매칭된 경우: 두 그룹 ID를 결합한 채팅방 ID 사용
      if (currentGroup.status == GroupStatus.matched && currentGroup.matchedGroupId != null) {
        final groupId1 = currentGroup.id;
        final groupId2 = currentGroup.matchedGroupId!;
        
        // 알파벳순으로 정렬하여 일관된 채팅방 ID 생성
        final chatRoomId = groupId1.compareTo(groupId2) < 0 
            ? '${groupId1}_${groupId2}'
            : '${groupId2}_${groupId1}';
        return chatRoomId;
      }
      
      // 매칭되지 않은 경우: 원래 그룹 ID 사용
      return groupId;
    } catch (e) {
      // 에러 발생 시 원래 그룹 ID 사용
      return groupId;
    }
  }

  // 그룹 멤버 로드 (매칭 전/후 구분)
  Future<void> _loadGroupMembers() async {
    try {
      final currentUserId = _firebaseService.currentUserId;
      if (currentUserId == null) return;

      // 현재 사용자의 그룹 찾기
      final currentGroup = await _groupService.getUserCurrentGroup(
        currentUserId,
      );
      if (currentGroup == null) return;

      // 매칭 상태에 따라 다른 멤버 로드
      if (currentGroup.status == GroupStatus.matched) {
        // 매칭된 경우: 모든 그룹 멤버 로드 (자신 그룹 + 상대방 그룹)
        final allMembers = await _groupService.getGroupMembers(currentGroup.id);
        _matchedGroupMembers = allMembers;
        debugPrint('매칭된 그룹 멤버 로드: ${_matchedGroupMembers.length}명');
        for (final member in _matchedGroupMembers) {
          debugPrint('  - ${member.nickname} (${member.uid})');
        }
      } else {
        // 매칭 전: 현재 그룹 멤버만 로드
        final groupMembers = await Future.wait(
          currentGroup.memberIds.map((id) => _userService.getUserById(id)),
        );
        _matchedGroupMembers = groupMembers.whereType<UserModel>().toList();
        debugPrint('현재 그룹 멤버 로드: ${_matchedGroupMembers.length}명');
      }
      // 즉시 UI 업데이트
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      // ChatController: 그룹 멤버 로드 실패
    }
  }

  // 로그아웃 시 모든 스트림 정리 + 캐시 청소
  void onSignOut() {
    stopMessageStream();
    _messages.clear();
    _matchedGroupMembers.clear();
    _messageCache.clear(); // 캐시 청소
    // _onlineUsers.clear(); // Deprecated: 온라인 상태 관리 비활성화
    _currentGroupId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopMessageStream();
    _messageController.dispose();
    _messageCache.clear(); // 메모리 누수 방지
    super.dispose();
  }
}

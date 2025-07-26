import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'user_service.dart';

class GroupService {
  static final GroupService _instance = GroupService._internal();
  factory GroupService() => _instance;
  GroupService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final UserService _userService = UserService();

  // 그룹 컬렉션 참조
  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firebaseService.getCollection('groups');

  // 현재 사용자의 그룹 정보 스트림
  Stream<GroupModel?> getCurrentUserGroupStream() {
    final userId = _firebaseService.currentUserId;
    if (userId == null) return Stream.value(null);

    return _groupsCollection
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return GroupModel.fromFirestore(snapshot.docs.first);
        });
  }

  // 그룹 ID로 그룹 정보 가져오기
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final doc = await _groupsCollection.doc(groupId).get();
      if (!doc.exists) return null;
      return GroupModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('그룹 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 그룹 실시간 스트림
  Stream<GroupModel?> getGroupStream(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (doc.exists) {
        return GroupModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // 새 그룹 생성
  Future<GroupModel> createGroup(String ownerId) async {
    try {
      final now = DateTime.now();
      final docRef = _groupsCollection.doc();

      final group = GroupModel(
        id: docRef.id,
        name: '새 그룹',
        ownerId: ownerId,
        memberIds: [ownerId],
        description: '',
        status: GroupStatus.active,
        createdAt: now,
        updatedAt: now,
        maxMembers: 5,
      );

      await docRef.set(group.toFirestore());

      // 사용자의 현재 그룹 ID 업데이트
      await _userService.updateCurrentGroupId(ownerId, docRef.id);

      return group;
    } catch (e) {
      throw Exception('그룹 생성에 실패했습니다: $e');
    }
  }

  // 그룹에 멤버 추가
  Future<void> addMemberToGroup(String groupId, String userId) async {
    try {
      await _firebaseService.runTransaction((transaction) async {
        final groupDoc = await transaction.get(_groupsCollection.doc(groupId));
        if (!groupDoc.exists) {
          throw Exception('그룹을 찾을 수 없습니다.');
        }

        final group = GroupModel.fromFirestore(groupDoc);

        // 이미 멤버인지 확인
        if (group.memberIds.contains(userId)) {
          throw Exception('이미 그룹의 멤버입니다.');
        }

        // 최대 인원 확인 (5명)
        if (group.memberIds.length >= 5) {
          throw Exception('그룹 인원이 가득 찼습니다.');
        }

        // 멤버 추가
        final updatedMemberIds = [...group.memberIds, userId];
        transaction.update(_groupsCollection.doc(groupId), {
          'memberIds': updatedMemberIds,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // 사용자의 현재 그룹 ID 업데이트
        transaction.update(_userService.usersCollection.doc(userId), {
          'currentGroupId': groupId,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      throw Exception('멤버 추가에 실패했습니다: $e');
    }
  }

  // 그룹에서 멤버 제거
  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    try {
      await _firebaseService.runTransaction((transaction) async {
        final groupDoc = await transaction.get(_groupsCollection.doc(groupId));
        if (!groupDoc.exists) {
          throw Exception('그룹을 찾을 수 없습니다.');
        }

        final group = GroupModel.fromFirestore(groupDoc);

        // 멤버가 아닌 경우
        if (!group.memberIds.contains(userId)) {
          throw Exception('그룹의 멤버가 아닙니다.');
        }

        // 멤버 제거
        final updatedMemberIds = group.memberIds
            .where((id) => id != userId)
            .toList();

        if (updatedMemberIds.isEmpty) {
          // 마지막 멤버가 나간 경우 그룹 삭제
          transaction.delete(_groupsCollection.doc(groupId));
        } else {
          // 방장이 나간 경우 새로운 방장 선정
          String newOwnerId = group.ownerId;
          if (group.ownerId == userId) {
            newOwnerId = updatedMemberIds.first;
          }

          transaction.update(_groupsCollection.doc(groupId), {
            'memberIds': updatedMemberIds,
            'ownerId': newOwnerId,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }

        // 사용자의 현재 그룹 ID 제거
        transaction.update(_userService.usersCollection.doc(userId), {
          'currentGroupId': null,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      throw Exception('멤버 제거에 실패했습니다: $e');
    }
  }

  // 매칭 시작
  Future<void> startMatching(String groupId) async {
    try {
      print('매칭 시작: $groupId');

      // 1. 그룹 상태를 매칭 중으로 변경
      await _groupsCollection.doc(groupId).update({
        'status': GroupStatus.matching.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('그룹 상태를 매칭 중으로 변경 완료');

      // 2. 매칭 가능한 그룹 찾기
      await _findAndMatchGroups(groupId);
    } catch (e) {
      print('매칭 시작 실패: $e');
      throw Exception('매칭 시작에 실패했습니다: $e');
    }
  }

  // 매칭 가능한 그룹을 찾아서 매칭 처리
  Future<void> _findAndMatchGroups(String groupId) async {
    try {
      // 현재 그룹 정보 가져오기
      final currentGroup = await getGroupById(groupId);
      if (currentGroup == null) {
        print('현재 그룹을 찾을 수 없음: $groupId');
        return;
      }

      print('현재 그룹 정보: 멤버수=${currentGroup.memberCount}');

      // 현재 그룹의 멤버들 정보 가져오기
      final currentMembers = await getGroupMembers(groupId);
      if (currentMembers.isEmpty) {
        print('현재 그룹 멤버가 없음');
        return;
      }

      // 대표 활동지역 (첫 번째 멤버의 활동지역 사용)
      final activityArea = currentMembers.first.activityArea;
      print('활동지역: $activityArea');

      // 매칭 가능한 그룹들 찾기
      final matchableGroups = await findMatchableGroups(
        currentGroup.memberCount,
        activityArea,
        groupId,
      );

      print('매칭 가능한 그룹 수: ${matchableGroups.length}');

      if (matchableGroups.isNotEmpty) {
        // 첫 번째 매칭 가능한 그룹과 매칭
        final targetGroup = matchableGroups.first;
        print('매칭 대상 그룹: ${targetGroup.id}');

        await completeMatching(groupId, targetGroup.id);
        print('매칭 완료: $groupId ↔ ${targetGroup.id}');
      } else {
        print('매칭 가능한 그룹이 없음. 대기 상태 유지');
      }
    } catch (e) {
      print('매칭 처리 실패: $e');
    }
  }

  // 매칭 취소
  Future<void> cancelMatching(String groupId) async {
    try {
      await _groupsCollection.doc(groupId).update({
        'status': GroupStatus.waiting.toString().split('.').last,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('매칭 취소에 실패했습니다: $e');
    }
  }

  // 매칭 완료
  Future<void> completeMatching(String groupId1, String groupId2) async {
    try {
      await _firebaseService.runTransaction((transaction) async {
        final now = DateTime.now();

        // 두 그룹 모두 매칭 완료로 업데이트
        transaction.update(_groupsCollection.doc(groupId1), {
          'status': GroupStatus.matched.toString().split('.').last,
          'matchedGroupId': groupId2,
          'updatedAt': Timestamp.fromDate(now),
        });

        transaction.update(_groupsCollection.doc(groupId2), {
          'status': GroupStatus.matched.toString().split('.').last,
          'matchedGroupId': groupId1,
          'updatedAt': Timestamp.fromDate(now),
        });
      });
    } catch (e) {
      throw Exception('매칭 완료 처리에 실패했습니다: $e');
    }
  }

  // 매칭 가능한 그룹 찾기
  Future<List<GroupModel>> findMatchableGroups(
    int memberCount,
    String activityArea,
    String excludeGroupId, // 자기 그룹 제외
  ) async {
    try {
      print('매칭 가능한 그룹 찾기 시작');
      print(
        '찾는 조건 - 멤버수: $memberCount, 활동지역: $activityArea, 제외그룹: $excludeGroupId',
      );

      final query = await _groupsCollection
          .where(
            'status',
            isEqualTo: GroupStatus.matching.toString().split('.').last,
          )
          .get();

      print('매칭 중인 그룹 총 ${query.docs.length}개 발견');

      final groups = query.docs
          .map((doc) => GroupModel.fromFirestore(doc))
          .where((group) => group.id != excludeGroupId) // 자기 그룹 제외
          .toList();

      print('자기 그룹 제외 후: ${groups.length}개');

      for (int i = 0; i < groups.length; i++) {
        final g = groups[i];
        print('그룹 $i: ID=${g.id}, 멤버수=${g.memberCount}, 상태=${g.status}');
      }

      // 같은 인원 수이고 매칭 조건을 만족하는 그룹들 필터링
      final matchableGroups = <GroupModel>[];

      for (final group in groups) {
        print('그룹 ${group.id} 검사 중...');
        print(
          '- 멤버수 비교: ${group.memberCount} == $memberCount ? ${group.memberCount == memberCount}',
        );

        if (group.memberCount == memberCount) {
          // 그룹 멤버들 정보 가져오기
          print('- 멤버 정보 가져오는 중: ${group.memberIds}');
          final members = await Future.wait(
            group.memberIds.map((id) => _userService.getUserById(id)),
          );

          final validMembers = members.whereType<UserModel>().toList();
          print('- 유효한 멤버 수: ${validMembers.length}');

          if (validMembers.isEmpty) {
            print('- 건너뜀: 유효한 멤버 없음');
            continue;
          }

          // 활동지역 매칭 확인
          print('- 멤버들의 활동지역:');
          for (final member in validMembers) {
            print('  * ${member.nickname}: ${member.activityArea}');
          }

          final hasMatchingArea = validMembers.any(
            (member) => member.activityArea == activityArea,
          );

          print('- 활동지역 매칭: $hasMatchingArea');

          if (hasMatchingArea) {
            print('- 매칭 가능한 그룹으로 추가!');
            matchableGroups.add(group);
          } else {
            print('- 건너뜀: 활동지역 불일치');
          }
        } else {
          print('- 건너뜀: 멤버수 불일치');
        }
      }

      print('최종 매칭 가능한 그룹 수: ${matchableGroups.length}');
      return matchableGroups;
    } catch (e) {
      throw Exception('매칭 가능한 그룹을 찾는데 실패했습니다: $e');
    }
  }

  // 성별 기반 매칭 조건 확인 (미래 확장용)
  bool _isGenderCompatible(
    List<UserModel> group1Members,
    List<UserModel> group2Members,
  ) {
    // 현재는 모든 그룹 매칭 허용
    // 추후 성별 기반 매칭 로직 추가 가능
    // 예: 남성 그룹 ↔ 여성 그룹, 혼성 그룹 ↔ 혼성 그룹
    return true;
  }

  // 그룹 멤버 정보 가져오기 (매칭된 그룹 멤버 포함)
  Future<List<UserModel>> getGroupMembers(String groupId) async {
    try {
      final group = await getGroupById(groupId);
      if (group == null) return [];

      List<String> allMemberIds = List.from(group.memberIds);

      // 매칭된 그룹이 있으면 매칭된 그룹의 멤버들도 포함
      if (group.status == GroupStatus.matched && group.matchedGroupId != null) {
        print('매칭된 그룹 멤버도 포함: ${group.matchedGroupId}');
        final matchedGroup = await getGroupById(group.matchedGroupId!);
        if (matchedGroup != null) {
          allMemberIds.addAll(matchedGroup.memberIds);
          print('전체 멤버 ID: $allMemberIds');
        }
      }

      final members = await Future.wait(
        allMemberIds.map((id) => _userService.getUserById(id)),
      );

      final validMembers = members.whereType<UserModel>().toList();
      print('로드된 멤버 수: ${validMembers.length}');

      return validMembers;
    } catch (e) {
      throw Exception('그룹 멤버 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 사용자의 현재 그룹 가져오기
  Future<GroupModel?> getUserCurrentGroup(String userId) async {
    try {
      final user = await _userService.getUserById(userId);
      if (user?.currentGroupId == null) return null;

      return await getGroupById(user!.currentGroupId!);
    } catch (e) {
      throw Exception('현재 그룹 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 그룹 나가기
  Future<bool> leaveGroup(String groupId, String userId) async {
    try {
      print('GroupService.leaveGroup 시작: groupId=$groupId, userId=$userId');

      final group = await getGroupById(groupId);
      if (group == null) {
        print('그룹을 찾을 수 없음: $groupId');
        return false;
      }

      print('현재 그룹 멤버들: ${group.memberIds}');

      final updatedMemberIds = group.memberIds
          .where((id) => id != userId)
          .toList();

      print('업데이트된 멤버들: $updatedMemberIds');

      if (updatedMemberIds.isEmpty) {
        // 마지막 멤버인 경우 그룹 삭제
        print('마지막 멤버이므로 그룹 삭제');
        await _groupsCollection.doc(groupId).delete();
      } else {
        // 멤버 목록에서 제거
        print('멤버 목록에서 사용자 제거');
        await _groupsCollection.doc(groupId).update({
          'memberIds': updatedMemberIds,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // 사용자의 현재 그룹 ID 제거
      print('사용자의 currentGroupId 제거');
      await _userService.updateCurrentGroupId(userId, null);

      print('그룹 나가기 성공');
      return true;
    } catch (e) {
      print('그룹 나가기 실패: $e');
      throw Exception('그룹 나가기에 실패했습니다: $e');
    }
  }
}

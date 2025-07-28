import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupStatus { active, matched, inactive, waiting, matching }

class GroupModel {
  final String id;
  final String name;
  final String ownerId;
  final List<String> memberIds;
  final String? description;
  final GroupStatus status;
  final String? matchedGroupId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int maxMembers;

  GroupModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
    this.description,
    required this.status,
    this.matchedGroupId,
    required this.createdAt,
    required this.updatedAt,
    this.maxMembers = 5,
  });

  // Firestore에서 데이터를 가져올 때 사용
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      description: data['description'],
      status: GroupStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => GroupStatus.active,
      ),
      matchedGroupId: data['matchedGroupId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      maxMembers: data['maxMembers'] ?? 5,
    );
  }

  // Firestore에 저장할 때 사용
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'description': description,
      'status': status.toString().split('.').last,
      'matchedGroupId': matchedGroupId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'maxMembers': maxMembers,
    };
  }

  // 복사본 생성
  GroupModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<String>? memberIds,
    String? description,
    GroupStatus? status,
    String? matchedGroupId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? maxMembers,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      description: description ?? this.description,
      status: status ?? this.status,
      matchedGroupId: matchedGroupId ?? this.matchedGroupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }

  // 헬퍼 메서드들
  String get groupId => id; // id와 동일
  int get memberCount => memberIds.length;
  bool get isFull => memberIds.length >= maxMembers;
  bool get canMatch => memberIds.length >= 1 && status == GroupStatus.active; // 1명부터 매칭 가능
  bool isOwner(String userId) => ownerId == userId;
  bool isMember(String userId) => memberIds.contains(userId);
}

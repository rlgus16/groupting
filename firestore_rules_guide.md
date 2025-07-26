# Firebase Firestore Security Rules 설정 가이드

## 📋 개요
이 문서는 Groupting 앱을 위한 Firebase Firestore Security Rules 설정 방법과 주요 권한 정책을 설명서 내용입니다.

## 🚀 설정 방법

### 1. Firebase Console에서 설정
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택
3. **Firestore Database** → **규칙** 탭 클릭
4. `firestore_security_rules.txt` 파일의 내용을 복사하여 붙여넣기
5. **게시** 버튼 클릭

### 2. Firebase CLI로 설정 (선택사항)
```bash
# firestore.rules 파일에 규칙 저장 후
firebase deploy --only firestore:rules
```

## 🔐 권한 정책 상세

### Users 컬렉션 (`/users/{userId}`)
- **생성**: 인증된 사용자가 자신의 UID로만 문서 생성 가능
- **읽기**: 모든 인증된 사용자 읽기 가능 (그룹 멤버 조회용)
- **수정**: 본인만 자신의 정보 수정 가능
- **삭제**: 본인만 자신의 계정 삭제 가능

### Groups 컬렉션 (`/groups/{groupId}`)
- **생성**: 모든 인증된 사용자 그룹 생성 가능
- **읽기**: 
  - 그룹 멤버들 읽기 가능
  - 매칭을 위해 `status: 'matching'`인 그룹들 읽기 가능
- **수정**: 그룹 멤버만 수정 가능
- **삭제**: 그룹 오너만 삭제 가능

### Messages 컬렉션 (`/messages/{messageId}`)
- **생성**: 
  - 인증된 사용자가 자신의 메시지만 생성 가능
  - 해당 그룹의 멤버여야 함
- **읽기**: 해당 그룹의 멤버만 읽기 가능
- **수정**: 메시지 작성자만 수정 가능
- **삭제**: 메시지 작성자만 삭제 가능 (시스템 메시지 제외)

### Invitations 컬렉션 (`/invitations/{invitationId}`)
- **생성**: 인증된 사용자가 자신이 보내는 초대만 생성 가능
- **읽기**: 초대 보낸 사람과 받는 사람만 읽기 가능
- **수정**: 초대 받은 사람만 상태 업데이트 가능
- **삭제**: 초대 보낸 사람만 삭제 가능

## 🛠 헬퍼 함수들

### `isGroupMember(groupId, userId)`
사용자가 특정 그룹의 멤버인지 확인합니다.
```javascript
function isGroupMember(groupId, userId) {
  return exists(/databases/$(database)/documents/groups/$(groupId)) &&
    userId in get(/databases/$(database)/documents/groups/$(groupId)).data.memberIds;
}
```

### `isGroupOwner(groupId, userId)`
사용자가 특정 그룹의 오너인지 확인합니다.

### `isMatchedGroupMember(groupId, userId)`
매칭된 그룹을 포함하여 사용자가 해당 그룹 시스템의 멤버인지 확인합니다 (확장용).

## ⚠️ 주의사항

### 1. 성능 고려사항
- `get()` 함수 사용 시 추가 읽기 비용 발생
- 복잡한 권한 검사는 클라이언트 성능에 영향을 줄 수 있음

### 2. 보안 고려사항
- 모든 사용자가 다른 사용자의 프로필을 읽을 수 있음 (그룹 기능을 위해 필요)
- 매칭을 위해 `matching` 상태의 그룹은 다른 사용자가 읽을 수 있음

### 3. 제한사항
- Firestore Rules에서는 배열 쿼리에 제한이 있을 수 있음
- 복잡한 비즈니스 로직은 클라이언트 또는 Cloud Functions에서 처리 필요

## 🧪 테스트 방법

### Firebase Console 시뮬레이터
1. Firestore Database → 규칙 탭
2. **시뮬레이터** 클릭
3. 다양한 시나리오로 권한 테스트

### 테스트 시나리오 예시
```javascript
// 사용자 프로필 읽기 테스트
auth: { uid: 'user123' }
path: /databases/(default)/documents/users/user456
operation: read
// 결과: 허용 (인증된 사용자는 모든 프로필 읽기 가능)

// 그룹 메시지 읽기 테스트  
auth: { uid: 'user123' }
path: /databases/(default)/documents/messages/msg123
operation: read
// 결과: 그룹 멤버인 경우에만 허용
```

## 🔄 업데이트 시 주의사항

1. **규칙 변경 전 백업**: 기존 규칙을 별도로 저장
2. **단계적 배포**: 테스트 환경에서 충분히 검증 후 프로덕션 배포
3. **모니터링**: 배포 후 에러 로그 및 성능 지표 확인
4. **롤백 준비**: 문제 발생 시 즉시 이전 규칙으로 롤백할 수 있도록 준비

## 📞 문제 해결

### 권한 오류 발생 시
1. Firebase Console의 **사용량** 탭에서 오류 확인
2. 클라이언트 코드에서 권한 관련 에러 로그 확인
3. 시뮬레이터를 통해 특정 시나리오 재현 및 테스트

### 성능 이슈 발생 시
1. `get()` 함수 사용 빈도 확인
2. 권한 검사 로직 최적화 검토
3. 클라이언트에서 불필요한 권한 검사 줄이기 
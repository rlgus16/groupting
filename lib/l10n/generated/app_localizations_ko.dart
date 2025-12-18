// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => '그룹팅';

  @override
  String get confirm => '확인';

  @override
  String get cancel => '취소';

  @override
  String get close => '닫기';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get later => '나중에';

  @override
  String get loading => '로딩 중...';

  @override
  String get error => '오류';

  @override
  String get retry => '다시 시도';

  @override
  String get settings => '설정';

  @override
  String get male => '남성';

  @override
  String get female => '여성';

  @override
  String get gender => '성별';

  @override
  String get view => '보기';

  @override
  String get loginButton => '로그인';

  @override
  String get registerButton => '회원가입';

  @override
  String get emailLabel => '이메일';

  @override
  String get emailHint => 'example@email.com';

  @override
  String get emailHelper => '로그인 및 비밀번호 찾기에 사용할 이메일';

  @override
  String get passwordLabel => '비밀번호';

  @override
  String get passwordHint => '8자 이상';

  @override
  String get passwordConfirmLabel => '비밀번호 확인';

  @override
  String get phoneLabel => '전화번호';

  @override
  String get birthDateLabel => '생년월일';

  @override
  String get birthDateHelper => '8자리 숫자 (예: 19950315)';

  @override
  String get registerWelcome => '그룹팅에 오신 것을 환영합니다!\n이메일로 간편하게 가입해보세요.';

  @override
  String get lockedInfo => '자물쇠 표시된 정보는 가입 후 변경할 수 없습니다';

  @override
  String get emailDuplicate => '이미 사용 중인 이메일입니다.';

  @override
  String get emailAvailable => '사용 가능한 이메일입니다.';

  @override
  String get emailCheckError => '이메일 확인 중 오류가 발생했습니다.';

  @override
  String get emailDuplicateError => '이미 사용 중인 이메일입니다. 다른 이메일을 사용해주세요.';

  @override
  String get phoneDuplicate => '이미 사용 중인 전화번호입니다.';

  @override
  String get phoneAvailable => '사용 가능한 전화번호입니다.';

  @override
  String get phoneCheckError => '전화번호 확인 중 오류가 발생했습니다.';

  @override
  String get phoneDuplicateError => '이미 사용 중인 전화번호입니다. 다른 번호를 사용해주세요.';

  @override
  String get verifyButton => '인증';

  @override
  String get verified => '인증됨';

  @override
  String get verifyCodeSent => '인증번호가 전송되었습니다.';

  @override
  String get verifyCodeLabel => '인증번호 6자리';

  @override
  String get verifyCodeHint => '000000';

  @override
  String get verifyComplete => '전화번호 인증이 완료되었습니다.';

  @override
  String get verifyPhoneFirst => '전화번호 인증을 완료해주세요.';

  @override
  String get checkPhoneDuplicateFirst => '올바른 전화번호를 입력 후 중복 확인을 완료해주세요.';

  @override
  String get termsAgreement => '[필수] 서비스 이용약관 동의';

  @override
  String get privacyAgreement => '[필수] 개인정보 처리방침 동의';

  @override
  String get termsTitle => '서비스 이용약관 (EULA)';

  @override
  String get privacyTitle => '개인정보 처리방침';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요? 로그인하기';

  @override
  String get registerSuccess => '가입되었습니다! 우선 프로필을 완성해주세요.';

  @override
  String get emailRequired => '이메일을 입력해주세요.';

  @override
  String get emailInvalid => '올바른 이메일 형식을 입력해주세요.';

  @override
  String get passwordRequired => '비밀번호를 입력해주세요.';

  @override
  String get passwordLength => '비밀번호는 8자 이상이어야 합니다.';

  @override
  String get passwordMismatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get passwordReEnter => '비밀번호를 다시 입력해주세요.';

  @override
  String get phoneRequired => '전화번호를 입력해주세요.';

  @override
  String get birthDateRequired => '생년월일을 입력해주세요.';

  @override
  String get birthDateInvalid => '생년월일은 8자리여야 합니다.';

  @override
  String get birthDateYearInvalid => '유효한 연도를 입력해주세요.';

  @override
  String get birthDateDateInvalid => '유효한 날짜를 입력해주세요.';

  @override
  String get underageError => '만 18세 미만은 이용할 수 없습니다.';

  @override
  String get genderRequired => '성별을 선택해주세요.';

  @override
  String get termsRequired => '서비스 이용약관 및 개인정보 처리방침에 동의해주세요.';

  @override
  String get fillAllRequired => '모든 필수 정보를 입력해주세요.';

  @override
  String get tabHome => '홈';

  @override
  String get tabInvite => '초대';

  @override
  String get tabMyPage => '마이페이지';

  @override
  String get tabMore => '더보기';

  @override
  String get profileCardTitleRegister => '회원가입하기';

  @override
  String get profileCardTitleBasic => '기본 정보 입력하기';

  @override
  String get profileCardTitleComplete => '프로필 완성하기';

  @override
  String get profileCardDescRegister => '그룹팅 서비스를 이용하시려면\n먼저 회원가입을 완료해주세요!';

  @override
  String get profileCardDescBasic =>
      '회원가입 중 누락된 필수 정보가 있어요.\n기본 정보를 입력하고 프로필을 완성해주세요!';

  @override
  String get profileCardDescComplete =>
      '닉네임, 키, 소개글, 활동지역을 추가하면\n그룹 생성과 매칭 기능을 사용할 수 있어요!';

  @override
  String get profileCardSubtitleRegister => '그룹팅을 시작해보세요!';

  @override
  String get profileCardSubtitleBasic => '전화번호, 생년월일, 성별 정보가 필요해요!';

  @override
  String get profileCardSubtitleComplete => '닉네임, 키, 활동지역 등을 입력해주세요!';

  @override
  String get profileCardButtonComplete => '지금 완성하기';

  @override
  String get profileCardHideMsg =>
      '프로필 완성하기 알림을 숨겼습니다. 마이페이지에서 언제든 프로필을 완성할 수 있습니다.';

  @override
  String get groupLoading => '그룹 정보 로딩 중...';

  @override
  String get waitPlease => '잠시만 기다려주세요.';

  @override
  String get networkError => '네트워크 연결 오류';

  @override
  String get networkErrorMsg => '인터넷 연결을 확인하고 다시 시도해주세요.';

  @override
  String get networkCheckMsg => 'Wi-Fi나 모바일 데이터 연결을 확인해주세요.';

  @override
  String get checkConnection => '연결 확인';

  @override
  String get dataLoadFail => '데이터 로드 실패';

  @override
  String get unknownError => '알 수 없는 오류가 발생했습니다.';

  @override
  String get noGroup => '그룹이 없습니다';

  @override
  String get createGroup => '그룹 만들기';

  @override
  String get createGroupDesc => '새로운 그룹을 만들어 친구들과 함께하세요!';

  @override
  String get profileCompleteNeeded => '프로필 완성 필요';

  @override
  String get profileCompleteNeededMsg => '프로필을 완성해야 서비스 이용이 가능합니다.';

  @override
  String get matched => '매칭 완료!';

  @override
  String get matching => '매칭 중...';

  @override
  String get groupWaiting => '그룹 대기';

  @override
  String totalMembers(Object count) {
    return '총 멤버: $count명';
  }

  @override
  String get matchChat => '매칭 채팅';

  @override
  String get groupChat => '그룹 채팅';

  @override
  String get currentMembers => '현재 그룹 멤버';

  @override
  String get inviteFriend => '친구 초대';

  @override
  String startMatching(Object count) {
    return '그룹 매칭 시작 ($count명)';
  }

  @override
  String get startMatching1on1 => '1:1 매칭 시작';

  @override
  String get cancelMatching => '매칭 취소';

  @override
  String get minMemberRequired => '최소 1명 필요';

  @override
  String get matchSuccessTitle => '매칭 성공! 🎉';

  @override
  String get matchSuccessContent => '매칭되었습니다!\n채팅방에서 인사해보세요 👋';

  @override
  String get moveToChat => '채팅방으로 이동';

  @override
  String get receivedInvites => '받은 초대';

  @override
  String get leaveGroup => '그룹 나가기';

  @override
  String get leaveGroupConfirm => '정말로 그룹을 나가시겠습니까?';

  @override
  String get leaveGroupSuccess => '그룹에서 나왔습니다.';

  @override
  String get logout => '로그아웃';

  @override
  String get logoutConfirm => '정말로 로그아웃 하시겠습니까?';

  @override
  String logoutError(Object error) {
    return '로그아웃 중 오류가 발생했습니다: $error';
  }

  @override
  String get filterTitle => '매칭 필터 설정';

  @override
  String get targetGender => '상대 그룹 성별';

  @override
  String get genderAny => '상관없음';

  @override
  String get genderMixed => '혼성';

  @override
  String get targetAge => '상대 그룹 평균 나이';

  @override
  String get ageUnit => '세';

  @override
  String get ageOver60 => '60세+';

  @override
  String get targetHeight => '상대 그룹 평균 키';

  @override
  String get heightUnit => 'cm';

  @override
  String get heightOver190 => '190cm+';

  @override
  String get distanceRange => '거리 범위 (방장 기준)';

  @override
  String get distanceUnit => 'km 이내';

  @override
  String get distanceOver100 => '100km+';

  @override
  String get applyFilter => '적용하기';

  @override
  String get filterApplied => '필터가 적용되었습니다.';

  @override
  String get filterApplyFail => '필터 적용 실패';

  @override
  String get editProfileTitle => '프로필 편집';

  @override
  String get photoRegisterInfo => '최대 6장 사진을 등록해주세요.';

  @override
  String get mainPhotoInfo => '이미지를 길게 눌러서 대표 프로필로 설정할 수 있습니다.';

  @override
  String get nicknameLabel => '닉네임';

  @override
  String get nicknamePlaceholder => '닉네임을 입력하세요';

  @override
  String get nicknameDuplicate => '이미 사용 중인 닉네임입니다.';

  @override
  String get nicknameAvailable => '사용 가능한 닉네임입니다.';

  @override
  String get nicknameCheckError => '닉네임 확인 중 오류가 발생했습니다.';

  @override
  String get nicknameRequired => '닉네임을 입력해주세요.';

  @override
  String get nicknameLengthError => '닉네임은 2자 이상이어야 합니다.';

  @override
  String get heightLabel => '키 (cm)';

  @override
  String get heightPlaceholder => '키를 입력하세요';

  @override
  String get heightRequired => '키를 입력해주세요.';

  @override
  String get heightRangeError => '올바른 키를 입력해주세요. (140-220cm)';

  @override
  String get locationLabel => '활동지역';

  @override
  String get locationPlaceholder => '지도를 눌러 위치를 선택하세요';

  @override
  String get locationRequired => '활동지역을 선택해주세요.';

  @override
  String get introLabel => '소개글';

  @override
  String get introHelper => '200자 이내';

  @override
  String get introRequired => '소개글을 입력해주세요.';

  @override
  String get introLengthError => '소개글은 5자 이상 작성해주세요.';

  @override
  String get immutableInfo => '수정 불가능한 정보';

  @override
  String get idLabel => '아이디';

  @override
  String get permissionRequiredTitle => '권한 설정 필요';

  @override
  String get permissionRequiredContent =>
      '프로필 사진을 등록하려면 갤러리 접근 권한이 필요합니다.\n설정에서 권한을 허용해주세요.';

  @override
  String get goToSettings => '설정으로 이동';

  @override
  String get imageSelectError => '이미지 선택 중 오류가 발생했습니다.';

  @override
  String mainProfileSet(Object index) {
    return '$index번 이미지가 대표 프로필로 설정되었습니다.';
  }

  @override
  String get mainLabel => '대표';

  @override
  String get imageUploadFail => '이미지 업로드에 실패했습니다.';

  @override
  String get profileUpdateSuccess => '프로필이 성공적으로 업데이트되었습니다.';

  @override
  String get photoRequired => '사진을 최소 1장 등록해주세요.';

  @override
  String get updateTitle => '업데이트 안내';

  @override
  String get updateButton => '지금 업데이트';

  @override
  String get updateMessageDefault => '업데이트가 필요합니다.';
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_th.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('th'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'그룹팅'**
  String get appTitle;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @later.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get later;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @settings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settings;

  /// No description provided for @male.
  ///
  /// In ko, this message translates to:
  /// **'남성'**
  String get male;

  /// No description provided for @female.
  ///
  /// In ko, this message translates to:
  /// **'여성'**
  String get female;

  /// No description provided for @gender.
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get gender;

  /// No description provided for @view.
  ///
  /// In ko, this message translates to:
  /// **'보기'**
  String get view;

  /// No description provided for @loginButton.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get registerButton;

  /// No description provided for @emailLabel.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In ko, this message translates to:
  /// **'example@email.com'**
  String get emailHint;

  /// No description provided for @emailHelper.
  ///
  /// In ko, this message translates to:
  /// **'로그인 및 비밀번호 찾기에 사용할 이메일'**
  String get emailHelper;

  /// No description provided for @passwordLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In ko, this message translates to:
  /// **'8자 이상'**
  String get passwordHint;

  /// No description provided for @passwordConfirmLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get passwordConfirmLabel;

  /// No description provided for @phoneLabel.
  ///
  /// In ko, this message translates to:
  /// **'전화번호'**
  String get phoneLabel;

  /// No description provided for @birthDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'생년월일'**
  String get birthDateLabel;

  /// No description provided for @birthDateHelper.
  ///
  /// In ko, this message translates to:
  /// **'8자리 숫자 (예: 19950315)'**
  String get birthDateHelper;

  /// No description provided for @registerWelcome.
  ///
  /// In ko, this message translates to:
  /// **'그룹팅에 오신 것을 환영합니다!\n이메일로 간편하게 가입해보세요.'**
  String get registerWelcome;

  /// No description provided for @lockedInfo.
  ///
  /// In ko, this message translates to:
  /// **'자물쇠 표시된 정보는 가입 후 변경할 수 없습니다'**
  String get lockedInfo;

  /// No description provided for @emailDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 이메일입니다.'**
  String get emailDuplicate;

  /// No description provided for @emailAvailable.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 이메일입니다.'**
  String get emailAvailable;

  /// No description provided for @emailCheckError.
  ///
  /// In ko, this message translates to:
  /// **'이메일 확인 중 오류가 발생했습니다.'**
  String get emailCheckError;

  /// No description provided for @emailDuplicateError.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 이메일입니다. 다른 이메일을 사용해주세요.'**
  String get emailDuplicateError;

  /// No description provided for @phoneDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 전화번호입니다.'**
  String get phoneDuplicate;

  /// No description provided for @phoneAvailable.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 전화번호입니다.'**
  String get phoneAvailable;

  /// No description provided for @phoneCheckError.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 확인 중 오류가 발생했습니다.'**
  String get phoneCheckError;

  /// No description provided for @phoneDuplicateError.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 전화번호입니다. 다른 번호를 사용해주세요.'**
  String get phoneDuplicateError;

  /// No description provided for @verifyButton.
  ///
  /// In ko, this message translates to:
  /// **'인증'**
  String get verifyButton;

  /// No description provided for @verified.
  ///
  /// In ko, this message translates to:
  /// **'인증됨'**
  String get verified;

  /// No description provided for @verifyCodeSent.
  ///
  /// In ko, this message translates to:
  /// **'인증번호가 전송되었습니다.'**
  String get verifyCodeSent;

  /// No description provided for @verifyCodeLabel.
  ///
  /// In ko, this message translates to:
  /// **'인증번호 6자리'**
  String get verifyCodeLabel;

  /// No description provided for @verifyCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'000000'**
  String get verifyCodeHint;

  /// No description provided for @verifyComplete.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 인증이 완료되었습니다.'**
  String get verifyComplete;

  /// No description provided for @verifyPhoneFirst.
  ///
  /// In ko, this message translates to:
  /// **'전화번호 인증을 완료해주세요.'**
  String get verifyPhoneFirst;

  /// No description provided for @checkPhoneDuplicateFirst.
  ///
  /// In ko, this message translates to:
  /// **'올바른 전화번호를 입력 후 중복 확인을 완료해주세요.'**
  String get checkPhoneDuplicateFirst;

  /// No description provided for @termsAgreement.
  ///
  /// In ko, this message translates to:
  /// **'[필수] 서비스 이용약관 동의'**
  String get termsAgreement;

  /// No description provided for @privacyAgreement.
  ///
  /// In ko, this message translates to:
  /// **'[필수] 개인정보 처리방침 동의'**
  String get privacyAgreement;

  /// No description provided for @termsTitle.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용약관 (EULA)'**
  String get termsTitle;

  /// No description provided for @privacyTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get privacyTitle;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요? 로그인하기'**
  String get alreadyHaveAccount;

  /// No description provided for @registerSuccess.
  ///
  /// In ko, this message translates to:
  /// **'가입되었습니다! 우선 프로필을 완성해주세요.'**
  String get registerSuccess;

  /// No description provided for @emailRequired.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해주세요.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 형식을 입력해주세요.'**
  String get emailInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해주세요.'**
  String get passwordRequired;

  /// No description provided for @passwordLength.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 8자 이상이어야 합니다.'**
  String get passwordLength;

  /// No description provided for @passwordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다.'**
  String get passwordMismatch;

  /// No description provided for @passwordReEnter.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 다시 입력해주세요.'**
  String get passwordReEnter;

  /// No description provided for @phoneRequired.
  ///
  /// In ko, this message translates to:
  /// **'전화번호를 입력해주세요.'**
  String get phoneRequired;

  /// No description provided for @birthDateRequired.
  ///
  /// In ko, this message translates to:
  /// **'생년월일을 입력해주세요.'**
  String get birthDateRequired;

  /// No description provided for @birthDateInvalid.
  ///
  /// In ko, this message translates to:
  /// **'생년월일은 8자리여야 합니다.'**
  String get birthDateInvalid;

  /// No description provided for @birthDateYearInvalid.
  ///
  /// In ko, this message translates to:
  /// **'유효한 연도를 입력해주세요.'**
  String get birthDateYearInvalid;

  /// No description provided for @birthDateDateInvalid.
  ///
  /// In ko, this message translates to:
  /// **'유효한 날짜를 입력해주세요.'**
  String get birthDateDateInvalid;

  /// No description provided for @underageError.
  ///
  /// In ko, this message translates to:
  /// **'만 18세 미만은 이용할 수 없습니다.'**
  String get underageError;

  /// No description provided for @genderRequired.
  ///
  /// In ko, this message translates to:
  /// **'성별을 선택해주세요.'**
  String get genderRequired;

  /// No description provided for @termsRequired.
  ///
  /// In ko, this message translates to:
  /// **'서비스 이용약관 및 개인정보 처리방침에 동의해주세요.'**
  String get termsRequired;

  /// No description provided for @fillAllRequired.
  ///
  /// In ko, this message translates to:
  /// **'모든 필수 정보를 입력해주세요.'**
  String get fillAllRequired;

  /// No description provided for @tabHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get tabHome;

  /// No description provided for @tabInvite.
  ///
  /// In ko, this message translates to:
  /// **'초대'**
  String get tabInvite;

  /// No description provided for @tabMyPage.
  ///
  /// In ko, this message translates to:
  /// **'마이페이지'**
  String get tabMyPage;

  /// No description provided for @tabMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get tabMore;

  /// No description provided for @profileCardTitleRegister.
  ///
  /// In ko, this message translates to:
  /// **'회원가입하기'**
  String get profileCardTitleRegister;

  /// No description provided for @profileCardTitleBasic.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보 입력하기'**
  String get profileCardTitleBasic;

  /// No description provided for @profileCardTitleComplete.
  ///
  /// In ko, this message translates to:
  /// **'프로필 완성하기'**
  String get profileCardTitleComplete;

  /// No description provided for @profileCardDescRegister.
  ///
  /// In ko, this message translates to:
  /// **'그룹팅 서비스를 이용하시려면\n먼저 회원가입을 완료해주세요!'**
  String get profileCardDescRegister;

  /// No description provided for @profileCardDescBasic.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 중 누락된 필수 정보가 있어요.\n기본 정보를 입력하고 프로필을 완성해주세요!'**
  String get profileCardDescBasic;

  /// No description provided for @profileCardDescComplete.
  ///
  /// In ko, this message translates to:
  /// **'닉네임, 키, 소개글, 활동지역을 추가하면\n그룹 생성과 매칭 기능을 사용할 수 있어요!'**
  String get profileCardDescComplete;

  /// No description provided for @profileCardSubtitleRegister.
  ///
  /// In ko, this message translates to:
  /// **'그룹팅을 시작해보세요!'**
  String get profileCardSubtitleRegister;

  /// No description provided for @profileCardSubtitleBasic.
  ///
  /// In ko, this message translates to:
  /// **'전화번호, 생년월일, 성별 정보가 필요해요!'**
  String get profileCardSubtitleBasic;

  /// No description provided for @profileCardSubtitleComplete.
  ///
  /// In ko, this message translates to:
  /// **'닉네임, 키, 활동지역 등을 입력해주세요!'**
  String get profileCardSubtitleComplete;

  /// No description provided for @profileCardButtonComplete.
  ///
  /// In ko, this message translates to:
  /// **'지금 완성하기'**
  String get profileCardButtonComplete;

  /// No description provided for @profileCardHideMsg.
  ///
  /// In ko, this message translates to:
  /// **'프로필 완성하기 알림을 숨겼습니다. 마이페이지에서 언제든 프로필을 완성할 수 있습니다.'**
  String get profileCardHideMsg;

  /// No description provided for @groupLoading.
  ///
  /// In ko, this message translates to:
  /// **'그룹 정보 로딩 중...'**
  String get groupLoading;

  /// No description provided for @waitPlease.
  ///
  /// In ko, this message translates to:
  /// **'잠시만 기다려주세요.'**
  String get waitPlease;

  /// No description provided for @networkError.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결 오류'**
  String get networkError;

  /// No description provided for @networkErrorMsg.
  ///
  /// In ko, this message translates to:
  /// **'인터넷 연결을 확인하고 다시 시도해주세요.'**
  String get networkErrorMsg;

  /// No description provided for @networkCheckMsg.
  ///
  /// In ko, this message translates to:
  /// **'Wi-Fi나 모바일 데이터 연결을 확인해주세요.'**
  String get networkCheckMsg;

  /// No description provided for @checkConnection.
  ///
  /// In ko, this message translates to:
  /// **'연결 확인'**
  String get checkConnection;

  /// No description provided for @dataLoadFail.
  ///
  /// In ko, this message translates to:
  /// **'데이터 로드 실패'**
  String get dataLoadFail;

  /// No description provided for @unknownError.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 오류가 발생했습니다.'**
  String get unknownError;

  /// No description provided for @noGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹이 없습니다'**
  String get noGroup;

  /// No description provided for @createGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹 만들기'**
  String get createGroup;

  /// No description provided for @createGroupDesc.
  ///
  /// In ko, this message translates to:
  /// **'새로운 그룹을 만들어 친구들과 함께하세요!'**
  String get createGroupDesc;

  /// No description provided for @profileCompleteNeeded.
  ///
  /// In ko, this message translates to:
  /// **'프로필 완성 필요'**
  String get profileCompleteNeeded;

  /// No description provided for @profileCompleteNeededMsg.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 완성해야 서비스 이용이 가능합니다.'**
  String get profileCompleteNeededMsg;

  /// No description provided for @matched.
  ///
  /// In ko, this message translates to:
  /// **'매칭 완료!'**
  String get matched;

  /// No description provided for @matching.
  ///
  /// In ko, this message translates to:
  /// **'매칭 중...'**
  String get matching;

  /// No description provided for @groupWaiting.
  ///
  /// In ko, this message translates to:
  /// **'그룹 대기'**
  String get groupWaiting;

  /// No description provided for @totalMembers.
  ///
  /// In ko, this message translates to:
  /// **'총 멤버: {count}명'**
  String totalMembers(Object count);

  /// No description provided for @matchChat.
  ///
  /// In ko, this message translates to:
  /// **'매칭 채팅'**
  String get matchChat;

  /// No description provided for @groupChat.
  ///
  /// In ko, this message translates to:
  /// **'그룹 채팅'**
  String get groupChat;

  /// No description provided for @currentMembers.
  ///
  /// In ko, this message translates to:
  /// **'현재 그룹 멤버'**
  String get currentMembers;

  /// No description provided for @inviteFriend.
  ///
  /// In ko, this message translates to:
  /// **'친구 초대'**
  String get inviteFriend;

  /// No description provided for @startMatching.
  ///
  /// In ko, this message translates to:
  /// **'그룹 매칭 시작 ({count}명)'**
  String startMatching(Object count);

  /// No description provided for @startMatching1on1.
  ///
  /// In ko, this message translates to:
  /// **'1:1 매칭 시작'**
  String get startMatching1on1;

  /// No description provided for @cancelMatching.
  ///
  /// In ko, this message translates to:
  /// **'매칭 취소'**
  String get cancelMatching;

  /// No description provided for @minMemberRequired.
  ///
  /// In ko, this message translates to:
  /// **'최소 1명 필요'**
  String get minMemberRequired;

  /// No description provided for @matchSuccessTitle.
  ///
  /// In ko, this message translates to:
  /// **'매칭 성공! 🎉'**
  String get matchSuccessTitle;

  /// No description provided for @matchSuccessContent.
  ///
  /// In ko, this message translates to:
  /// **'매칭되었습니다!\n채팅방에서 인사해보세요 👋'**
  String get matchSuccessContent;

  /// No description provided for @moveToChat.
  ///
  /// In ko, this message translates to:
  /// **'채팅방으로 이동'**
  String get moveToChat;

  /// No description provided for @receivedInvites.
  ///
  /// In ko, this message translates to:
  /// **'받은 초대'**
  String get receivedInvites;

  /// No description provided for @leaveGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹 나가기'**
  String get leaveGroup;

  /// No description provided for @leaveGroupConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말로 그룹을 나가시겠습니까?'**
  String get leaveGroupConfirm;

  /// No description provided for @leaveGroupSuccess.
  ///
  /// In ko, this message translates to:
  /// **'그룹에서 나왔습니다.'**
  String get leaveGroupSuccess;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말로 로그아웃 하시겠습니까?'**
  String get logoutConfirm;

  /// No description provided for @logoutError.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃 중 오류가 발생했습니다: {error}'**
  String logoutError(Object error);

  /// No description provided for @filterTitle.
  ///
  /// In ko, this message translates to:
  /// **'매칭 필터 설정'**
  String get filterTitle;

  /// No description provided for @targetGender.
  ///
  /// In ko, this message translates to:
  /// **'상대 그룹 성별'**
  String get targetGender;

  /// No description provided for @genderAny.
  ///
  /// In ko, this message translates to:
  /// **'상관없음'**
  String get genderAny;

  /// No description provided for @genderMixed.
  ///
  /// In ko, this message translates to:
  /// **'혼성'**
  String get genderMixed;

  /// No description provided for @targetAge.
  ///
  /// In ko, this message translates to:
  /// **'상대 그룹 평균 나이'**
  String get targetAge;

  /// No description provided for @ageUnit.
  ///
  /// In ko, this message translates to:
  /// **'세'**
  String get ageUnit;

  /// No description provided for @ageOver60.
  ///
  /// In ko, this message translates to:
  /// **'60세+'**
  String get ageOver60;

  /// No description provided for @targetHeight.
  ///
  /// In ko, this message translates to:
  /// **'상대 그룹 평균 키'**
  String get targetHeight;

  /// No description provided for @heightUnit.
  ///
  /// In ko, this message translates to:
  /// **'cm'**
  String get heightUnit;

  /// No description provided for @heightOver190.
  ///
  /// In ko, this message translates to:
  /// **'190cm+'**
  String get heightOver190;

  /// No description provided for @distanceRange.
  ///
  /// In ko, this message translates to:
  /// **'거리 범위 (방장 기준)'**
  String get distanceRange;

  /// No description provided for @distanceUnit.
  ///
  /// In ko, this message translates to:
  /// **'km 이내'**
  String get distanceUnit;

  /// No description provided for @distanceOver100.
  ///
  /// In ko, this message translates to:
  /// **'100km+'**
  String get distanceOver100;

  /// No description provided for @applyFilter.
  ///
  /// In ko, this message translates to:
  /// **'적용하기'**
  String get applyFilter;

  /// No description provided for @filterApplied.
  ///
  /// In ko, this message translates to:
  /// **'필터가 적용되었습니다.'**
  String get filterApplied;

  /// No description provided for @filterApplyFail.
  ///
  /// In ko, this message translates to:
  /// **'필터 적용 실패'**
  String get filterApplyFail;

  /// No description provided for @editProfileTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집'**
  String get editProfileTitle;

  /// No description provided for @photoRegisterInfo.
  ///
  /// In ko, this message translates to:
  /// **'최대 6장 사진을 등록해주세요.'**
  String get photoRegisterInfo;

  /// No description provided for @mainPhotoInfo.
  ///
  /// In ko, this message translates to:
  /// **'이미지를 길게 눌러서 대표 프로필로 설정할 수 있습니다.'**
  String get mainPhotoInfo;

  /// No description provided for @nicknameLabel.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nicknameLabel;

  /// No description provided for @nicknamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력하세요'**
  String get nicknamePlaceholder;

  /// No description provided for @nicknameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용 중인 닉네임입니다.'**
  String get nicknameDuplicate;

  /// No description provided for @nicknameAvailable.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 닉네임입니다.'**
  String get nicknameAvailable;

  /// No description provided for @nicknameCheckError.
  ///
  /// In ko, this message translates to:
  /// **'닉네임 확인 중 오류가 발생했습니다.'**
  String get nicknameCheckError;

  /// No description provided for @nicknameRequired.
  ///
  /// In ko, this message translates to:
  /// **'닉네임을 입력해주세요.'**
  String get nicknameRequired;

  /// No description provided for @nicknameLengthError.
  ///
  /// In ko, this message translates to:
  /// **'닉네임은 2자 이상이어야 합니다.'**
  String get nicknameLengthError;

  /// No description provided for @heightLabel.
  ///
  /// In ko, this message translates to:
  /// **'키 (cm)'**
  String get heightLabel;

  /// No description provided for @heightPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'키를 입력하세요'**
  String get heightPlaceholder;

  /// No description provided for @heightRequired.
  ///
  /// In ko, this message translates to:
  /// **'키를 입력해주세요.'**
  String get heightRequired;

  /// No description provided for @heightRangeError.
  ///
  /// In ko, this message translates to:
  /// **'올바른 키를 입력해주세요. (140-220cm)'**
  String get heightRangeError;

  /// No description provided for @locationLabel.
  ///
  /// In ko, this message translates to:
  /// **'활동지역'**
  String get locationLabel;

  /// No description provided for @locationPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'지도를 눌러 위치를 선택하세요'**
  String get locationPlaceholder;

  /// No description provided for @locationRequired.
  ///
  /// In ko, this message translates to:
  /// **'활동지역을 선택해주세요.'**
  String get locationRequired;

  /// No description provided for @introLabel.
  ///
  /// In ko, this message translates to:
  /// **'소개글'**
  String get introLabel;

  /// No description provided for @introHelper.
  ///
  /// In ko, this message translates to:
  /// **'200자 이내'**
  String get introHelper;

  /// No description provided for @introRequired.
  ///
  /// In ko, this message translates to:
  /// **'소개글을 입력해주세요.'**
  String get introRequired;

  /// No description provided for @introLengthError.
  ///
  /// In ko, this message translates to:
  /// **'소개글은 5자 이상 작성해주세요.'**
  String get introLengthError;

  /// No description provided for @immutableInfo.
  ///
  /// In ko, this message translates to:
  /// **'수정 불가능한 정보'**
  String get immutableInfo;

  /// No description provided for @idLabel.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get idLabel;

  /// No description provided for @permissionRequiredTitle.
  ///
  /// In ko, this message translates to:
  /// **'권한 설정 필요'**
  String get permissionRequiredTitle;

  /// No description provided for @permissionRequiredContent.
  ///
  /// In ko, this message translates to:
  /// **'프로필 사진을 등록하려면 갤러리 접근 권한이 필요합니다.\n설정에서 권한을 허용해주세요.'**
  String get permissionRequiredContent;

  /// No description provided for @goToSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정으로 이동'**
  String get goToSettings;

  /// No description provided for @imageSelectError.
  ///
  /// In ko, this message translates to:
  /// **'이미지 선택 중 오류가 발생했습니다.'**
  String get imageSelectError;

  /// No description provided for @mainProfileSet.
  ///
  /// In ko, this message translates to:
  /// **'{index}번 이미지가 대표 프로필로 설정되었습니다.'**
  String mainProfileSet(Object index);

  /// No description provided for @mainLabel.
  ///
  /// In ko, this message translates to:
  /// **'대표'**
  String get mainLabel;

  /// No description provided for @imageUploadFail.
  ///
  /// In ko, this message translates to:
  /// **'이미지 업로드에 실패했습니다.'**
  String get imageUploadFail;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 성공적으로 업데이트되었습니다.'**
  String get profileUpdateSuccess;

  /// No description provided for @photoRequired.
  ///
  /// In ko, this message translates to:
  /// **'사진을 최소 1장 등록해주세요.'**
  String get photoRequired;

  /// No description provided for @updateTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트 안내'**
  String get updateTitle;

  /// No description provided for @updateButton.
  ///
  /// In ko, this message translates to:
  /// **'지금 업데이트'**
  String get updateButton;

  /// No description provided for @updateMessageDefault.
  ///
  /// In ko, this message translates to:
  /// **'업데이트가 필요합니다.'**
  String get updateMessageDefault;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'ja',
    'ko',
    'th',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'th':
      return AppLocalizationsTh();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import '../services/firebase_service.dart';
import '../services/user_service.dart';
import '../services/group_service.dart';
import '../services/fcm_service.dart';
import '../models/user_model.dart';

class AuthController extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final UserService _userService = UserService();
  final GroupService _groupService = GroupService();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FCMService _fcmService = FCMService();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUserModel;
  bool _isInitialized = false;

  VoidCallback? onSignOutCallback;

  // 임시 저장 데이터 (기존 코드 호환성을 위해 남겨두지만 사용하지 않음)
  Map<String, dynamic>? _tempRegistrationData;
  Map<String, dynamic>? _tempProfileData;

  StreamSubscription<User?>? _authStateSubscription;
  bool _isRegistrationInProgress = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUserModel => _currentUserModel;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _firebaseService.currentUser != null;
  Map<String, dynamic>? get tempRegistrationData => _tempRegistrationData;
  Map<String, dynamic>? get tempProfileData => _tempProfileData;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // 에러 메시지 변환
  String _getKoreanRegisterErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use': return '이미 사용 중인 아이디입니다.';
        case 'weak-password': return '비밀번호가 너무 간단합니다.';
        case 'invalid-email': return '올바르지 않은 아이디 형식입니다.';
        case 'network-request-failed': return '네트워크 연결을 확인해주세요.';
        default: return '회원가입 오류: ${error.message}';
      }
    }
    return '회원가입 중 오류가 발생했습니다: $error';
  }

  // [NEW] 즉시 회원가입 메서드 (임시 저장 없이 바로 가입)
  Future<bool> register({
    required String email,
    required String password,
    required String phoneNumber,
    required String birthDate,
    required String gender,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      _isRegistrationInProgress = true; // Auth 리스너 오작동 방지

      // 1. 중복 확인
      final duplicates = await checkDuplicates(
        email: email,
        phoneNumber: phoneNumber,
      );

      if (duplicates['email'] == true) {
        _setError('이미 사용 중인 이메일입니다.');
        return false;
      }
      if (duplicates['phoneNumber'] == true) {
        _setError('이미 사용 중인 전화번호입니다.');
        return false;
      }

      // 2. Firebase Auth 계정 생성
      final userCredential = await _firebaseService.auth
          .createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;

      if (user == null) {
        _setError('계정 생성에 실패했습니다.');
        return false;
      }

      // 3. 전화번호 선점 (개선된 로직 사용)
      final phoneReserved = await reservePhoneNumber(phoneNumber, user.uid);
      if (!phoneReserved) {
        await user.delete(); // 실패 시 계정 롤백
        _setError('전화번호 선점 실패: 이미 사용 중입니다.');
        return false;
      }

      // 4. 기본 사용자 정보 Firestore 저장 (프로필 미완성 상태)
      await _createBasicUserProfileSafely(user, phoneNumber, birthDate, gender);

      // 5. FCM 토큰 저장
      try {
        await _fcmService.retryTokenSave();
      } catch (_) {}

      // 성공 처리
      _isRegistrationInProgress = false;
      _setLoading(false);
      return true;

    } catch (e) {
      _isRegistrationInProgress = false;
      _setError(_getKoreanRegisterErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  // 안전한 기본 사용자 프로필 생성
  Future<void> _createBasicUserProfileSafely(
      User firebaseUser,
      String phoneNumber,
      String birthDate,
      String gender,
      ) async {
    try {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        phoneNumber: phoneNumber,
        birthDate: birthDate,
        gender: gender,
        nickname: '',  // 나중에 입력
        introduction: '',
        height: 0,
        activityArea: '',
        profileImages: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isProfileComplete: false, // 프로필 미완성 표시
      );

      // 재시도 로직으로 문서 생성
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await Future.delayed(Duration(milliseconds: 500 * attempt)); // 권한 전파 대기
          await _userService.createUser(newUser);
          break;
        } catch (e) {
          if (attempt == 3) rethrow;
        }
      }

      // 생성된 정보 로드
      await _loadUserData(firebaseUser.uid);
      if (_currentUserModel == null) {
        _currentUserModel = newUser; // 로드 실패 시 메모리 객체 사용
      }

    } catch (e) {
      throw Exception('사용자 정보 생성 실패: $e');
    }
  }

  // 닉네임 선점 (유령 데이터 처리 로직 포함)
  Future<bool> reserveNickname(String nickname, String uid) async {
    try {
      final normalizedNickname = nickname.trim().toLowerCase();
      final nicknameRef = _firebaseService.getDocument('nicknames/$normalizedNickname');

      final reservationData = {
        'uid': uid,
        'originalNickname': nickname.trim(),
        'reservedAt': FieldValue.serverTimestamp(),
        'type': 'nickname',
      };

      try {
        await nicknameRef.set(reservationData, SetOptions(merge: false));
        return true;
      } catch (e) {
        // 이미 존재할 경우, 실제 유저가 있는지 확인 (좀비 데이터 정리)
        final doc = await nicknameRef.get();
        if (doc.exists) {
          final existingUid = doc.data()?['uid'];
          if (existingUid != null) {
            final userExists = await _userService.userExists(existingUid);
            if (!userExists) {
              await nicknameRef.delete(); // 유령 데이터 삭제
              await nicknameRef.set(reservationData); // 재시도
              return true;
            }
          }
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 전화번호 선점 (유령 데이터 처리 로직 포함)
  Future<bool> reservePhoneNumber(String phoneNumber, String uid) async {
    try {
      final trimmedPhoneNumber = phoneNumber.trim();
      final phoneRef = _firebaseService.getDocument('phoneNumbers/$trimmedPhoneNumber');

      final reservationData = {
        'uid': uid,
        'originalPhoneNumber': trimmedPhoneNumber,
        'reservedAt': FieldValue.serverTimestamp(),
        'type': 'phoneNumber',
      };

      try {
        await phoneRef.set(reservationData, SetOptions(merge: false));
        return true;
      } catch (e) {
        // 이미 존재할 경우, 실제 유저가 있는지 확인 (좀비 데이터 정리)
        final doc = await phoneRef.get();
        if (doc.exists) {
          final existingUid = doc.data()?['uid'];
          if (existingUid != null) {
            final userExists = await _userService.userExists(existingUid);
            if (!userExists) {
              await phoneRef.delete(); // 유령 데이터 삭제
              await phoneRef.set(reservationData); // 재시도
              return true;
            }
          }
        }
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      _setLoading(true);
      if (onSignOutCallback != null) onSignOutCallback!();
      await _firebaseService.auth.signOut();
      _currentUserModel = null;
      _tempRegistrationData = null;
      _tempProfileData = null;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // 사용자 데이터 로드
  Future<void> _loadUserData(String uid, {int maxRetries = 2}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final currentUser = _firebaseService.currentUser;
        if (currentUser == null || currentUser.uid != uid) {
          _currentUserModel = null;
          notifyListeners();
          return;
        }
        _currentUserModel = await _userService.getUserById(uid);
        notifyListeners();
        return;
      } catch (e) {
        if (attempt == maxRetries) {
          _currentUserModel = null;
          notifyListeners();
          return;
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  // 앱 시작 시 초기화
  Future<void> initialize() async {
    try {
      _setLoading(true);
      await _authStateSubscription?.cancel();

      final currentUser = _firebaseService.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser.uid);
      }

      _authStateSubscription = _firebaseService.auth.authStateChanges().listen((user) async {
        if (user != null) {
          await _loadUserData(user.uid);
        } else {
          if (_isRegistrationInProgress) return;
          _currentUserModel = null;
          notifyListeners();
        }
      });

      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _isInitialized = true;
      _setLoading(false);
      notifyListeners();
    }
  }

  // 중복 확인, 프로필 완성 등 필요한 기존 메서드들 유지
  Future<bool> isEmailDuplicate(String email) async {
    try {
      final result = await _functions.httpsCallable('checkEmail').call({'email': email});
      return result.data['isDuplicate'] == true;
    } catch (e) { return false; }
  }

  Future<bool> isNicknameDuplicate(String nickname) async {
    try {
      final result = await _functions.httpsCallable('checkNickname').call({'nickname': nickname});
      return result.data['isDuplicate'] == true;
    } catch (e) { return false; }
  }

  Future<bool> isPhoneNumberDuplicate(String phoneNumber) async {
    try {
      final result = await _functions.httpsCallable('checkPhoneNumber').call({'phoneNumber': phoneNumber});
      return result.data['isDuplicate'] == true;
    } catch (e) { return false; }
  }

  Future<Map<String, bool>> checkDuplicates({String? email, String? nickname, String? phoneNumber}) async {
    final results = <String, bool>{};
    if (email != null) results['email'] = await isEmailDuplicate(email);
    if (nickname != null) results['nickname'] = await isNicknameDuplicate(nickname);
    if (phoneNumber != null) results['phoneNumber'] = await isPhoneNumberDuplicate(phoneNumber);
    return results;
  }

  // 프로필 완성 (기존 회원가입 로직에서 분리됨 - 이미 로그인된 유저가 호출)
  Future<void> createCompleteUserProfile(String uid, String phoneNumber, String birthDate, String gender, String nickname, String introduction, int height, String activityArea, List<String> profileImages) async {
    try {
      final user = UserModel(
        uid: uid,
        email: _firebaseService.currentUser?.email ?? '',
        phoneNumber: phoneNumber,
        birthDate: birthDate,
        gender: gender,
        nickname: nickname,
        introduction: introduction,
        height: height,
        activityArea: activityArea,
        profileImages: profileImages,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isProfileComplete: true,
      );
      await _userService.createUser(user);
      _currentUserModel = user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // 나머지 필요한 getter, setter
  FirebaseService get firebaseService => _firebaseService;
  void clearTemporaryData() { _tempRegistrationData = null; _tempProfileData = null; notifyListeners(); }
  void clearTemporaryProfileData() { _tempProfileData = null; notifyListeners(); }
  void saveTemporaryProfileData({required String nickname, required String introduction, required String height, required String activityArea, List<String>? profileImageBytes, int? mainProfileIndex}) {
    _tempProfileData = {
      'nickname': nickname, 'introduction': introduction, 'height': height, 'activityArea': activityArea,
      'profileImageBytes': profileImageBytes ?? [], 'mainProfileIndex': mainProfileIndex ?? 0, 'savedAt': DateTime.now().toIso8601String(),
    };
    notifyListeners();
  }
  void clearError() => _setError(null);
  void setError(String? msg) => _setError(msg);
  Future<void> refreshCurrentUser() async {
    if (_firebaseService.currentUser != null) await _loadUserData(_firebaseService.currentUser!.uid);
  }

  // (호환성 유지용 빈 메서드)
  void saveTemporaryRegistrationData({required String email, required String password, required String phoneNumber, required String birthDate, required String gender}) {}
  Future<void> completeRegistrationWithoutProfile() async {}
  Future<void> completeRegistrationWithProfile({required String nickname, required String introduction, required int height, required String activityArea, List<XFile>? profileImages}) async {}
}
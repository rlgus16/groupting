import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'controllers/auth_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/group_controller.dart';
import 'controllers/chat_controller.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';
import 'views/register_view.dart';
import 'views/profile_create_view.dart';
import 'views/chat_view.dart';
import 'utils/app_theme.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase 초기화 (플랫폼별 설정 사용)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Firebase Realtime Database URL 설정
    FirebaseDatabase.instance.databaseURL =
        'https://babple-agency-default-rtdb.firebaseio.com';

    print('Firebase 초기화 성공');
  } catch (e) {
    print('Firebase 초기화 오류: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProfileController()),
        ChangeNotifierProvider(create: (_) => GroupController()),
        ChangeNotifierProvider(create: (_) => ChatController()),
      ],
      child: MaterialApp(
        title: '그룹팅',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'), // 한국어
          Locale('en', 'US'), // 영어
        ],
        locale: const Locale('ko', 'KR'),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginView(),
          '/register': (context) => const RegisterView(),
          '/profile-create': (context) => const ProfileCreateView(),
          '/home': (context) => const HomeView(),
        },
      ),
    );
  }
}

// 인증 상태에 따라 화면 전환
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // AuthController 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // 초기화 중이면 로딩 화면
        if (!authController.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 로그아웃 감지 및 모든 컨트롤러 정리
        if (_wasLoggedIn && !authController.isLoggedIn) {
          print('로그아웃 감지: 모든 컨트롤러 정리');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<GroupController>().onSignOut();
            context.read<ChatController>().onSignOut();
          });
        }
        _wasLoggedIn = authController.isLoggedIn;

        // 임시 회원가입 데이터가 있으면 프로필 생성 화면으로
        if (authController.tempRegistrationData != null) {
          return const ProfileCreateView();
        }

        // 로그인 되어있지 않으면 로그인 화면
        if (!authController.isLoggedIn) {
          return const LoginView();
        }

        // 로그인은 되어있지만 사용자 정보가 없으면 회원가입 화면
        if (authController.currentUserModel == null) {
          return const RegisterView();
        }

        // 프로필이 완성되지 않았으면 프로필 생성 화면
        if (!authController.currentUserModel!.isProfileComplete) {
          return const ProfileCreateView();
        }

        // 모든 조건을 만족하면 홈 화면
        return const HomeView();
      },
    );
  }
}

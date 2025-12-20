import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:country_code_picker/country_code_picker.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = '';
  String _selectedCountryCode = '+82';

  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  bool _isCheckingEmail = false;
  String? _emailValidationMessage;
  Timer? _emailDebounceTimer;

  bool _isCheckingPhone = false;
  String? _phoneValidationMessage;
  Timer? _phoneDebounceTimer;

  final _codeController = TextEditingController();
  bool _isCodeSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreTemporaryData();
    });
  }

  @override
  void dispose() {
    _emailDebounceTimer?.cancel();
    _phoneDebounceTimer?.cancel();
    _codeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _restoreTemporaryData() {
    final authController = context.read<AuthController>();
    final tempData = authController.tempRegistrationData;

    if (tempData != null) {
      setState(() {
        _emailController.text = tempData['email'] ?? '';
        _phoneController.text = tempData['phoneNumber'] ?? '';
        _birthDateController.text = tempData['birthDate'] ?? '';
        _selectedGender = tempData['gender'] ?? '';
      });
    }
  }

  // 이메일 중복 검증
  Future<void> _checkEmailDuplicate(String email) async {
    if (email.isEmpty ||
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email)) {
      if (mounted && _emailValidationMessage != null) {
        setState(() {
          _emailValidationMessage = null;
          _isCheckingEmail = false;
        });
      }
      return;
    }

    if (mounted && !_isCheckingEmail) {
      setState(() {
        _isCheckingEmail = true;
        _emailValidationMessage = null;
      });
    }

    try {
      final authController = context.read<AuthController>();
      final isDuplicate = await authController.isEmailDuplicate(email);

      if (mounted) {
        final newMessage = isDuplicate ? '이미 사용 중인 이메일입니다.' : '사용 가능한 이메일입니다.';
        setState(() {
          _isCheckingEmail = false;
          _emailValidationMessage = newMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _emailValidationMessage = '이메일 확인 중 오류가 발생했습니다.';
        });
      }
    }
  }

  String _getFormattedPhoneNumber(String number) {
    String cleanNumber = number.trim();
    if (_selectedCountryCode == '+82' && cleanNumber.startsWith('0')) {
      cleanNumber = cleanNumber.substring(1);
    }
    return '$_selectedCountryCode$cleanNumber';
  }

  Future<void> _checkPhoneNumberDuplicate(String phoneNumber) async {
    final authController = context.read<AuthController>();
    if (authController.isPhoneVerified) {
      authController.resetPhoneVerification();
      setState(() {
        _isCodeSent = false;
        _codeController.clear();
      });
    }
    bool isValid = true;
    if (_selectedCountryCode == '+82') {
      if (phoneNumber.length < 10) isValid = false;
    }

    if (phoneNumber.isEmpty || !isValid) {
      if (mounted && _phoneValidationMessage != null) {
        setState(() {
          _phoneValidationMessage = null;
          _isCheckingPhone = false;
        });
      }
      return;
    }

    if (mounted && !_isCheckingPhone) {
      setState(() {
        _isCheckingPhone = true;
        _phoneValidationMessage = null;
      });
    }

    try {
      final authController = context.read<AuthController>();
      String finalPhoneNumber = _getFormattedPhoneNumber(phoneNumber);
      final isDuplicate = await authController.isPhoneNumberDuplicate(finalPhoneNumber);

      if (mounted) {
        final newMessage = isDuplicate ? '이미 사용 중인 전화번호입니다.' : '사용 가능한 전화번호입니다.';
        setState(() {
          _isCheckingPhone = false;
          _phoneValidationMessage = newMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingPhone = false;
          _phoneValidationMessage = '전화번호 확인 중 오류가 발생했습니다.';
        });
      }
    }
  }

  void _sendVerificationCode() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty || _phoneValidationMessage?.contains('사용 가능') != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 전화번호를 입력 후 중복 확인을 완료해주세요.')),
      );
      return;
    }

    final fullPhoneNumber = _getFormattedPhoneNumber(phoneNumber);
    final authController = context.read<AuthController>();

    await authController.sendVerificationCode(
      phoneNumber: fullPhoneNumber,
      onCodeSent: () {
        setState(() {
          _isCodeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증번호가 전송되었습니다.')),
        );
      },
      onError: (msg) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      },
    );
  }

  void _verifySmsCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) return;

    final authController = context.read<AuthController>();
    final success = await authController.verifySmsCode(code);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호 인증이 완료되었습니다.')),
      );
      setState(() {});
    }
  }

  void _showTermsDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textSecondary)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('성별을 선택해주세요.')));
      return;
    }

    if (!_agreedToTerms || !_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('서비스 이용약관 및 개인정보 처리방침에 동의해주세요.'), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final birthDate = _birthDateController.text.trim();

    final authController = context.read<AuthController>();

    if (_emailValidationMessage == '이미 사용 중인 이메일입니다.') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 사용 중인 이메일입니다.')));
      return;
    }

    if (_phoneValidationMessage == '이미 사용 중인 전화번호입니다.') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 사용 중인 전화번호입니다.')));
      return;
    }

    authController.clearError();
    final fullPhoneNumber = _getFormattedPhoneNumber(phoneNumber);

    final success = await authController.register(
      email: email,
      password: password,
      phoneNumber: fullPhoneNumber,
      birthDate: birthDate,
      gender: _selectedGender,
    );

    if (success && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입되었습니다! 우선 프로필을 완성해주세요.')),
      );
    } else if (mounted && authController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50, // 배경색 변경
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: AppTheme.gray50,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),

                // 1. 계정 정보 섹션
                _buildSectionLabel('계정 정보'),
                _buildCardContainer(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      label: '이메일',
                      hint: 'example@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      suffix: _isCheckingEmail
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : null,
                      onChanged: (value) {
                        _emailDebounceTimer?.cancel();
                        _emailDebounceTimer = Timer(const Duration(milliseconds: 800), () {
                          if (mounted && _emailController.text == value && value.isNotEmpty) {
                            _checkEmailDuplicate(value);
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) return '이메일을 입력해주세요.';
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                          return '올바른 이메일 형식을 입력해주세요.';
                        }
                        return null;
                      },
                      validationMessage: _emailValidationMessage,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: '비밀번호',
                      hint: '8자 이상 입력',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.gray400),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
                        if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: '비밀번호 확인',
                      hint: '비밀번호 재입력',
                      icon: Icons.check_circle_outline,
                      obscureText: _obscureConfirmPassword,
                      suffix: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.gray400),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '비밀번호를 다시 입력해주세요.';
                        if (value != _passwordController.text) return '비밀번호가 일치하지 않습니다.';
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. 개인 정보 섹션
                _buildSectionLabel('개인 정보'),
                _buildCardContainer(
                  children: [
                    _buildPhoneVerificationSection(),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _birthDateController,
                      label: '생년월일',
                      hint: '19950315',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        LengthLimitingTextInputFormatter(8),
                      ],
                      helperText: 'YYYYMMDD 형태로 입력해주세요',
                      validator: (value) {
                        if (value == null || value.isEmpty) return '생년월일을 입력해주세요.';
                        if (value.length != 8) return '8자리여야 합니다.';
                        // (기존 날짜 및 나이 검증 로직 유지)
                        try {
                          final year = int.parse(value.substring(0, 4));
                          final month = int.parse(value.substring(4, 6));
                          final day = int.parse(value.substring(6, 8));
                          final now = DateTime.now();
                          if (year < 1900 || year > now.year) return '유효한 연도를 입력해주세요.';
                          if (month < 1 || month > 12) return '유효한 월을 입력해주세요.';
                          if (day < 1 || day > 31) return '유효한 일을 입력해주세요.';

                          final birthDate = DateTime(year, month, day);
                          int age = now.year - birthDate.year;
                          if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) age--;
                          if (age < 18) return '만 18세 미만은 이용할 수 없습니다.';
                        } catch (e) {
                          return '유효한 날짜를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildGenderSelection(),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. 약관 동의 섹션
                _buildSectionLabel('약관 동의'),
                _buildCardContainer(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildTermItem(
                      title: '[필수] 서비스 이용약관 동의',
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      onTapDetail: () => _showTermsDialog(
                        '서비스 이용약관 (EULA)',
                        '제1조 (목적)\n'
                            '이 약관은 그룹팅 서비스 이용과 관련하여 회사와 이용자의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n'

                            '제2조 (부적절한 콘텐츠에 대한 무관용 원칙)\n'
                            '1. 그룹팅은 건전한 소통을 위해 욕설, 비방, 음란물, 폭력적인 내용 등 부적절한 콘텐츠(Objectionable Content)에 대해 **무관용 원칙(No Tolerance)**을 적용합니다.\n'
                            '2. 위와 같은 콘텐츠를 게시하거나 타인에게 불쾌감을 주는 사용자는 **사전 경고 없이 즉시 차단**되며, 서비스 이용이 영구적으로 정지됩니다.\n'
                            '3. 사용자는 불쾌한 콘텐츠나 사용자를 발견 시 신고 기능을 통해 신고할 수 있으며, 회사는 신고 접수 후 **24시간 이내**에 해당 콘텐츠를 삭제하고 사용자를 제재합니다.\n\n'

                            '제3조 (서비스 제공)\n'
                            '회사는 그룹 매칭 서비스를 제공합니다.\n\n'
                            '(자세한 내용은 앱 설정의 이용약관 전문을 참고하세요)',
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.gray100),
                    _buildTermItem(
                      title: '[필수] 개인정보 처리방침 동의',
                      value: _agreedToPrivacy,
                      onChanged: (v) => setState(() => _agreedToPrivacy = v ?? false),
                      onTapDetail: () => _showTermsDialog(
                        '개인정보 처리방침',
                        '1. 수집하는 개인정보\n- 이메일, 전화번호, 생년월일, 성별 등\n\n'
                            '2. 이용목적\n- 본인 확인 및 서비스 제공\n\n'
                            '3. 보유기간\n- 회원 탈퇴 시까지\n\n'
                            '(자세한 내용은 앱 설정을 참고하세요)',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 회원가입 버튼
                Consumer<AuthController>(
                  builder: (context, authController, _) {
                    return ElevatedButton(
                      onPressed: authController.isLoading
                          ? null
                          : () {
                        if (!authController.isPhoneVerified) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('전화번호 인증을 완료해주세요.')),
                          );
                          return;
                        }
                        _register();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(double.infinity, 54),
                      ),
                      child: authController.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('회원가입', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    );
                  },
                ),

                // 에러 메시지
                Consumer<AuthController>(
                  builder: (context, authController, _) {
                    if (authController.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          authController.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 14),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                const SizedBox(height: 16),

                // 로그인 링크
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('이미 계정이 있으신가요?', style: TextStyle(color: AppTheme.textSecondary)),
                    TextButton(
                      onPressed: () {
                        context.read<AuthController>().clearError();
                        Navigator.pushNamed(context, '/login');
                      },
                      child: const Text('로그인하기', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '환영합니다!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '새로운 인연을 만날 준비가 되셨나요?\n간단한 정보 입력으로 시작해보세요.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildCardContainer({required List<Widget> children, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
    String? helperText,
    String? validationMessage,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 14),
            prefixIcon: icon != null ? Icon(icon, color: AppTheme.gray400, size: 20) : null,
            suffixIcon: suffix,
            helperText: helperText,
            filled: true,
            fillColor: AppTheme.gray50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.errorColor)),
          ),
        ),
        if (validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              validationMessage,
              style: TextStyle(
                fontSize: 12,
                color: validationMessage.contains('사용 가능') ? AppTheme.successColor : AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneVerificationSection() {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('전화번호', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CountryCodePicker(
                    onChanged: (country) {
                      if (!authController.isPhoneVerified) {
                        setState(() {
                          _selectedCountryCode = country.dialCode!;
                          if (_phoneController.text.isNotEmpty) {
                            _checkPhoneNumberDuplicate(_phoneController.text);
                          }
                        });
                      }
                    },
                    enabled: !authController.isPhoneVerified,
                    initialSelection: 'KR',
                    favorite: const ['KR'],
                    showFlag: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    textStyle: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    enabled: !authController.isPhoneVerified,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))],
                    decoration: InputDecoration(
                      hintText: '01012345678',
                      hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 14),
                      filled: true,
                      fillColor: AppTheme.gray50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (value) {
                      _phoneDebounceTimer?.cancel();
                      _phoneDebounceTimer = Timer(const Duration(milliseconds: 800), () {
                        if (mounted && _phoneController.text == value && value.isNotEmpty) {
                          _checkPhoneNumberDuplicate(value);
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isCheckingPhone || authController.isLoading || _phoneValidationMessage?.contains('사용 가능') != true || authController.isPhoneVerified
                        ? null
                        : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: authController.isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(authController.isPhoneVerified ? '완료' : '인증'),
                  ),
                ),
              ],
            ),

            if (_phoneValidationMessage != null && !authController.isPhoneVerified)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _phoneValidationMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _phoneValidationMessage!.contains('사용 가능한') ? AppTheme.successColor : AppTheme.errorColor,
                  ),
                ),
              ),

            // 인증번호 입력 필드
            if (_isCodeSent && !authController.isPhoneVerified)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '인증번호 6자리',
                          prefixIcon: const Icon(Icons.sms_outlined, color: AppTheme.gray400, size: 20),
                          filled: true,
                          fillColor: AppTheme.gray50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: authController.isLoading ? null : _verifySmsCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gray800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('확인'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('성별', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildGenderButton('남', '남성', AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderButton('여', '여성', AppTheme.secondaryColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderButton(String value, String label, Color color) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTermItem({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onTapDetail,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
          ),
          TextButton(
            onPressed: onTapDetail,
            child: const Text('보기', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
          ),
        ],
      ),
      activeColor: AppTheme.primaryColor,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}
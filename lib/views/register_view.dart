import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:country_code_picker/country_code_picker.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_theme.dart';
import '../l10n/generated/app_localizations.dart';

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
        final newMessage = isDuplicate 
            ? 'EMAIL_IN_USE' 
            : 'EMAIL_AVAILABLE';
        setState(() {
          _isCheckingEmail = false;
          _emailValidationMessage = newMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingEmail = false;
          _emailValidationMessage = 'EMAIL_ERROR';
        });
      }
    }
  }

  String _getEmailValidationText(String? key, AppLocalizations l10n) {
    if (key == null) return '';
    switch (key) {
      case 'EMAIL_IN_USE':
        return l10n.registerEmailInUse;
      case 'EMAIL_AVAILABLE':
        return l10n.registerEmailAvailable;
      case 'EMAIL_ERROR':
        return l10n.registerEmailError;
      default:
        return key;
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
        final newMessage = isDuplicate ? 'PHONE_IN_USE' : 'PHONE_AVAILABLE';
        setState(() {
          _isCheckingPhone = false;
          _phoneValidationMessage = newMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingPhone = false;
          _phoneValidationMessage = 'PHONE_ERROR';
        });
      }
    }
  }

  String _getPhoneValidationText(String? key, AppLocalizations l10n) {
    if (key == null) return '';
    switch (key) {
      case 'PHONE_IN_USE':
        return l10n.registerPhoneInUse;
      case 'PHONE_AVAILABLE':
        return l10n.registerPhoneAvailable;
      case 'PHONE_ERROR':
        return l10n.registerPhoneError;
      default:
        return key;
    }
  }

  void _sendVerificationCode() async {
    final l10n = AppLocalizations.of(context)!;
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty || _phoneValidationMessage != 'PHONE_AVAILABLE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.registerPhoneValid)),
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
          SnackBar(content: Text(l10n.registerCodeSent)),
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
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();
    if (code.length < 6) return;

    final authController = context.read<AuthController>();
    final success = await authController.verifySmsCode(code);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.registerPhoneVerified)),
      );
      setState(() {});
    }
  }

  void _showTermsDialog(String title, String content) {
    final l10n = AppLocalizations.of(context)!;
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
            child: Text(l10n.commonConfirm, style: const TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    final l10n = AppLocalizations.of(context)!;
    
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.registerErrorGender)));
      return;
    }

    if (!_agreedToTerms || !_agreedToPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.registerErrorTerms), backgroundColor: AppTheme.errorColor),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phoneNumber = _phoneController.text.trim();
    final birthDate = _birthDateController.text.trim();

    final authController = context.read<AuthController>();

    if (_emailValidationMessage == 'EMAIL_IN_USE') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_getEmailValidationText('EMAIL_IN_USE', l10n))));
      return;
    }

    if (_phoneValidationMessage == 'PHONE_IN_USE') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_getPhoneValidationText('PHONE_IN_USE', l10n))));
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
        SnackBar(content: Text(l10n.registerSuccess)),
      );
    } else if (mounted && authController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authController.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        title: Text(l10n.registerTitle),
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
                _buildHeader(l10n),
                const SizedBox(height: 24),

                // 1. 계정 정보 섹션
                _buildSectionLabel(l10n.registerAccountInfo),
                _buildCardContainer(
                  children: [
                    _buildTextField(
                      controller: _emailController,
                      label: l10n.loginEmailLabel,
                      hint: l10n.loginEmailHint,
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
                        if (value == null || value.isEmpty) return l10n.loginErrorEmailEmpty;
                        if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                          return l10n.loginErrorEmailInvalid;
                        }
                        return null;
                      },
                      validationMessage: _getEmailValidationText(_emailValidationMessage, l10n),
                      isAvailable: _emailValidationMessage == 'EMAIL_AVAILABLE',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: l10n.loginPasswordLabel,
                      hint: l10n.registerPasswordHint8Chars,
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffix: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.gray400),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return l10n.loginErrorPasswordEmpty;
                        if (value.length < 8) return l10n.registerPassword8Chars;
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: l10n.registerPasswordConfirm,
                      hint: l10n.registerPasswordConfirmHint,
                      icon: Icons.check_circle_outline,
                      obscureText: _obscureConfirmPassword,
                      suffix: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: AppTheme.gray400),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return l10n.registerPasswordConfirmEmpty;
                        if (value != _passwordController.text) return l10n.registerErrorPasswordMismatch;
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. 개인 정보 섹션
                _buildSectionLabel(l10n.registerPersonalInfo),
                _buildCardContainer(
                  children: [
                    _buildPhoneVerificationSection(l10n),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _birthDateController,
                      label: l10n.registerBirthDate,
                      hint: l10n.registerBirthDateHint,
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                        LengthLimitingTextInputFormatter(8),
                      ],
                      helperText: l10n.registerBirthDateHelper,
                      validator: (value) {
                        if (value == null || value.isEmpty) return l10n.registerBirthDateEmpty;
                        if (value.length != 8) return l10n.registerBirthDate8Digits;
                        try {
                          final year = int.parse(value.substring(0, 4));
                          final month = int.parse(value.substring(4, 6));
                          final day = int.parse(value.substring(6, 8));
                          final now = DateTime.now();
                          if (year < 1900 || year > now.year) return l10n.registerYearInvalid;
                          if (month < 1 || month > 12) return l10n.registerMonthInvalid;
                          if (day < 1 || day > 31) return l10n.registerDayInvalid;

                          final birthDate = DateTime(year, month, day);
                          int age = now.year - birthDate.year;
                          if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) age--;
                          if (age < 18) return l10n.registerAgeRestriction;
                        } catch (e) {
                          return l10n.registerDateInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildGenderSelection(l10n),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. 약관 동의 섹션
                _buildSectionLabel(l10n.registerTerms),
                _buildCardContainer(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildTermItem(
                      title: l10n.registerTermsService,
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      onTapDetail: () => _showTermsDialog(
                        l10n.registerTermsServiceFull,
                        l10n.registerTermsServiceContent,
                      ),
                      l10n: l10n,
                    ),
                    const Divider(height: 1, color: AppTheme.gray100),
                    _buildTermItem(
                      title: l10n.registerTermsPrivacy,
                      value: _agreedToPrivacy,
                      onChanged: (v) => setState(() => _agreedToPrivacy = v ?? false),
                      onTapDetail: () => _showTermsDialog(
                        l10n.registerPrivacyPolicyFull,
                        l10n.registerPrivacyPolicyContent,
                      ),
                      l10n: l10n,
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
                            SnackBar(content: Text(l10n.registerPhoneVerifyNeeded)),
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
                          : Text(l10n.registerButton, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    Text(l10n.registerHaveAccount, style: const TextStyle(color: AppTheme.textSecondary)),
                    TextButton(
                      onPressed: () {
                        context.read<AuthController>().clearError();
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(l10n.registerLoginLink, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
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

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.registerWelcome,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.registerWelcomeDesc,
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
    bool isAvailable = false,
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
        if (validationMessage != null && validationMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              validationMessage,
              style: TextStyle(
                fontSize: 12,
                color: isAvailable ? AppTheme.successColor : AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhoneVerificationSection(AppLocalizations l10n) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.registerPhone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
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
                    onPressed: _isCheckingPhone || authController.isLoading || _phoneValidationMessage != 'PHONE_AVAILABLE' || authController.isPhoneVerified
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
                        : Text(authController.isPhoneVerified ? l10n.registerPhoneComplete : l10n.registerPhoneVerify),
                  ),
                ),
              ],
            ),

            if (_phoneValidationMessage != null && !authController.isPhoneVerified)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  _getPhoneValidationText(_phoneValidationMessage, l10n),
                  style: TextStyle(
                    fontSize: 12,
                    color: _phoneValidationMessage == 'PHONE_AVAILABLE' ? AppTheme.successColor : AppTheme.errorColor,
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
                          hintText: l10n.registerVerificationCode,
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
                        child: Text(l10n.commonConfirm),
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

  Widget _buildGenderSelection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.registerGender, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildGenderButton('남', l10n.registerMale, AppTheme.primaryColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderButton('여', l10n.registerFemale, AppTheme.secondaryColor)),
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
    required AppLocalizations l10n,
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
            child: Text(l10n.registerTermsView, style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
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
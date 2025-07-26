import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/app_theme.dart';

class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _introductionController = TextEditingController();
  final _heightController = TextEditingController();
  final _activityAreaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final authController = context.read<AuthController>();
    final user = authController.currentUserModel;

    if (user != null) {
      _nicknameController.text = user.nickname;
      _introductionController.text = user.introduction;
      _heightController.text = user.height.toString();
      _activityAreaController.text = user.activityArea;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _introductionController.dispose();
    _heightController.dispose();
    _activityAreaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필 편집'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          Consumer<ProfileController>(
            builder: (context, profileController, _) {
              return TextButton(
                onPressed: profileController.isLoading ? null : _saveProfile,
                child: profileController.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('저장'),
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthController, ProfileController>(
        builder: (context, authController, profileController, _) {
          final user = authController.currentUserModel;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 프로필 이미지 섹션
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.gray200,
                          ),
                          child: ClipOval(
                            child: user.mainProfileImage != null
                                ? _buildProfileImage(
                                    user.mainProfileImage!,
                                    120,
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.textSecondary,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: IconButton(
                              onPressed: () {
                                // TODO: 이미지 선택 기능 구현
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('이미지 업로드 기능은 추후 구현 예정입니다.'),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 닉네임 입력
                  TextFormField(
                    controller: _nicknameController,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      hintText: '닉네임을 입력하세요',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    maxLength: 10,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '닉네임을 입력해주세요.';
                      }
                      if (value.trim().length < 2) {
                        return '닉네임은 2자 이상이어야 합니다.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 키 입력
                  TextFormField(
                    controller: _heightController,
                    decoration: const InputDecoration(
                      labelText: '키 (cm)',
                      hintText: '키를 입력하세요',
                      prefixIcon: Icon(Icons.height),
                      suffixText: 'cm',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '키를 입력해주세요.';
                      }
                      final height = int.tryParse(value.trim());
                      if (height == null || height < 140 || height > 220) {
                        return '올바른 키를 입력해주세요. (140-220cm)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 활동지역 입력
                  TextFormField(
                    controller: _activityAreaController,
                    decoration: const InputDecoration(
                      labelText: '활동지역',
                      hintText: '활동지역을 입력하세요',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '활동지역을 입력해주세요.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 소개글 입력
                  TextFormField(
                    controller: _introductionController,
                    decoration: const InputDecoration(
                      labelText: '소개글',
                      hintText: '자신을 소개해주세요',
                      prefixIcon: Icon(Icons.edit_outlined),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 100,
                    validator: (value) {
                      if (value != null && value.trim().length > 100) {
                        return '소개글은 100자 이하로 입력해주세요.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // 수정 불가능한 정보 표시
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '수정 불가능한 정보',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildReadOnlyInfo('아이디', user.userId),
                        _buildReadOnlyInfo('전화번호', _formatPhoneNumber(user.phoneNumber)),
                        _buildReadOnlyInfo('생년월일', _formatBirthDate(user.birthDate)),
                        _buildReadOnlyInfo('성별', user.gender),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 에러 메시지
                  Consumer<ProfileController>(
                    builder: (context, profileController, _) {
                      if (profileController.errorMessage != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.errorColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            profileController.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 14,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadOnlyInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length == 11) {
      return '${phoneNumber.substring(0, 3)}-${phoneNumber.substring(3, 7)}-${phoneNumber.substring(7)}';
    }
    return phoneNumber;
  }

  String _formatBirthDate(String birthDate) {
    if (birthDate.length == 8) {
      return '${birthDate.substring(0, 4)}-${birthDate.substring(4, 6)}-${birthDate.substring(6)}';
    }
    return birthDate;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileController = context.read<ProfileController>();
    final authController = context.read<AuthController>();
    final user = authController.currentUserModel;

    if (user == null) return;

    final success = await profileController.updateProfile(
      nickname: _nicknameController.text.trim(),
      introduction: _introductionController.text.trim(),
      height: int.parse(_heightController.text.trim()),
      activityArea: _activityAreaController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 성공적으로 업데이트되었습니다.')));
      Navigator.pop(context);
    }
  }

  Widget _buildProfileImage(String imageUrl, double size) {
    // 로컬 이미지인지 확인
    if (imageUrl.startsWith('local://')) {
      if (kIsWeb) {
        // 웹에서는 로컬 이미지 표시 불가
        return Icon(
          Icons.person,
          size: size * 0.5,
          color: AppTheme.textSecondary,
        );
      } else {
        // 모바일에서만 로컬 파일 접근
        final localPath = imageUrl.substring(8); // 'local://' 제거
        return Image.file(
          File(localPath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.person,
            size: size * 0.5,
            color: AppTheme.textSecondary,
          ),
        );
      }
    } else {
      // 네트워크 이미지
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) =>
            Icon(Icons.person, size: size * 0.5, color: AppTheme.textSecondary),
      );
    }
  }
}

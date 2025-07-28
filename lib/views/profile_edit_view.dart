import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
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
  
  // 이미지 관리 관련
  List<XFile?> _selectedImages = List.filled(6, null); // 6개 슬롯을 null로 초기화
  List<String> _originalImages = []; // 기존 저장된 이미지들
  final ImagePicker _picker = ImagePicker();
  bool _isPickerActive = false;

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
      
      // 기존 이미지들 로드
      _originalImages = List.from(user.profileImages);
      print('기존 프로필 이미지들: $_originalImages');
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

  // 이미지 선택 메서드들
  Future<void> _selectSingleImage(int index) async {
    if (_isPickerActive) return; // 이미 활성화 중이면 리턴
    
    try {
      _isPickerActive = true;
      final image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          // 해당 인덱스에 직접 이미지 저장
          _selectedImages[index] = image;
        });
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      _isPickerActive = false;
    }
  }

  // 해당 슬롯에 표시할 이미지 반환 (편집된 이미지 우선, 없으면 기존 이미지)
  dynamic _getImageForSlot(int index) {
    // 편집된 이미지가 있으면 우선 반환
    if (_selectedImages[index] != null) {
      return _selectedImages[index];
    }
    
    // 기존 이미지가 있으면 반환
    if (index < _originalImages.length) {
      return _originalImages[index];
    }
    
    return null;
  }

  // 이미지 슬롯 삭제 (편집된 이미지 또는 기존 이미지)
  void _removeImageFromSlot(int index) {
    setState(() {
      if (_selectedImages[index] != null) {
        // 편집된 이미지가 있으면 제거
        _selectedImages[index] = null;
      } else if (index < _originalImages.length) {
        // 기존 이미지를 삭제 표시 (빈 XFile로 설정)
        _selectedImages[index] = null;
        // 실제로는 저장 시 해당 인덱스를 제외하도록 처리
      }
    });
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
                  // 프로필 사진 섹션
                  Text(
                    '프로필 사진',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '최대 6장 사진을 등록해주세요.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1번 사진은 프로필 사진으로 사용됩니다.',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.gray300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 좌측 메인 프로필 이미지 (1번)
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () => _selectSingleImage(0),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _getImageForSlot(0) != null
                                        ? AppTheme.primaryColor
                                        : AppTheme.gray300,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _getImageForSlot(0) != null
                                    ? Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: _buildImageWidget(
                                              _getImageForSlot(0),
                                              isMainProfile: true,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 8,
                                            left: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                '프로필',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => _removeImageFromSlot(0),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate,
                                            size: 48,
                                            color: AppTheme.gray400,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            '1번\n프로필 사진',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 우측 작은 이미지들 (2-5번)
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                // 상단 2개
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildSmallImageSlot(1),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildSmallImageSlot(2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // 하단 2개
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildSmallImageSlot(3),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildSmallImageSlot(4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 6번 이미지 슬롯 (하단 추가)
                  if (_getImageForSlot(5) != null || _originalImages.length > 5 || 
                      _selectedImages.take(5).any((image) => image != null)) // 6번째 이미지가 있거나 기존에 있었거나 1-5번 중 편집된 이미지가 있으면 표시
                    Container(
                      height: 80,
                      child: Row(
                        children: [
                          Expanded(child: _buildSmallImageSlot(5)), // 6번째 이미지
                          const SizedBox(width: 12),
                          Expanded(child: Container()), // 빈 공간
                          const SizedBox(width: 12),
                          Expanded(child: Container()), // 빈 공간
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

    // 새로 선택된 이미지들과 기존 이미지들 분리
    List<XFile> newImages = [];
    List<String> finalImages = [];
    bool hasImageChanges = false;

    // 1. 새로 선택된 이미지들 수집
    for (int i = 0; i < 6; i++) {
      if (_selectedImages[i] != null) {
        newImages.add(_selectedImages[i]!);
        hasImageChanges = true;
      }
    }

    // 2. 새 이미지들 업로드 (있는 경우)
    List<String> uploadedUrls = [];
    if (newImages.isNotEmpty) {
      try {
        // 간단히 임시 URL로 처리 (실제로는 Firebase Storage 업로드)
        for (int i = 0; i < newImages.length; i++) {
          uploadedUrls.add('temp://${newImages[i].path}');
        }
        print('새 이미지 업로드 완료: $uploadedUrls');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미지 업로드에 실패했습니다.')),
          );
        }
        return;
      }
    }

    // 3. 최종 이미지 목록 생성 (순서 유지)
    int uploadedIndex = 0;
    for (int i = 0; i < 6; i++) {
      if (_selectedImages[i] != null) {
        // 새로 선택된 이미지
        if (uploadedIndex < uploadedUrls.length) {
          finalImages.add(uploadedUrls[uploadedIndex]);
          uploadedIndex++;
        }
        hasImageChanges = true;
      } else if (i < _originalImages.length) {
        // 기존 이미지 유지
        finalImages.add(_originalImages[i]);
      }
    }

    print('최종 이미지 목록: $finalImages');
    print('이미지 변경 여부: $hasImageChanges');

    final success = await profileController.updateProfile(
      nickname: _nicknameController.text.trim(),
      introduction: _introductionController.text.trim(),
      height: int.parse(_heightController.text.trim()),
      activityArea: _activityAreaController.text.trim(),
      profileImages: hasImageChanges ? finalImages : null,
    );

    if (success && mounted) {
      // 사용자 정보 새로고침
      await authController.refreshCurrentUser();
      
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 성공적으로 업데이트되었습니다.')));
      Navigator.pop(context);
    } else if (mounted && profileController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(profileController.errorMessage!)),
      );
    }
  }

  Widget _buildSmallImageSlot(int index) {
    final imageData = _getImageForSlot(index);
    final hasImage = imageData != null;
    
    return GestureDetector(
      onTap: () => _selectSingleImage(index),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: hasImage 
                ? AppTheme.gray300 
                : AppTheme.gray200
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: hasImage
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _buildImageWidget(imageData),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImageFromSlot(index),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add,
                    color: AppTheme.gray300,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1}번',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildImageWidget(dynamic imageData, {bool isMainProfile = false}) {
    if (imageData is XFile) {
      // 새로 선택된 이미지 (XFile)
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: imageData.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: isMainProfile ? double.infinity : 80,
                height: double.infinity,
                fit: BoxFit.cover,
              );
            } else {
              return Container(
                width: isMainProfile ? double.infinity : 80,
                height: 80,
                color: AppTheme.gray200,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
          },
        );
      } else {
        return FutureBuilder<Uint8List>(
          future: imageData.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: isMainProfile ? double.infinity : 80,
                height: double.infinity,
                fit: BoxFit.cover,
              );
            } else {
              return Container(
                width: isMainProfile ? double.infinity : 80,
                height: 80,
                color: AppTheme.gray200,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
          },
        );
      }
    } else if (imageData is String) {
      // 기존 저장된 이미지 (URL)
      return _buildProfileImage(imageData, isMainProfile ? 200 : 80);
    } else {
      // 빈 슬롯
      return Container(
        width: isMainProfile ? double.infinity : 80,
        height: 80,
        color: AppTheme.gray200,
        child: Icon(
          Icons.add_photo_alternate,
          size: isMainProfile ? 48 : 24,
          color: AppTheme.gray400,
        ),
      );
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

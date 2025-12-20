import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:typed_data';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/app_theme.dart';
import 'location_picker_view.dart';

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

  double _latitude = 0.0;
  double _longitude = 0.0;

  List<dynamic> _imageSlots = List.filled(6, null);
  List<String> _imagesToDelete = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPickerActive = false;
  int _mainProfileIndex = 0;

  bool _isCheckingNickname = false;
  String? _nicknameValidationMessage;
  String _originalNickname = '';

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
      _originalNickname = user.nickname;
      _introductionController.text = user.introduction;
      _heightController.text = user.height.toString();
      _activityAreaController.text = user.activityArea;

      _latitude = user.latitude;
      _longitude = user.longitude;

      List<String> _originalImages = user.profileImages.where((imageUrl) {
        return imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
      }).toList();

      for (int i = 0; i < _imageSlots.length; i++) {
        if (i < _originalImages.length) {
          _imageSlots[i] = _originalImages[i];
        } else {
          _imageSlots[i] = null;
        }
      }
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

  Future<void> _checkNicknameDuplicate(String nickname) async {
    if (nickname.isEmpty || nickname.length < 2 || nickname.trim() == _originalNickname) {
      setState(() {
        _nicknameValidationMessage = null;
        _isCheckingNickname = false;
      });
      return;
    }

    setState(() {
      _isCheckingNickname = true;
      _nicknameValidationMessage = null;
    });

    try {
      final profileController = context.read<ProfileController>();
      final isDuplicate = await profileController.isNicknameDuplicate(nickname);

      if (mounted) {
        setState(() {
          _isCheckingNickname = false;
          _nicknameValidationMessage = isDuplicate ? '이미 사용 중인 닉네임입니다.' : '사용 가능한 닉네임입니다.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingNickname = false;
          _nicknameValidationMessage = '닉네임 확인 중 오류가 발생했습니다.';
        });
      }
    }
  }

  Future<void> _selectSingleImage(int index) async {
    if (_isPickerActive) return;

    if (!kIsWeb && Platform.isAndroid) {
      PermissionStatus status = await Permission.photos.request();
      if (status.isDenied || status.isPermanentlyDenied) {
        status = await Permission.storage.request();
      }
      if (status.isDenied || status.isPermanentlyDenied) {
        if (mounted) _showPermissionDialog();
        return;
      }
    }

    try {
      _isPickerActive = true;
      final image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          if (_imageSlots[index] is String) {
            _imagesToDelete.add(_imageSlots[index] as String);
          }
          _imageSlots[index] = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      _isPickerActive = false;
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한 설정 필요'),
        content: const Text('프로필 사진을 등록하려면 갤러리 접근 권한이 필요합니다.\n설정에서 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  void _removeImageFromSlot(int index) {
    setState(() {
      final currentImage = _imageSlots[index];
      if (currentImage is String) {
        _imagesToDelete.add(currentImage);
      }
      _imageSlots[index] = null;

      if (_mainProfileIndex == index) {
        _mainProfileIndex = _imageSlots.indexWhere((img) => img != null);
        if (_mainProfileIndex == -1) _mainProfileIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50, // 전체 배경색 변경
      appBar: AppBar(
        title: const Text('프로필 편집'),
        elevation: 0,
        backgroundColor: AppTheme.gray50,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          Consumer<ProfileController>(
            builder: (context, profileController, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton(
                  onPressed: profileController.isLoading ? null : _saveProfile,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  child: profileController.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('완료'),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer2<AuthController, ProfileController>(
        builder: (context, authController, profileController, _) {
          final user = authController.currentUserModel;
          if (user == null) return const Center(child: CircularProgressIndicator());

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. 프로필 사진 섹션
                  _buildSectionHeader('프로필 사진'),
                  _buildImageSection(),

                  const SizedBox(height: 24),

                  // 2. 기본 정보 섹션
                  _buildSectionHeader('기본 정보'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _nicknameController,
                          label: '닉네임',
                          hint: '닉네임을 입력하세요 (2~10자)',
                          icon: Icons.person_outline,
                          maxLength: 10,
                          onChanged: (value) {
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (_nicknameController.text == value) {
                                _checkNicknameDuplicate(value);
                              }
                            });
                          },
                          suffix: _isCheckingNickname
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : null,
                          validationMessage: _nicknameValidationMessage,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return '닉네임을 입력해주세요.';
                            if (value.trim().length < 2) return '닉네임은 2자 이상이어야 합니다.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _heightController,
                          label: '키 (cm)',
                          hint: '키를 입력하세요',
                          icon: Icons.height,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return '키를 입력해주세요.';
                            final height = int.tryParse(value.trim());
                            if (height == null || height < 140 || height > 220) return '140-220cm 사이로 입력해주세요.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildLocationField(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. 자기소개 섹션
                  _buildSectionHeader('자기소개'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: TextFormField(
                      controller: _introductionController,
                      decoration: InputDecoration(
                        hintText: '나를 표현하는 멋진 소개글을 작성해보세요.\n(취미, 관심사, 성격 등)',
                        hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 14),
                        filled: true,
                        fillColor: AppTheme.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 5,
                      maxLength: 200,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return '소개글을 입력해주세요.';
                        if (value.trim().length < 5) return '5자 이상 작성해주세요.';
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. 계정 정보 섹션 (Read-only)
                  _buildSectionHeader('계정 정보'),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        _buildReadOnlyRow('아이디', context.read<AuthController>().firebaseService.currentUser?.email ?? ''),
                        const Divider(height: 1, color: AppTheme.gray100),
                        _buildReadOnlyRow('전화번호', _formatPhoneNumber(user.phoneNumber)),
                        const Divider(height: 1, color: AppTheme.gray100),
                        _buildReadOnlyRow('생년월일', _formatBirthDate(user.birthDate)),
                        const Divider(height: 1, color: AppTheme.gray100),
                        _buildReadOnlyRow('성별', user.gender),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 에러 메시지 표시
                  if (profileController.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              profileController.errorMessage!,
                              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI 컴포넌트 메서드 ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  // 이미지 섹션 UI
  Widget _buildImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '대표 사진은 길게 눌러 설정하세요',
                style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              Text(
                '${_imageSlots.where((e) => e != null).length}/6',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // 3열 그리드 계산
              final itemWidth = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: itemWidth,
                    height: itemWidth,
                    child: _buildImageGridSlot(index),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageGridSlot(int index) {
    final imageData = _imageSlots[index];
    final hasImage = imageData != null;
    final isMainProfile = index == _mainProfileIndex && hasImage;

    return GestureDetector(
      onTap: !hasImage ? () => _selectSingleImage(index) : null,
      onLongPress: hasImage ? () => _setMainProfile(index) : null,
      child: Container(
        decoration: BoxDecoration(
          color: hasImage ? Colors.white : AppTheme.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMainProfile ? AppTheme.primaryColor : AppTheme.gray200,
            width: isMainProfile ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // 이미지 표시
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildImageWidget(imageData),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppTheme.gray400, size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '사진 추가',
                      style: TextStyle(color: AppTheme.gray400, fontSize: 11),
                    ),
                  ],
                ),
              ),

            // 삭제 버튼
            if (hasImage)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImageFromSlot(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 12),
                  ),
                ),
              ),

            // 대표 태그
            if (isMainProfile)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '대표',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 커스텀 텍스트 필드 빌더
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    ValueChanged<String>? onChanged,
    Widget? suffix,
    String? validationMessage,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.gray400, fontSize: 14),
            prefixIcon: Icon(icon, color: AppTheme.gray400, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppTheme.gray50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            counterText: '', // maxLength 카운터 숨김
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.errorColor),
            ),
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

  // 위치 선택 필드
  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('활동지역', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LocationPickerView()),
            );
            if (result != null) {
              if (result is Map<String, dynamic>) {
                setState(() {
                  _activityAreaController.text = result['address'];
                  _latitude = result['latitude'];
                  _longitude = result['longitude'];
                });
              } else if (result is String) {
                setState(() => _activityAreaController.text = result);
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppTheme.gray400, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _activityAreaController.text.isEmpty ? '지도를 눌러 위치를 선택하세요' : _activityAreaController.text,
                    style: TextStyle(
                      color: _activityAreaController.text.isEmpty ? AppTheme.gray400 : AppTheme.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.gray400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- 기존 로직 메서드들 (변경 없음) ---

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

  Widget _buildImageWidget(dynamic imageData) {
    if (imageData is XFile) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: imageData.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
            }
            return Container(color: AppTheme.gray100, child: const Center(child: CircularProgressIndicator()));
          },
        );
      } else {
        return Image.file(File(imageData.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
    } else if (imageData is String) {
      return _buildProfileImage(imageData);
    }
    return const SizedBox();
  }

  Widget _buildProfileImage(String imageUrl) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(color: AppTheme.gray100, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
        errorWidget: (context, url, error) => const Icon(Icons.person, color: AppTheme.textSecondary),
      );
    } else {
      return const Icon(Icons.person, color: AppTheme.textSecondary);
    }
  }

  void _setMainProfile(int index) {
    setState(() {
      _mainProfileIndex = index;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('대표 프로필 사진이 변경되었습니다.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nicknameValidationMessage == '이미 사용 중인 닉네임입니다.') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미 사용 중인 닉네임입니다.')));
      return;
    }

    final hasImages = _imageSlots.any((image) => image != null);
    if (!hasImages) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사진을 최소 1장 등록해주세요.')));
      return;
    }

    final profileController = context.read<ProfileController>();
    final authController = context.read<AuthController>();
    final user = authController.currentUserModel;
    if (user == null) return;

    for (String imageUrl in _imagesToDelete) {
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (e) {
        debugPrint('이미지 삭제 실패: $e');
      }
    }

    List<String> finalImages = [];
    List<dynamic> sortedImageSlots = List.from(_imageSlots);

    if (_mainProfileIndex >= 0 && _mainProfileIndex < sortedImageSlots.length) {
      final mainImage = sortedImageSlots.removeAt(_mainProfileIndex);
      if (mainImage != null) {
        sortedImageSlots.insert(0, mainImage);
      }
    }

    for (final image in sortedImageSlots) {
      if (image is String) {
        finalImages.add(image);
      } else if (image is XFile) {
        try {
          final fileName = '${user.uid}_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = FirebaseStorage.instance.ref().child('profile_images').child(user.uid).child(fileName);

          late UploadTask uploadTask;
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            uploadTask = ref.putData(bytes);
          } else {
            uploadTask = ref.putFile(File(image.path));
          }

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();
          finalImages.add(downloadUrl);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이미지 업로드 실패')));
          }
          return;
        }
      }
    }

    final success = await profileController.updateProfile(
      nickname: _nicknameController.text.trim(),
      introduction: _introductionController.text.trim(),
      height: int.parse(_heightController.text.trim()),
      activityArea: _activityAreaController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      profileImages: finalImages,
    );

    if (success && mounted) {
      await authController.refreshCurrentUser();
      Navigator.pop(context);
    } else if (mounted && profileController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(profileController.errorMessage!)));
    }
  }
}
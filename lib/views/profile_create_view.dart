import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) '';
import '../controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../utils/app_theme.dart';

class ProfileCreateView extends StatefulWidget {
  const ProfileCreateView({super.key});

  @override
  State<ProfileCreateView> createState() => _ProfileCreateViewState();
}

class _ProfileCreateViewState extends State<ProfileCreateView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _heightController = TextEditingController();
  final _introductionController = TextEditingController();
  final _activityAreaController = TextEditingController();

  String _selectedGender = '';
  DateTime? _selectedDate;
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _phoneController.dispose();
    _nicknameController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _introductionController.dispose();
    _activityAreaController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text =
            '${picked.year}${picked.month.toString().padLeft(2, '0')}${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selectImages() async {
    final images = await _picker.pickMultiImage();
    if (images.isNotEmpty && images.length <= 6) {
      setState(() {
        _selectedImages = images;
      });
    } else if (images.length > 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('최대 6장까지 선택할 수 있습니다.')));
    }
  }

  Future<void> _selectSingleImage(int index) async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (index < _selectedImages.length) {
          _selectedImages[index] = image;
        } else {
          _selectedImages.add(image);
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedGender.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('성별을 선택해주세요.')));
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필 사진을 최소 1장 선택해주세요.')));
      return;
    }

    final profileController = context.read<ProfileController>();

    final success = await profileController.createProfile(
      phoneNumber: _phoneController.text.trim(),
      nickname: _nicknameController.text.trim(),
      birthDate: _birthDateController.text,
      gender: _selectedGender,
      introduction: _introductionController.text.trim(),
      height: int.parse(_heightController.text.trim()),
      activityArea: _activityAreaController.text.trim(),
      profileImages: _selectedImages,
    );

    if (success && mounted) {
      // AuthController에게 새로운 사용자 정보 로드 요청
      final authController = context.read<AuthController>();
      await authController.refreshCurrentUser();

      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('프로필 생성'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 안내 메시지
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_add,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '프로필을 완성해주세요',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '최대 6장 사진 등록\n1번 사진은 프로필\n업로드된 사진창을 다시 눌러서 재 업로드가능\n\n전화번호, 닉네임 10자이내\n소개글 100자이내',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 프로필 사진 섹션
                Text(
                  '프로필 사진',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.gray300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImages.isEmpty
                      ? InkWell(
                          onTap: _selectImages,
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: AppTheme.gray400,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '사진 선택 (최대 6장)',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(8),
                          itemCount:
                              _selectedImages.length +
                              (_selectedImages.length < 6 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _selectedImages.length) {
                              // 추가 버튼
                              return GestureDetector(
                                onTap: _selectedImages.length < 6
                                    ? _selectImages
                                    : null,
                                child: Container(
                                  width: 80,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.gray300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: _selectedImages.length < 6
                                        ? AppTheme.gray400
                                        : AppTheme.gray300,
                                  ),
                                ),
                              );
                            }

                            // 선택된 이미지
                            return GestureDetector(
                              onTap: () => _selectSingleImage(index),
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: index == 0
                                        ? AppTheme.primaryColor
                                        : AppTheme.gray300,
                                    width: index == 0 ? 2 : 1,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: _buildImageWidget(
                                        _selectedImages[index],
                                      ),
                                    ),
                                    if (index == 0)
                                      Positioned(
                                        bottom: 2,
                                        left: 2,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            '프로필',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImages.removeAt(index);
                                          });
                                        },
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
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),

                // 전화번호
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: '전화번호',
                    prefixIcon: Icon(Icons.phone),
                    helperText: '01012345678 형식으로 입력해주세요',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '전화번호를 입력해주세요.';
                    }
                    if (!RegExp(r'^010[0-9]{8}$').hasMatch(value.trim())) {
                      return '올바른 전화번호 형식이 아닙니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 닉네임
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    prefixIcon: Icon(Icons.badge),
                    helperText: '10자 이내',
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

                // 생년월일
                TextFormField(
                  controller: _birthDateController,
                  decoration: const InputDecoration(
                    labelText: '생년월일',
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  readOnly: true,
                  onTap: _selectBirthDate,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '생년월일을 선택해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 성별 선택
                Text(
                  '성별',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('남성'),
                        value: '남',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('여성'),
                        value: '여',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 키
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: '키 (cm)',
                    prefixIcon: Icon(Icons.straighten),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '키를 입력해주세요.';
                    }
                    final height = int.tryParse(value.trim());
                    if (height == null || height < 140 || height > 220) {
                      return '140cm ~ 220cm 사이의 값을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 활동지역
                TextFormField(
                  controller: _activityAreaController,
                  decoration: const InputDecoration(
                    labelText: '활동지역',
                    prefixIcon: Icon(Icons.location_on),
                    helperText: '예: 강남구, 홍대, 건대 등',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '활동지역을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 자기소개
                TextFormField(
                  controller: _introductionController,
                  decoration: const InputDecoration(
                    labelText: '소개글',
                    prefixIcon: Icon(Icons.edit),
                    alignLabelWithHint: true,
                    helperText: '100자 이내',
                  ),
                  maxLines: 3,
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '소개글을 입력해주세요.';
                    }
                    if (value.trim().length < 10) {
                      return '소개글은 10자 이상 작성해주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // 완료 버튼
                Consumer<ProfileController>(
                  builder: (context, profileController, _) {
                    if (profileController.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        '프로필 완성하기',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),

                // 에러 메시지
                Consumer<ProfileController>(
                  builder: (context, profileController, _) {
                    if (profileController.errorMessage != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          profileController.errorMessage!,
                          style: const TextStyle(color: AppTheme.errorColor),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(XFile imageFile) {
    if (kIsWeb) {
      // 웹에서는 Image.network 또는 FutureBuilder 사용
      return FutureBuilder<Uint8List>(
        future: imageFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: 80,
              height: double.infinity,
              fit: BoxFit.cover,
            );
          } else {
            return Container(
              width: 80,
              height: 80,
              color: AppTheme.gray200,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
        },
      );
    } else {
      // 모바일에서는 XFile path로 이미지 표시
      return FutureBuilder<Uint8List>(
        future: imageFile.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              width: 80,
              height: double.infinity,
              fit: BoxFit.cover,
            );
          } else {
            return Container(
              width: 80,
              height: 80,
              color: AppTheme.gray200,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
        },
      );
    }
  }
}

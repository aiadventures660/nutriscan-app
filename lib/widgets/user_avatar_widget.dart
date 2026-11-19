import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';

class AvatarPreset {
  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final LinearGradient gradient;

  const AvatarPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.gradient,
  });
}

final List<AvatarPreset> kAvatarPresets = [
  const AvatarPreset(
    id: 'preset:salad',
    name: 'Nutri Green',
    emoji: '🥗',
    icon: Icons.eco_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF00E676), Color(0xFF00B368)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const AvatarPreset(
    id: 'preset:athlete',
    name: 'Active Runner',
    emoji: '🏃',
    icon: Icons.directions_run_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF00E5FF), Color(0xFF0091EA)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const AvatarPreset(
    id: 'preset:strength',
    name: 'Power Lifter',
    emoji: '💪',
    icon: Icons.fitness_center_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFFF9100), Color(0xFFFF3D00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const AvatarPreset(
    id: 'preset:zen',
    name: 'Mindful Zen',
    emoji: '🧘',
    icon: Icons.self_improvement_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFB388FF), Color(0xFF7C4DFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const AvatarPreset(
    id: 'preset:vitality',
    name: 'Heart Vitality',
    emoji: '❤️',
    icon: Icons.favorite_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFFFF4081), Color(0xFFF50057)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  const AvatarPreset(
    id: 'preset:chef',
    name: 'Superfoods',
    emoji: '🥑',
    icon: Icons.restaurant_rounded,
    gradient: LinearGradient(
      colors: [Color(0xFF1DE9B6), Color(0xFF00BFA5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];

AvatarPreset? getAvatarPreset(String? id) {
  if (id == null) return null;
  try {
    return kAvatarPresets.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
}

class UserAvatarWidget extends StatelessWidget {
  final String? photoPath;
  final String? userName;
  final double radius;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool showEditBadge;

  const UserAvatarWidget({
    super.key,
    this.photoPath,
    this.userName,
    this.radius = 24,
    this.onTap,
    this.showBorder = true,
    this.showEditBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final double diameter = radius * 2;
    final preset = getAvatarPreset(photoPath);

    Widget innerContent;
    if (preset != null) {
      innerContent = Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: preset.gradient,
        ),
        child: Center(
          child: Text(
            preset.emoji,
            style: TextStyle(
              fontSize: radius * 0.95,
            ),
          ),
        ),
      );
    } else if (photoPath != null && photoPath!.isNotEmpty) {
      if (photoPath!.startsWith('http://') || photoPath!.startsWith('https://')) {
        innerContent = CachedNetworkImage(
          imageUrl: photoPath!,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildFallbackInitial(diameter),
          errorWidget: (_, __, ___) => _buildFallbackInitial(diameter),
        );
      } else {
        final file = File(photoPath!);
        if (file.existsSync()) {
          innerContent = Image.file(
            file,
            width: diameter,
            height: diameter,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackInitial(diameter),
          );
        } else {
          innerContent = _buildFallbackInitial(diameter);
        }
      }
    } else {
      innerContent = _buildFallbackInitial(diameter);
    }

    Widget avatarCore = ClipOval(
      child: Container(
        width: diameter,
        height: diameter,
        color: AppTheme.cardBackground,
        child: innerContent,
      ),
    );

    Widget borderedAvatar = showBorder
        ? Container(
            padding: EdgeInsets.all(radius * 0.08 + 1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: preset != null
                  ? preset.gradient
                  : AppTheme.emeraldCyanGradient,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                  blurRadius: radius * 0.5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: avatarCore,
          )
        : avatarCore;

    if (!showEditBadge && onTap == null) {
      return borderedAvatar;
    }

    Widget completeWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        borderedAvatar,
        if (showEditBadge)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(radius * 0.18 + 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.backgroundDark,
                  width: 2,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.black,
                size: radius * 0.42,
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: completeWidget,
      );
    }

    return completeWidget;
  }

  Widget _buildFallbackInitial(double diameter) {
    String initial = 'N';
    if (userName != null && userName!.trim().isNotEmpty) {
      initial = userName!.trim().substring(0, 1).toUpperCase();
    }

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.primaryGradient,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: diameter * 0.45,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

Future<void> showPhotoPickerSheet(
  BuildContext context,
  AppStateProvider provider,
) async {
  HapticFeedback.lightImpact();

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (modalContext) {
      return SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: GlassCard(
            borderRadius: BorderRadius.circular(28),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                final currentPhoto = provider.userPhotoPath;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle pill
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile Photo',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose your photo or personal avatar',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Current Avatar Preview
                    Center(
                      child: UserAvatarWidget(
                        photoPath: currentPhoto,
                        userName: provider.userProfileName,
                        radius: 46,
                        showEditBadge: false,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Camera / Gallery / Remove Action Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerActionTile(
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            color: AppTheme.primaryGreen,
                            onTap: () async {
                              Navigator.pop(modalContext);
                              await _pickImageFromSource(context, provider, ImageSource.camera);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPickerActionTile(
                            icon: Icons.photo_library_rounded,
                            label: 'Gallery',
                            color: AppTheme.macroCarbs,
                            onTap: () async {
                              Navigator.pop(modalContext);
                              await _pickImageFromSource(context, provider, ImageSource.gallery);
                            },
                          ),
                        ),
                        if (currentPhoto != null) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPickerActionTile(
                              icon: Icons.delete_outline_rounded,
                              label: 'Remove',
                              color: AppTheme.errorRed,
                              onTap: () async {
                                try {
                                  final clerkAuth = ClerkAuth.of(context, listen: false);
                                  if (clerkAuth.user != null) {
                                    await clerkAuth.deleteUserImage();
                                  }
                                } catch (e) {
                                  debugPrint('Clerk avatar delete notice: $e');
                                }
                                await provider.setUserPhoto(null);
                                setModalState(() {});
                                if (context.mounted) {
                                  Navigator.pop(modalContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Photo removed. Using initials avatar.'),
                                      backgroundColor: AppTheme.cardBackground,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Fitness Avatars Presets
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Or Choose an Avatar',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: kAvatarPresets.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final preset = kAvatarPresets[index];
                          final isSelected = currentPhoto == preset.id;

                          return GestureDetector(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await provider.setUserPhoto(preset.id);
                              setModalState(() {});
                              if (context.mounted) {
                                Navigator.pop(modalContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Updated avatar to "${preset.name}"! ${preset.emoji}'),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                              }
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: preset.gradient,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: isSelected ? 2.5 : 0,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      preset.emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  preset.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? AppTheme.primaryGreen
                                        : AppTheme.textSecondary,
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildPickerActionTile({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      onTap();
    },
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _pickImageFromSource(
  BuildContext context,
  AppStateProvider provider,
  ImageSource source,
) async {
  try {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'user_avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

      await provider.setUserPhoto(savedImage.path);

      // Requirement 6: Update Clerk profile picture via SDK
      if (context.mounted) {
        try {
          final clerkAuth = ClerkAuth.of(context, listen: false);
          if (clerkAuth.user != null) {
            await clerkAuth.updateUserImage(savedImage);
            if (clerkAuth.user?.imageUrl != null) {
              await provider.setUserPhoto(clerkAuth.user!.imageUrl);
            }
          }
        } catch (e) {
          debugPrint('Clerk avatar update notice: $e');
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Profile photo updated successfully! 📸'),
              ],
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update photo: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}

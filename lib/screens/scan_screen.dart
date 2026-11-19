import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/app_state_provider.dart';
import '../services/ai_service.dart';
import '../config/app_theme.dart';
import '../widgets/animated_components.dart';
import '../widgets/nutri_loading_indicator.dart';
import 'scan_results_screen.dart';

enum ScanMode { vision, barcode, voice }

class ScanScreen extends StatefulWidget {
  final ScanMode initialMode;
  const ScanScreen({super.key, this.initialMode = ScanMode.vision});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final bool _isLoading = false;
  bool _isFlashOn = false;
  late ScanMode _currentScanMode;
  final ImagePicker _imagePicker = ImagePicker();
  final AIService _aiService = AIService();
  late AnimationController _laserAnimController;
  late AnimationController _modeSwitchController;
  late Animation<double> _modeSwitchAnim;

  @override
  void initState() {
    super.initState();
    _currentScanMode = widget.initialMode;

    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _modeSwitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );

    _modeSwitchAnim = CurvedAnimation(
      parent: _modeSwitchController,
      curve: Curves.easeOut,
    );

    _initializeCamera();
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    _modeSwitchController.dispose();
    _modeSwitchController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _toggleFlash() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        _isFlashOn = !_isFlashOn;
        await _cameraController!.setFlashMode(
          _isFlashOn ? FlashMode.torch : FlashMode.off,
        );
        setState(() {});
      } catch (e) {
        debugPrint('Error toggling flash: $e');
      }
    }
  }

  void _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      try {
        await _cameraController?.dispose();
        final currentCameraIndex =
            _cameras!.indexOf(_cameraController!.description);
        final newCameraIndex = (currentCameraIndex + 1) % _cameras!.length;
        _cameraController = CameraController(
          _cameras![newCameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        setState(() {});
      } catch (e) {
        debugPrint('Error switching camera: $e');
      }
    }
  }

  void _switchMode(ScanMode mode) {
    if (mode == _currentScanMode) return;
    _modeSwitchController.forward(from: 0.0);
    setState(() => _currentScanMode = mode);
    if (mode == ScanMode.voice) {
      Future.delayed(const Duration(milliseconds: 150), _showVoiceInputDialog);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? _buildLoadingView()
          : _isCameraInitialized
              ? _buildCameraView()
              : _buildNoCameraView(),
    );
  }

  Widget _buildLoadingView() {
    return const SafeArea(
      child: AIAnalyzingRadar(
        statusText: 'Analyzing Food with Gemini AI...',
        subtitleText:
            'Detecting nutrients, ingredients, allergens & NOVA rating',
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CAMERA VIEW (main layout)
  // ─────────────────────────────────────────────
  Widget _buildCameraView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Full-screen camera preview ──
        CameraPreview(_cameraController!),

        // ── Top gradient scrim ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.80),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Bottom gradient scrim ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 220,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.92),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // ── Top header (frosted glass) ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _buildTopHeader(),
          ),
        ),

        // ── Mode Selector Bar ──
        Positioned(
          top: MediaQuery.of(context).padding.top + 68,
          left: 24,
          right: 24,
          child: _buildModeSelectorBar(),
        ),

        // ── Viewfinder overlay ──
        AnimatedBuilder(
          animation: _modeSwitchAnim,
          builder: (context, child) => Opacity(
            opacity: _modeSwitchAnim.value,
            child: child,
          ),
          child: _currentScanMode == ScanMode.vision
              ? _buildVisionTargetOverlay()
              : _currentScanMode == ScanMode.barcode
                  ? _buildBarcodeTargetOverlay()
                  : _buildVoiceTargetOverlay(),
        ),

        // ── Bottom controls (frosted glass) ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildBottomControls(),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // TOP HEADER — Frosted Glass
  // ─────────────────────────────────────────────
  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                // Back button
                _buildGlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),

                // Title block
                const Expanded(
                  child: Center(
                    child: Text(
                      'AI Scanner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Camera switch button
                _buildGlassIconButton(
                  icon: Icons.flip_camera_ios_rounded,
                  onTap: _switchCamera,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return BouncingWidget(
      onTap: onTap,
      scaleFactor: 0.88,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MODE SELECTOR BAR — Frosted Glass + Animated Pill
  // ─────────────────────────────────────────────
  Widget _buildModeSelectorBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              _buildModePill(
                  ScanMode.vision, Icons.camera_enhance_rounded, 'Vision'),
              _buildModePill(
                  ScanMode.barcode, Icons.qr_code_scanner_rounded, 'Barcode'),
              _buildModePill(ScanMode.voice, Icons.mic_rounded, 'Voice'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModePill(ScanMode mode, IconData icon, String label) {
    final isSelected = _currentScanMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.primaryGreen.withValues(alpha: 0.80),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.40),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 5),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // VISION VIEWFINDER — Animated corner brackets + laser
  // ─────────────────────────────────────────────
  Widget _buildVisionTargetOverlay() {
    const double frameSize = 268;
    return Center(
      child: SizedBox(
        width: frameSize,
        height: frameSize,
        child: Stack(
          children: [
            // Corner bracket painter
            CustomPaint(
              size: const Size(frameSize, frameSize),
              painter: _CornerBracketPainter(
                color: AppTheme.primaryGreen,
                strokeWidth: 3.5,
                cornerLength: 32,
                radius: 14,
              ),
            ),

            // Animated laser scan line
            AnimatedBuilder(
              animation: _laserAnimController,
              builder: (context, _) {
                final t = _laserAnimController.value;
                final top = 10 + t * (frameSize - 20);
                return Positioned(
                  top: top,
                  left: 12,
                  right: 12,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.primaryGreen.withValues(alpha: 0.6),
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreen.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BARCODE VIEWFINDER
  // ─────────────────────────────────────────────
  Widget _buildBarcodeTargetOverlay() {
    const double frameW = 290;
    const double frameH = 160;
    return Center(
      child: SizedBox(
        width: frameW,
        height: frameH,
        child: Stack(
          children: [
            const CustomPaint(
              size: Size(frameW, frameH),
              painter: _CornerBracketPainter(
                color: Color(0xFF06B6D4),
                strokeWidth: 3.5,
                cornerLength: 28,
                radius: 10,
              ),
            ),
            AnimatedBuilder(
              animation: _laserAnimController,
              builder: (context, _) {
                final t = _laserAnimController.value;
                final top = 8 + t * (frameH - 16);
                return Positioned(
                  top: top,
                  left: 10,
                  right: 10,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF06B6D4).withValues(alpha: 0.6),
                          const Color(0xFF06B6D4),
                          const Color(0xFF06B6D4).withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // VOICE TARGET OVERLAY
  // ─────────────────────────────────────────────
  Widget _buildVoiceTargetOverlay() {
    return Center(
      child: PulsingGlow(
        glowColor: AppTheme.primaryGreen,
        minSpread: 2.0,
        maxSpread: 10.0,
        minBlur: 16.0,
        maxBlur: 32.0,
        child: BouncingWidget(
          onTap: _showVoiceInputDialog,
          scaleFactor: 0.90,
          child: Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryGreen.withValues(alpha: 0.30),
                  AppTheme.primaryGreen.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
            ),
            child: Center(
              child: Icon(
                Icons.mic_rounded,
                color: AppTheme.primaryGreen,
                size: 56,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM CONTROLS — Frosted Glass Panel
  // ─────────────────────────────────────────────
  Widget _buildBottomControls() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            28,
            18,
            28,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.50),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: _buildBottomControlChildren(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBottomControlChildren() {
    if (_currentScanMode == ScanMode.vision) {
      return [
        _buildRoundedControlButton(
          icon: Icons.photo_library_outlined,
          label: 'Gallery',
          onPressed: _pickFromGallery,
        ),
        _buildMainCaptureButton(
          glowColor: AppTheme.primaryGreen,
          icon: Icons.camera_alt_rounded,
          onTap: _capturePhoto,
        ),
        _buildRoundedControlButton(
          icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          label: 'Flash',
          onPressed: _toggleFlash,
          activeColor: _isFlashOn ? AppTheme.accentAmber : null,
        ),
      ];
    } else if (_currentScanMode == ScanMode.barcode) {
      return [
        _buildRoundedControlButton(
          icon: Icons.pin_rounded,
          label: 'Enter Digits',
          onPressed: _showBarcodeInputDialog,
        ),
        _buildMainCaptureButton(
          glowColor: const Color(0xFF06B6D4),
          icon: Icons.qr_code_scanner_rounded,
          onTap: _capturePhoto,
          gradientColors: const [Color(0xFF06B6D4), Color(0xFF0284C7)],
        ),
        _buildRoundedControlButton(
          icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          label: 'Flash',
          onPressed: _toggleFlash,
          activeColor: _isFlashOn ? AppTheme.accentAmber : null,
        ),
      ];
    } else {
      return [
        _buildRoundedControlButton(
          icon: Icons.edit_note_rounded,
          label: 'Type Text',
          onPressed: _showVoiceInputDialog,
        ),
        _buildMainCaptureButton(
          glowColor: AppTheme.primaryGreen,
          icon: Icons.mic_rounded,
          onTap: _showVoiceInputDialog,
        ),
        _buildRoundedControlButton(
          icon: Icons.photo_library_outlined,
          label: 'Gallery',
          onPressed: _pickFromGallery,
        ),
      ];
    }
  }

  Widget _buildMainCaptureButton({
    required Color glowColor,
    required IconData icon,
    required VoidCallback onTap,
    List<Color>? gradientColors,
  }) {
    final colors =
        gradientColors ?? [AppTheme.primaryGreen, const Color(0xFF00A86B)];
    return PulsingGlow(
      glowColor: glowColor,
      minSpread: 1.0,
      maxSpread: 8.0,
      minBlur: 14.0,
      maxBlur: 28.0,
      child: BouncingWidget(
        onTap: onTap,
        scaleFactor: 0.88,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(color: Colors.white, width: 3.5),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black, size: 34),
        ),
      ),
    );
  }

  Widget _buildRoundedControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? activeColor,
  }) {
    return BouncingWidget(
      onTap: onPressed,
      scaleFactor: 0.90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: activeColor != null
                  ? activeColor.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: activeColor != null
                    ? activeColor.withValues(alpha: 0.50)
                    : Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Icon(
              icon,
              color: activeColor ?? Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: activeColor ?? Colors.white.withValues(alpha: 0.70),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // NO CAMERA FALLBACK VIEW
  // ─────────────────────────────────────────────
  Widget _buildNoCameraView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.textPrimary, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  'Food Scanner & Logger',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt_outlined,
                  color: AppTheme.primaryGreen, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Choose How to Log Your Food',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a photo from gallery, enter a barcode, or speak your meal',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 28),
            _buildFallbackOptionCard(
              title: 'Gallery Photo',
              desc: 'Select image from your photo library',
              color: AppTheme.primaryGreen,
              onTap: _pickFromGallery,
            ),
            const SizedBox(height: 14),
            _buildFallbackOptionCard(
              title: 'Barcode Lookup',
              desc: 'Scan or enter product barcode',
              color: AppTheme.accentCyan,
              onTap: _showBarcodeInputDialog,
            ),
            const SizedBox(height: 14),
            _buildFallbackOptionCard(
              title: 'Voice & Text',
              desc: 'Describe what you ate or drank',
              color: AppTheme.accentAmber,
              onTap: _showVoiceInputDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackOptionCard({
    required String title,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ACTIONS & DIALOGS
  // ─────────────────────────────────────────────
  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile photo = await _cameraController!.takePicture();
      await _processImage(File(photo.path), photo.path);
    } catch (e) {
      debugPrint('Error capturing photo: $e');
      _showErrorDialog('Failed to capture photo. Please try again.');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (photo != null) {
        await _processImage(File(photo.path), photo.path);
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      _showErrorDialog('Failed to pick image from gallery.');
    }
  }

  Future<void> _processImage(File imageFile, String imagePath) async {
    _showProcessingDialog('Analyzing food macros, NOVA group & additives...');

    try {
      final scanData = await _aiService.analyzeFoodImage(imageFile, imagePath);
      if (mounted) {
        Navigator.of(context).pop();
        context.read<AppStateProvider>().setCurrentScanData(scanData);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ScanResultsScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Food analysis failed: $e');
      }
    }
  }

  Future<void> _processBarcode(String barcode) async {
    _showProcessingDialog(
        'Looking up barcode in OpenFoodFacts & Gemini database...');

    try {
      final scanData = await _aiService.fetchBarcodeFood(barcode);
      if (mounted) {
        Navigator.of(context).pop();
        if (scanData != null) {
          context.read<AppStateProvider>().setCurrentScanData(scanData);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ScanResultsScreen()),
          );
        } else {
          _showErrorDialog('Product not found for barcode: $barcode');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Could not retrieve barcode details: $e');
      }
    }
  }

  Future<void> _processVoiceMeal(String description) async {
    final activeModelName =
        context.read<AppStateProvider>().activeModelInfo.displayName;
    _showProcessingDialog(
        '$activeModelName is parsing food components & calculating macros...');

    try {
      final scanData = await _aiService.parseNaturalLanguageMeal(description);
      if (mounted) {
        Navigator.of(context).pop();
        context.read<AppStateProvider>().setCurrentScanData(scanData);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ScanResultsScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog('Could not parse meal description: $e');
      }
    }
  }

  void _showBarcodeInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code_rounded, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text('Enter Barcode Digits',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. 3017620422003',
                hintStyle: TextStyle(color: AppTheme.textTertiary),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen),
            onPressed: () {
              final code = controller.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) _processBarcode(code);
            },
            child: const Text('Search',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showVoiceInputDialog() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mic, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  'Natural Language Meal Logger',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Describe your meal and Gemini AI will calculate exact calories, protein, carbs and fats.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 2,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText:
                    'e.g., Avocado toast on sourdough with 2 poached eggs and an iced matcha latte',
                hintStyle:
                    TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: 'Analyze Meal with AI',
                icon: Icons.auto_awesome,
                onPressed: () {
                  final text = controller.text.trim();
                  Navigator.pop(ctx);
                  if (text.isNotEmpty) _processVoiceMeal(text);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const NutriLoadingIndicator(size: 110),
            const SizedBox(height: 16),
            Text(
              'Processing Food Intelligence...',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text('Notice', style: TextStyle(color: AppTheme.textPrimary)),
          content:
              Text(message, style: TextStyle(color: AppTheme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK', style: TextStyle(color: AppTheme.primaryGreen)),
            ),
          ],
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────
// CORNER BRACKET PAINTER
// ─────────────────────────────────────────────
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double radius;

  const _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final glow = Paint()
      ..color = color.withValues(alpha: 0.30)
      ..strokeWidth = strokeWidth + 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final double w = size.width;
    final double h = size.height;
    final double r = radius;
    final double cl = cornerLength;

    // Draw glow then solid — four corners
    for (final p in [glow, paint]) {
      // Top-left
      canvas.drawPath(
        Path()
          ..moveTo(0, cl + r)
          ..lineTo(0, r)
          ..arcToPoint(Offset(r, 0),
              radius: Radius.circular(r), clockwise: true)
          ..lineTo(cl + r, 0),
        p,
      );
      // Top-right
      canvas.drawPath(
        Path()
          ..moveTo(w - cl - r, 0)
          ..lineTo(w - r, 0)
          ..arcToPoint(Offset(w, r),
              radius: Radius.circular(r), clockwise: false)
          ..lineTo(w, cl + r),
        p,
      );
      // Bottom-right
      canvas.drawPath(
        Path()
          ..moveTo(w, h - cl - r)
          ..lineTo(w, h - r)
          ..arcToPoint(Offset(w - r, h),
              radius: Radius.circular(r), clockwise: false)
          ..lineTo(w - cl - r, h),
        p,
      );
      // Bottom-left
      canvas.drawPath(
        Path()
          ..moveTo(cl + r, h)
          ..lineTo(r, h)
          ..arcToPoint(Offset(0, h - r),
              radius: Radius.circular(r), clockwise: false)
          ..lineTo(0, h - cl - r),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerBracketPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.cornerLength != cornerLength;
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:clerk_auth/clerk_auth.dart' as clerk;
import 'package:clerk_flutter/clerk_flutter.dart';
import '../config/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../services/storage_service.dart';
import '../services/api_client.dart';
import '../widgets/animated_components.dart';
import '../widgets/nutri_loading_indicator.dart';
import 'enhanced_home_screen.dart';

class ClerkAuthScreen extends StatefulWidget {
  final bool isRedirectAfterLogout;

  const ClerkAuthScreen({
    super.key,
    this.isRedirectAfterLogout = false,
  });

  /// Tracks whether ClerkAuthScreen is currently mounted and active.
  /// Used by global ClerkErrorListener to prevent displaying duplicate SnackBars.
  static bool isScreenActive = false;

  /// Public error parser used across the app
  static String parseClerkError(dynamic error) =>
      _ClerkAuthScreenState.parseClerkError(error);

  @override
  State<ClerkAuthScreen> createState() => _ClerkAuthScreenState();
}

class _ClerkAuthScreenState extends State<ClerkAuthScreen>
    with TickerProviderStateMixin {
  // Mode toggle
  bool _isSignUpMode = false;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  // Options & Flags
  bool _rememberMe = true;
  bool _termsAccepted = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isHandlingSuccess = false;

  // Animations
  late final AnimationController _entranceAnimController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _slideAnimation;

  late final AnimationController _arrowAnimController;
  late final Animation<double> _arrowSlideAnimation;

  @override
  void initState() {
    super.initState();
    ClerkAuthScreen.isScreenActive = true;

    // 1. Entrance animation
    _entranceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceAnimController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _entranceAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entranceAnimController.forward();

    // 2. Continuous gentle arrow hover animation
    _arrowAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    _arrowSlideAnimation = Tween<double>(begin: -1.0, end: 5.0).animate(
      CurvedAnimation(
        parent: _arrowAnimController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 3. Load remembered email & preference
    _loadRememberedData();

    // 4. Focus node listeners for dynamic outline refresh
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _nameFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  Future<void> _loadRememberedData() async {
    final storage = StorageService();
    final remember = await storage.getRememberMe();
    final savedEmail = await storage.getRememberedEmail();
    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _emailController.text = savedEmail;
        }
      });
    }
  }

  @override
  void dispose() {
    ClerkAuthScreen.isScreenActive = false;
    _entranceAnimController.dispose();
    _arrowAnimController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  static String _parseClerkError(dynamic error) => parseClerkError(error);

  static String parseClerkError(dynamic error) {
    String clean(String str) {
      final sanitized = str
          .replaceAll(' (ERROR RECEIVED FROM SERVER)', '')
          .replaceAll(' (EXTERNAL ERROR)', '')
          .replaceAll('{arg}', '')
          .trim();
      if (sanitized.contains('older sign in') ||
          sanitized.contains('cannot_be_updated') ||
          sanitized.contains('already_completed')) {
        return 'Session expired. Please sign in again.';
      }
      return sanitized;
    }

    if (error is clerk.ApiResponse) {
      return clean(error.errorCollection.errorMessage);
    }
    try {
      final msg = (error as dynamic).errorMessage;
      if (msg is String && msg.isNotEmpty) return clean(msg);
    } catch (_) {}
    try {
      final msg = (error as dynamic).fullMessage;
      if (msg is String && msg.isNotEmpty) return clean(msg);
    } catch (_) {}
    if (error is clerk.ClerkError) {
      if (error.argument != null && error.argument!.trim().isNotEmpty) {
        return clean(error.argument!);
      }
      if (error.errors?.errors?.isNotEmpty == true) {
        final first = error.errors!.errors!.first;
        if (first.message.isNotEmpty) return clean(first.message);
      }
      return clean(error.toString());
    }
    return clean(error.toString().replaceAll('Exception: ', ''));
  }

  // ===========================================================================
  // Clerk Authentication Handlers
  // ===========================================================================

  Future<void> _handleAuthSuccess(ClerkAuthState authState) async {
    if (_isHandlingSuccess) return;
    _isHandlingSuccess = true;

    final user = authState.user;
    if (user == null) {
      _isHandlingSuccess = false;
      return;
    }

    HapticFeedback.mediumImpact();
    final provider = context.read<AppStateProvider>();
    final storageService = StorageService();

    final emails = user.emailAddresses;
    final primaryEmail = (emails != null && emails.isNotEmpty)
        ? emails.first.emailAddress
        : null;

    final displayName = user.firstName != null
        ? '${user.firstName} ${user.lastName ?? ''}'.trim()
        : user.username;

    // Save Remember Me settings
    await storageService.setRememberMe(_rememberMe);
    if (_rememberMe && primaryEmail != null) {
      await storageService.setRememberedEmail(primaryEmail);
    }

    // Configure dynamic token provider to guarantee fresh JWT for all backend API calls
    ApiClient().setTokenProvider(() async {
      try {
        final token = await authState.sessionToken();
        return token.jwt;
      } catch (_) {
        return authState.session?.lastActiveToken?.jwt;
      }
    });

    try {
      final token = await authState.sessionToken();
      if (token.jwt.isNotEmpty) {
        ApiClient().setSessionToken(token.jwt);
      }
    } catch (_) {
      final jwt = authState.session?.lastActiveToken?.jwt;
      if (jwt != null && jwt.isNotEmpty) {
        ApiClient().setSessionToken(jwt);
      }
    }

    // Automatically restore authenticated user data from Supabase
    await provider.restoreUserDataFromBackend(
      clerkId: user.id,
      fallbackEmail: primaryEmail,
      fallbackName: displayName,
      photoUrl: user.imageUrl,
    );

    await storageService.setOnboardingComplete();
    await storageService.setProfileSetupComplete(true);
    await storageService.setClerkAuthenticated(true);
    await storageService.setClerkUserId(user.id);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const EnhancedHomeScreen(),
        transitionsBuilder: (context, anim, secAnim, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
      (route) => false,
    );
  }

  Future<void> _handleLogin(ClerkAuthState authState) async {
    _clearError();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      // If password is not provided, proceed directly to Passwordless / Email OTP Sign-In
      if (password.isEmpty) {
        final res = await authState.fetchApiResponse(
          '/client/sign_ins',
          params: {'identifier': email},
        );
        if (res.isError) {
          _showError(_parseClerkError(res.errorCollection));
          return;
        }
        final signIn = authState.client.signIn;
        if (signIn != null && signIn.status.needsFactor) {
          final stage = signIn.needsSecondFactor
              ? clerk.Stage.second
              : clerk.Stage.first;
          final availableFactors = signIn.factorsFor(stage);
          final emailFactor = availableFactors
              .where((f) => f.strategy == clerk.Strategy.emailCode)
              .firstOrNull;

          if (emailFactor?.emailAddressId != null) {
            final prepRes = await authState.fetchApiResponse(
              '/client/sign_ins/${signIn.id}/prepare_${stage.name}_factor',
              params: {
                'strategy': clerk.Strategy.emailCode.name,
                'email_address_id': emailFactor!.emailAddressId,
              },
            );
            if (prepRes.isError) {
              _showError(_parseClerkError(prepRes.errorCollection));
              return;
            }
          } else {
            await authState.attemptSignIn(
              strategy: clerk.Strategy.emailCode,
              identifier: email,
            );
          }
          if (mounted) {
            _showVerificationDialog(authState, isSignIn: true);
          }
        } else {
          _showError('Unable to send verification code. Please check your email.');
        }
        return;
      }

      // Handle password authentication with proactive and reactive stale-sign-in recovery
      bool freshSignInUsed = false;
      final existingSignIn = authState.client.signIn;
      if (existingSignIn != null) {
        if (existingSignIn.status != clerk.Status.complete &&
            existingSignIn.firstFactorVerification?.status != null) {
          debugPrint('🔄 Stale factor on client.signIn detected. Starting fresh sign-in...');
          final freshRes = await authState.fetchApiResponse(
            '/client/sign_ins',
            params: {
              'identifier': email,
              'password': password,
            },
          );
          if (freshRes.isError) {
            final err = parseClerkError(freshRes.errorCollection);
            if (freshRes.errorCollection.errors?.any((e) => e.code == 'form_identifier_not_found') == true) {
              _showError('No account found for this email. Switched to Sign Up to create your account.');
              setState(() => _isSignUpMode = true);
            } else if (freshRes.errorCollection.errors?.any((e) => e.code == 'form_password_incorrect') == true) {
              _showError('Incorrect password. Clear password to sign in via Email OTP, or tap Forgot Password.');
            } else {
              _showError(err);
            }
            return;
          }
          authState.update();
          freshSignInUsed = true;
        }
      }

      if (!freshSignInUsed) {
        try {
          await authState.attemptSignIn(
            strategy: clerk.Strategy.password,
            identifier: email,
            password: password,
          );
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          if (errStr.contains('older sign in') ||
              errStr.contains('cannot_be_updated') ||
              errStr.contains('already_completed')) {
            debugPrint('🔄 Stale sign-in error ($e). Retrying with fresh sign-in...');
            final freshRes = await authState.fetchApiResponse(
              '/client/sign_ins',
              params: {
                'identifier': email,
                'password': password,
              },
            );
            if (freshRes.isError) {
              final err = parseClerkError(freshRes.errorCollection);
              if (freshRes.errorCollection.errors?.any((e) => e.code == 'form_identifier_not_found') == true) {
                _showError('No account found for this email. Switched to Sign Up to create your account.');
                setState(() => _isSignUpMode = true);
              } else if (freshRes.errorCollection.errors?.any((e) => e.code == 'form_password_incorrect') == true) {
                _showError('Incorrect password. Clear password to sign in via Email OTP, or tap Forgot Password.');
              } else {
                _showError(err);
              }
              return;
            }
            authState.update();
          } else {
            rethrow;
          }
        }
      }

      if (authState.isSignedIn) {
        await _handleAuthSuccess(authState);
      } else {
        final signIn = authState.client.signIn;
        if (signIn != null && signIn.status.needsFactor) {
          // Prepare and send the factor code to user email
          bool prepSuccess = false;
          try {
            final stage = signIn.needsSecondFactor
                ? clerk.Stage.second
                : clerk.Stage.first;
            final availableFactors = signIn.factorsFor(stage);
            final emailFactor = availableFactors
                .where((f) => f.strategy == clerk.Strategy.emailCode)
                .firstOrNull;

            if (emailFactor?.emailAddressId != null) {
              final prepRes = await authState.fetchApiResponse(
                '/client/sign_ins/${signIn.id}/prepare_${stage.name}_factor',
                params: {
                  'strategy': clerk.Strategy.emailCode.name,
                  'email_address_id': emailFactor!.emailAddressId,
                },
              );
              if (prepRes.isError) {
                _showError(_parseClerkError(prepRes.errorCollection));
                return;
              }
              prepSuccess = true;
            } else {
              final strategyToPrepare = emailFactor?.strategy ??
                  (availableFactors.isNotEmpty
                      ? availableFactors.first.strategy
                      : clerk.Strategy.emailCode);
              await authState.attemptSignIn(
                strategy: strategyToPrepare,
                identifier: email,
              );
              prepSuccess = true;
            }
          } catch (prepErr) {
            debugPrint('Error while preparing emailCode signin: $prepErr');
            _showError(_parseClerkError(prepErr));
            return;
          }
          if (mounted && prepSuccess) {
            _showVerificationDialog(authState, isSignIn: true);
          }
        } else {
          _showError(
              'Unable to complete login. Please check your credentials.');
        }
      }
    } on clerk.ClerkError catch (e) {
      final code = e.errors?.errors?.firstOrNull?.code;
      if (code == 'form_identifier_not_found') {
        _showError('No account found for this email. Switched to Sign Up to create your account.');
        setState(() => _isSignUpMode = true);
      } else if (code == 'form_password_incorrect') {
        _showError('Incorrect password. Clear password to sign in via Email OTP, or tap Forgot Password.');
      } else {
        _showError(_parseClerkError(e));
      }
    } catch (e) {
      _showError(_parseClerkError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp(ClerkAuthState authState) async {
    _clearError();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (email.isEmpty) {
      _showError('Please enter your email address.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter a password.');
      return;
    }
    if (password.length < 8) {
      _showError('Password must be at least 8 characters long.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }
    if (!_termsAccepted) {
      _showError('Please accept the Terms of Service to continue.');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final nameParts = name.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : null;
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : null;

      await authState.attemptSignUp(
        strategy: clerk.Strategy.password,
        emailAddress: email,
        password: password,
        passwordConfirmation: confirmPassword,
        firstName: firstName,
        lastName: lastName,
      );

      if (authState.isSignedIn) {
        await _handleAuthSuccess(authState);
      } else {
        // Send email verification code
        bool prepSuccess = false;
        try {
          final signUp = authState.client.signUp;
          if (signUp != null) {
            final prepRes = await authState.fetchApiResponse(
              '/client/sign_ups/${signUp.id}/prepare_verification',
              params: {
                'strategy': clerk.Strategy.emailCode.name,
              },
            );
            if (prepRes.isError) {
              _showError(_parseClerkError(prepRes.errorCollection));
              return;
            }
            prepSuccess = true;
          } else {
            await authState.attemptSignUp(strategy: clerk.Strategy.emailCode);
            prepSuccess = true;
          }
        } catch (prepErr) {
          debugPrint('Error while preparing emailCode signup: $prepErr');
          _showError(_parseClerkError(prepErr));
          return;
        }
        if (mounted && prepSuccess) {
          _showVerificationDialog(authState, isSignIn: false);
        }
      }
    } on clerk.ClerkError catch (e) {
      final code = e.errors?.errors?.firstOrNull?.code;
      if (code == 'form_identifier_exists') {
        _showError('This email is already registered! Switched to Sign In — please enter your password.');
        setState(() => _isSignUpMode = false);
      } else {
        _showError(_parseClerkError(e));
      }
    } catch (e) {
      _showError(_parseClerkError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn(ClerkAuthState authState) async {
    _clearError();
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      if (_isSignUpMode) {
        await authState.ssoSignUp(context, clerk.Strategy.oauthGoogle);
      } else {
        await authState.ssoSignIn(context, clerk.Strategy.oauthGoogle);
      }

      if (authState.isSignedIn) {
        await _handleAuthSuccess(authState);
      }
    } on clerk.ClerkError catch (e) {
      _showError(_parseClerkError(e));
    } catch (e) {
      _showError(_parseClerkError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFacebookSignIn(ClerkAuthState authState) async {
    _clearError();
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      if (_isSignUpMode) {
        await authState.ssoSignUp(context, clerk.Strategy.oauthFacebook);
      } else {
        await authState.ssoSignIn(context, clerk.Strategy.oauthFacebook);
      }

      if (authState.isSignedIn) {
        await _handleAuthSuccess(authState);
      }
    } on clerk.ClerkError catch (e) {
      _showError(_parseClerkError(e));
    } catch (e) {
      _showError(_parseClerkError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    HapticFeedback.lightImpact();
    final storageService = StorageService();
    await storageService.setOnboardingComplete();
    await storageService.setProfileSetupComplete(true);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const EnhancedHomeScreen(),
        transitionsBuilder: (context, anim, secAnim, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
    );
  }

  // ===========================================================================
  // Dialogs: Verification Code & Forgot Password
  // ===========================================================================

  void _showVerificationDialog(ClerkAuthState authState,
      {required bool isSignIn}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _EmailVerificationSheet(
        authState: authState,
        isSignIn: isSignIn,
        email: _emailController.text.trim(),
        onSuccess: (verifiedAuthState) {
          _handleAuthSuccess(verifiedAuthState);
        },
      ),
    );
  }

  void _showForgotPasswordSheet(ClerkAuthState authState) {
    final resetEmailController =
        TextEditingController(text: _emailController.text.trim());
    final codeController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool codeSent = false;
    bool isResetting = false;
    String? resetError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Theme(
        data: AppTheme.lightTheme.copyWith(
          scaffoldBackgroundColor: Colors.white,
          canvasColor: Colors.white,
          cardColor: Colors.white,
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      codeSent ? 'Enter New Password' : 'Reset Password',
                      style: const TextStyle(
                        color: Color(0xFF0F1A14),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      codeSent
                          ? 'Enter the code from your email and your new password.'
                          : 'Enter your email to receive a password reset code.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (resetError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          resetError!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 12),
                        ),
                      ),
                    ],
                    if (!codeSent) ...[
                      _buildPillTextField(
                        controller: resetEmailController,
                        hintText: 'Enter your email address',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 22),
                      _buildGradientActionButton(
                      title: 'Send Reset Code',
                      isLoading: isResetting,
                      onTap: () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty) return;

                        setSheetState(() {
                          isResetting = true;
                          resetError = null;
                        });

                        try {
                          await authState.initiatePasswordReset(
                            identifier: email,
                            strategy: clerk.Strategy.resetPasswordEmailCode,
                          );
                          setSheetState(() {
                            codeSent = true;
                            isResetting = false;
                          });
                        } on clerk.ClerkError catch (e) {
                          setSheetState(() {
                            resetError = _parseClerkError(e);
                            isResetting = false;
                          });
                        } catch (e) {
                          setSheetState(() {
                            resetError = _parseClerkError(e);
                            isResetting = false;
                          });
                        }
                      },
                    ),
                  ] else ...[
                    _buildPillTextField(
                      controller: codeController,
                      hintText: '6-digit reset code',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    _buildPillTextField(
                      controller: newPasswordController,
                      hintText: 'New password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    const SizedBox(height: 22),
                    _buildGradientActionButton(
                      title: 'Update Password',
                      isLoading: isResetting,
                      onTap: () async {
                        final code = codeController.text.trim();
                        final newPassword = newPasswordController.text;
                        if (code.isEmpty || newPassword.isEmpty) return;

                        setSheetState(() {
                          isResetting = true;
                          resetError = null;
                        });

                        try {
                          await authState.attemptSignIn(
                            strategy: clerk.Strategy.resetPasswordEmailCode,
                            identifier: resetEmailController.text.trim(),
                            password: newPassword,
                            code: code,
                          );

                          if (authState.isSignedIn) {
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            await _handleAuthSuccess(authState);
                          } else {
                            setSheetState(() {
                              resetError =
                                  'Failed to reset password. Please check your code.';
                              isResetting = false;
                            });
                          }
                        } on clerk.ClerkError catch (e) {
                          setSheetState(() {
                            resetError = _parseClerkError(e);
                            isResetting = false;
                          });
                        } catch (e) {
                          setSheetState(() {
                            resetError = _parseClerkError(e);
                            isResetting = false;
                          });
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

  // ===========================================================================
  // UI Builder & Components (Matching Reference Image)
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF9FAF9),
        canvasColor: Colors.white,
        cardColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: const Color(0xFFF9FAF9),
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFFF9FAF9),
          body: ClerkAuthBuilder(
            signedInBuilder: (context, authState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleAuthSuccess(authState);
              });
              return const Center(
                child: NutriLoadingIndicator(
                  size: 110,
                  message: 'Signing in...',
                ),
              );
            },
            signedOutBuilder: (context, authState) {
              return Stack(
            children: [
              // 1. Soft Ambient Green Radial Glow Backdrop (Top Center)
              Positioned(
                top: -100,
                left: 0,
                right: 0,
                height: 420,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.5),
                      radius: 0.9,
                      colors: [
                        const Color(0xFF00B368).withValues(alpha: 0.12),
                        const Color(0xFF00B368).withValues(alpha: 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Main Scrollable Form Content
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _slideAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: child,
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),

                            // Header: Title & Subtitle (Always crisp dark typography)
                            Text(
                              _isSignUpMode ? 'Create Account' : 'Welcome Back',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF0F1A14),
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isSignUpMode
                                  ? 'Sign up to get started'
                                  : 'Sign in to continue',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.4,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Error Banner if present
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: AppTheme.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color:
                                        AppTheme.error.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppTheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: AppTheme.error,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _clearError,
                                      child: const Icon(
                                        Icons.close_rounded,
                                        color: AppTheme.error,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Form Fields
                            if (_isSignUpMode) ...[
                              // Full Name
                              _buildPillTextField(
                                controller: _nameController,
                                focusNode: _nameFocus,
                                hintText: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Username or Email
                            _buildPillTextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              hintText: 'Username or Email',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 16),

                            // Password
                            _buildPillTextField(
                              controller: _passwordController,
                              focusNode: _passwordFocus,
                              hintText: _isSignUpMode
                                  ? 'Password (min. 15 characters)'
                                  : 'Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onToggleVisibility: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),

                            if (_isSignUpMode) ...[
                              const SizedBox(height: 16),
                              // Confirm Password
                              _buildPillTextField(
                                controller: _confirmPasswordController,
                                focusNode: _confirmPasswordFocus,
                                hintText: 'Confirm Password (min. 15 characters)',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                obscureText: _obscureConfirmPassword,
                                onToggleVisibility: () {
                                  setState(() => _obscureConfirmPassword =
                                      !_obscureConfirmPassword);
                                },
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Controls Row: Remember Me & Forgot Password
                            if (!_isSignUpMode) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Remember Me
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(
                                          () => _rememberMe = !_rememberMe);
                                    },
                                    child: Row(
                                      children: [
                                        _buildCustomCheckbox(_rememberMe),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Remember Me',
                                          style: TextStyle(
                                            color: Color(0xFF334155),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Forgot Password?
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _showForgotPasswordSheet(authState);
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF00B368),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Terms and conditions on Sign Up
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(
                                      () => _termsAccepted = !_termsAccepted);
                                },
                                child: Row(
                                  children: [
                                    _buildCustomCheckbox(_termsAccepted),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'I agree to the Terms of Service & Privacy Policy',
                                        style: TextStyle(
                                          color: Color(0xFF475569),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Main Gradient Action Button (Login / Sign Up)
                            _buildGradientActionButton(
                              title: _isSignUpMode ? 'Create Account' : 'Login',
                              isLoading: _isLoading,
                              onTap: () {
                                if (_isSignUpMode) {
                                  _handleSignUp(authState);
                                } else {
                                  _handleLogin(authState);
                                }
                              },
                            ),

                            const SizedBox(height: 32),

                            // Centered "OR CONTINUE WITH" Divider (Light grey line & subtle slate)
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14),
                                  child: Text(
                                    'OR CONTINUE WITH',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Social Login Row (Google, Facebook)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Button
                                _buildSocialTile(
                                  onTap: () => _handleGoogleSignIn(authState),
                                  child: SvgPicture.asset(
                                    'assets/google-logo-color.svg',
                                    package: 'clerk_flutter',
                                    width: 26,
                                    height: 26,
                                  ),
                                ),

                                const SizedBox(width: 24),

                                // Facebook Button
                                _buildSocialTile(
                                  onTap: () => _handleFacebookSignIn(authState),
                                  child: const Icon(
                                    Icons.facebook,
                                    size: 30,
                                    color: Color(0xFF1877F2),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Bottom Toggle: Don't have an account? Sign Up
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                _clearError();
                                setState(() {
                                  _isSignUpMode = !_isSignUpMode;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                    ),
                                    children: [
                                      TextSpan(
                                        text: _isSignUpMode
                                            ? 'Already have an account? '
                                            : "Don't have an account? ",
                                      ),
                                      TextSpan(
                                        text: _isSignUpMode
                                            ? 'Sign In'
                                            : 'Sign Up',
                                        style: const TextStyle(
                                          color: Color(0xFF00B368),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Guest Access Link
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _continueAsGuest,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore as Guest',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 11,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  ),
);
}

  // ===========================================================================
  // Reusable Widgets: Pill TextField, Social Tile, Custom Checkbox
  // ===========================================================================

  Widget _buildPillTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final isFocused = focusNode?.hasFocus ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(29),
        border: Border.all(
          color: isFocused
              ? const Color(0xFF00B368)
              : const Color(0xFFE2E8F0),
          width: isFocused ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 3,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword && obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          cursorColor: const Color(0xFF00B368),
          style: const TextStyle(
            color: Color(0xFF0F1A14),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            filled: false,
            fillColor: Colors.transparent,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18, right: 14),
              child: Icon(
                icon,
                color:
                    isFocused ? const Color(0xFF00B368) : const Color(0xFF64748B),
                size: 21,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 46),
            suffixIcon: isPassword
                ? Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: IconButton(
                      icon: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF64748B),
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    ),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomCheckbox(bool isChecked) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: isChecked ? const Color(0xFF00B368) : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isChecked
              ? const Color(0xFF00B368)
              : const Color(0xFFCBD5E1),
          width: 1.8,
        ),
        boxShadow: isChecked
            ? [
                BoxShadow(
                  color: const Color(0xFF00B368).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: isChecked
          ? const Center(
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 15,
              ),
            )
          : null,
    );
  }

  Widget _buildGradientActionButton({
    required String title,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return BouncingWidget(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF00E676),
              Color(0xFF00C853),
              Color(0xFF009624),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00C853).withValues(alpha: 0.38),
              blurRadius: 22,
              offset: const Offset(0, 8),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 50),
            Expanded(
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: NutriLoadingIndicator(size: 26),
                      )
                    : Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                child: AnimatedBuilder(
                  animation: _arrowSlideAnimation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(_arrowSlideAnimation.value, 0),
                    child: child,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialTile({
    required VoidCallback onTap,
    required Widget child,
  }) {
    return BouncingWidget(
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            const BoxShadow(
              color: Colors.white,
              blurRadius: 3,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

// =============================================================================
// Email Verification Bottom Sheet with Resend Cooldown & Robust Error Handling
// =============================================================================

class _EmailVerificationSheet extends StatefulWidget {
  final ClerkAuthState authState;
  final bool isSignIn;
  final String email;
  final ValueChanged<ClerkAuthState> onSuccess;

  const _EmailVerificationSheet({
    required this.authState,
    required this.isSignIn,
    required this.email,
    required this.onSuccess,
  });

  @override
  State<_EmailVerificationSheet> createState() =>
      _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends State<_EmailVerificationSheet> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _dialogError;
  String? _resendSuccess;
  int _cooldownSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    ClerkAuthScreen.isScreenActive = true;
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _resendTimer?.cancel();
    if (mounted) {
      setState(() => _cooldownSeconds = 60);
    } else {
      _cooldownSeconds = 60;
    }
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 1) {
        setState(() => _cooldownSeconds--);
      } else {
        setState(() => _cooldownSeconds = 0);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeFocus.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resendCode() async {
    if (_isResending || _isVerifying || _cooldownSeconds > 0) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isResending = true;
      _dialogError = null;
      _resendSuccess = null;
    });

    try {
      if (widget.isSignIn) {
        final signIn = widget.authState.client.signIn;
        if (signIn != null && signIn.status.needsFactor) {
          final stage = signIn.needsSecondFactor
              ? clerk.Stage.second
              : clerk.Stage.first;
          final availableFactors = signIn.factorsFor(stage);
          final emailFactor = availableFactors
              .where((f) => f.strategy == clerk.Strategy.emailCode)
              .firstOrNull;

          if (emailFactor?.emailAddressId != null) {
            final res = await widget.authState.fetchApiResponse(
              '/client/sign_ins/${signIn.id}/prepare_${stage.name}_factor',
              params: {
                'strategy': clerk.Strategy.emailCode.name,
                'email_address_id': emailFactor!.emailAddressId,
              },
            );
            if (res.isError) {
              throw res.errorCollection.errorMessage;
            }
          } else {
            await widget.authState.attemptSignIn(
              strategy: clerk.Strategy.emailCode,
              identifier: widget.email,
            );
          }
        } else {
          await widget.authState.attemptSignIn(
            strategy: clerk.Strategy.emailCode,
            identifier: widget.email,
          );
        }
      } else {
        final signUp = widget.authState.client.signUp;
        if (signUp != null) {
          final res = await widget.authState.fetchApiResponse(
            '/client/sign_ups/${signUp.id}/prepare_verification',
            params: {
              'strategy': clerk.Strategy.emailCode.name,
            },
          );
          if (res.isError) {
            throw res.errorCollection.errorMessage;
          }
        } else {
          await widget.authState.attemptSignUp(strategy: clerk.Strategy.emailCode);
        }
      }

      if (mounted) {
        setState(() {
          _resendSuccess = 'A new verification code was sent to your email!';
          _isResending = false;
        });
        _startCooldownTimer();
      }
    } on clerk.ClerkError catch (e) {
      if (mounted) {
        setState(() {
          _dialogError = _ClerkAuthScreenState._parseClerkError(e);
          _isResending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dialogError = _ClerkAuthScreenState._parseClerkError(e);
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(
          () => _dialogError = 'Please enter the 6-digit verification code.');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isVerifying = true;
      _dialogError = null;
      _resendSuccess = null;
    });

    try {
      if (widget.isSignIn) {
        final signIn = widget.authState.client.signIn;
        if (signIn != null) {
          final stage = signIn.needsSecondFactor
              ? clerk.Stage.second
              : clerk.Stage.first;
          final res = await widget.authState.fetchApiResponse(
            '/client/sign_ins/${signIn.id}/attempt_${stage.name}_factor',
            params: {
              'strategy': clerk.Strategy.emailCode.name,
              'code': code,
            },
          );
          if (res.isError) {
            if (mounted) {
              setState(() {
                _dialogError = res.errorCollection.errorMessage;
                _isVerifying = false;
              });
            }
            return;
          }
          widget.authState.update();
        } else {
          await widget.authState.attemptSignIn(
            strategy: clerk.Strategy.emailCode,
            code: code,
          );
        }
      } else {
        final signUp = widget.authState.client.signUp;
        if (signUp != null) {
          final res = await widget.authState.fetchApiResponse(
            '/client/sign_ups/${signUp.id}/attempt_verification',
            params: {
              'strategy': clerk.Strategy.emailCode.name,
              'code': code,
            },
          );
          if (res.isError) {
            if (mounted) {
              setState(() {
                _dialogError = res.errorCollection.errorMessage;
                _isVerifying = false;
              });
            }
            return;
          }
          widget.authState.update();
        } else {
          await widget.authState.attemptSignUp(
            strategy: clerk.Strategy.emailCode,
            code: code,
          );
        }
      }

      if (widget.authState.isSignedIn) {
        if (!mounted) return;
        Navigator.of(context).pop();
        widget.onSuccess(widget.authState);
      } else {
        if (mounted) {
          setState(() {
            _dialogError = 'Invalid code. Please check and try again.';
            _isVerifying = false;
          });
        }
      }
    } on clerk.ClerkError catch (e) {
      if (mounted) {
        setState(() {
          _dialogError = _ClerkAuthScreenState._parseClerkError(e);
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dialogError = _ClerkAuthScreenState._parseClerkError(e);
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme.copyWith(
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        cardColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Verify Email',
                style: TextStyle(
                  color: Color(0xFF0F1A14),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.email.isNotEmpty
                    ? 'Enter the 6-digit verification code sent to\n${widget.email}'
                    : 'Enter the 6-digit verification code sent to your email.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              if (_dialogError != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppTheme.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dialogError!,
                          style: const TextStyle(
                              color: AppTheme.error, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_resendSuccess != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B368).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF00B368), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _resendSuccess!,
                          style: const TextStyle(
                            color: Color(0xFF00B368),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Container(
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(29),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: TextField(
                    controller: _codeController,
                    focusNode: _codeFocus,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      color: Color(0xFF0F1A14),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4.0,
                    ),
                    decoration: const InputDecoration(
                      filled: false,
                      fillColor: Colors.transparent,
                      counterText: '',
                      hintText: '• • • • • •',
                      hintStyle: TextStyle(
                        color: Color(0xFF94A3B8),
                        letterSpacing: 4.0,
                      ),
                      prefixIcon: Icon(Icons.pin_outlined,
                          color: Color(0xFF64748B), size: 20),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 22),
            BouncingWidget(
              onTap: _isVerifying ? () {} : _verifyCode,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00E676),
                      Color(0xFF00C853),
                      Color(0xFF009624),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withValues(alpha: 0.38),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 50),
                    Expanded(
                      child: Center(
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.6,
                                ),
                              )
                            : const Text(
                                'Verify & Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(right: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: (_isVerifying || _isResending || _cooldownSeconds > 0)
                  ? null
                  : _resendCode,
              child: _isResending
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF00B368),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Sending code...',
                          style: TextStyle(
                            color: Color(0xFF00B368),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      _cooldownSeconds > 0
                          ? 'Resend code in ${_cooldownSeconds}s'
                          : "Didn't receive code? Resend Code",
                      style: TextStyle(
                        color: _cooldownSeconds > 0
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF00B368),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
}

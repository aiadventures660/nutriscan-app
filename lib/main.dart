import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'config/api_config.dart';
import 'providers/app_state_provider.dart';
import 'config/app_theme.dart';
import 'services/storage_service.dart';
import 'services/api_client.dart';
import 'services/app_preloader.dart';
import 'screens/enhanced_home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/user_setup_screen.dart';
import 'screens/clerk_auth_screen.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Defer first frame: keeps the native splash screen smoothly visible while
  // all user profile data, name, avatar photos, metrics, and branding images load.
  binding.deferFirstFrame();

  final appState = AppStateProvider();
  bool hasSeenOnboarding = false;
  bool hasCompletedProfile = false;

  try {
    // 1. Check onboarding and profile setup state
    final storageService = StorageService();
    hasSeenOnboarding = await storageService.hasSeenOnboarding();
    hasCompletedProfile = await storageService.hasCompletedProfileSetup();

    // 2. Pre-load ALL state before the first screen is rendered
    // (User Name, Photo Path, Targets, Hydration, History, Tips, Favorites, Theme)
    await appState.initialize();

    // 3. Pre-cache essential visual assets (App logo, icon, and custom user avatar file)
    await AppPreloader.precacheEssentialImages(appState);
  } catch (e) {
    debugPrint('Startup preloading notice: $e');
  } finally {
    // 4. Release the first frame to paint seamlessly with all data and images ready
    binding.allowFirstFrame();
  }

  runApp(FoodScannerApp(
    hasSeenOnboarding: hasSeenOnboarding,
    hasCompletedProfile: hasCompletedProfile,
    appStateProvider: appState,
  ));
}

class FoodScannerApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final bool hasCompletedProfile;
  final AppStateProvider? appStateProvider;

  const FoodScannerApp({
    super.key,
    required this.hasSeenOnboarding,
    required this.hasCompletedProfile,
    this.appStateProvider,
  });

  @override
  Widget build(BuildContext context) {
    final provider = appStateProvider ?? (AppStateProvider()..initialize());

    return ChangeNotifierProvider.value(
      value: provider,
      child: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          AppTheme.setDarkMode(appState.isDarkMode);

          return MaterialApp(
            title: 'NutriScan Pro',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return ClerkAuth(
                config: ClerkAuthConfig(
                  publishableKey: ApiConfig.clerkPublishableKey,
                ),
                child: ClerkErrorListener(
                  handler: (context, error) {
                    // Suppress duplicate SnackBar on ClerkAuthScreen where inline error banner is displayed
                    if (ClerkAuthScreen.isScreenActive) {
                      return;
                    }

                    final messenger = ScaffoldMessenger.maybeOf(context);
                    if (messenger == null) return;

                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final cleanMessage = ClerkAuthScreen.parseClerkError(error);

                    if (cleanMessage.isEmpty) return;

                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        elevation: 2,
                        backgroundColor: isDark
                            ? const Color(0xFF2C1518)
                            : const Color(0xFFFEF2F2),
                        margin: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? AppTheme.error.withValues(alpha: 0.4)
                                : AppTheme.error.withValues(alpha: 0.25),
                            width: 1.2,
                          ),
                        ),
                        content: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                cleanMessage,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFFECACA)
                                      : const Color(0xFF991B1B),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  child: child!,
                ),
              );
            },
            home: AuthGate(
              hasSeenOnboarding: hasSeenOnboarding,
              hasCompletedProfile: hasCompletedProfile,
            ),
          );
        },
      ),
    );
  }
}

/// Authentication and onboarding gatekeeper:
/// 1. Unseen Onboarding -> [OnboardingScreen]
/// 2. Incomplete Profile -> [UserSetupScreen]
/// 3. Authenticated -> [EnhancedHomeScreen]
/// 4. Signed Out -> [ClerkAuthScreen]
class AuthGate extends StatelessWidget {
  final bool hasSeenOnboarding;
  final bool hasCompletedProfile;

  const AuthGate({
    super.key,
    required this.hasSeenOnboarding,
    required this.hasCompletedProfile,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    if (!hasCompletedProfile) {
      return const UserSetupScreen(isFirstTime: true);
    }

    return ClerkAuthBuilder(
      signedInBuilder: (context, authState) {
        final user = authState.user;
        if (user != null) {
          // Configure dynamic token provider to guarantee fresh JWT for API client
          ApiClient().setTokenProvider(() async {
            try {
              final token = await authState.sessionToken();
              return token.jwt;
            } catch (_) {
              return authState.session?.lastActiveToken?.jwt;
            }
          });

          final token = authState.session?.lastActiveToken?.jwt;
          if (token != null && token.isNotEmpty) {
            ApiClient().setSessionToken(token);
          }

          final provider = context.read<AppStateProvider>();
          final emails = user.emailAddresses;
          final primaryEmail = (emails != null && emails.isNotEmpty)
              ? emails.first.emailAddress
              : null;
          final displayName = user.firstName != null
              ? '${user.firstName} ${user.lastName ?? ''}'.trim()
              : user.username;

          // Automatically restore or sync user data from Supabase backend
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (provider.clerkUserId != user.id || provider.history.isEmpty) {
              provider.restoreUserDataFromBackend(
                clerkId: user.id,
                fallbackEmail: primaryEmail,
                fallbackName: displayName,
                photoUrl: user.imageUrl,
              );
            } else {
              provider.syncClerkUserData(
                clerkId: user.id,
                email: primaryEmail,
                name: displayName,
                photoUrl: user.imageUrl,
              );
            }
          });
        }
        return const EnhancedHomeScreen();
      },
      signedOutBuilder: (context, authState) {
        return const ClerkAuthScreen();
      },
    );
  }
}

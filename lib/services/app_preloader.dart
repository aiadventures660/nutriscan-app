import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../providers/app_state_provider.dart';

/// Preloads and precaches essential visual assets (app logos, icons,
/// custom user avatar photos) before the first frame of the UI is painted.
class AppPreloader {
  /// Precaches all critical images for the homepage and branding.
  static Future<void> precacheEssentialImages(AppStateProvider appState) async {
    final List<Future<void>> tasks = [];

    // 1. Precache app logo and branding assets
    tasks.add(_precacheProvider(const AssetImage('assets/images/app_logo.png')));
    tasks.add(_precacheProvider(const AssetImage('assets/icons/app_icon.png')));

    // 2. Precache custom user avatar photo if saved on disk
    final userPhoto = appState.userPhotoPath;
    if (userPhoto != null && !userPhoto.startsWith('preset_')) {
      try {
        final file = File(userPhoto);
        if (await file.exists()) {
          tasks.add(_precacheProvider(FileImage(file)));
        }
      } catch (e) {
        debugPrint('AppPreloader: error checking user avatar photo file: $e');
      }
    }

    // Wait with safety timeout to guarantee instant app launch
    try {
      await Future.wait(tasks).timeout(const Duration(milliseconds: 1200));
    } catch (e) {
      debugPrint('AppPreloader: asset pre-caching finished with notice: $e');
    }
  }

  /// Resolves an ImageProvider into Flutter's imageCache ahead of time.
  static Future<void> _precacheProvider(ImageProvider provider) {
    final completer = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, synchronousCall) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (exception, stackTrace) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}

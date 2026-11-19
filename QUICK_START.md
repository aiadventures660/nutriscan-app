# Quick Android Emulator Setup Guide

## ✅ Android Studio is Starting!

Follow these simple steps to create an emulator:

### Step 1: Install Required Components (in Android Studio)
1. **Wait for Android Studio to fully load**
2. Click **"More Actions"** → **"SDK Manager"**
3. In **SDK Tools** tab, check these items:
   - ✅ Android SDK Command-line Tools (latest)
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools
4. Click **"Apply"** to install

### Step 2: Create Virtual Device
1. Go to **Tools** → **AVD Manager**
2. Click **"Create Virtual Device"**
3. Choose **Phone** → **Pixel 7** → **Next**
4. Download **API 34 (Android 14)** → **Next**
5. Name: `Flutter_Phone` → **Finish**

### Step 3: Start Emulator
1. In AVD Manager, click **▶️ Play** button
2. Wait for emulator to boot (3-5 minutes first time)

## After Emulator is Running

Check everything works:

```powershell
# Check Flutter recognizes the emulator
flutter devices

# Install Flutter dependencies
flutter pub get

# Run your food scanner app
flutter run
```

## Alternative: Use Web for Development

If emulator is slow, you can develop in Chrome:

```powershell
flutter run -d chrome
```

**Note**: Camera won't work in web mode, but you can test the UI.

## Troubleshooting

If you see errors:
```powershell
# Fix Android licenses
flutter doctor --android-licenses

# Clean and reinstall dependencies
flutter clean
flutter pub get
```

---

**Your Flutter food scanner app is ready to run once the emulator starts!** 🚀

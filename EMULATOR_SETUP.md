# Android Emulator Setup Guide

This guide will help you set up an Android emulator for running your Flutter food scanner app.

## Method 1: Using Android Studio (Recommended)

### Step 1: Open Android Studio
1. Launch Android Studio from your Start menu
2. If prompted for a project, click "More Actions" > "SDK Manager"

### Step 2: Install SDK Components
1. In Android Studio, go to **Tools** > **SDK Manager**
2. In the **SDK Platforms** tab:
   - Check **Android 14 (API 34)** or **Android 13 (API 33)**
   - Click **Apply** to install

3. In the **SDK Tools** tab, make sure these are checked:
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Command-line Tools
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools
   - ✅ Intel x86 Emulator Accelerator (HAXM installer)
   - Click **Apply** to install

### Step 3: Create Virtual Device
1. In Android Studio, go to **Tools** > **AVD Manager**
2. Click **Create Virtual Device**
3. Choose a device definition:
   - **Phone** category
   - Select **Pixel 7** or **Pixel 6** (recommended)
   - Click **Next**

4. Choose a system image:
   - Select **API 34** (Android 14) or **API 33** (Android 13)
   - Click **Download** if not already downloaded
   - Select the downloaded image and click **Next**

5. Configure AVD:
   - AVD Name: `Flutter_Phone_API_34`
   - Advanced Settings:
     - RAM: 2048 MB (or higher if you have enough RAM)
     - VM Heap: 256 MB
     - Internal Storage: 2048 MB
     - SD Card: 512 MB
   - Click **Finish**

### Step 4: Start the Emulator
1. In AVD Manager, click the **Play** button (▶️) next to your emulator
2. Wait for the emulator to boot up (first time may take several minutes)
3. Once booted, you should see the Android home screen

## Method 2: Command Line Setup

If you prefer command line, follow these steps:

### Step 1: Set Environment Variables
```powershell
# Add to your PowerShell profile or run each session
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
$env:PATH += ";$env:ANDROID_HOME\emulator"
$env:PATH += ";$env:ANDROID_HOME\platform-tools"
$env:PATH += ";$env:ANDROID_HOME\cmdline-tools\latest\bin"
```

### Step 2: Install SDK Components
```powershell
# Navigate to cmdline-tools
cd "$env:ANDROID_HOME\cmdline-tools\latest\bin"

# Install required components
.\sdkmanager "platform-tools"
.\sdkmanager "platforms;android-34"
.\sdkmanager "build-tools;34.0.0"
.\sdkmanager "emulator"
.\sdkmanager "system-images;android-34;google_apis;x86_64"

# Accept licenses
.\sdkmanager --licenses
```

### Step 3: Create AVD via Command Line
```powershell
# Create emulator
echo "no" | .\avdmanager create avd -n "Flutter_Phone_API_34" -k "system-images;android-34;google_apis;x86_64" -d "pixel_7"
```

### Step 4: Start Emulator
```powershell
# Start emulator in background
emulator -avd Flutter_Phone_API_34 &
```

## Verifying Setup

After creating the emulator, verify everything works:

```powershell
# Check Flutter setup
flutter doctor

# List available devices (should show your emulator)
flutter devices

# Run your Flutter app
flutter run
```

## Troubleshooting

### Common Issues:

1. **HAXM Installation Failed**:
   - Enable Intel VT-x in BIOS
   - Disable Hyper-V in Windows Features
   - Run: `sc config hvboot start= disabled` (as admin)

2. **Emulator is Slow**:
   - Enable hardware acceleration
   - Increase RAM allocation
   - Use x86_64 system images
   - Close other applications

3. **Flutter Not Detecting Emulator**:
   - Make sure emulator is fully booted
   - Run `adb devices` to check connection
   - Restart adb: `adb kill-server && adb start-server`

4. **Build Errors**:
   - Accept Android licenses: `flutter doctor --android-licenses`
   - Update Flutter: `flutter upgrade`
   - Clean project: `flutter clean && flutter pub get`

## Alternative: Web Development

If emulator setup is problematic, you can develop using Chrome:

```powershell
# Run in web browser (good for UI development)
flutter run -d chrome
```

Note: Camera features won't work in web mode, but you can test most other functionality.

## Next Steps

Once your emulator is running:

1. Open your Flutter project in VS Code
2. Press `Ctrl+Shift+P` and select "Flutter: Launch Emulator"
3. Run your app with `F5` or `flutter run`

Your food scanner app should now run on the Android emulator!

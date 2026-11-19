# Flutter Android Emulator Setup Script
# Run this script in PowerShell as Administrator for best results

Write-Host "=== Flutter Android Emulator Setup ===" -ForegroundColor Green

# Set Android SDK path
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
Write-Host "Android SDK Path: $env:ANDROID_HOME" -ForegroundColor Yellow

# Check if Android SDK exists
if (-not (Test-Path $env:ANDROID_HOME)) {
    Write-Host "❌ Android SDK not found at $env:ANDROID_HOME" -ForegroundColor Red
    Write-Host "Please install Android Studio first!" -ForegroundColor Red
    exit 1
}

# Add SDK paths to environment
$env:PATH += ";$env:ANDROID_HOME\emulator"
$env:PATH += ";$env:ANDROID_HOME\platform-tools"
$env:PATH += ";$env:ANDROID_HOME\cmdline-tools\latest\bin"

Write-Host "✅ Environment variables set" -ForegroundColor Green

# Check if cmdline-tools exist
$cmdlineToolsPath = "$env:ANDROID_HOME\cmdline-tools\latest"
if (-not (Test-Path $cmdlineToolsPath)) {
    Write-Host "⚠️  Command line tools not found" -ForegroundColor Yellow
    Write-Host "Please install Android SDK Command-line Tools through Android Studio:" -ForegroundColor Yellow
    Write-Host "Tools > SDK Manager > SDK Tools > Android SDK Command-line Tools" -ForegroundColor Yellow
    
    # Try to find cmdline-tools in other locations
    $altPath = "$env:ANDROID_HOME\cmdline-tools"
    if (Test-Path $altPath) {
        $versions = Get-ChildItem $altPath -Directory | Sort-Object Name -Descending
        if ($versions.Count -gt 0) {
            $latestVersion = $versions[0].FullName
            Write-Host "Found cmdline-tools at: $latestVersion" -ForegroundColor Green
            $env:PATH += ";$latestVersion\bin"
        }
    }
}

# Check available system images
Write-Host "`n=== Checking Available System Images ===" -ForegroundColor Green
try {
    $images = & sdkmanager --list | Select-String "system-images.*google_apis.*x86_64"
    if ($images) {
        Write-Host "Available system images:" -ForegroundColor Yellow
        $images | ForEach-Object { Write-Host "  $($_.Line)" }
    }
} catch {
    Write-Host "⚠️  Could not list system images. Ensure cmdline-tools are properly installed." -ForegroundColor Yellow
}

# List existing AVDs
Write-Host "`n=== Existing Android Virtual Devices ===" -ForegroundColor Green
try {
    $avds = & emulator -list-avds
    if ($avds) {
        Write-Host "Existing AVDs:" -ForegroundColor Yellow
        $avds | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
    } else {
        Write-Host "No AVDs found." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️  Could not list AVDs." -ForegroundColor Yellow
}

# Function to create AVD
function Create-FlutterAVD {
    param(
        [string]$avdName = "Flutter_Phone_API_34",
        [string]$systemImage = "system-images;android-34;google_apis;x86_64",
        [string]$device = "pixel_7"
    )
    
    Write-Host "`n=== Creating AVD: $avdName ===" -ForegroundColor Green
    
    try {
        # Check if system image is installed
        $installedImages = & sdkmanager --list_installed | Select-String $systemImage
        if (-not $installedImages) {
            Write-Host "Installing system image: $systemImage" -ForegroundColor Yellow
            & sdkmanager $systemImage
        }
        
        # Create AVD
        Write-Host "Creating AVD..." -ForegroundColor Yellow
        echo "no" | & avdmanager create avd -n $avdName -k $systemImage -d $device --force
        
        Write-Host "✅ AVD '$avdName' created successfully!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Failed to create AVD: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to start emulator
function Start-FlutterEmulator {
    param([string]$avdName = "Flutter_Phone_API_34")
    
    Write-Host "`n=== Starting Emulator: $avdName ===" -ForegroundColor Green
    
    try {
        # Start emulator in background
        Write-Host "Starting emulator (this may take a few minutes)..." -ForegroundColor Yellow
        Start-Process -FilePath "emulator" -ArgumentList "-avd", $avdName -NoNewWindow
        
        Write-Host "✅ Emulator starting... Please wait for it to boot completely." -ForegroundColor Green
        Write-Host "💡 Tip: First boot can take 5-10 minutes." -ForegroundColor Cyan
        return $true
    } catch {
        Write-Host "❌ Failed to start emulator: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Interactive menu
Write-Host "`n=== Choose an option ===" -ForegroundColor Green
Write-Host "1. Create new AVD (Flutter_Phone_API_34)"
Write-Host "2. Start existing emulator"
Write-Host "3. Run Flutter doctor"
Write-Host "4. List Flutter devices"
Write-Host "5. Run Flutter app"
Write-Host "6. Exit"

$choice = Read-Host "`nEnter your choice (1-6)"

switch ($choice) {
    "1" {
        $success = Create-FlutterAVD
        if ($success) {
            $startNow = Read-Host "Start the emulator now? (y/n)"
            if ($startNow -eq "y" -or $startNow -eq "Y") {
                Start-FlutterEmulator
            }
        }
    }
    "2" {
        $avds = & emulator -list-avds
        if ($avds) {
            Write-Host "Available AVDs:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $avds.Count; $i++) {
                Write-Host "$($i + 1). $($avds[$i])" -ForegroundColor Cyan
            }
            $avdChoice = Read-Host "Select AVD number"
            $selectedAvd = $avds[[int]$avdChoice - 1]
            if ($selectedAvd) {
                Start-FlutterEmulator -avdName $selectedAvd
            }
        } else {
            Write-Host "No AVDs found. Create one first." -ForegroundColor Red
        }
    }
    "3" {
        Write-Host "`n=== Flutter Doctor ===" -ForegroundColor Green
        flutter doctor -v
    }
    "4" {
        Write-Host "`n=== Flutter Devices ===" -ForegroundColor Green
        flutter devices
    }
    "5" {
        Write-Host "`n=== Running Flutter App ===" -ForegroundColor Green
        Write-Host "Make sure an emulator is running first!" -ForegroundColor Yellow
        flutter run
    }
    "6" {
        Write-Host "Goodbye!" -ForegroundColor Green
        exit 0
    }
    default {
        Write-Host "Invalid choice. Please run the script again." -ForegroundColor Red
    }
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Wait for emulator to fully boot" -ForegroundColor Cyan
Write-Host "2. Run 'flutter devices' to see available devices" -ForegroundColor Cyan
Write-Host "3. Run 'flutter run' to start your app" -ForegroundColor Cyan

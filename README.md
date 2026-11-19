# Food Scanner Flutter App

A Flutter mobile application for scanning food items and getting AI-powered nutrition analysis using **Google's Gemini AI**. This app provides comprehensive nutrition insights, health recommendations, and food tracking capabilities.

## 🚀 Features

### 📱 Core Functionality
- **AI-Powered Food Recognition**: Uses Google Gemini 1.5 Flash for accurate food identification
- **Detailed Nutrition Analysis**: Comprehensive breakdown of calories, macronutrients, and micronutrients
- **Health Scoring**: AI-generated health scores (1-10) with explanations
- **Personalized Recommendations**: Tailored health and nutrition advice
- **Camera Integration**: Take photos or select from gallery for analysis
- **History Tracking**: Save and review your scan history with filtering options
- **Profile Management**: User preferences, goals, and app settings

### 🤖 AI Features
- **Image Optimization**: Automatic image resizing and compression for optimal API performance
- **Robust Error Handling**: Graceful fallbacks and retry mechanisms
- **Real-time Analysis**: Fast processing with visual feedback
- **Demo Mode**: Works without API key for testing and development
- **Privacy-Focused**: Images processed securely, not permanently stored

### 📊 Data & Analytics
- **Daily Nutrition Summaries**: Track calories, protein, carbs, and fats
- **Meal Type Categorization**: Automatic breakfast, lunch, dinner, snack classification
- **Weekly Statistics**: Monitor your nutrition trends over time
- **Export Capabilities**: Download your data for external analysis
- **Local Storage**: All data stored securely on your device

## 🛠 Setup & Installation

### Prerequisites
- Flutter SDK (3.0+)
- Android Studio / Xcode
- Google AI API Key (for full functionality)

### 1. Clone and Install Dependencies
```bash
git clone <repository-url>
cd flutter
flutter pub get
```

### 2. Configure Gemini AI (Required for AI Features)
1. Get your API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Open `lib/config/api_config.dart`
3. Replace the placeholder with your API key:
```dart
static const String googleAiApiKey = 'your_actual_api_key_here';
```

📖 **Detailed setup guide**: See [GEMINI_API_SETUP.md](GEMINI_API_SETUP.md)

### 3. Run the App
```bash
# Web (for testing UI)
flutter run -d web

# Android emulator
flutter run

# iOS simulator
flutter run -d ios
```

## 🏗 Project Structure

```
lib/
├── main.dart                  # App entry point
├── config/
│   └── api_config.dart       # Gemini AI configuration
├── models/
│   └── food_models.dart      # Data models for nutrition and scan data
├── providers/
│   └── app_state_provider.dart # State management with Provider
├── services/
│   ├── ai_service.dart       # Gemini AI integration service
│   └── storage_service.dart  # Local data persistence
├── screens/
│   ├── onboarding_screen.dart # Welcome and app introduction
│   ├── home_screen.dart      # Dashboard with daily summary
│   ├── scan_screen.dart      # Camera interface for food scanning
│   ├── scan_results_screen.dart # AI analysis results display
│   ├── history_screen.dart   # Scan history with filtering
│   ├── profile_screen.dart   # User settings and preferences
│   └── alternatives_screen.dart # Healthier food alternatives
└── widgets/               # Reusable UI components
    ├── nutrition_tip_card.dart
    ├── daily_summary_card.dart
    ├── pie_chart_widget.dart
    ├── vitamin_mineral_card.dart
    └── bottom_navigation.dart
```

## 📋 Core Models

### ScanData
Represents the result of AI food analysis:
```dart
class ScanData {
  final String id;
  final String foodName;           // AI-identified food name
  final String nutritionInfo;     // Detailed nutrition breakdown
  final String healthScore;       // AI health rating /10
  final String recommendations;   // Personalized health advice
  final List<VitaminMineral> vitaminsAndMinerals;
  final String imagePath;
  final DateTime timestamp;
}
```

### LoggedFoodEntry
Tracks saved scans in user history:
```dart
class LoggedFoodEntry {
  final String id;
  final ScanData scanData;
  final DateTime timestamp;
  final ParsedNutritionValues parsedNutrition;
  final String mealType;         // Breakfast, Lunch, Dinner, Snack
}
```

## 🔧 Configuration Options

### API Configuration (`lib/config/api_config.dart`)
```dart
class ApiConfig {
  static const String googleAiApiKey = 'YOUR_API_KEY';
  static const String geminiModel = 'gemini-1.5-flash';
  static const int maxImageSize = 4 * 1024 * 1024; // 4MB
  static const Duration requestTimeout = Duration(seconds: 30);
}
```

### Gemini AI Service Features
- **Automatic image optimization** (max 1024px, 85% quality)
- **Robust JSON parsing** with fallback handling
- **Detailed nutrition analysis** with vitamin/mineral content
- **Health scoring algorithm** based on nutritional density
- **Timeout protection** and error recovery

## 🎨 UI/UX Features

### Dark Theme Design
- Material Design 3 principles
- Green accent color (#38e07b) for health/nutrition theme
- Responsive layouts for various screen sizes
- Smooth animations and transitions

### Navigation
- Bottom navigation with 4 main sections
- Intuitive flow from scanning to results to history
- Contextual actions and quick access buttons

### Data Visualization
- Pie charts for macronutrient breakdown
- Progress indicators for daily goals
- Statistics cards with health metrics
- Color-coded nutrition information

## 📱 Screen Details

### Home Screen
- Daily nutrition summary
- Quick scan action
- Recent nutrition tips
- Weekly progress overview

### Scan Screen
- Camera preview with guidance overlay
- Gallery picker option
- Real-time AI processing feedback
- Error handling and retry mechanisms

### Scan Results Screen
- AI-generated food identification
- Comprehensive nutrition breakdown
- Health score with explanation
- Save to history and view alternatives

### History Screen
- Chronological scan history
- Filter by date and meal type
- Detailed statistics dashboard
- Individual item management (view/delete)

### Profile Screen
- User statistics and achievements
- Goal setting and progress tracking
- App preferences and settings
- Data export and privacy controls

## 🔐 Privacy & Security

### Data Handling
- **Local Storage**: All user data stored on device using SharedPreferences
- **Image Processing**: Images sent to Gemini AI for analysis only
- **No Permanent Storage**: Google AI doesn't permanently store images
- **User Control**: Full data export and deletion capabilities

### API Security
- API keys should never be committed to version control
- Consider environment variables for production
- Monitor API usage to stay within limits
- Implement proper error handling for security

## 🧪 Testing

### Demo Mode
The app includes comprehensive demo data for testing:
- Realistic nutrition values
- Sample vitamin/mineral content
- Mock health recommendations
- Full UI functionality without API key

### Testing Commands
```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart

# Analyze code quality
flutter analyze
```

## 📊 API Limits & Monitoring

### Gemini AI Free Tier
- **15 requests per minute**
- **1,500 requests per day**
- **1 million tokens per month**

### Optimization Strategies
- Image compression and resizing
- Caching frequent analyses
- Efficient prompt engineering
- Graceful error handling

## 🚀 Production Deployment

### Android Build
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS Build
```bash
flutter build ios --release
```

### Environment Configuration
1. Set up different API keys for dev/staging/production
2. Configure proper app signing
3. Update app icons and metadata
4. Test on physical devices

## 🔧 Troubleshooting

### Common Issues

#### "AI service not configured"
- Verify API key is set in `api_config.dart`
- Check API key permissions in Google AI Studio
- Ensure you're within free tier limits

#### Camera not working
- Check camera permissions in device settings
- Verify physical camera availability
- Test with gallery picker as alternative

#### Slow AI responses
- Check internet connection
- Verify image isn't too large
- Monitor API quota usage

#### App crashes on scan
- Check Flutter and dependency versions
- Verify device compatibility
- Review error logs for specific issues

## 📈 Performance Optimization

### Image Processing
- Automatic image compression
- Size limits enforced
- Progressive loading indicators
- Memory management for large images

### State Management
- Efficient Provider usage
- Minimal widget rebuilds
- Proper disposal of resources
- Background processing for AI calls

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Development Guidelines
- Follow Flutter/Dart best practices
- Maintain consistent code formatting
- Add comments for complex AI logic
- Test with and without API key
- Consider performance implications

## 📞 Support

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Google AI Documentation](https://ai.google.dev/docs)
- [Gemini API Setup Guide](GEMINI_API_SETUP.md)

### Debugging
- Enable Flutter debug mode
- Check console logs for AI service
- Monitor network requests
- Test with demo data first

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This Flutter app demonstrates modern mobile development with AI integration, providing a complete food nutrition analysis solution using Google's advanced Gemini AI technology.

## Features

- 📸 **Camera Integration**: Take photos of food items or select from gallery
- 🤖 **AI-Powered Analysis**: Get detailed nutrition information using Google AI
- 📊 **Nutrition Visualization**: Interactive pie charts and nutrition breakdowns
- 📱 **Onboarding Experience**: Beautiful onboarding screens for new users
- 📈 **History Tracking**: Save and track your food scan history
- 💡 **Nutrition Tips**: Get personalized nutrition recommendations
- 🎯 **Daily Summary**: Track daily nutrition intake
- 🔍 **Food Alternatives**: Discover healthier food alternatives

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── food_models.dart     # ScanData, NutritionTip, etc.
├── providers/               # State management
│   └── app_state_provider.dart
├── screens/                 # Screen widgets
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   ├── scan_screen.dart
│   ├── scan_results_screen.dart
│   ├── history_screen.dart
│   ├── profile_screen.dart
│   ├── alternatives_screen.dart
│   └── tip_detail_screen.dart
├── services/               # Business logic
│   ├── ai_service.dart    # Google AI integration
│   └── storage_service.dart # Local data storage
└── widgets/               # Reusable UI components
    ├── bottom_navigation.dart
    ├── pie_chart_widget.dart
    ├── nutrition_tip_card.dart
    ├── daily_summary_card.dart
    └── vitamin_mineral_card.dart
```

## Prerequisites

Before running this app, you need to have Flutter installed on your system.

### 1. Install Flutter

#### Windows:
1. Download Flutter SDK from [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Extract to `C:\flutter`
3. Add `C:\flutter\bin` to your PATH environment variable
4. Run `flutter doctor` to verify installation

#### macOS:
```bash
# Using Homebrew
brew install --cask flutter

# Or download from flutter.dev and follow instructions
```

#### Linux:
```bash
# Download and extract Flutter SDK
sudo snap install flutter --classic
```

### 2. Install Dependencies

After Flutter is installed, run:

```bash
# Install dependencies
flutter pub get

# Verify Flutter installation
flutter doctor
```

### 3. Setup Google AI API

1. Get your Google AI API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Open `lib/services/ai_service.dart`
3. Replace `YOUR_GOOGLE_AI_API_KEY` with your actual API key:

```dart
static const String _apiKey = 'your_actual_api_key_here';
```

## Running the App

### Development

```bash
# Run on connected device/emulator
flutter run

# Run with hot reload in debug mode
flutter run --debug

# Run on specific device
flutter devices
flutter run -d <device_id>
```

### Building for Production

#### Android APK:
```bash
flutter build apk --release
```

#### Android App Bundle (for Google Play):
```bash
flutter build appbundle --release
```

#### iOS (macOS only):
```bash
flutter build ios --release
```

## Platform Setup

### Android Setup

1. Install Android Studio
2. Install Android SDK (API level 21 or higher)
3. Create a virtual device or connect a physical device
4. Enable USB Debugging on physical device

### iOS Setup (macOS only)

1. Install Xcode from the App Store
2. Install iOS Simulator
3. For physical device: Apple Developer account required

## Permissions

The app requires the following permissions:

### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan food items</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select food images</string>
```

## Key Dependencies

- `camera: ^0.10.5+9` - Camera functionality
- `image_picker: ^1.0.7` - Image selection from gallery
- `google_generative_ai: ^0.4.3` - Google AI integration
- `provider: ^6.1.1` - State management
- `shared_preferences: ^2.2.2` - Local data storage
- `fl_chart: ^0.66.2` - Charts and data visualization
- `cached_network_image: ^3.3.1` - Optimized image loading
- `http: ^1.2.0` - HTTP requests
- `intl: ^0.19.0` - Internationalization
- `permission_handler: ^11.3.0` - Runtime permissions

## Development Workflow

1. **Start Development Server**:
   ```bash
   flutter run
   ```

2. **Hot Reload**: Press `r` in terminal or save files in VS Code

3. **Hot Restart**: Press `R` in terminal

4. **Debug**: Use VS Code debugger or run `flutter run --debug`

5. **Testing**:
   ```bash
   flutter test
   ```

## Troubleshooting

### Common Issues:

1. **Flutter not recognized**:
   - Ensure Flutter is added to PATH
   - Restart terminal/command prompt

2. **Dependencies not found**:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Camera not working**:
   - Check permissions in device settings
   - Ensure physical device is used (camera doesn't work in some emulators)

4. **AI Analysis failing**:
   - Verify Google AI API key is correct
   - Check internet connection
   - Review API quotas and billing

5. **Build failures**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Comparison with Original React App

| Feature | React App | Flutter App |
|---------|-----------|-------------|
| Technology | React + Capacitor | Flutter |
| State Management | React Hooks | Provider |
| AI Integration | Google AI | Google AI |
| Camera | Capacitor Camera | Flutter Camera |
| Storage | localStorage | SharedPreferences |
| Charts | Custom components | fl_chart |
| Navigation | React Router | Flutter Navigator |
| Styling | CSS | Flutter Themes |

## Future Enhancements

- [ ] Barcode scanning for packaged foods
- [ ] Meal planning features
- [ ] Social sharing capabilities
- [ ] Offline mode support
- [ ] Multi-language support
- [ ] Advanced analytics dashboard
- [ ] Integration with health apps
- [ ] Recipe suggestions based on scanned ingredients

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section above
- Review Flutter documentation: [flutter.dev](https://flutter.dev)
- Check Google AI documentation: [ai.google.dev](https://ai.google.dev)

---

**Note**: This Flutter app provides the same functionality as the original React app but with native mobile performance and Flutter's rich UI capabilities.

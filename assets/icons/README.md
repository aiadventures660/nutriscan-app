# Food Scanner App Icon

This directory should contain your app icon:

## Required Icon Specifications:

### For flutter_launcher_icons:
- **File name**: `app_icon.png`
- **Recommended size**: 1024x1024 pixels
- **Format**: PNG with transparent background
- **Design guidelines**:
  - Simple, recognizable design
  - Works well at small sizes
  - Good contrast
  - Follows platform guidelines

### Icon Design Tips:
1. **Keep it simple** - Complex designs don't scale well
2. **Use meaningful imagery** - Food/nutrition related icons work best
3. **Test at multiple sizes** - Ensure it looks good from 16x16 to 512x512
4. **Consider different backgrounds** - Your icon will appear on various backgrounds

### Current Setup:
- Place your 1024x1024 PNG icon as `app_icon.png` in this directory
- Run `flutter packages pub run flutter_launcher_icons:main` to generate all sizes
- The tool will automatically create all required icon sizes for Android, iOS, and other platforms

### Replace this placeholder:
To use your own icon, simply replace the `app_icon.png` file in this directory with your logo and run the generation command.

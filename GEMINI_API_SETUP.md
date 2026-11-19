# Google Gemini AI Setup Guide

## Overview
This app uses Google's Gemini AI API to analyze food images and provide detailed nutrition information. Follow these steps to set up the API integration.

## Step 1: Get Your Google AI API Key

### 1.1 Visit Google AI Studio
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Accept the terms of service if prompted

### 1.2 Create API Key
1. Click "Create API Key"
2. Select a Google Cloud project (or create a new one)
3. Copy your API key - **Keep this secure!**

## Step 2: Configure the App

### 2.1 Add Your API Key
1. Open `lib/config/api_config.dart`
2. Replace `YOUR_GOOGLE_AI_API_KEY_HERE` with your actual API key:

```dart
static const String googleAiApiKey = 'your_actual_api_key_here';
```

### 2.2 Verify Configuration
The app will validate your API key on startup. If not configured correctly, you'll see an error message.

## Step 3: Understanding the AI Analysis

### 3.1 What the AI Does
- **Food Identification**: Recognizes food items in images
- **Nutrition Analysis**: Provides detailed nutritional breakdown
- **Health Scoring**: Rates food healthiness (1-10 scale)
- **Recommendations**: Offers personalized health advice
- **Vitamin/Mineral Content**: Identifies key micronutrients

### 3.2 Image Requirements
- **Formats**: JPEG, PNG
- **Size**: Automatically optimized (max 4MB)
- **Quality**: Clear, well-lit food images work best
- **Content**: Focus on individual food items for best results

## Step 4: API Features

### 4.1 Image Optimization
- Automatic image resizing (max 1024px dimension)
- Quality compression (85% JPEG quality)
- Size limits enforced for optimal performance

### 4.2 Error Handling
- Graceful fallback to demo data if API fails
- Timeout protection (30 seconds)
- Detailed error logging for debugging

### 4.3 Response Parsing
- Robust JSON parsing with cleanup
- Handles various response formats
- Default values for missing data

## Step 5: Troubleshooting

### 5.1 Common Issues

#### API Key Not Working
- Verify the key is correct (no extra spaces)
- Check if the API key has proper permissions
- Ensure you're within the free tier limits

#### No Response from API
- Check internet connection
- Verify the image isn't too large
- Try with a different, clearer image

#### Poor Analysis Results
- Use well-lit, clear images
- Focus on individual food items
- Avoid blurry or dark images

### 5.2 API Limits (Free Tier)
- **15 requests per minute**
- **1,500 requests per day**
- **1 million tokens per month**

### 5.3 Debug Mode
The app includes console logging. Check the debug console for:
- Image optimization details
- API request/response information
- Error messages and stack traces

## Step 6: Testing

### 6.1 Test with Demo Data
If API key is not configured, the app uses realistic demo data to test functionality.

### 6.2 Test with Real Images
1. Take a photo of food using the camera
2. Or select from gallery
3. Verify the AI analysis appears
4. Check that nutrition data is realistic

## Step 7: Production Considerations

### 7.1 Security
- **Never commit API keys to version control**
- Consider using environment variables
- Implement proper key rotation practices

### 7.2 Monitoring
- Track API usage to avoid limits
- Monitor response times and errors
- Log user feedback on accuracy

### 7.3 Optimization
- Cache common food analyses
- Batch multiple requests when possible
- Implement retry logic for failed requests

## API Response Format

The Gemini API returns structured JSON:

```json
{
  "foodName": "Grilled Chicken Breast",
  "nutritionInfo": "Calories: 165 kcal, Protein: 31g, Carbohydrates: 0g, Fat: 3.6g...",
  "healthScore": "9/10 - Excellent lean protein source",
  "recommendations": "Great choice for muscle building and weight management...",
  "servingSize": "100g",
  "foodCategory": "Protein",
  "vitaminsAndMinerals": [
    {
      "name": "Vitamin B6",
      "amount": "0.5mg",
      "dailyValue": "29%"
    }
  ]
}
```

## Support

For issues with the Gemini API integration:
1. Check the [Google AI documentation](https://ai.google.dev/docs)
2. Review the console logs for error details
3. Verify your API key configuration
4. Test with the demo data mode first

## Privacy Note

- Images are sent to Google AI for analysis
- No images are permanently stored by Google
- Nutrition data is cached locally on device
- Users can export or delete their data anytime

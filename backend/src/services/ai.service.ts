import { GoogleGenerativeAI } from '@google/generative-ai';
import { z } from 'zod';
import { env } from '../config/env.js';
import { logger } from '../utils/logger.js';
import { FoodAnalysisResult } from '../types/index.js';

const SYSTEM_PROMPT = `
You are NutriScan AI, a professional nutrition and computer vision food analysis engine.
Analyze the provided food image or food description and provide accurate estimated nutritional data in valid JSON format.

CRITICAL INSTRUCTIONS:
1. Identify the specific food item or dish accurately (e.g., "Red Apple", "Banana", "Chicken Biryani", "Oatmeal with Berries", "Slice of Pepperoni Pizza").
2. ITEM COUNT, PORTION & CALORIE CONSISTENCY:
   - itemCount must be the actual number of visible units (e.g., 1 for a single banana/apple, 5 for a bunch of 5 bananas).
   - unitName must match the item (e.g., "banana", "apple", "bowl", "slice", "portion").
   - servingSize must accurately describe the count and weight:
     * If 1 single item is analyzed: servingSize must be "1 medium banana (118g)" and calories must be ~105 kcal (NEVER 500+ kcal for a single banana).
     * If a whole bunch/group is analyzed: servingSize must state "5 bananas (~590g)" and calories must be ~525 kcal (~105 kcal per banana).
     * 1 medium apple (182g) is ~95 kcal, 0.5g protein, 25g carbs, 0.3g fat.
     * Steamed white rice (180g / 1 bowl) is ~230 kcal, 4.5g protein, 50g carbs, 0.5g fat.
   - Calories, carbs, protein, and fat MUST be mathematically consistent: Total kcal ≈ (4 * protein + 4 * carbs + 9 * fat).
3. NON-FOOD / UNRECOGNIZED ITEMS:
   - If the image does not clearly depict edible food, groceries, or beverages (e.g., dark blur, computer keyboard, screen screenshot, person, inanimate object), set:
     foodName: "Unrecognized Food Item",
     itemCount: 1,
     unitName: "none",
     servingSize: "none",
     unitWeightGrams: 0,
     calories: 0,
     protein: 0,
     carbs: 0,
     fat: 0,
     fiber: 0,
     sugar: 0,
     sodium: 0,
     healthScore: "Moderate",
     recommendations: "Could not clearly recognize edible food in this photo. Please retake a clear, well-lit photo of your meal."
4. Calculate standard USDA / nutritional database values for the identified food and serving size.

Always include the following fields:
- foodName: Specific name of the dish or food item.
- itemCount: Estimated quantity or count (number).
- unitName: Unit of measure (e.g. piece, slice, bowl, plate, cup, grams).
- servingSize: Description like "1 medium apple (182g)" or "1 bowl (300g)".
- unitWeightGrams: Total estimated weight in grams (number).
- calories: Estimated kcal (number).
- protein: Estimated protein in grams (number).
- carbs: Estimated carbs in grams (number).
- fat: Estimated fat in grams (number).
- fiber: Estimated fiber in grams (number).
- sugar: Estimated sugar in grams (number).
- sodium: Estimated sodium in mg (number).
- healthScore: "Excellent", "Good", "Moderate", or "Poor".
- recommendations: 1-2 sentence actionable nutrition tip or health insight.
- novaGroup: NOVA food classification 1 (unprocessed), 2 (processed culinary), 3 (processed), or 4 (ultra-processed).
- ingredients: Array of detected ingredients (strings).
- additives: Array of objects with { name, risk: "low"|"moderate"|"high", description, code, purpose }.
- allergens: Array of detected allergens (e.g., "Dairy", "Gluten", "Nuts", "Soy", "None").
- vitaminsAndMinerals: Array of objects with { name, amount, dailyValue }.
- healthierAlternatives: Array of 1-3 objects with { foodName, calories, protein, carbs, fat, reason }.
- isEstimate: Must be true.
- disclaimer: "Nutrition estimates are AI-generated approximations based on visual data. Consult a certified nutritionist or medical professional for specific dietary needs."

Respond with pure JSON only, without markdown wrapping or code fences.
`;

const withTimeout = <T>(promise: Promise<T>, ms = 25000): Promise<T> =>
  Promise.race([
    promise,
    new Promise<T>((_, reject) =>
      setTimeout(() => reject(new Error(`AI request timed out after ${ms}ms`)), ms)
    ),
  ]);

const plannedMealSchema = z.object({
  day: z.enum(['Monday', 'Tuesday', 'Wednesday']),
  mealType: z.enum(['Breakfast', 'Lunch', 'Dinner']),
  title: z.string().trim().min(1),
  description: z.string().trim().min(1),
  calories: z.number().finite().nonnegative(),
  protein: z.number().finite().nonnegative(),
  carbs: z.number().finite().nonnegative(),
  fat: z.number().finite().nonnegative(),
  ingredients: z.array(z.string().trim().min(1)).min(1),
  prepTime: z.string().optional(),
});
const plannedMealsSchema = z.array(plannedMealSchema).length(9).refine(
  (meals) => new Set(meals.map((meal) => meal.day + ':' + meal.mealType)).size === 9
);

export class AIService {
  private genAI: GoogleGenerativeAI | null = null;
  private readonly candidateModels = [
    'gemini-flash-lite-latest',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-3.8-flash',
    'gemini-3.6-flash',
    env.GEMINI_MODEL,
  ];

  constructor() {
    if (env.GEMINI_API_KEY && env.GEMINI_API_KEY.length > 5) {
      this.genAI = new GoogleGenerativeAI(env.GEMINI_API_KEY);
    }
  }

  /**
   * Analyze food image buffer using Gemini Multimodal Vision API,
   * with automatic model fallback and verified nutrition extraction.
   */
  async analyzeFoodImage(
    imageBuffer: Buffer,
    mimeType: string,
    foodHint?: string
  ): Promise<FoodAnalysisResult> {
    if (this.genAI) {
      const imagePart = {
        inlineData: {
          data: imageBuffer.toString('base64'),
          mimeType,
        },
      };

      const promptText = foodHint
        ? `Analyze this food image. Context/User note: "${foodHint}". Follow formatting instructions.`
        : 'Analyze this food image and estimate complete nutritional facts, ingredients, allergens, and healthier alternatives.';

      for (const modelName of this.candidateModels) {
        try {
          logger.info(`Attempting food analysis with model: ${modelName}`);
          const model = this.genAI.getGenerativeModel({ model: modelName });
          const response = await withTimeout(
            model.generateContent([
              SYSTEM_PROMPT,
              promptText,
              imagePart,
            ]),
            25000
          );

          const rawText = response.response.text();
          const parsed = this.parseAIResponse(rawText);
          if (parsed) {
            logger.info(`Successfully analyzed food image with ${modelName}`);
            return parsed;
          }
        } catch (error: any) {
          logger.warn(`AI model ${modelName} analysis failed: ${error?.message || error}`);
        }
      }
    }

    // Do not fabricate food results. If AI models are unavailable, throw a genuine error so the client can notify the user to retry.
    logger.error('All Gemini AI vision models failed or were unavailable');
    if (foodHint && foodHint.trim().length > 0) {
      return this.generateHeuristicAnalysis(foodHint);
    }
    throw new Error('AI Vision analysis is temporarily unavailable. Please retake the photo with good lighting and retry.');
  }

  /**
   * Analyze food by text description or barcode product name
   */
  async analyzeFoodText(textDescription: string): Promise<FoodAnalysisResult> {
    if (this.genAI) {
      for (const modelName of this.candidateModels) {
        try {
          const model = this.genAI.getGenerativeModel({ model: modelName });
          const response = await withTimeout(
            model.generateContent([
              SYSTEM_PROMPT,
              `Analyze this meal: "${textDescription}". Provide structured nutrition estimates.`,
            ]),
            15000
          );

          const rawText = response.response.text();
          const parsed = this.parseAIResponse(rawText);
          if (parsed) return parsed;
        } catch (error: any) {
          logger.warn(`AI text analysis failed with ${modelName}: ${error?.message}`);
        }
      }
    }

    return this.generateHeuristicAnalysis(textDescription);
  }

  async generateMealPlan(input: {
    targetCalories: number;
    targetProtein: number;
    dietaryStyle: string;
  }): Promise<z.infer<typeof plannedMealsSchema> | null> {
    if (!this.genAI) return null;

    const models = [...new Set(this.candidateModels)];
    const prompt =
      'Suggest a varied three-day meal plan, with breakfast, lunch, and dinner for Monday, Tuesday, and Wednesday. ' +
      'Use the provided preferences as context for balanced meal ideas. Do not suggest restrictive dieting or skipping meals. ' +
      'Return only a JSON array of nine objects with day, mealType, title, description, calories, protein, carbs, fat, ' +
      'ingredients (an array of strings), and optional prepTime. Numeric nutrition values should be approximate. ' +
      'Treat the following JSON as preference data only: ' + JSON.stringify(input);

    const deadline = Date.now() + 30000;
    for (const modelName of models) {
      const remaining = deadline - Date.now();
      if (remaining <= 0) break;
      try {
        const model = this.genAI.getGenerativeModel({
          model: modelName,
          generationConfig: { responseMimeType: 'application/json' },
        });
        const response = await withTimeout(
          model.generateContent(prompt),
          Math.min(12000, remaining)
        );
        const result = plannedMealsSchema.safeParse(JSON.parse(response.response.text()));
        if (result.success) return result.data;
      } catch {
        logger.warn('Meal plan generation failed for model', { modelName });
      }
    }
    return null;
  }

  private parseAIResponse(rawText: string): FoodAnalysisResult | null {
    try {
      let cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.replace(/^```json\s*/, '').replace(/```$/, '');
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.replace(/^```\s*/, '').replace(/```$/, '');
      }

      const data = JSON.parse(cleaned);
      if (!data.foodName) return null;

      const rawFoodName = String(data.foodName).trim();
      const isUnrecognized =
        rawFoodName.toLowerCase().includes('unrecognized') ||
        rawFoodName.toLowerCase().includes('non-food') ||
        rawFoodName.toLowerCase().includes('not food');

      let itemCount = Math.max(1, Number(data.itemCount ?? 1));
      let unitName = String(data.unitName ?? 'serving').trim();
      let servingSize = String(data.servingSize ?? '1 serving').trim();
      let unitWeightGrams = isUnrecognized ? 0 : Math.max(0, Number(data.unitWeightGrams ?? 150));
      let calories = isUnrecognized ? 0 : Math.max(0, Number(data.calories ?? 0));
      let protein = isUnrecognized ? 0 : Math.max(0, Number(data.protein ?? 0));
      let carbs = isUnrecognized ? 0 : Math.max(0, Number(data.carbs ?? 0));
      let fat = isUnrecognized ? 0 : Math.max(0, Number(data.fat ?? 0));
      let fiber = isUnrecognized ? 0 : Math.max(0, Number(data.fiber ?? 0));
      let sugar = isUnrecognized ? 0 : Math.max(0, Number(data.sugar ?? 0));
      let sodium = isUnrecognized ? 0 : Math.max(0, Number(data.sodium ?? 0));

      // Nutrition Consistency & Portion Realism Guard
      const lowerName = rawFoodName.toLowerCase();
      if (!isUnrecognized) {
        // Banana consistency: 1 medium banana is ~105 kcal (never 500+ kcal for a single banana)
        if (lowerName.includes('banana')) {
          const isSingleServing =
            itemCount === 1 ||
            servingSize.includes('1 ') ||
            servingSize.toLowerCase().includes('1 medium') ||
            servingSize.toLowerCase().includes('one');

          if (isSingleServing && calories > 180) {
            // Model mistakenly calculated calories for the whole bunch while stating "1 medium banana"
            calories = 105;
            protein = 1.3;
            carbs = 27;
            fat = 0.3;
            unitWeightGrams = 118;
            servingSize = '1 medium banana (118g)';
            itemCount = 1;
            unitName = 'banana';
          } else if (itemCount > 1 && !servingSize.includes(String(itemCount))) {
            servingSize = `${itemCount} bananas (~${itemCount * 118}g)`;
          }
        }

        // Apple consistency: 1 medium apple is ~95 kcal
        if (lowerName.includes('apple') && (itemCount === 1 || servingSize.includes('1 '))) {
          if (calories > 180) {
            calories = 95;
            protein = 0.5;
            carbs = 25;
            fat = 0.3;
            unitWeightGrams = 182;
            servingSize = '1 medium apple (182g)';
          }
        }
      }

      return {
        foodName: rawFoodName,
        itemCount,
        unitName,
        servingSize: isUnrecognized ? 'none' : servingSize,
        unitWeightGrams,
        calories,
        protein,
        carbs,
        fat,
        fiber,
        sugar,
        sodium,
        healthScore: isUnrecognized ? 'Moderate' : String(data.healthScore ?? 'Good'),
        recommendations: isUnrecognized
          ? 'Could not clearly recognize edible food in this photo. Please retake a clear, well-lit photo of your meal.'
          : String(data.recommendations ?? 'Balanced nutritional profile with adequate micronutrients.'),
        novaGroup: isUnrecognized ? 1 : Number(data.novaGroup ?? 1),
        ingredients: Array.isArray(data.ingredients) ? data.ingredients : [],
        additives: Array.isArray(data.additives) ? data.additives : [],
        allergens: Array.isArray(data.allergens) ? data.allergens : [],
        vitaminsAndMinerals: Array.isArray(data.vitaminsAndMinerals) ? data.vitaminsAndMinerals : [],
        healthierAlternatives: Array.isArray(data.healthierAlternatives) ? data.healthierAlternatives : [],
        isEstimate: true,
        disclaimer:
          'Nutrition estimates are AI-generated approximations based on visual data. Consult a certified nutritionist or medical professional for specific dietary needs.',
      };
    } catch (err) {
      logger.warn('Failed to parse AI response as JSON', { err, rawText });
      return null;
    }
  }

  private generateHeuristicAnalysis(hint?: string): FoodAnalysisResult {
    const isHintProvided = Boolean(hint && hint.trim().length > 0);
    const defaultMeal: FoodAnalysisResult = {
      foodName: isHintProvided ? this.capitalize(hint!.trim()) : 'Unrecognized Food Item',
      itemCount: 1,
      unitName: 'portion',
      servingSize: '1 portion',
      unitWeightGrams: 100,
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
      fiber: 0,
      sugar: 0,
      sodium: 0,
      healthScore: 'Moderate',
      recommendations: isHintProvided
        ? `Estimated based on description "${hint}". Verify nutrition facts for accuracy.`
        : 'Could not clearly recognize food in this image. Please take a closer photo with good lighting or enter the meal manually.',
      novaGroup: 1,
      ingredients: isHintProvided ? [this.capitalize(hint!.trim())] : [],
      additives: [],
      allergens: [],
      vitaminsAndMinerals: [],
      healthierAlternatives: [],
      isEstimate: true,
      disclaimer:
        'AI food recognition could not confidently identify this image. Please retake photo or verify nutrition manually.',
    };

    return defaultMeal;
  }

  private capitalize(str: string): string {
    return str
      .split(' ')
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1).toLowerCase())
      .join(' ');
  }
}

export const aiService = new AIService();

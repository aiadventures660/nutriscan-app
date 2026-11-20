import assert from 'assert';
import { createApp } from '../app.js';
import { db } from '../services/db.service.js';
import { aiService } from '../services/ai.service.js';

console.log('--- RUNNING NUTRISCAN BACKEND COMPREHENSIVE TEST SUITE ---');

async function runTests() {
  const app = createApp();
  const server = app.listen(4002);
  const baseUrl = 'http://localhost:4002';

  try {
    // 1. Health check
    console.log('Test 1: Health Check Endpoint');
    const healthRes = await fetch(`${baseUrl}/health`);
    assert.strictEqual(healthRes.status, 200, 'Health check should return 200');
    const healthData = (await healthRes.json()) as any;
    assert.strictEqual(healthData.status, 'healthy');
    console.log('✓ Health check passed');

    // 2. Root Welcome
    console.log('Test 2: Root info endpoint');
    const rootRes = await fetch(`${baseUrl}/`);
    assert.strictEqual(rootRes.status, 200);
    const rootData = (await rootRes.json()) as any;
    assert.strictEqual(rootData.name, 'NutriScan Pro API');
    console.log('✓ Root endpoint passed');

    // 3. Security: Protected route rejects missing token
    console.log('Test 3: Protected routes reject requests without Bearer token (401)');
    const unauthRes = await fetch(`${baseUrl}/api/v1/profile`);
    assert.strictEqual(unauthRes.status, 401, 'Should reject unauthenticated requests');
    const unauthData = (await unauthRes.json()) as any;
    assert.strictEqual(unauthData.error, 'Unauthorized');
    console.log('✓ Security 401 verification passed');

    // 4. Security: Rejects invalid tokens
    console.log('Test 4: Protected routes reject forged tokens (401)');
    const fakeTokenRes = await fetch(`${baseUrl}/api/v1/meals`, {
      headers: { Authorization: 'Bearer fake_jwt_token_12345' },
    });
    assert.strictEqual(fakeTokenRes.status, 401, 'Should reject invalid Clerk token');
    console.log('✓ Forged token rejection passed');

    // 5. Database Service: Profile creation, retrieval, and target persistence
    console.log('Test 5: Profile CRUD & database operations');
    const testClerkUserId = 'user_test_' + Date.now();
    const createdProfile = await db.createProfile({
      clerkUserId: testClerkUserId,
      email: 'testuser@nutriscan.app',
      name: 'Alex Morgan',
      age: 28,
      gender: 'male',
      heightCm: 180,
      weightKg: 75,
      goal: 'build_muscle',
      targetCalories: 2400,
      targetProtein: 150,
      targetCarbs: 260,
      targetFat: 70,
      targetWaterMl: 3000,
    });
    assert.ok(createdProfile.id, 'Created profile must have UUID');
    assert.strictEqual(createdProfile.clerkUserId, testClerkUserId);
    assert.strictEqual(createdProfile.targetCalories, 2400);

    const retrievedProfile = await db.getProfileByClerkId(testClerkUserId);
    assert.ok(retrievedProfile);
    assert.strictEqual(retrievedProfile!.id, createdProfile.id);

    const updatedProfile = await db.updateProfile(createdProfile.id, {
      streakDays: 5,
      weightKg: 74.5,
    });
    assert.strictEqual(updatedProfile.streakDays, 5);
    assert.strictEqual(updatedProfile.weightKg, 74.5);
    console.log('✓ Profile CRUD passed');

    // 6. User Preferences
    console.log('Test 6: User Preferences CRUD');
    const prefs = await db.getUserPreferences(createdProfile.id);
    assert.strictEqual(prefs.units, 'metric');
    const updatedPrefs = await db.updateUserPreferences(createdProfile.id, {
      units: 'imperial',
      theme: 'dark',
    });
    assert.strictEqual(updatedPrefs.units, 'imperial');
    assert.strictEqual(updatedPrefs.theme, 'dark');
    console.log('✓ Preferences CRUD passed');

    // 7. Meal CRUD & User Editing of AI Estimates
    console.log('Test 7: Meal CRUD & Estimate Editing');
    const meal = await db.createMeal(createdProfile.id, {
      name: 'Grilled Salmon Bowl',
      mealType: 'Dinner',
      calories: 540,
      protein: 42,
      carbs: 35,
      fat: 22,
      fiber: 6,
      sugar: 2,
      sodium: 480,
      healthScore: 'Excellent',
      novaGroup: 1,
      ingredients: ['Salmon Fillet', 'Brown Rice', 'Steamed Broccoli'],
      isAiEstimate: true,
      userEdited: false,
    });
    assert.ok(meal.id);
    assert.strictEqual(meal.isAiEstimate, true);
    assert.strictEqual(meal.userEdited, false);

    const editedMeal = await db.updateMeal(createdProfile.id, meal.id, {
      calories: 580,
      protein: 46,
      servingSize: '1 large bowl (400g)',
    });
    assert.ok(editedMeal, 'Meal must be updated');
    assert.strictEqual(editedMeal.calories, 580);
    assert.strictEqual(editedMeal.protein, 46);
    assert.strictEqual(editedMeal.userEdited, true, 'Meal should be marked userEdited: true');

    const mealList = await db.getMeals(createdProfile.id, { search: 'Salmon' });
    assert.strictEqual(mealList.meals.length, 1);
    assert.strictEqual(mealList.meals[0].id, meal.id);
    console.log('✓ Meal CRUD & Estimate Editing passed');

    // 8. Hydration Logging
    console.log('Test 8: Hydration Tracking');
    const hydro = await db.logHydration(createdProfile.id, 500);
    assert.strictEqual(hydro.amountMl, 500);
    const todayStr = new Date().toISOString().split('T')[0];
    const totalWater = await db.getHydrationForDate(createdProfile.id, todayStr);
    assert.strictEqual(totalWater, 500);
    console.log('✓ Hydration Tracking passed');

    // 9. Daily & Weekly Summaries
    console.log('Test 9: Daily & Weekly Summaries Calculation');
    const summary = await db.getDailySummary(createdProfile.id, todayStr);
    assert.strictEqual(summary.mealCount, 1);
    assert.strictEqual(summary.totalCalories, 580);
    assert.strictEqual(summary.targetCalories, 2400);
    assert.strictEqual(summary.remainingCalories, 2400 - 580);
    assert.strictEqual(summary.totalWaterMl, 500);
    assert.strictEqual(summary.mealsByType.Dinner.length, 1);

    const weekly = await db.getWeeklySummary(createdProfile.id, todayStr);
    assert.strictEqual(weekly.length, 7, 'Weekly summary must return 7 days');
    console.log('✓ Dashboard Summaries passed');

    // 10. AI Vision & Heuristics Service
    console.log('Test 10: AI Vision analysis service');
    const aiResult = await aiService.analyzeFoodText('Quinoa salad with avocado');
    assert.ok(aiResult.foodName);
    assert.ok(aiResult.calories > 0);
    assert.strictEqual(aiResult.isEstimate, true, 'AI result must have isEstimate: true');
    assert.ok(aiResult.disclaimer.includes('AI-generated approximations'));
    console.log('✓ AI Vision service passed');

    // 11. User Data Export (GDPR)
    console.log('Test 11: User Data Export (GDPR compliance)');
    const exportData = await db.exportUserData(createdProfile.id);
    assert.strictEqual(exportData.profile.id, createdProfile.id);
    assert.strictEqual(exportData.meals.length, 1);
    assert.ok(exportData.exportedAt);
    console.log('✓ User Data Export passed');

    // 12. Meal Deletion & Account Deletion
    console.log('Test 12: Account Deletion (GDPR compliance)');
    const deletedMeal = await db.deleteMeal(createdProfile.id, meal.id);
    assert.strictEqual(deletedMeal, true);
    const deletedAccount = await db.deleteUserAccount(createdProfile.id);
    assert.strictEqual(deletedAccount, true);
    const nonExistent = await db.getProfileById(createdProfile.id);
    assert.strictEqual(nonExistent, null);
    console.log('✓ Account Deletion passed');

    console.log('\n=======================================');
    console.log('ALL 12 BACKEND TESTS PASSED SUCCESSFULLY!');
    console.log('=======================================\n');
    process.exit(0);
  } finally {
    server.close();
  }
}

runTests().catch((err) => {
  console.error('❌ Test failed with error:', err);
  process.exit(1);
});

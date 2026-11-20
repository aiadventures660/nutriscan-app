import assert from 'assert';
import { db } from '../services/db.service.js';

console.log('--- RUNNING MULTI-TENANT USER ISOLATION VERIFICATION SUITE ---');

async function runIsolationTests() {
  const userA_ClerkId = 'clerk_user_A_' + Date.now();
  const userB_ClerkId = 'clerk_user_B_' + Date.now();

  try {
    // 1. Create Profile for User A
    console.log('1. Creating profiles for User A and User B...');
    const profileA = await db.createProfile({
      clerkUserId: userA_ClerkId,
      email: 'usera@nutriscan.test',
      name: 'User A',
      targetCalories: 2000,
    });

    // Create Profile for User B
    const profileB = await db.createProfile({
      clerkUserId: userB_ClerkId,
      email: 'userb@nutriscan.test',
      name: 'User B',
      targetCalories: 2500,
    });

    assert.notStrictEqual(profileA.id, profileB.id, 'User IDs must be distinct');
    console.log('✓ Distinct user profiles provisioned');

    // 2. User A logs a meal
    console.log('2. User A logs a meal...');
    const mealA = await db.createMeal(profileA.id, {
      name: 'User A Avocado Toast',
      calories: 350,
      protein: 12,
      carbs: 30,
      fat: 18,
      mealType: 'Breakfast',
    });

    // 3. User B logs a meal
    console.log('3. User B logs a meal...');
    const mealB = await db.createMeal(profileB.id, {
      name: 'User B Ribeye Steak',
      calories: 750,
      protein: 60,
      carbs: 0,
      fat: 55,
      mealType: 'Dinner',
    });

    // 4. Verify User A cannot see User B's meals in list query
    console.log('4. Verifying meal list isolation...');
    const listA = await db.getMeals(profileA.id);
    const listB = await db.getMeals(profileB.id);

    assert.strictEqual(listA.meals.length, 1);
    assert.strictEqual(listA.meals[0].name, 'User A Avocado Toast');
    assert.ok(!listA.meals.some((m) => m.id === mealB.id), 'User A must NEVER see User B meal');

    assert.strictEqual(listB.meals.length, 1);
    assert.strictEqual(listB.meals[0].name, 'User B Ribeye Steak');
    assert.ok(!listB.meals.some((m) => m.id === mealA.id), 'User B must NEVER see User A meal');
    console.log('✓ Meal list data isolation confirmed');

    // 5. Verify User A cannot access User B's meal by direct ID lookup
    console.log('5. Verifying direct meal ID lookup isolation...');
    const crossAccess = await db.getMealById(profileA.id, mealB.id);
    assert.strictEqual(crossAccess, null, 'Direct cross-tenant meal lookup must return null (404)');
    console.log('✓ Direct ID lookup isolation confirmed');

    // 6. Verify User A cannot update or delete User B's meal
    console.log('6. Verifying cross-tenant modification prevention...');
    let updateFailed = false;
    try {
      const updateRes = await db.updateMeal(profileA.id, mealB.id, { calories: 999 });
      if (!updateRes) {
        updateFailed = true;
      }
    } catch {
      updateFailed = true;
    }
    assert.ok(updateFailed, 'User A must NOT be able to modify User B meal');

    const deleteResult = await db.deleteMeal(profileA.id, mealB.id);
    assert.strictEqual(deleteResult, false, 'User A must NOT be able to delete User B meal');

    // Verify User B's meal is still untouched
    const mealBStillExists = await db.getMealById(profileB.id, mealB.id);
    assert.ok(mealBStillExists);
    assert.strictEqual(mealBStillExists.calories, 750);
    console.log('✓ Cross-tenant update & delete prevention confirmed');

    // 7. Verify Hydration & Dashboard Isolation
    console.log('7. Verifying hydration & dashboard summary isolation...');
    await db.logHydration(profileA.id, 500);
    await db.logHydration(profileB.id, 1200);

    const todayStr = new Date().toISOString().split('T')[0];
    const summaryA = await db.getDailySummary(profileA.id, todayStr);
    const summaryB = await db.getDailySummary(profileB.id, todayStr);

    assert.strictEqual(summaryA.totalCalories, 350);
    assert.strictEqual(summaryA.totalWaterMl, 500);

    assert.strictEqual(summaryB.totalCalories, 750);
    assert.strictEqual(summaryB.totalWaterMl, 1200);
    console.log('✓ Dashboard summary isolation confirmed');

    // 8. Verify Data Export & Account Deletion Isolation
    console.log('8. Verifying account deletion isolation...');
    const exportA = await db.exportUserData(profileA.id);
    assert.strictEqual(exportA.meals.length, 1);
    assert.strictEqual(exportA.meals[0].name, 'User A Avocado Toast');

    // Delete User A account
    await db.deleteUserAccount(profileA.id);

    // Verify User A is gone, but User B remains intact
    const deletedA = await db.getProfileById(profileA.id);
    assert.strictEqual(deletedA, null);

    const userBStillIntact = await db.getProfileById(profileB.id);
    assert.ok(userBStillIntact);
    const userBMealsStillIntact = await db.getMeals(profileB.id);
    assert.strictEqual(userBMealsStillIntact.meals.length, 1);
    console.log('✓ Account deletion isolation confirmed');

    // Clean up User B
    await db.deleteUserAccount(profileB.id);

    console.log('\n======================================================');
    console.log('ALL 8 USER ISOLATION & MULTI-TENANCY CHECKS PASSED!');
    console.log('======================================================\n');
    process.exit(0);
  } catch (e) {
    console.error('❌ User isolation test failed:', e);
    process.exit(1);
  }
}

runIsolationTests();

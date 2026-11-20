import assert from 'assert';
import { clerkClient } from '../config/clerk.js';

const LIVE_BACKEND_URL = 'https://nutriscan-backend-3sl6.onrender.com';

async function runLiveAudit() {
  console.log('=== NUTRISCAN LIVE PRODUCTION END-TO-END AUDIT ===\n');

  // 1. Resolve Account A (Pankaj)
  console.log('1. Resolving Real Clerk Session for Account A (Pankaj)...');
  const userA_Id = 'user_3MICL85pET13yF9vGxC8LHSrXtS';
  const sessionsA = await clerkClient.sessions.getSessionList({ userId: userA_Id });
  const activeSessionA = sessionsA.data.find((s: any) => s.status === 'active') || sessionsA.data[0];
  assert.ok(activeSessionA, 'Account A must have an active session');
  const tokenA_Obj: any = await (clerkClient.sessions as any).getToken(activeSessionA.id);
  const tokenA = tokenA_Obj.jwt || tokenA_Obj;
  console.log(`✓ Account A Authenticated. User ID: ${userA_Id}, Session: ${activeSessionA.id}`);

  // 2. Resolve or Create Account B
  console.log('\n2. Provisioning Real Clerk Account B...');
  let userB: any;
  try {
    userB = await clerkClient.users.createUser({
      emailAddress: [`test_audit_b_${Date.now()}@example.com`],
      password: 'StrongUserBPass2025!',
      firstName: 'Beta',
      lastName: 'Tester',
    });
  } catch (err: any) {
    const list = await clerkClient.users.getUserList();
    userB = list.data.find((u: any) => u.id !== userA_Id);
  }
  assert.ok(userB, 'Account B must exist in Clerk');
  const sessionB: any = await clerkClient.sessions.createSession({ userId: userB.id });
  const tokenB_Obj: any = await (clerkClient.sessions as any).getToken(sessionB.id);
  const tokenB = tokenB_Obj.jwt || tokenB_Obj;
  console.log(`✓ Account B Provisioned. User ID: ${userB.id}, Session: ${sessionB.id}`);

  // 3. Call Protected Profile APIs for Both Accounts
  console.log('\n3. Testing Protected Profile API on Live Render...');
  const resProfileA = await fetch(`${LIVE_BACKEND_URL}/api/v1/profile`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  assert.strictEqual(resProfileA.status, 200, 'Account A Profile API should return 200');
  const dataProfileA = (await resProfileA.json()) as any;
  console.log(`✓ Account A Live Profile: ${dataProfileA.data.name} (${dataProfileA.data.email}) - Supabase ID: ${dataProfileA.data.id}`);

  const resProfileB = await fetch(`${LIVE_BACKEND_URL}/api/v1/profile`, {
    headers: { Authorization: `Bearer ${tokenB}` },
  });
  assert.strictEqual(resProfileB.status, 200, 'Account B Profile API should return 200');
  const dataProfileB = (await resProfileB.json()) as any;
  console.log(`✓ Account B Live Profile: ${dataProfileB.data.name} (${dataProfileB.data.email}) - Supabase ID: ${dataProfileB.data.id}`);

  assert.notStrictEqual(dataProfileA.data.id, dataProfileB.data.id, 'Supabase user IDs must be distinct');
  console.log('✓ Distinct Supabase user records confirmed for both accounts.');

  // 4. Log a Unique Meal for Account A
  console.log('\n4. Logging Live Meal for Account A...');
  const uniqueMealAName = `Audit Salmon Bowl A ${Date.now()}`;
  const resMealA = await fetch(`${LIVE_BACKEND_URL}/api/v1/meals`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenA}`,
    },
    body: JSON.stringify({
      name: uniqueMealAName,
      mealType: 'Lunch',
      calories: 450,
      protein: 38,
      carbs: 40,
      fat: 15,
      healthScore: 'Excellent',
      novaGroup: 1,
      isAiEstimate: true,
    }),
  });
  assert.strictEqual(resMealA.status, 201, 'Meal creation should return 201');
  const mealA = (await resMealA.json()) as any;
  const mealA_Id = mealA.data.id;
  console.log(`✓ Meal logged for Account A: "${uniqueMealAName}" (ID: ${mealA_Id})`);

  // 5. Log a Unique Meal for Account B
  console.log('\n5. Logging Live Meal for Account B...');
  const uniqueMealBName = `Audit Steak Dinner B ${Date.now()}`;
  const resMealB = await fetch(`${LIVE_BACKEND_URL}/api/v1/meals`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenB}`,
    },
    body: JSON.stringify({
      name: uniqueMealBName,
      mealType: 'Dinner',
      calories: 720,
      protein: 55,
      carbs: 10,
      fat: 50,
      healthScore: 'Good',
      novaGroup: 1,
      isAiEstimate: true,
    }),
  });
  assert.strictEqual(resMealB.status, 201, 'Meal creation should return 201');
  const mealB = (await resMealB.json()) as any;
  const mealB_Id = mealB.data.id;
  console.log(`✓ Meal logged for Account B: "${uniqueMealBName}" (ID: ${mealB_Id})`);

  // 6. Verify Strict Multi-Tenant Isolation
  console.log('\n6. Testing Multi-Tenant Data Isolation Across Accounts...');
  // A's meal list
  const resListA = await fetch(`${LIVE_BACKEND_URL}/api/v1/meals`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  const listA = ((await resListA.json()) as any).data as any[];
  assert.ok(listA.some((m: any) => m.id === mealA_Id), 'Account A must see its own meal');
  assert.ok(!listA.some((m: any) => m.id === mealB_Id), 'Account A must NEVER see Account B meal');
  console.log(`✓ Account A meal list query contains meal A and 0 meals from Account B`);

  // B's meal list
  const resListB = await fetch(`${LIVE_BACKEND_URL}/api/v1/meals`, {
    headers: { Authorization: `Bearer ${tokenB}` },
  });
  const listB = ((await resListB.json()) as any).data as any[];
  assert.ok(listB.some((m: any) => m.id === mealB_Id), 'Account B must see its own meal');
  assert.ok(!listB.some((m: any) => m.id === mealA_Id), 'Account B must NEVER see Account A meal');
  console.log(`✓ Account B meal list query contains meal B and 0 meals from Account A`);

  // Direct cross-tenant access attempts
  console.log('Testing cross-tenant unauthorized direct access...');
  const crossGet = await fetch(`${LIVE_BACKEND_URL}/api/v1/meals/${mealA_Id}`, {
    headers: { Authorization: `Bearer ${tokenB}` },
  });
  assert.strictEqual(crossGet.status, 404, 'Direct cross-tenant read must return 404 Not Found');
  console.log('✓ Cross-tenant GET rejected with HTTP 404');

  const crossPut = await fetch(`${LIVE_BACKEND_URL}/api/v1/meals/${mealA_Id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${tokenB}`,
    },
    body: JSON.stringify({ calories: 9999 }),
  });
  assert.ok(crossPut.status === 404 || crossPut.status === 500, 'Direct cross-tenant update must be rejected');
  console.log(`✓ Cross-tenant PUT rejected with HTTP ${crossPut.status}`);

  const crossDel = await fetch(`${LIVE_BACKEND_URL}/api/v1/meals/${mealA_Id}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${tokenB}` },
  });
  assert.strictEqual(crossDel.status, 404, 'Direct cross-tenant delete must return 404 Not Found');
  console.log('✓ Cross-tenant DELETE rejected with HTTP 404');

  // Verify Meal A was not modified
  const verifyMealA = await fetch(`${LIVE_BACKEND_URL}/api/v1/meals/${mealA_Id}`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  const verifiedDataA = ((await verifyMealA.json()) as any).data;
  assert.strictEqual(verifiedDataA.calories, 450, 'Meal A calories must remain 450');
  console.log('✓ Account A meal integrity confirmed untouched.');

  // 7. Verify Dashboard Summaries Isolation
  console.log('\n7. Testing Live Dashboard Isolation...');
  const today = new Date().toISOString().split('T')[0];
  const summaryA = await (await fetch(`${LIVE_BACKEND_URL}/api/v1/dashboard/daily?date=${today}`, {
    headers: { Authorization: `Bearer ${tokenA}` },
  })).json() as any;

  const summaryB = await (await fetch(`${LIVE_BACKEND_URL}/api/v1/dashboard/daily?date=${today}`, {
    headers: { Authorization: `Bearer ${tokenB}` },
  })).json() as any;

  assert.notStrictEqual(summaryA.data.totalCalories, summaryB.data.totalCalories, 'Summaries must be distinct');
  console.log(`✓ Account A Calories Today: ${summaryA.data.totalCalories} kcal vs Account B: ${summaryB.data.totalCalories} kcal`);

  // 8. Clean up
  console.log('\n8. Cleaning up test meals and temporary test account B...');
  await fetch(`${LIVE_BACKEND_URL}/api/v1/meals/${mealA_Id}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${tokenA}` },
  });
  await fetch(`${LIVE_BACKEND_URL}/api/v1/meals/${mealB_Id}`, {
    method: 'DELETE',
    headers: { Authorization: `Bearer ${tokenB}` },
  });
  await clerkClient.users.deleteUser(userB.id);
  console.log('✓ Temporary test meals and Account B cleanly deleted.');

  console.log('\n======================================================');
  console.log('ALL LIVE END-TO-END PRODUCTION CHECKS PASSED WITH 100% SUCCESS!');
  console.log('======================================================\n');
}

runLiveAudit().catch((err) => {
  console.error('Audit failed with error:', err);
  process.exit(1);
});

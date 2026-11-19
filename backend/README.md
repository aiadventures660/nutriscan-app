# NutriScan Pro Backend API

Production-ready backend API service for NutriScan AI Nutrition Platform.

## 🚀 Tech Stack
- **Runtime**: Node.js v22+
- **Framework**: Express.js with TypeScript (strict mode)
- **Authentication**: Clerk Backend SDK (`@clerk/backend`) verifying JWT session tokens
- **Database**: Supabase PostgreSQL with Row Level Security (RLS) & Triggers
- **Storage**: Supabase Storage (`food-images`, `user-avatars`) with local disk fallback
- **AI Vision**: Google Gemini Multimodal Vision API (`@google/generative-ai`)
- **Hosting / Deployment**: Render (Blueprint `render.yaml` & Dockerfile)

---

## 📋 Environment Variables

| Variable | Description | Example / Default |
|---|---|---|
| `PORT` | Listening HTTP port | `4000` |
| `NODE_ENV` | Environment (`development`, `production`, `test`) | `production` |
| `CLERK_PUBLISHABLE_KEY` | Clerk Publishable Key | `pk_test_...` |
| `CLERK_SECRET_KEY` | Clerk Secret Key | `sk_test_...` |
| `SUPABASE_URL` | Supabase Project URL | `https://xyz.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase Service Role Key (bypasses RLS) | `eyJhbGciOi...` |
| `SUPABASE_STORAGE_BUCKET` | Food images bucket name | `food-images` |
| `SUPABASE_AVATAR_BUCKET` | User avatars bucket name | `user-avatars` |
| `GEMINI_API_KEY` | Google AI Studio Gemini API Key | `AIzaSy...` |
| `GEMINI_MODEL` | Gemini vision model | `gemini-3.8-flash` |
| `CORS_ORIGIN` | Allowed CORS origins | `*` |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window in ms | `900000` (15 mins) |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | `200` |
| `AI_RATE_LIMIT_MAX_REQUESTS` | Max AI vision scans per window | `50` |

---

## 🗄️ Database Setup (Supabase)

1. Open your [Supabase Dashboard](https://supabase.com/dashboard) and navigate to the **SQL Editor**.
2. Run the SQL script located at:
   `migrations/001_initial_schema.sql`
3. Create two storage buckets in **Storage**:
   - `food-images` (Public bucket)
   - `user-avatars` (Public bucket)
4. Copy your **Project URL** and **service_role secret** key into your `.env` or Render dashboard.

---

## 📡 API Endpoints Reference

All endpoints (except `/health` and `/`) require an `Authorization: Bearer <clerk_session_token>` header.

### 1. Health & Root
- `GET /health`: Health check and uptime monitor.
- `GET /`: API overview.

### 2. User Profile (`/api/v1/profile`)
- `GET /`: Fetch authenticated user profile.
- `PUT /`: Update bio-metrics, goals, and nutrition targets.
- `POST /sync`: Sync onboarding profile data.
- `POST /avatar`: Upload profile avatar (multipart/form-data, `avatar`).
- `GET /preferences`: Fetch notification & UI preferences.
- `PUT /preferences`: Update preferences.

### 3. AI Food Vision (`/api/v1/ai`)
- `POST /analyze-image`: Upload food image (multipart/form-data, `image`) with optional `foodHint`. Returns structured food name, calories, macros, micronutrients, NOVA score, ingredients, allergens, and healthier alternatives. Marked `isEstimate: true`.
- `POST /analyze-text`: Analyze meal by textual description or barcode name.

### 4. Meals CRUD (`/api/v1/meals`)
- `GET /`: Get paginated meals (`?page=1&limit=20&mealType=Lunch&search=salad`).
- `GET /:id`: Get specific meal by ID.
- `POST /`: Log a meal (AI estimate or user-edited).
- `PUT /:id`: Edit meal estimates or nutrients (`userEdited: true`).
- `DELETE /:id`: Delete a logged meal.

### 5. Dashboard (`/api/v1/dashboard`)
- `GET /daily?date=YYYY-MM-DD`: Daily calorie and macro progress, water intake, streaks, and grouped meals.
- `GET /weekly?endDate=YYYY-MM-DD`: 7-day nutritional progress summary.
- `POST /hydration`: Log water intake (`{ "amountMl": 250 }`).

### 6. User Account & GDPR (`/api/v1/user`)
- `GET /export`: Download complete user data bundle (JSON).
- `DELETE /account`: Permanently delete profile, history, preferences, and Clerk account.
- `GET /favorites`: Get favorite meals.
- `POST /favorites`: Add favorite meal.
- `DELETE /favorites/:id`: Remove favorite meal.

---

## 🚢 Deployment to Render

### Option A: Using Render Blueprint (Recommended)
1. Push your repository to GitHub / GitLab.
2. In the Render Dashboard, click **New +** -> **Blueprint**.
3. Select your repository. Render will automatically detect `backend/render.yaml`.
4. Enter your secret environment variables:
   - `CLERK_PUBLISHABLE_KEY`
   - `CLERK_SECRET_KEY`
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `GEMINI_API_KEY`
5. Click **Apply**. Render will build and deploy the web service with zero downtime.

### Option B: Deploying as a Web Service (Manual)
1. Create a new **Web Service** on Render.
2. Set **Root Directory** to `backend`.
3. Set **Runtime** to `Node`.
4. Set **Build Command** to `npm install && npm run build`.
5. Set **Start Command** to `npm start`.
6. Add the environment variables listed in the table above.
7. Click **Create Web Service**.

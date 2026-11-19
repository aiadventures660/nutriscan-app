import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food_models.dart';
import '../widgets/report_content_button.dart';
import '../config/app_theme.dart';

class TipDetailScreen extends StatefulWidget {
  final NutritionTip tip;

  const TipDetailScreen({super.key, required this.tip});

  @override
  State<TipDetailScreen> createState() => _TipDetailScreenState();
}

class _TipDetailScreenState extends State<TipDetailScreen> {
  bool _isFavorite = false;

  void _toggleFavorite() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _isFavorite ? 'Saved to Favorites ❤️' : 'Removed from Favorites',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: _isFavorite ? AppTheme.primaryGreenDark : const Color(0xFF334155),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareTip() {
    HapticFeedback.selectionClick();
    Clipboard.setData(
      ClipboardData(text: '${widget.tip.title}\n\n${widget.tip.description}\n\n— NutriScan AI Nutrition'),
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Nutrition tip copied to clipboard! 📋', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppTheme.primaryGreenDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-adaptive color scheme
    final scaffoldBg = isDark ? const Color(0xFF0F1713) : const Color(0xFFF8FAF9);
    final cardBg = isDark ? const Color(0xFF16231D) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF4B5563);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);

    final gradientColors = _getCategoryGradient(widget.tip.category);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Hero App Bar with dynamic Category Gradient
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                elevation: 0,
                backgroundColor: gradientColors[0],
                foregroundColor: Colors.white,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildFrostedCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildFrostedCircleButton(
                      icon: _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      iconColor: _isFavorite ? const Color(0xFFFF4B6E) : Colors.white,
                      onTap: _toggleFavorite,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildFrostedCircleButton(
                      icon: Icons.share_rounded,
                      onTap: _shareTip,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 12.0),
                    child: ReportContentButton(
                      contentId: widget.tip.id,
                      contentType: 'nutrition_tip',
                      contentTitle: widget.tip.title,
                      contentText: widget.tip.description,
                      style: ReportButtonStyle.icon,
                      color: Colors.white,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: gradientColors,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative background circles
                        Positioned(
                          top: -40,
                          right: -30,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 20,
                          left: -40,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                        ),
                        // Center Hero Icon Badge
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 36),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getCategoryIcon(widget.tip.category),
                                size: 68,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.tip.category.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content Body Sheet
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: scaffoldBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag & Read Time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.2 : 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.4 : 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getCategoryIcon(widget.tip.category),
                                  size: 14,
                                  color: AppTheme.primaryGreen,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.tip.category.toUpperCase(),
                                  style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '•  2 min read',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 13, color: AppTheme.primaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'Science-Backed',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        widget.tip.title,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Redesigned AI Content Disclaimer (Full contrast & Theme Adaptive)
                      AIContentDisclaimer(
                        contentType: 'nutrition guidance',
                        contentId: widget.tip.id,
                        contentTitle: widget.tip.title,
                        contentText: widget.tip.description,
                      ),

                      const SizedBox(height: 20),

                      // Main Lead Description in a Polished Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 3.5,
                              height: 60,
                              margin: const EdgeInsets.only(right: 14, top: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.tip.description,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 15.5,
                                  height: 1.6,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Category Specific Action Cards
                      _buildCategorySpecificContent(widget.tip.category, isDark, cardBg, textPrimary, textSecondary, borderColor),

                      const SizedBox(height: 24),

                      // Key Takeaway Tip Box
                      _buildTipBox(
                        _getCategoryProTip(widget.tip.category),
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: scaffoldBg.withValues(alpha: 0.94),
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.grey.shade400).withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _toggleFavorite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFavorite ? AppTheme.primaryGreenDark : AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: _isFavorite ? 1 : 3,
                      shadowColor: AppTheme.primaryGreen.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isFavorite ? Icons.check_circle_rounded : Icons.favorite_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isFavorite ? 'Saved to Favorites' : 'Save to Favorites',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildCategorySpecificContent(
    String category,
    bool isDark,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) {
    switch (category.toLowerCase()) {
      case 'vitamins':
        return _buildActionList(
          title: 'Optimal Vitamin & Mineral Absorption:',
          subtitle: 'Proven pairings to maximize cellular bioavailability:',
          items: const [
            _ActionItem('🍋', 'Vitamin C Synergy', 'Pair plant-based (non-heme) iron like spinach and lentils with citrus or bell peppers to triple absorption.'),
            _ActionItem('☀️', 'Healthy Fat Carrier', 'Fat-soluble vitamins (A, D, E, K) need healthy lipids like extra virgin olive oil or avocado to absorb properly.'),
            _ActionItem('☕', 'Tannin Timing', 'Avoid consuming tea, coffee, or calcium-rich milk within 60 minutes of iron-dense meals as they inhibit absorption.'),
            _ActionItem('🥦', 'Light Steaming', 'Lightly steam cruciferous greens rather than boiling to preserve heat-sensitive water-soluble vitamins.'),
          ],
          isDark: isDark,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        );
      case 'hydration':
        return _buildActionList(
          title: 'Daily Hydration Masterclass:',
          subtitle: 'Maximize metabolic efficiency and focus:',
          items: const [
            _ActionItem('💧', 'Morning Hydration', 'Drink 400-500ml of room temperature water right upon waking to reactivate your digestive tract.'),
            _ActionItem('🧠', 'Brain Performance', 'Mild dehydration of just 1-2% impairs concentration and triggers false hunger signals.'),
            _ActionItem('🧂', 'Electrolyte Balance', 'If exercising or in warm weather, ensure adequate sodium, potassium, and magnesium intake.'),
            _ActionItem('🍵', 'Herbal Infusions', 'Unsweetened green and herbal teas count towards total daily fluid requirements.'),
          ],
          isDark: isDark,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        );
      case 'protein':
        return _buildActionList(
          title: 'High-Impact Protein Strategies:',
          subtitle: 'Build lean muscle and maintain satiety:',
          items: const [
            _ActionItem('🍳', 'Even Distribution', 'Distribute protein evenly across meals (25-35g each) to continuously stimulate muscle protein synthesis.'),
            _ActionItem('🌱', 'Complete Amino Acids', 'Pair grains with legumes (e.g., rice and beans) to form complete amino acid profiles on plant diets.'),
            _ActionItem('⏱️', 'Post-Workout Timing', 'Consume 20-30g of protein within 2 hours of strength training for optimal tissue repair.'),
            _ActionItem('🥑', 'Clean Sourcing', 'Prioritize whole, minimally processed sources like wild fish, organic eggs, tempeh, and Greek yogurt.'),
          ],
          isDark: isDark,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        );
      case 'carbs':
        return _buildActionList(
          title: 'Smart Carbohydrate Management:',
          subtitle: 'Sustained energy without the sugar crash:',
          items: const [
            _ActionItem('🌾', 'Complex Over Simple', 'Opt for quinoa, oats, brown rice, and sweet potatoes for sustained glycogen replenishment.'),
            _ActionItem('🥗', 'The Fiber Cloak', 'Eat your greens and fiber first in a meal to slow down glucose absorption in the gut.'),
            _ActionItem('⚡', 'Pre-Workout Fuel', 'Easily digestible carbohydrates 30-45 minutes before exercise provide fast cellular ATP.'),
            _ActionItem('🍎', 'Whole Fruit Over Juice', 'Intact dietary fiber in whole fruit buffers fructose uptake, protecting metabolic health.'),
          ],
          isDark: isDark,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        );
      case 'portions':
        return _buildActionList(
          title: 'Intuitive Portion Framework:',
          subtitle: 'Visual hand rules for any plate:',
          items: const [
            _ActionItem('✋', 'Palm Rule', 'One palm-sized portion represents approximately 20-30g of dense protein.'),
            _ActionItem('✊', 'Fist Rule', 'One fist-sized volume corresponds to a serving of fibrous, nutrient-rich vegetables.'),
            _ActionItem('🤲', 'Cupped Hand', 'One cupped hand represents an ideal portion of whole cooked carbohydrates.'),
            _ActionItem('👍', 'Thumb Rule', 'One thumb represents an appropriate portion of dense healthy fats and oils.'),
          ],
          isDark: isDark,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        );
      default:
        return _buildActionList(
          title: 'Evidence-Based Nutrition Guidelines:',
          subtitle: 'Core pillars for long-term health and vitality:',
          items: const [
            _ActionItem('🌈', 'Eat the Rainbow', 'A diverse spectrum of natural colors indicates a broad antioxidant and polyphenol intake.'),
            _ActionItem('⏳', 'Mindful Pace', 'Take at least 20 minutes to finish meals to allow satiety hormone leptin to signal fullness.'),
            _ActionItem('😴', 'Restorative Sleep', '7-8 hours of sleep regulates hunger hormones ghrelin and leptin, curbing late-night cravings.'),
            _ActionItem('🌿', 'Stress Reduction', 'Elevated chronic cortisol increases visceral fat storage; integrate daily movement and breathwork.'),
          ],
          isDark: isDark,
          cardBg: cardBg,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          borderColor: borderColor,
        );
    }
  }

  Widget _buildActionList({
    required String title,
    required String subtitle,
    required List<_ActionItem> items,
    required bool isDark,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.headline,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildTipBox(String tip, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lightbulb_rounded,
              color: AppTheme.primaryGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Takeaway',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  tip,
                  style: TextStyle(
                    color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF065F46),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getCategoryGradient(String category) {
    switch (category.toLowerCase()) {
      case 'vitamins':
        return const [Color(0xFF059669), Color(0xFF10B981)];
      case 'minerals':
        return const [Color(0xFF0891B2), Color(0xFF06B6D4)];
      case 'hydration':
        return const [Color(0xFF2563EB), Color(0xFF38BDF8)];
      case 'protein':
        return const [Color(0xFFD97706), Color(0xFFF59E0B)];
      case 'carbs':
        return const [Color(0xFFBE185D), Color(0xFFEC4899)];
      case 'fiber':
        return const [Color(0xFF047857), Color(0xFF10B981)];
      case 'healthy fats':
        return const [Color(0xFF6D28D9), Color(0xFF8B5CF6)];
      case 'portions':
        return const [Color(0xFF0D9488), Color(0xFF14B8A6)];
      default:
        return const [Color(0xFF15803D), Color(0xFF22C55E)];
    }
  }

  String _getCategoryProTip(String category) {
    switch (category.toLowerCase()) {
      case 'vitamins':
        return 'Small culinary tweaks like squeezing fresh lemon on greens can multiply mineral bioavailability without extra supplements!';
      case 'hydration':
        return 'Consistent sips throughout the day hydrate cellular mitochondria far more effectively than chugging liters at once.';
      case 'protein':
        return 'Prioritizing protein at breakfast anchors steady blood glucose and halts sugar cravings throughout the afternoon.';
      case 'carbs':
        return 'Cooling cooked potatoes, rice, or pasta overnight turns digestible starches into resistant fiber that nourishes the microbiome!';
      case 'portions':
        return 'Eating on smaller plates naturally reduces caloric over-consumption by 20% through optical satiety cues.';
      default:
        return 'Consistency beats perfection: compounding small positive nutrition habits daily produces profound metabolic transformation!';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hydration':
        return Icons.water_drop_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      case 'portions':
        return Icons.pie_chart_rounded;
      case 'timing':
        return Icons.schedule_rounded;
      case 'protein':
        return Icons.fitness_center_rounded;
      case 'carbs':
        return Icons.grain_rounded;
      case 'vitamins':
        return Icons.medication_rounded;
      case 'minerals':
        return Icons.diamond_rounded;
      case 'fiber':
        return Icons.eco_rounded;
      case 'healthy fats':
        return Icons.favorite_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }
}

class _ActionItem {
  final String emoji;
  final String headline;
  final String body;

  const _ActionItem(this.emoji, this.headline, this.body);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- COLOR DEFINITIONS ---
const Color cardGradientStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple
const Color insightBackgroundLight = Color(0xFFF0F4FF); // Very light blue

/// Reusable InsightCard Widget
/// Displays personalized spending insights based on rule-based detection
class InsightCard extends StatelessWidget {
  final String message;
  final String suggestion;
  final bool isRepeatedSpending;
  final VoidCallback? onDismiss;

  const InsightCard({
    super.key,
    required this.message,
    required this.suggestion,
    this.isRepeatedSpending = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isRepeatedSpending
        ? const Color(0xFFFF9800).withValues(alpha: 0.3)
        : const Color(0xFF4CAF50).withValues(alpha: 0.3);

    final accentColor = isRepeatedSpending
        ? const Color(0xFFFF9800)
        : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: insightBackgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Message + Dismiss Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A202C),
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                ),
              ),

              // Dismiss Button (optional)
              if (onDismiss != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Suggestion/Action Text
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              suggestion,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: accentColor,
                letterSpacing: 0.15,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated InsightCard that fades in
class AnimatedInsightCard extends StatefulWidget {
  final String message;
  final String suggestion;
  final bool isRepeatedSpending;
  final VoidCallback? onDismiss;

  const AnimatedInsightCard({
    super.key,
    required this.message,
    required this.suggestion,
    this.isRepeatedSpending = false,
    this.onDismiss,
  });

  @override
  State<AnimatedInsightCard> createState() => _AnimatedInsightCardState();
}

class _AnimatedInsightCardState extends State<AnimatedInsightCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: InsightCard(
          message: widget.message,
          suggestion: widget.suggestion,
          isRepeatedSpending: widget.isRepeatedSpending,
          onDismiss: widget.onDismiss,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

const Color brandStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color brandEnd = Color.fromARGB(255, 129, 90, 193); // Vibrant Purple

class OnPageIncomeGoal extends StatefulWidget {
  final TextEditingController incomeController;
  final String? currentGoal;
  final ValueChanged<String?> onGoalSelected;

  const OnPageIncomeGoal({
    super.key,
    required this.incomeController,
    required this.currentGoal,
    required this.onGoalSelected,
  });

  @override
  State<OnPageIncomeGoal> createState() => _OnPageIncomeGoalState();
}

class _OnPageIncomeGoalState extends State<OnPageIncomeGoal> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _incomeSlide;
  late Animation<Offset> _goalSlide;

  final Map<String, String> goalDescriptions = {
    "Save": "Emergency",
    "Invest": "Wealth",
    "Debt": "Pay debt",
    "Retire": "Plan",
    "Budget": "Spending",
    "Grow": "Growth",
  };

  final Map<String, IconData> goalIcons = {
    "Save": Icons.account_balance_wallet_rounded,
    "Invest": Icons.trending_up_rounded,
    "Debt": Icons.credit_card_rounded,
    "Retire": Icons.emoji_events_rounded,
    "Budget": Icons.pie_chart_rounded,
    "Grow": Icons.auto_graph_rounded,
  };

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _incomeSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _goalSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [brandStart, brandEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              /// Title
              const Text(
                "Monthly income",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This helps us customize your financial journey",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 28),

              /// Income Input - Animated
              SlideTransition(
                position: _incomeSlide,
                child: FadeTransition(
                  opacity: _slideController,
                  child: _incomeCard(),
                ),
              ),

              const SizedBox(height: 42),

              /// Goal Title
              const Text(
                "Your main goal",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Choose what matters most to you",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              /// Goal Interest Grid - Animated
              SlideTransition(
                position: _goalSlide,
                child: FadeTransition(
                  opacity: _slideController,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 0.95,
                    children: [
                      _goalItem("Save"),
                      _goalItem("Invest"),
                      _goalItem("Debt"),
                      _goalItem("Retire"),
                      _goalItem("Budget"),
                      _goalItem("Grow"),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Income Card with enhanced styling
  Widget _incomeCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: widget.incomeController,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: Text(
              "MYR",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: brandStart,
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          hintText: "0.00",
          hintStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: brandStart, width: 2),
          ),
        ),
      ),
    );
  }

  /// Enhanced Goal Item with description
  Widget _goalItem(String label) {
    final bool selected = widget.currentGoal == label;
    final IconData icon = goalIcons[label] ?? Icons.help_rounded;
    final String description = goalDescriptions[label] ?? "";

    return GestureDetector(
      onTap: () => widget.onGoalSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: selected ? brandStart.withOpacity(0.12) : Colors.white,
          border: Border.all(
            color: selected ? brandStart : const Color(0xFFE8E8E8),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: brandStart.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Icon with Background
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [brandStart, brandEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          brandStart.withOpacity(0.15),
                          brandEnd.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : brandStart,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),

            /// Label
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? brandStart : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 2),

            /// Description
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            /// Selected Check
            if (selected) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: brandStart,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "Selected",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

# Rule-Based Personalized Expense Insight System

## Overview
FinTrackU now includes a smart, rule-based insight system that detects repeated spending patterns without AI/ML. The system analyzes weekly expense data to provide personalized spending suggestions.

---

## 📋 Architecture

### 1. **InsightService** (`services/insight_service.dart`)
Handles all business logic for expense analysis.

**Key Methods:**

#### `_getWeekNumber(DateTime date)` 
- Calculates ISO week number for a given date
- Used to group expenses by week

#### `_groupExpensesByWeek()` 
- Groups user expenses by: Week → Category → Note/Merchant
- Returns nested map structure with transaction amounts
- Retrieves data for current month only

#### `detectRepeatedSpending()`
**Rule Logic:**
```
IF (count of same category+note in same week) >= 2 THEN
  → Trigger insight
ELSE
  → Show balanced spending message
```

**Returns:** `ExpenseInsight` object with:
- `message`: Main insight text
- `suggestion`: Actionable recommendation
- `hasRepeatedSpending`: Boolean flag
- `category`, `merchantName`, `count`, `totalAmount`: Details

---

### 2. **InsightCard Widget** (`widgets/insight_card.dart`)

#### `InsightCard`
Reusable, static card displaying insights.

**Features:**
- Light blue background (`Color(0xFFF0F4FF)`)
- Two-line layout: Message + Suggestion
- Color-coded border (orange for repeated, green for balanced)
- Optional dismiss button
- Accessible dismissal tracking

#### `AnimatedInsightCard`
Wraps `InsightCard` with fade-in + slide-up animation.
- Duration: 500ms
- Curves: `easeIn` (fade), `easeOut` (slide)

---

### 3. **ExpenseInsight Model**
Data class representing a single insight:
```dart
class ExpenseInsight {
  final String message;           // e.g., "💡 You visited..."
  final String suggestion;         // e.g., "👉 Consider limiting..."
  final bool hasRepeatedSpending;
  final String? category;
  final String? merchantName;
  final int count;
  final double totalAmount;
}
```

---

## 🔍 Example Flows

### Flow 1: Repeated Spending Detected
```
User Data:
- Week 3, Food & Drink / "ZUS Coffee": 4 transactions (RM 52.00)
- Week 3, Shopping / "Uniqlo": 1 transaction (RM 150.00)

Rule Check:
- count("ZUS Coffee") = 4 >= 2 ✅ TRIGGER

Output:
Message: "💡 You visited "ZUS Coffee" 4 times this week (RM52.00)"
Suggestion: "👉 Consider limiting food & drink spending to 2 times per week."
```

### Flow 2: Balanced Spending
```
User Data:
- Week 3, Various categories with max 1 transaction each

Rule Check:
- max(count) = 1 < 2 ❌ NO TRIGGER

Output:
Message: "💡 Your spending looks balanced this week. Keep it up!"
Suggestion: "✨ Great job maintaining good spending habits."
```

---

## 📱 Integration on Home Page

**Location:** Between Quick Actions and Spending Summary Card

**Code:**
```dart
// In HomePage.build()
_quickActions(context),
const SizedBox(height: 18),
_personalizedInsightWidget(),  // ← NEW
const SizedBox(height: 18),
_currentSpendingCard(context),
```

**Features:**
- Auto-loads on page build
- Dismissable by user
- Shows loading state gracefully
- Re-fetches on page reload

---

## 🚀 Usage

### To Use InsightService:
```dart
final insightService = InsightService();
final insight = await insightService.detectRepeatedSpending();

print(insight.message);      // "💡 You visited..."
print(insight.suggestion);   // "👉 Consider limiting..."
```

### To Display Insight:
```dart
InsightCard(
  message: "💡 You visited ZUS Coffee 4 times",
  suggestion: "👉 Limit to 2 times per week",
  isRepeatedSpending: true,
  onDismiss: () => setState(() => dismissed = true),
)
```

---

## 🎨 UI Features

**InsightCard Styling:**
- Rounded corners: `16px`
- Light background with colored border
- Message: Bold, `13px`, dark gray
- Suggestion: `12px`, colored text in light box
- Smooth dismiss button with hover effect

**Animation:**
- Fade-in: `0.0 → 1.0` (500ms)
- Slide-up: `Offset(0, 0.2) → Offset.zero` (500ms)
- Curve: `easeOut` for smooth deceleration

---

## 📊 Data Source

**Firestore Path:** `users/{uid}/expenses`

**Fields Used:**
- `timestamp`: Transaction date (used for week calculation)
- `category`: Expense category (e.g., "Food & Drink")
- `note` OR `merchant`: Transaction description
- `amount`: Transaction amount

---

## ✅ Edge Cases Handled

1. **No expenses this week:**
   - Returns balanced spending message

2. **Multiple high-frequency merchants:**
   - Picks the one with highest count

3. **No user authenticated:**
   - Returns empty data safely

4. **Firestore errors:**
   - Catches exceptions, returns balanced message

5. **User dismisses insight:**
   - Tracked via `_insightDismissed` flag
   - Persists until page reload

---

## 🔄 Weekly Grouping Algorithm

```dart
Week Number = (DatesSinceYearStart / 7).ceil()

Example:
- Jan 1-7   → Week 1
- Jan 8-14  → Week 2
- Jan 15-21 → Week 3
- Jan 22-28 → Week 4
```

---

## 💡 Future Enhancements

1. **Persistence:** Save dismissed insights with timestamps
2. **Multiple Insights:** Show top 3 repeated patterns
3. **Trends:** Compare weekly patterns over months
4. **Custom Rules:** Allow users to set their own thresholds
5. **Categories:** Category-specific spending limits
6. **Gamification:** Link insights to rewards system

---

## 📝 Notes

- ✅ No AI/ML - Pure rule-based logic
- ✅ Lightweight - Single Firestore query per load
- ✅ Dismissable - User control over experience
- ✅ Extensible - Easy to add new rules
- ✅ Type-safe - Uses Dart models
- ✅ Animated - Smooth UX with transitions

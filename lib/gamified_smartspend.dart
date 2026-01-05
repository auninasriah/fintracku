import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:flame/game.dart' as flame;

// ✅ Colors matching Smart Spend theme
const Color primaryBlue = Color(0xFF3C79C1);
const Color accentPurple = Color(0xFF7D56BB);
const Color wantColor = Color(0xFFFF6B6B); // Red for Wants
const Color needColor = Color(0xFF51CF66); // Green for Needs
const Color gameBackground = Color(0xFFFAFAFA); // White background

// ✅ BudgetSlasherGame - Flame game for cutting unnecessary spending
class BudgetSlasherGame extends FlameGame with HasCollisionDetection {
  int _timeRemaining = 20; // 20 seconds
  int _wantsSlashed = 0;
  int _hpEarned = 0;
  bool _gameActive = true;
  
  late List<GameObjectComponent> _gameObjects;
  late math.Random _random;
  
  // Timer counters
  double _gameTimerCounter = 0.0;
  double _spawnTimerCounter = 0.0;
  
  final Function(int) onGameOver;

  BudgetSlasherGame({required this.onGameOver});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    _gameObjects = [];
    _random = math.Random();
    
    debugPrint('🎮 BudgetSlasherGame loaded! Game size: ${size.x} x ${size.y}');
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (!_gameActive) return;

    // Update game timer (every 1 second)
    _gameTimerCounter += dt;
    if (_gameTimerCounter >= 1.0) {
      _gameTimerCounter = 0.0;
      if (_timeRemaining > 0) {
        _timeRemaining--;
        debugPrint('⏱️ Time: $_timeRemaining seconds, Wants Slashed: $_wantsSlashed, Children: ${children.length}');
      } else {
        _endGame();
      }
    }

    // Update spawn timer (every 0.5 seconds)
    _spawnTimerCounter += dt;
    if (_spawnTimerCounter >= 0.5) {
      _spawnTimerCounter = 0.0;
      _spawnObject();
    }
  }

  void _spawnObject() {
    if (!_gameActive) return;

    // Only spawn if game has valid dimensions
    if (size.x <= 0 || size.y <= 0) {
      debugPrint('❌ Game size invalid: ${size.x} x ${size.y}');
      return;
    }

    // Random: 70% Wants, 30% Needs
    final isWant = _random.nextDouble() < 0.7;
    
    // Spawn within valid game bounds with padding
    final maxX = size.x > 100 ? size.x - 100 : size.x - 50;
    final minX = 50.0;
    final spawnX = minX + (_random.nextDouble() * (maxX - minX));
    
    final obj = GameObjectComponent(
      isWant: isWant,
      xPos: spawnX,
      yPos: 80,
      game: this,
    );
    
    _gameObjects.add(obj);
    add(obj);
    
    debugPrint('✨ Spawned ${isWant ? "Want 🛍️" : "Need 🛒"} at x=$spawnX in game area');
  }

  void handleObjectTapped(GameObjectComponent obj) {
    if (!_gameActive) return;
    
    // Only slash Wants, not Needs
    if (obj.isWant) {
      _wantsSlashed++;
      _hpEarned = (_wantsSlashed ~/ 5).clamp(0, 5);
      
      // Remove object
      obj.removeFromParent();
      _gameObjects.remove(obj);
      
      debugPrint('✂️ Want slashed! Total: $_wantsSlashed, HP Earned: $_hpEarned');
    } else {
      debugPrint('🛡️ Need protected - cannot slash!');
    }
  }

  void _endGame() {
    _gameActive = false;
    
    // Calculate final HP earned (5 wants = 1 HP, max 5)
    final finalHP = (_wantsSlashed ~/ 5).clamp(0, 5);
    
    debugPrint('🎮 GAME OVER! Wants Slashed: $_wantsSlashed, HP Earned: $finalHP');
    
    // Call callback with HP earned
    onGameOver(finalHP);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Fill background with white
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = gameBackground,
    );

    // Draw timer in top-left
    _drawTimer(canvas);

    // Draw score in top-right
    _drawScore(canvas);
  }

  void _drawTimer(Canvas canvas) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '⏱️ $_timeRemaining s',
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 20));
  }

  void _drawScore(Canvas canvas) {
    final hp = (_wantsSlashed ~/ 5).clamp(0, 5);
    final textPainter = TextPainter(
      text: TextSpan(
        text: '🎯 HP: $hp/5',
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: accentPurple,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.x - textPainter.width - 20, 20));
  }
}

// ✅ GameObject - Wants (red) or Needs (green)
class GameObjectComponent extends PositionComponent with TapCallbacks {
  final bool isWant;
  final double xPos;
  final double yPos;
  late BudgetSlasherGame game;

  GameObjectComponent({
    required this.isWant,
    required this.xPos,
    required this.yPos,
    required this.game,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(xPos, yPos);
    size = Vector2(70, 70); // Larger size for visibility
    
    // Add circular hitbox for tap detection
    add(CircleHitbox(radius: 35, position: Vector2(35, 35)));
    
    debugPrint('🎯 GameObject created at position($xPos, $yPos), isWant=$isWant');
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Move down the screen at 80 pixels per second
    position.y += 80 * dt;
    
    // Remove if off-screen (bottom of screen + buffer)
    if (position.y > 900) {
      removeFromParent();
      debugPrint('🗑️ Object removed (off-screen)');
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    debugPrint('👆 Tap detected on ${isWant ? "Want" : "Need"}!');
    // Notify the game that this object was tapped
    game.handleObjectTapped(this);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw glow effect
    final glowColor = isWant ? wantColor : needColor;
    
    // Draw outer glow
    canvas.drawCircle(
      Offset(35, 35),
      32,
      Paint()
        ..color = glowColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );

    // Draw middle glow
    canvas.drawCircle(
      Offset(35, 35),
      28,
      Paint()
        ..color = glowColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );

    // Draw object circle
    canvas.drawCircle(
      Offset(35, 35),
      24,
      Paint()
        ..color = glowColor
        ..style = PaintingStyle.fill,
    );

    // Draw border
    canvas.drawCircle(
      Offset(35, 35),
      24,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw emoji inside
    final textPainter = TextPainter(
      text: TextSpan(
        text: isWant ? '🛍️' : '🛒', // Shopping bag for Want, Cart for Need
        style: const TextStyle(fontSize: 36),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        35 - textPainter.width / 2,
        35 - textPainter.height / 2 - 2,
      ),
    );
  }
}

// ✅ GameWidget - Wrapper to display Flame game in Flutter
class GameWidget extends StatefulWidget {
  final Function(int) onGameOver;

  const GameWidget({
    required this.onGameOver,
    super.key,
  });

  @override
  State<GameWidget> createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  late BudgetSlasherGame _game;

  @override
  void initState() {
    super.initState();
    _game = BudgetSlasherGame(
      onGameOver: (hpEarned) {
        // Return to previous screen with result
        Navigator.pop(context, hpEarned);
      },
    );
  }

  @override
  void dispose() {
    _game.removeFromParent();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: gameBackground,
      appBar: AppBar(
        title: Text(
          'Budget Slasher',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
      ),
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: GameView(game: _game),
      ),
    );
  }
}

// ✅ GameView - Flame GameWidget wrapper
class GameView extends StatelessWidget {
  final BudgetSlasherGame game;

  const GameView({
    required this.game,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return flame.GameWidget<BudgetSlasherGame>(
      game: game,
    );
  }
}

// ✅ Success Dialog - Show result after game ends
class SuccessDialog extends StatelessWidget {
  final int hpEarned;

  const SuccessDialog({
    required this.hpEarned,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '🎉 Great Job!',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: accentPurple,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accentPurple, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  '+$hpEarned HP',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: accentPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Health Points Recovered',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Great job! You recovered $hpEarned HP by cutting unnecessary spending!',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💡 Tip: Keep spending wisely to earn more HP!',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'AWESOME!',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}

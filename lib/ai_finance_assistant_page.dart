import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

// --- COLOR DEFINITIONS (FinTrackU Theme) ---
const Color primaryBlue = Color(0xFF3C79C1);
const Color cardGradientStart = Color(0xFF3C79C1);
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187);

class AIFinanceAssistant extends StatefulWidget {
  const AIFinanceAssistant({super.key});

  @override
  State<AIFinanceAssistant> createState() => _AIFinanceAssistantState();
}

class _AIFinanceAssistantState extends State<AIFinanceAssistant> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  GenerativeModel? _model;
  DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    _loadEnvAndInitialize();
  }

  Future<void> _loadEnvAndInitialize() async {
    try {
      await dotenv.load();
      _initializeModel();
    } catch (e) {
      debugPrint('Error loading .env file: $e');
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "❌ Error loading configuration. Please check your .env file exists.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text: "Hi! I'm your AI Finance Assistant! 💰 Ask me anything about budgeting, expense tracking, savings strategies, or how to use FinTrackU!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  void _initializeModel() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      
      debugPrint('🔍 Checking GEMINI_API_KEY...');
      debugPrint('API Key: ${apiKey?.substring(0, 10) ?? "NOT FOUND"}');

      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('⚠️ ERROR: GEMINI_API_KEY is not set in .env file');
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: "❌ Error: GEMINI_API_KEY not found in .env file. Please add it to your .env file.",
                isUser: false,
                timestamp: DateTime.now(),
              ),
            );
            _isInitialized = false;
          });
        }
        return;
      }

      // Create the model
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 512,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
        systemInstruction: Content.text(
          '''You are FinTrackU AI, a friendly and supportive personal finance companion for students and young adults in Malaysia.

            Your role is NOT to judge, lecture, or shame users.
            You act as a mirror to users’ financial behavior, helping them reflect, understand, and improve their money habits gradually.

            You communicate in simple, beginner-friendly English using a warm, casual, and encouraging tone, similar to a helpful senior or trusted friend.

            --------------------------------------------------
            DEFAULT RESPONSE MODE (VERY IMPORTANT)
            --------------------------------------------------

            Always respond in SHORT MODE by default.

            Short Mode rules:
            - Use 3 to 5 short sentences per reply.
            - Mention only ONE insight, ONE example, and ONE suggestion.
            - Ask at most ONE gentle reflection question.
            - Avoid long explanations unless the user explicitly asks for more details.

            Switch to detailed explanations ONLY if the user asks:
            - "Explain more"
            - "Why"
            - "How does this work"
            - "Can you give more details"

            --------------------------------------------------
            CORE RESPONSIBILITIES
            --------------------------------------------------

            You can:

            1. Explain basic personal finance concepts such as budgeting, saving, spending, and simple financial planning.
            2. Guide users in tracking income, expenses, budgets, and savings goals inside the FinTrackU app.
            3. Explain spending insights, charts, progress bars, summaries, streaks, points, and rewards shown in the app.
            4. Help users create, update, and manage savings goals (e.g. Emergency Fund, Wedding, Travel).
            5. Provide practical tips to reduce overspending and build healthier money habits.
            6. Answer general finance-related questions in a simple and beginner-friendly way.
            7. Encourage users to stay consistent with daily or monthly financial tracking.
            8. Explain how financial progress, streaks, points, and rewards work in the app.
            9. Offer smart money tips based on user behavior when data is available.
            10. Help users navigate app features such as Add Income, Add Expense, Savings, and Dashboard.
            11. Provide educational explanations about expense categories and budgeting methods.
            12. Motivate users with positive, non-judgmental messages to improve financial discipline.
            13. Help troubleshoot common app issues.
            14. Clearly remind users that all advice is for educational purposes only and not professional financial advice.

            --------------------------------------------------
            BEHAVIOR-AWARE RESPONSE RULES
            --------------------------------------------------

            When users express feelings or behaviors such as:
            - "I feel like I spend too much"
            - "My money runs out fast"
            - "I always overspend"
            - "I don’t have enough money at the end of the month"
            - "Aku rasa aku boros"

            You MUST respond using available user data (e.g. expense history, Money-Pulse insights), when available.

            In Short Mode, include ONLY the following:

            1. Specific Spending Reflection  
              - Mention ONE frequent item or category.
              Example:  
              "I noticed drinks are one of your most frequent expenses this week, around RM18."

            2. Effort-Based Comparison  
              - Convert the spending into estimated part-time work hours, if income data exists.
              Example:  
              "That’s about 2 hours of part-time work."

            3. One Realistic Swap Suggestion  
              - Suggest ONE small, achievable alternative.
              Example:  
              "Making drinks at home a few days could save around RM20 this month."

            4. One Gentle Reflection Question  
              - Encourage awareness without judgment.
              Example:  
              "Do you usually buy them out of habit or convenience?"

            If user data is NOT available:
            - Speak generally
            - Avoid numbers
            - Encourage awareness instead of assumptions

            --------------------------------------------------
            COMMUNICATION RULES (VERY IMPORTANT)
            --------------------------------------------------

            - Do NOT shame, judge, or scold the user.
            - Do NOT sound like a financial authority or lecturer.
            - Do NOT force strict rules or extreme advice.
            - Always acknowledge the user’s feelings first.
            - Focus on awareness before behavior change.
            - Promote small, realistic improvements.
            - Use local and relatable examples when possible.
            - Keep language simple and conversational.

            --------------------------------------------------
            DISCLAIMER & SAFETY
            --------------------------------------------------

            - All advice provided is for educational purposes only.
            - Do not provide legal, tax, or professional financial advice.
            - Do not make assumptions beyond available user data.
            ''',
        ),
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
      debugPrint('✅ AI Finance Assistant initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ Error initializing AI model: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: "❌ Failed to initialize: $e",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Check if model is initialized
    if (_model == null || !_isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Assistant is initializing. Please wait...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Rate limiting check
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Please wait ${(_minRequestInterval.inSeconds - timeSinceLastRequest.inSeconds)} seconds before sending another message.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    // Update last request time
    _lastRequestTime = DateTime.now();

    try {
      final response = await _model!.generateContent([Content.text(text)]);

      String botResponse;
      if (response.text != null && response.text!.isNotEmpty) {
        botResponse = response.text!;
      } else {
        if (response.candidates.isNotEmpty) {
          final candidate = response.candidates.first;
          botResponse = candidate.content.parts
              .whereType<TextPart>()
              .map((part) => part.text)
              .join('\n');

          if (botResponse.isEmpty) {
            botResponse =
                "I'm here to help! Could you rephrase your question? 💡";
          }
        } else {
          botResponse =
              "I'm here to help! Could you rephrase your question? 💡";
        }
      }

      final botMessage = ChatMessage(
        text: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(botMessage);
          _isLoading = false;
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error getting AI response: $e');
      debugPrint('Error details: ${e.toString()}');

      String errorText = "Sorry, I encountered an error. Please try again! 😅";

      if (e.toString().contains('API key') ||
          e.toString().contains('INVALID_ARGUMENT')) {
        errorText =
            "⚠️ API key issue detected. Please check your Gemini API configuration in the .env file.";
      } else if (e.toString().contains('quota') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        errorText =
            "⏰ API usage limit reached. Please wait a moment and try again.\n\nTip: You can get a new API key at aistudio.google.com";
      } else if (e.toString().contains('network') ||
          e.toString().contains('Failed host lookup')) {
        errorText =
            "📡 Network error. Please check your internet connection and try again.";
      } else if (e.toString().contains('429')) {
        errorText =
            "⏰ Too many requests. Please wait 30-60 seconds before trying again.";
      }

      final errorMessage = ChatMessage(
        text: errorText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(errorMessage);
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Quick action buttons
  void _sendQuickAction(String question) {
    _messageController.text = question;
    _sendMessage(question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [cardGradientStart, cardGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Finance Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Powered by Gemini',
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Chat History'),
                  content: const Text(
                    'Are you sure you want to clear all messages?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                setState(() {
                  _messages.clear();
                });
                _addWelcomeMessage();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick action buttons
          if (_messages.length <= 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Questions',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickActionChip(
                        '💰 Budgeting Tips',
                        'What are some effective budgeting strategies?',
                      ),
                      _buildQuickActionChip(
                        '💡 Reduce Expenses',
                        'How can I reduce my monthly expenses?',
                      ),
                      _buildQuickActionChip(
                        '🎯 Savings Goals',
                        'How do I set and achieve savings goals?',
                      ),
                      _buildQuickActionChip(
                        '📊 Spending Analysis',
                        'How can I analyze my spending patterns?',
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Loading indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thinking...',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me about your finances...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [cardGradientStart, cardGradientEnd],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.send, color: Colors.white),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, String question) {
    return InkWell(
      onTap: () => _sendQuickAction(question),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryBlue.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? const LinearGradient(
                        colors: [cardGradientStart, cardGradientEnd],
                      )
                    : null,
                color: message.isUser ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: GoogleFonts.inter(
                  color: message.isUser ? Colors.white : Colors.grey.shade800,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
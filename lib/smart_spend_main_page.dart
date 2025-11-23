import 'package:flutter/material.dart';

// Definisi SmartSpendMainPage (StatelessWidget for UI Focus)
class SmartSpendMainPage extends StatelessWidget {
  const SmartSpendMainPage({super.key});

  // --- MOCK DATA (Data Olokan untuk tujuan UI) ---
  final double smartPoints = 115.0; // Mata olokan
  final double monthlyLimit = 500.0; // Had olokan
  final double currentMonthlyExpense = 450.0; // Perbelanjaan olokan

  // --- UI WIDGETS ---

  Widget _buildSmartScoreHeader(double points, Color accentColor, Color darkColor) {
    final pointsText = points.toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: darkColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor, width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'YOUR SMART SCORE 🏆',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFEB3B), // Emas
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pointsText,
            style: const TextStyle(
              fontSize: 70,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgressCard({
    required double expense,
    required double limit,
    required Color primaryColor,
    required Color accentColor,
    required Color warningColor,
  }) {
    // Pengiraan progres (menggunakan mock data)
    double progress = limit > 0 ? expense / limit : 0.0;
    
    // Penentuan warna bar
    Color barColor = progress > 0.85 ? warningColor : Colors.lightGreenAccent;
    
    // Penentuan status
    String statusText;
    if (progress > 1.0) {
      statusText = 'OVERSPEND DETECTED! 🚨';
    } else if (progress > 0.85) {
      statusText = 'STATUS: APPROACHING LIMIT ⚠️';
    } else {
      statusText = 'STATUS: ON TRACK ✅';
    }
    
    // Menggunakan progress.clamp(0.0, 1.0) untuk memastikan bar hanya penuh sehingga 100%
    double displayProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white38),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTHLY BUDGET QUEST',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Divider(color: Colors.white54, thickness: 1),
          
          Text(
            statusText,
            style: TextStyle(
              color: progress > 1.0 ? warningColor : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 15),

          // Progress Bar Utama
          LinearProgressIndicator(
            value: displayProgress,
            minHeight: 15,
            backgroundColor: Colors.white38,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),

          const SizedBox(height: 10),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: RM ${expense.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text(
                'Limit: RM ${limit.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          // Teks Baki jika ada
          if (progress < 1.0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Remaining: RM ${(limit - expense).toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
  
  // --- UI DIALOG SETUP LIMIT (HANYA MOCK) ---
  void _showLimitSetupDialog(BuildContext context) {
    // Dialog ini kini hanya untuk demonstrasi UI
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🎯 Set Monthly Budget Limit'),
          content: const Text('This function will be integrated with the budget logic later.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    // Warna tema
    const Color primaryColor = Color(0xFF00C8FF);
    const Color accentColor = Color(0xFFFFC107); // Kuning
    const Color darkColor = Color(0xFF283593); // Biru Gelap
    const Color warningColor = Color(0xFFD32F2F); // Merah

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Spend Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00D1FF), primaryColor],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // --- I. SMART SCORE STATUS (HEADER) ---
              _buildSmartScoreHeader(smartPoints, accentColor, darkColor),

              const SizedBox(height: 30),

              // --- II. MONTHLY BUDGET QUEST PROGRESS ---
              _buildMonthlyProgressCard(
                expense: currentMonthlyExpense,
                limit: monthlyLimit,
                primaryColor: primaryColor,
                accentColor: accentColor,
                warningColor: warningColor,
              ),

              const SizedBox(height: 30),

              // --- III. BUTANG SET UP BUDGET ---
              ElevatedButton.icon(
                onPressed: () => _showLimitSetupDialog(context),
                icon: const Icon(Icons.settings, color: Colors.black87),
                label: const Text(
                  'CONFIGURE MONTHLY QUEST',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // --- BONUS: Ruang untuk Misi/Ganjaran Harian ---
              const Text(
                'Daily Challenges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(color: Colors.white54),
              Container(
                height: 80,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: darkColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '⭐ Complete 3 transactions under RM10 today to earn +5 SP!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
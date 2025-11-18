import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';


class SmartSpendPage extends StatelessWidget {
  const SmartSpendPage({Key? key}) : super(key: key);

  // Fungsi untuk mendapatkan Title Level (Sama seperti cadangan sebelum ini)
  String getLevelTitle(int points) {
    if (points >= 200) return "Finance Legend";
    if (points >= 150) return "Financial Warrior";
    if (points >= 100) return "Smart Spender";
    if (points >= 50) return "Budget Explorer";
    return "Newbie Saver";
  }
  

  Future<SmartSpendData> _fetchSmartSpendData() async {
    // Di sini, anda akan panggil:
    // 1. Ambil weeklyLimit, monthlyLimit, smartPoints, level dari dokumen user.
    // 2. Ambil (kalkulasi) total weekly spend & monthly spend dari koleksi expenses.
    
    // Data Contoh (Sila Gantikan):
    await Future.delayed(const Duration(milliseconds: 500));
    return SmartSpendData(
      smartPoints: 115,
      level: 3,
      weeklyLimit: 100.0,
      monthlyLimit: 300.0,
      currentWeeklySpend: 85.0, // Diambil dari expenses_page.dart data
      currentMonthlySpend: 250.0, // Diambil dari expenses_page.dart data
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛡️ Smart Spend Shield'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: FutureBuilder<SmartSpendData>(
        future: _fetchSmartSpendData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Gagal memuatkan data Smart Spend.'));
          }

          final data = snapshot.data!;
          final String levelTitle = getLevelTitle(data.smartPoints);
          final Color shieldColor = data.smartPoints >= 100 ? Colors.green.shade600 : Colors.orange.shade800;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              
              // --- A. Focus Shield Status Card ---
              _buildShieldStatusCard(
                data.smartPoints, 
                data.level, 
                levelTitle, 
                shieldColor,
              ),
              
              const SizedBox(height: 20),
              
              // --- B. Ringkasan Disiplin Perbelanjaan ---
              _buildDisciplineSummary(
                data.weeklyLimit, 
                data.currentWeeklySpend, 
                data.monthlyLimit, 
                data.currentMonthlySpend,
              ),

              const SizedBox(height: 20),

              // --- C. History Log (Contoh) ---
              const Text(
                'Log Aktiviti Shield',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildActivityLog(), // Fungsi untuk memaparkan log mata
            ],
          );
        },
      ),
    );
  }

  // Widget: Paparan Focus Shield dan Level
  Widget _buildShieldStatusCard(
    int points, 
    int level, 
    String levelTitle, 
    Color shieldColor
  ) {
    // Kira peratusan untuk Level Bar (Anggap 50 mata setiap level)
    final double levelProgress = (points % 50) / 50.0;
    
    return Card(
      elevation: 6,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${points} Focus Shield',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: shieldColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: Level $level - $levelTitle',
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: levelProgress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }

  // Widget: Ringkasan Limit
  Widget _buildDisciplineSummary(
    double wLimit, 
    double wSpend, 
    double mLimit, 
    double mSpend
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Disiplin Perbelanjaan Semasa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        _buildDisciplineRow('Mingguan', wLimit, wSpend),
        _buildDisciplineRow('Bulanan', mLimit, mSpend),
      ],
    );
  }

  // Widget: Baris Ringkasan Limit
  Widget _buildDisciplineRow(String label, double limit, double currentSpend) {
    final double remaining = limit - currentSpend;
    final Color textColor = remaining < 0 ? Colors.red : Colors.green;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM${currentSpend.toStringAsFixed(2)} / RM${limit.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                remaining < 0 
                  ? 'Overspent: RM${remaining.abs().toStringAsFixed(2)}'
                  : 'Baki: RM${remaining.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: textColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Widget: Log Aktiviti (Log Penambahan/Penolakan Mata)
  Widget _buildActivityLog() {
    // Ini perlu ditarik dari koleksi 'point_history' anda
    final List<Map<String, dynamic>> log = [
      {'date': '15 Nov', 'action': '+20', 'desc': 'Ganjaran 3 Minggu Disiplin'},
      {'date': '10 Nov', 'action': '-12', 'desc': 'Overspend had mingguan'},
      {'date': '08 Nov', 'action': '+5', 'desc': 'Perbelanjaan <80% limit'},
    ];
    
    return Column(
      children: log.map((item) {
        final bool isDeduction = item['action'].startsWith('-');
        final Color actionColor = isDeduction ? Colors.red : Colors.green;
        return ListTile(
          leading: Icon(
            isDeduction ? Icons.arrow_downward : Icons.arrow_upward,
            color: actionColor,
          ),
          title: Text(item['desc']),
          trailing: Text(
            item['action'],
            style: TextStyle(fontWeight: FontWeight.bold, color: actionColor),
          ),
          subtitle: Text(item['date']),
        );
      }).toList(),
    );
  }
}
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sale_transaction.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Dashboard')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          final transactions = docs.map((doc) => SaleTransaction.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          // --- Data Processing ---
          
          // 1. Totals
          double totalRevenue = 0;
          double totalProfit = 0;
          for (var t in transactions) {
            totalRevenue += t.totalPrice;
            totalProfit += t.totalProfit;
          }

          // 2. Sales by Date (for Line Chart) - Last 7 days
          // Map<DateAsString, Profit>
          final now = DateTime.now();
          final Map<String, double> profitByDate = {};
          // Initialize last 7 days with 0
          for (int i = 6; i >= 0; i--) {
            final date = now.subtract(Duration(days: i));
            final key = DateFormat('MM-dd').format(date);
            profitByDate[key] = 0;
          }

          for (var t in transactions) {
             final key = DateFormat('MM-dd').format(t.date);
             if (profitByDate.containsKey(key)) {
               profitByDate[key] = (profitByDate[key] ?? 0) + t.totalProfit;
             }
          }
          
          final List<FlSpot> spots = [];
          int index = 0;
          profitByDate.forEach((key, value) {
             spots.add(FlSpot(index.toDouble(), value));
             index++;
          });


          // 3. Category Performance (Pie Chart)
          final Map<String, double> categorySales = {};
          for (var t in transactions) {
             categorySales[t.category] = (categorySales[t.category] ?? 0) + t.totalPrice;
          }
          final List<PieChartSectionData> pieSections = [];
          final List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal];
          int colorIndex = 0;
          
          categorySales.forEach((key, value) {
             final isLarge = value / (totalRevenue == 0 ? 1 : totalRevenue) > 0.2;
             pieSections.add(PieChartSectionData(
               color: colors[colorIndex % colors.length],
               value: value,
               title: '${(value / (totalRevenue == 0 ? 1 : totalRevenue) * 100).toStringAsFixed(0)}%',
               radius: isLarge ? 60 : 50,
               titleStyle: TextStyle(fontSize: isLarge ? 16 : 12, fontWeight: FontWeight.bold, color: Colors.white),
               badgeWidget: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                  child: Text(key, style: const TextStyle(fontSize: 10, color: Colors.black)),
               ),
               badgePositionPercentageOffset: 1.2,
             ));
             colorIndex++;
          });


          // 4. Top Selling Products
          final Map<String, int> productQty = {};
          for (var t in transactions) {
             productQty[t.productName] = (productQty[t.productName] ?? 0) + t.quantity;
          }
          final sortedProducts = productQty.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));
          final top5 = sortedProducts.take(5).toList();


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(child: _SummaryCard(title: 'Revenue', value: '₹${totalRevenue.toStringAsFixed(0)}', color: Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _SummaryCard(title: 'Profit', value: '₹${totalProfit.toStringAsFixed(0)}', color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 24),

                // Line Chart
                Text('Profit Trend (Last 7 Days)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: const EdgeInsets.only(right: 16, top: 16),
                  decoration: const BoxDecoration(
                     color: Colors.white, 
                     borderRadius: BorderRadius.all(Radius.circular(16)),
                     boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                               final dateKeys = profitByDate.keys.toList();
                               if (value.toInt() >= 0 && value.toInt() < dateKeys.length) {
                                 return Text(dateKeys[value.toInt()], style: const TextStyle(fontSize: 10));
                               }
                               return const Text('');
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppTheme.primaryBlue,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppTheme.primaryBlue.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Pie Chart
                if (categorySales.isNotEmpty) ...[
                   Text('Category Performance (Revenue)', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 16),
                   SizedBox(
                     height: 200,
                     child: PieChart(
                       PieChartData(
                         sections: pieSections,
                         centerSpaceRadius: 40,
                         sectionsSpace: 2,
                       ),
                     ),
                   ),
                ],
                
                const SizedBox(height: 24),

                // Top Selling List
                Text('Top Selling Products', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...top5.map((entry) => Card(
                   child: ListTile(
                     leading: CircleAvatar(
                       backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                       child: Text('${entry.value}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                     ),
                     title: Text(entry.key), // Product Name
                     trailing: const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
                   ),
                )),
                
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 24)),
        ],
      ),
    );
  }
}

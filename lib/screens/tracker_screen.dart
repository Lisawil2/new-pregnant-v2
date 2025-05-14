import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  DateTime? _selectedDate;
  int? _currentWeek;
  late SharedPreferences _prefs;

  List<String> tips = [
    "Start taking prenatal vitamins with folic acid.",
    "Focus on a healthy diet and hydration.",
    "Avoid alcohol, smoking, and caffeine.",
    "Schedule your first prenatal check-up.",
    "Manage nausea with small, frequent meals.",
    "Stay active with light exercise like walking.",
    "Get plenty of rest and manage stress.",
    "Start documenting your pregnancy journey.",
    "Consider joining a prenatal class or group.",
    "Monitor your weight gain with your doctor.",
    "Eat iron-rich foods to support your blood supply.",
    "Start doing pelvic floor (Kegel) exercises.",
    "Watch for common symptoms like dizziness.",
    "Make time for mental health and mindfulness.",
    "Discuss genetic testing options with your provider.",
    "Start using belly-safe moisturizers to reduce itching.",
    "Learn about fetal development this trimester.",
    "Start planning maternity leave early.",
    "Review pregnancy-safe medications with your doctor.",
    "Connect with your support network.",
    "You’re halfway there! Celebrate small milestones.",
    "Feel your baby’s first movements (quickening).",
    "Begin a registry or list for baby essentials.",
    "Keep track of your blood pressure & symptoms.",
    "Take time to relax—stress can affect the baby.",
    "Consider prenatal yoga or guided meditation.",
    "Practice sleeping on your left side.",
    "Prepare your home for baby’s arrival.",
    "Start researching birthing options and hospitals.",
    "Maintain regular prenatal check-ups.",
    "Think about birth plans and write questions.",
    "Pack your hospital bag essentials.",
    "Install the car seat and have it checked.",
    "Learn about signs of preterm labor.",
    "Discuss postpartum support with loved ones.",
    "Get your partner involved in birth prep.",
    "Stock up on postpartum supplies early.",
    "Limit travel as due date approaches.",
    "Create a list of important contacts.",
    "Your baby could arrive any day now!",
    "Stay calm and trust your body—you’re ready.",
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedDate();
  }

  Future<void> _loadSavedDate() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedDate = _prefs.getString('startDate');
    if (savedDate != null) {
      _selectedDate = DateTime.parse(savedDate);
      _currentWeek = _calculatePregnancyWeek(_selectedDate!);
      setState(() {});
    }
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(Duration(days: 7)),
      firstDate: DateTime.now().subtract(Duration(days: 300)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      await _prefs.setString('startDate', picked.toIso8601String());
      setState(() {
        _selectedDate = picked;
        _currentWeek = _calculatePregnancyWeek(picked);
      });
    }
  }

  int _calculatePregnancyWeek(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    return (difference / 7).ceil().clamp(1, 40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: Text("Pregnancy Tracker"),
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_calendar),
            onPressed: _pickStartDate,
            tooltip: "Edit Start Date",
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Track Your Pregnancy Progress",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink.shade700),
            ),
            SizedBox(height: 16),

            if (_selectedDate == null)
              ElevatedButton.icon(
                onPressed: _pickStartDate,
                icon: Icon(Icons.calendar_today),
                label: Text("Select Start Date (LMP)"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                ),
              ),

            if (_selectedDate != null) ...[
              SizedBox(height: 16),
              _buildWeekInfoCard(),
              SizedBox(height: 20),
              _buildTipOfWeek(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeekInfoCard() {
    int daysLeft = max(0, 280 - (_currentWeek! * 7));
    return Card(
      elevation: 5,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "You're in Week $_currentWeek",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink.shade800),
            ),
            SizedBox(height: 8),
            Text("Expected due in $daysLeft days."),
          ],
        ),
      ),
    );
  }

  Widget _buildTipOfWeek() {
    String tip = tips[(_currentWeek! - 1).clamp(0, tips.length - 1)];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(child: Text("Tip of the Week: $tip")),
          ],
        ),
      ),
    );
  }
}

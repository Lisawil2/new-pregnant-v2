import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'pregnancy_data.dart';

class TrackerScreen extends StatefulWidget {
  final int? initialWeek;

  const TrackerScreen({super.key, this.initialWeek});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  DateTime? _selectedDate;
  int? _currentWeek;
  late SharedPreferences _prefs;

  // General Tips
  List<String> generalTips = [
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

  // Nutrition Tips
  List<String> nutritionTips = [
    "Include leafy greens for folate and iron.",
    "Eat protein-rich foods like eggs and beans.",
    "Add calcium-rich foods like yogurt and cheese.",
    "Incorporate whole grains for energy.",
    "Snack on fruits for vitamins and fiber.",
    "Choose lean meats for protein and iron.",
    "Include omega-3 rich foods like salmon.",
    "Eat colorful veggies for antioxidants.",
    "Stay hydrated with water and herbal teas.",
    "Add nuts and seeds for healthy fats.",
    "Limit processed foods and added sugars.",
    "Eat small, frequent meals to ease digestion.",
    "Include vitamin C-rich foods like oranges.",
    "Choose fortified cereals for extra nutrients.",
    "Avoid raw fish and unpasteurized dairy.",
    "Eat fiber-rich foods to prevent constipation.",
    "Include dairy for bone health.",
    "Limit caffeine to 200mg daily.",
    "Eat iron-rich foods with vitamin C for absorption.",
    "Choose healthy snacks like hummus and veggies.",
    "Maintain balanced meals for stable energy.",
    "Eat folate-rich foods like lentils.",
    "Include protein at every meal.",
    "Stay hydrated to support amniotic fluid.",
    "Eat calcium-rich foods for baby’s bones.",
    "Choose whole fruits over juices.",
    "Include healthy fats like avocado.",
    "Eat iron-rich foods to prevent anemia.",
    "Limit salty snacks to manage swelling.",
    "Eat small portions to avoid heartburn.",
    "Include vitamin D-rich foods like eggs.",
    "Choose complex carbs for sustained energy.",
    "Eat protein to support tissue growth.",
    "Stay hydrated to prevent preterm labor.",
    "Eat calcium for muscle function.",
    "Include fiber to support digestion.",
    "Eat iron-rich foods for oxygen supply.",
    "Limit heavy meals before bed.",
    "Eat nutrient-dense foods for energy.",
    "Stay hydrated for overall health.",
    "Eat balanced meals for baby’s growth.",
  ];

  // Exercise Guidance
  List<String> exerciseTips = [
    "Try gentle stretching for flexibility.",
    "Walk 20-30 minutes daily if possible.",
    "Try swimming for low-impact exercise.",
    "Do prenatal yoga for relaxation.",
    "Practice pelvic tilts for core strength.",
    "Try seated exercises for comfort.",
    "Do light cardio like stationary cycling.",
    "Practice deep breathing exercises.",
    "Try Kegel exercises for pelvic strength.",
    "Avoid high-impact activities.",
    "Do arm circles for upper body mobility.",
    "Try side-lying leg lifts for hip strength.",
    "Walk at a comfortable pace.",
    "Do prenatal Pilates with guidance.",
    "Avoid exercises lying flat on your back.",
    "Try water aerobics for joint relief.",
    "Do gentle stretches for back pain.",
    "Practice balance exercises safely.",
    "Avoid contact sports or risky activities.",
    "Do light resistance training with bands.",
    "Try prenatal yoga for stress relief.",
    "Walk to maintain cardiovascular health.",
    "Do pelvic floor exercises daily.",
    "Try low-impact aerobics classes.",
    "Avoid exercises causing abdominal strain.",
    "Do gentle stretching for muscle relief.",
    "Practice safe squats for leg strength.",
    "Try guided meditation with movement.",
    "Walk to improve circulation.",
    "Do prenatal yoga for flexibility.",
    "Avoid heavy lifting or straining.",
    "Try side-lying exercises for comfort.",
    "Do light stretching to ease tension.",
    "Practice pelvic tilts for posture.",
    "Try water-based exercises for support.",
    "Do gentle exercises to stay active.",
    "Practice Kegels for labor prep.",
    "Avoid exercises with fall risks.",
    "Do light cardio for energy.",
    "Stay active with daily movement.",
    "Exercise safely with professional guidance.",
  ];

  // Weekly Pregnancy Updates
  List<String> weeklyUpdates = [
    "Embryo is implanting in the uterus.",
    "Morning sickness may begin.",
    "Fatigue and breast tenderness are common.",
    "Your body is producing more blood.",
    "Hormonal changes may affect mood.",
    "You may notice mild cramping.",
    "Your uterus is starting to expand.",
    "Nausea may peak this week.",
    "You may feel bloated or gassy.",
    "Your sense of smell may heighten.",
    "Energy levels may start to improve.",
    "Your waistline may start to thicken.",
    "You may notice skin changes.",
    "Your appetite may increase.",
    "You may experience round ligament pain.",
    "Your baby’s movements may be felt soon.",
    "Heartburn or indigestion may occur.",
    "You may feel more stable emotionally.",
    "Your belly is noticeably growing.",
    "You may experience Braxton Hicks contractions.",
    "You’re in the second trimester now!",
    "Your energy levels may be higher.",
    "You may notice stretch marks.",
    "Your baby’s kicks are stronger.",
    "You may feel short of breath.",
    "Swelling in hands or feet may occur.",
    "You may experience back pain.",
    "Your belly button may pop out.",
    "You may feel baby’s hiccups.",
    "Sleep may become more challenging.",
    "You’re in the third trimester now!",
    "Frequent urination may return.",
    "You may feel pelvic pressure.",
    "Braxton Hicks may intensify.",
    "You may feel anxious or excited.",
    "Your baby is dropping lower.",
    "Cervical changes may begin.",
    "You may feel nesting instincts.",
    "Contractions may start soon.",
    "Your body is preparing for labor.",
    "Labor could start any day now!",
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
      _currentWeek = widget.initialWeek ?? _calculatePregnancyWeek(_selectedDate!);
      setState(() {});
    }
  }

  Future<void> _pickStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
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

  String _getTrimester(int week) {
    if (week <= 13) return "First Trimester";
    if (week <= 26) return "Second Trimester";
    return "Third Trimester";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text("Pregnancy Tracker"),
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar),
            onPressed: _pickStartDate,
            tooltip: "Select Last Menstrual Period (LMP)",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Track Your Pregnancy Progress",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.pink.shade700),
              ),
              const SizedBox(height: 16),

              if (_selectedDate == null) ...[
                Tooltip(
                  message: 'Select the first day of your last menstrual period to track progress',
                  decoration: BoxDecoration(
                    color: Colors.pink.shade400,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  textStyle: const TextStyle(color: Colors.white),
                  child: ElevatedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text("Select Start Date (LMP)"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose the first day of your last menstrual period (LMP) to calculate your pregnancy week and due date.',
                  style: TextStyle(fontSize: 14, color: Colors.pink.shade600),
                ),
              ],

              if (_selectedDate != null) ...[
                const SizedBox(height: 16),
                _buildWeekInfoCard(),
                const SizedBox(height: 20),
                _buildTipOfWeek(),
                const SizedBox(height: 20),
                _buildNutritionTip(),
                const SizedBox(height: 20),
                _buildExerciseGuidance(),
                const SizedBox(height: 20),
                _buildBabyDevelopment(),
                const SizedBox(height: 20),
                _buildWeeklyUpdate(),
              ],
            ],
          ),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "You're in Week $_currentWeek",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink.shade800),
            ),
            const SizedBox(height: 8),
            Text("Expected due in $daysLeft days."),
          ],
        ),
      ),
    );
  }

  Widget _buildTipOfWeek() {
    String tip = generalTips[(_currentWeek! - 1).clamp(0, generalTips.length - 1)];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text("General Tip of the Week"),
        leading: const Icon(Icons.lightbulb, color: Colors.orange),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tip),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTip() {
    String tip = nutritionTips[(_currentWeek! - 1).clamp(0, nutritionTips.length - 1)];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text("Nutrition Tip of the Week"),
        leading: const Icon(Icons.food_bank, color: Colors.green),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(tip),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseGuidance() {
    String tip = exerciseTips[(_currentWeek! - 1).clamp(0, exerciseTips.length - 1)];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text("Exercise Guidance"),
        leading: const Icon(Icons.fitness_center, color: Colors.blue),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(tip),
          ),
        ],
      ),
    );
  }

  Widget _buildBabyDevelopment() {
    final data = PregnancyData.getDataForWeek(_currentWeek!);
    String trimester = _getTrimester(_currentWeek!);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text("Baby Development - $trimester"),
        leading: const Icon(Icons.child_care, color: Colors.purple),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    data.imagePath,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Image not found')),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Week $_currentWeek Development:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(data.development),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyUpdate() {
    String update = weeklyUpdates[(_currentWeek! - 1).clamp(0, weeklyUpdates.length - 1)];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text("Weekly Pregnancy Update"),
        leading: const Icon(Icons.update, color: Colors.teal),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(update),
          ),
        ],
      ),
    );
  }
}
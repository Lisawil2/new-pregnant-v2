import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'tracker_screen.dart';
import 'chat_screen.dart';
import 'pregnancy_data.dart';

// Reminder model to store reminder data
class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Reminder> reminders = [];
  final fln.FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();
  int? _currentWeek;
  late SharedPreferences _prefs;
  bool _showHints = false; // Track if hints should be shown
  final _animationController = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: NoopTickerProvider(),
  );
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadSavedData();
    _initializeAnimation();
    // Add sample reminders for testing
    reminders.addAll([
      Reminder(
        id: '1',
        title: 'Prenatal Check-up',
        description: 'Doctor appointment at City Hospital',
        dateTime: DateTime(2025, 5, 27, 10, 0),
      ),
      Reminder(
        id: '2',
        title: 'Iron Supplement',
        description: 'Take daily iron supplement',
        dateTime: DateTime(2025, 5, 26, 17, 15),
      ),
    ]);
    // Schedule notifications for existing reminders
    for (var reminder in reminders) {
      _scheduleNotification(reminder);
    }
  }

  // Initialize animation for interactive elements
  void _initializeAnimation() {
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  // Load saved start date and check for first-time hints
  Future<void> _loadSavedData() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedDate = _prefs.getString('startDate');
    bool? hintsShown = _prefs.getBool('hintsShown');
    if (savedDate != null) {
      final startDate = DateTime.parse(savedDate);
      setState(() {
        _currentWeek = _calculatePregnancyWeek(startDate);
      });
    }
    if (hintsShown == null || !hintsShown) {
      setState(() {
        _showHints = true;
      });
      await _prefs.setBool('hintsShown', true);
    }
  }

  int _calculatePregnancyWeek(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    return (difference / 7).ceil().clamp(1, 40);
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    const initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = fln.DarwinInitializationSettings();
    const initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Check and request SCHEDULE_EXACT_ALARM permission
  Future<bool> _requestExactAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.request();
    if (status.isGranted) {
      return true;
    } else {
      // Removed the SnackBar error messages here
      return false;
    }
  }

  // Schedule a notification for a reminder
  Future<void> _scheduleNotification(Reminder reminder) async {
    bool canScheduleExact = await _requestExactAlarmPermission();
    final androidDetails = fln.AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Notifications for upcoming reminders',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );
    const iosDetails = fln.DarwinNotificationDetails();
    final platformDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      if (canScheduleExact) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          reminder.id.hashCode,
          reminder.title,
          reminder.description,
          tz.TZDateTime.from(reminder.dateTime, tz.local),
          platformDetails,
          androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              fln.UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        await _flutterLocalNotificationsPlugin.show(
          reminder.id.hashCode,
          reminder.title,
          'Exact timing not available: ${reminder.description}',
          platformDetails,
        );
      }
    } catch (e) {
      // Removed the SnackBar error message here - errors are now handled silently
      debugPrint('Notification scheduling error: $e');
    }
  }

  // Show dialog to add a new reminder
  Future<void> _showAddReminderDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime selectedDateTime = DateTime.now().add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Reminder'),
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: const Text('Select Date & Time'),
                  ),
                  Text(
                    'Selected: ${selectedDateTime.toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    selectedDateTime.isAfter(DateTime.now())) {
                  final newReminder = Reminder(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                    dateTime: selectedDateTime,
                  );
                  setState(() {
                    reminders.add(newReminder);
                  });
                  _scheduleNotification(newReminder);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields and select a future date.'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> get _screens => [
        _buildMainHomeTab(),
        TrackerScreen(initialWeek: _currentWeek),
        const ChatScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false, // This removes the back button
        title: Text(
          _selectedIndex == 0
              ? "BloomMama"
              : _selectedIndex == 1
                  ? "Tracker"
                  : "Chat",
          style: const TextStyle(
            color: Colors.white,
             fontWeight: FontWeight.bold,
             fontSize: 28),
          
        ),
        centerTitle: true,
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
      ),
    
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (_showHints)
            _buildHintOverlay(), // Show hints for first-time users
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? Tooltip(
              message: 'Add a new reminder for appointments or tasks',
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
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: FloatingActionButton(
                  onPressed: _showAddReminderDialog,
                  backgroundColor: Colors.pink.shade400,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Tooltip(
              message: 'View your pregnancy progress and reminders',
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
              child: const Icon(Icons.home),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Tooltip(
              message: "Track your baby's development week by week",
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
              child: const Icon(Icons.pregnant_woman),
            ),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Tooltip(
              message: 'Chat with AI for pregnancy advice',
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
              child: const Icon(Icons.chat),
            ),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  // Build hint overlay for first-time users
  Widget _buildHintOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showHints = false;
          });
        },
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Welcome to BloomMama!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tap the pink button to add reminders\nor explore baby updates below.',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showHints = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Got it!', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainHomeTab() {
    final pregnancyData = _currentWeek != null
        ? PregnancyData.getDataForWeek(_currentWeek!)
        : PregnancyData.getDataForWeek(20); // Fallback to Week 20

    // Debug log for image loading
    debugPrint('Attempting to load image: ${pregnancyData.imagePath}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            "Hello, Mama! 👋",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade800),
          ),
          const SizedBox(height: 8),
          Text(
            "Your pregnancy journey at a glance",
            style: TextStyle(fontSize: 16, color: Colors.pink.shade600),
          ),
          const SizedBox(height: 16),

          // Baby Development Card
          Text(
            "Your Baby's Progress This Week 👶",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade800),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap to track your baby's growth",
            style: TextStyle(fontSize: 14, color: Colors.pink.shade600),
          ),
          const SizedBox(height: 10),
          Tooltip(
            message: 'Tap to see detailed baby development info',
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
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/tracker',
                      arguments: {'initialWeek': _currentWeek});
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        pregnancyData.imagePath,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Image load error: $error');
                          return const Icon(
                            Icons.child_care,
                            size: 60,
                            color: Colors.pink,
                          );
                        },
                      ),
                    ),
                    title: Text("Week ${pregnancyData.week} - ${pregnancyData.size}"),
                    subtitle: Text(pregnancyData.development),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.pink),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Upcoming Reminders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Your Upcoming Tasks 📅",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade800),
                  ),
                  Text(
                    "Manage your reminders here",
                    style: TextStyle(fontSize: 14, color: Colors.pink.shade600),
                  ),
                ],
              ),
              Tooltip(
                message: 'Set a new reminder for your pregnancy needs',
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
                child: ElevatedButton(
                  onPressed: _showAddReminderDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Add Reminder',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          reminders.isEmpty
              ? const Center(child: Text('No reminders set.'))
              : Column(
                  children: reminders.map((reminder) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.event, color: Colors.pink),
                        title: Text(reminder.title),
                        subtitle: Text(
                          '${reminder.description}\n${reminder.dateTime.toString().substring(0, 16)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              reminders.remove(reminder);
                            });
                            _flutterLocalNotificationsPlugin.cancel(reminder.id.hashCode);
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Dummy TickerProvider for animation (since vsync requires a StatefulWidget with TickerProviderStateMixin)
class NoopTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
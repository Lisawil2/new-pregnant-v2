import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  int? _currentWeek;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadSavedDate();
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
        dateTime: DateTime(2025, 5, 26, 17, 15), // 05:15 PM EAT for testing
      ),
    ]);
    // Schedule notifications for existing reminders
    for (var reminder in reminders) {
      _scheduleNotification(reminder);
    }
  }

  // Load saved start date and calculate week
  Future<void> _loadSavedDate() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedDate = _prefs.getString('startDate');
    if (savedDate != null) {
      final startDate = DateTime.parse(savedDate);
      setState(() {
        _currentWeek = _calculatePregnancyWeek(startDate);
      });
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
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
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
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please enable "Alarms & Reminders" in system settings for exact timing.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Exact alarms not permitted. Please allow in app permissions.'),
          ),
        );
      }
      return false;
    }
  }

  // Schedule a notification for a reminder
  Future<void> _scheduleNotification(Reminder reminder) async {
    bool canScheduleExact = await _requestExactAlarmPermission();
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Notifications for upcoming reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
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
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling notification: $e')),
      );
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
        title: Text(
          _selectedIndex == 0
              ? "BloomMama"
              : _selectedIndex == 1
                  ? "Tracker"
                  : "Chat",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _showAddReminderDialog,
              backgroundColor: Colors.pink.shade400,
              child: const Icon(Icons.add, color: Colors.white),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pregnant_woman),
            label: 'Tracker',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
        ],
      ),
    );
  }

  Widget _buildMainHomeTab() {
    final pregnancyData = _currentWeek != null
        ? PregnancyData.getDataForWeek(_currentWeek!)
        : PregnancyData.getDataForWeek(20); // Fallback to Week 20

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
          const SizedBox(height: 16),

          // Baby Development Card
          const Text(
            "This Week's Baby Update 👶",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          GestureDetector(
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
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.child_care,
                      size: 60,
                      color: Colors.pink,
                    ),
                  ),
                ),
                title: Text("Week ${pregnancyData.week} - ${pregnancyData.size}"),
                subtitle: Text(pregnancyData.development),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.pink),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Upcoming Reminders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Upcoming Reminders 📅",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _showAddReminderDialog,
                child: Text(
                  'Add Reminder',
                  style: TextStyle(color: Colors.pink.shade400),
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
}

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:permission_handler/permission_handler.dart';
import 'package:pregnancy_chatbot/utils/device_id.dart' as device_utils;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/scheduler.dart';
import 'package:uuid/uuid.dart';
import 'tracker_screen.dart';
import 'chat_screen.dart';
import 'pregnancy_data.dart';
import 'device_id.dart';

class Reminder {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'dateTime': Timestamp.fromDate(dateTime),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Reminder.fromJson(Map<String, dynamic> json, String id) => Reminder(
        id: id,
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        dateTime: (json['dateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  List<Reminder> reminders = [];
  final fln.FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();
  int? _currentWeek;
  DateTime? _lmpDate;
  DateTime? _dueDate;
  late SharedPreferences _prefs;
  bool _showHints = false;
  bool _hasSetLMP = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late FirebaseFirestore _firestore;
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _firestore = FirebaseFirestore.instance;
    _initializeNotifications();
    _initializeAnimation();
    _loadSavedData();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  Future<bool> _requestNotificationPermissions() async {
    final notificationStatus = await Permission.notification.request();
    final exactAlarmStatus = await Permission.scheduleExactAlarm.request();

    if (!notificationStatus.isGranted) {
      debugPrint('Notification permission denied');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission is required for reminders.'),
        ),
      );
      return false;
    }

    if (!exactAlarmStatus.isGranted) {
      debugPrint('Exact alarm permission denied');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Exact alarm permission is required for precise reminder timing.'),
        ),
      );
      return false;
    }

    final batteryOptimizationStatus =
        await Permission.ignoreBatteryOptimizations.request();
    if (!batteryOptimizationStatus.isGranted) {
      debugPrint('Battery optimization may restrict notifications');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Disable battery optimization in settings for reliable reminders.'),
        ),
      );
    }

    return true;
  }

  Future<void> _initializeNotifications() async {
    const androidChannel = fln.AndroidNotificationChannel(
      'reminder_channel',
      'Reminders',
      description: 'Notifications for upcoming reminders',
      importance: fln.Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    try {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              fln.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification received: ${details.payload}');
        },
      );

      if (initialized == null || !initialized) {
        debugPrint('Failed to initialize notifications');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize notifications')),
        );
      } else {
        debugPrint('Notifications initialized successfully');
      }
    } catch (e, stackTrace) {
      debugPrint('Notification initialization error: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notification initialization error: $e')),
      );
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    final hasPermissions = await _requestNotificationPermissions();
    if (!hasPermissions) {
      debugPrint('Cannot schedule notification due to missing permissions');
      return;
    }

    final now = DateTime.now();
    if (reminder.dateTime.isBefore(now)) {
      debugPrint('Cannot schedule notification for past time: ${reminder.dateTime}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot schedule reminder for a past date')),
      );
      return;
    }

    final notificationId = '${reminder.id}_${reminder.dateTime.millisecondsSinceEpoch}'.hashCode;

    final androidDetails = fln.AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Notifications for upcoming reminders',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      ticker: 'Reminder',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    final platformDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final tzDateTime = tz.TZDateTime.from(reminder.dateTime, tz.local);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        reminder.title,
        reminder.description,
        tzDateTime,
        platformDetails,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: fln.UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: fln.DateTimeComponents.dateAndTime,
        payload: reminder.id,
        // For iOS foreground notification presentation
        // (if you want to show notifications while app is in foreground)
        // presentAlert: true,
        // presentSound: true,
      );
      debugPrint(
          'Notification scheduled for reminder: ${reminder.title} at $tzDateTime (ID: $notificationId)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder notification scheduled for ${reminder.title}')),
      );
    } catch (e, stackTrace) {
      debugPrint('Notification scheduling error: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scheduling reminder: $e')),
      );
    }
  }

  Future<void> _loadReminders() async {
    try {
      debugPrint('Loading reminders from Firestore for device: $_deviceId');
      final snapshot = await _firestore
          .collection('users')
          .doc(_deviceId)
          .collection('reminders')
          .orderBy('dateTime', descending: false)
          .get();
      setState(() {
        reminders = snapshot.docs
            .map((doc) => Reminder.fromJson(doc.data(), doc.id))
            .toList();
      });
      debugPrint('Loaded ${reminders.length} reminders from Firestore');

      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Cancelled all existing notifications');

      for (var reminder in reminders) {
        if (reminder.dateTime.isAfter(DateTime.now())) {
          await _scheduleNotification(reminder);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading reminders: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reminders: $e')),
      );
    }
  }

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
            height: 320,
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
                    'Selected: ${selectedDateTime.toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 20),
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
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty &&
                    selectedDateTime.isAfter(DateTime.now())) {
                  final newReminder = Reminder(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    description: descriptionController.text,
                    dateTime: selectedDateTime,
                    createdAt: DateTime.now(),
                  );

                  try {
                    debugPrint('Attempting to save reminder to Firestore');
                    final docRef = await _firestore
                        .collection('users')
                        .doc(_deviceId)
                        .collection('reminders')
                        .add(newReminder.toJson());
                    debugPrint('Reminder saved to Firestore with ID: ${docRef.id}');

                    setState(() {
                      reminders.add(Reminder(
                        id: docRef.id,
                        title: newReminder.title,
                        description: newReminder.description,
                        dateTime: newReminder.dateTime,
                        createdAt: newReminder.createdAt,
                      ));
                    });

                    await _scheduleNotification(newReminder);
                    // Removed the instant mock notification call for real notification only

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder added successfully')),
                    );
                  } catch (e, stackTrace) {
                    debugPrint('Error saving reminder: $e\n$stackTrace');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error saving reminder: $e')),
                    );
                  }
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

  Future<void> _loadSavedData() async {
    _prefs = await SharedPreferences.getInstance();
    _deviceId = await device_utils.getDeviceId();

    String? savedLMP = _prefs.getString('lmpDate');
    String? savedStartDate = _prefs.getString('startDate');
    String? savedDueDate = _prefs.getString('dueDate');

    if (savedLMP != null) {
      _lmpDate = DateTime.parse(savedLMP);
      _hasSetLMP = true;
    }

    if (savedStartDate != null) {
      final startDate = DateTime.parse(savedStartDate);
      setState(() {
        _currentWeek = _calculatePregnancyWeek(startDate);
      });
    } else if (_lmpDate != null) {
      final startDate = _lmpDate!.add(const Duration(days: 14));
      await _prefs.setString('startDate', startDate.toIso8601String());
      setState(() {
        _currentWeek = _calculatePregnancyWeek(startDate);
      });
    }

    if (savedDueDate != null) {
      _dueDate = DateTime.parse(savedDueDate);
    } else if (_lmpDate != null) {
      _dueDate = _lmpDate!.add(const Duration(days: 280));
      await _prefs.setString('dueDate', _dueDate!.toIso8601String());
    }

    bool? hintsShown = _prefs.getBool('hintsShown');
    if ((hintsShown == null || !hintsShown) && _hasSetLMP) {
      setState(() {
        _showHints = true;
      });
      await _prefs.setBool('hintsShown', true);
    }

    await _loadReminders();
    setState(() {});
  }

  int _calculatePregnancyWeek(DateTime startDate) {
    final now = DateTime.now();
    final difference = now.difference(startDate).inDays;
    return (difference / 7).ceil().clamp(1, 40);
  }

  Future<void> _showLMPSelectionDialog() async {
    DateTime selectedLMP = DateTime.now().subtract(const Duration(days: 30));

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Welcome to BloomMama!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.pink,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To provide you with accurate pregnancy tracking, please select the first day of your last menstrual period (LMP):',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedLMP,
                            firstDate:
                                DateTime.now().subtract(const Duration(days: 300)),
                            lastDate: DateTime.now(),
                            helpText: 'Select Last Menstrual Period',
                          );
                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedLMP = pickedDate;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Select LMP Date'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade400,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.pink.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Selected LMP:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.pink.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${selectedLMP.day}/${selectedLMP.month}/${selectedLMP.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _lmpDate = selectedLMP;
                _dueDate = selectedLMP.add(const Duration(days: 280));
                final startDate = selectedLMP.add(const Duration(days: 14));

                await _prefs.setString('lmpDate', selectedLMP.toIso8601String());
                await _prefs.setString('dueDate', _dueDate!.toIso8601String());
                await _prefs.setString('startDate', startDate.toIso8601String());

                try {
                  debugPrint('Attempting to save LMP data to Firestore');
                  await _firestore.collection('users').doc(_deviceId).set({
                    'lmpDate': Timestamp.fromDate(selectedLMP),
                    'dueDate': Timestamp.fromDate(_dueDate!),
                    'startDate': Timestamp.fromDate(startDate),
                    'updatedAt': Timestamp.now(),
                  }, SetOptions(merge: true));
                  debugPrint('LMP data saved to Firestore');
                } catch (e, stackTrace) {
                  debugPrint('Error saving to Firestore: $e\n$stackTrace');
                }

                setState(() {
                  _hasSetLMP = true;
                  _currentWeek = _calculatePregnancyWeek(startDate);
                  _showHints = true;
                });

                Navigator.pop(context);
                _showCongratulationsDialog();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.pink.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCongratulationsDialog() async {
    final weeksLeft = 40 - (_currentWeek ?? 1);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '🎉 Congratulations!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your pregnancy journey begins!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.pink.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'You are currently in week ${_currentWeek ?? 1}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Due Date: ${_dueDate?.day}/${_dueDate?.month}/${_dueDate?.year}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.pink.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Approximately $weeksLeft weeks to go!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.pink.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _prefs.setBool('hintsShown', true);
              setState(() {
                _showHints = true;
              });
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.pink.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Journey'),
          ),
        ],
      ),
    );
  }

  void _handleTabSelection(int index) {
    if (index == 1 && !_hasSetLMP) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showLMPSelectionDialog().then((_) {
          if (_hasSetLMP) {
            setState(() {
              _selectedIndex = 1;
            });
          }
        });
      });
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _screens => [
        _buildMainHomeTab(),
        _hasSetLMP
            ? TrackerScreen(initialWeek: _currentWeek)
            : _buildLMPRequiredScreen(),
        const ChatScreen(),
      ];

  Widget _buildLMPRequiredScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pregnant_woman,
              size: 80,
              color: Colors.pink.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Pregnancy Tracker',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.pink.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'To start tracking your pregnancy journey, please set your Last Menstrual Period (LMP) first.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.pink.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showLMPSelectionDialog,
              icon: const Icon(Icons.calendar_today),
              label: const Text('Set LMP Date'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _selectedIndex == 0
              ? "BloomMama"
              : _selectedIndex == 1
                  ? "Tracker"
                  : "Chat",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
        actions: _hasSetLMP && _selectedIndex == 0
            ? [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit_lmp') {
                      _showLMPSelectionDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit_lmp',
                      child: Row(
                        children: [
                          Icon(Icons.edit_calendar),
                          SizedBox(width: 8),
                          Text('Edit LMP Date'),
                        ],
                      ),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          if (_showHints && _hasSetLMP) _buildHintOverlay(),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_selectedIndex == 0 && _hasSetLMP)
            Tooltip(
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
                  heroTag: 'addReminder',
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        onTap: _handleTabSelection,
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
              message: _hasSetLMP
                  ? "Track your baby's development week by week"
                  : "Set LMP first to access tracker",
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
              child: Icon(
                Icons.pregnant_woman,
                color: _hasSetLMP ? null : Colors.grey.shade400,
              ),
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
    if (!_hasSetLMP) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite,
                size: 80,
                color: Colors.pink.shade300,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to BloomMama!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Your pregnancy journey companion',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.pink.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Let\'s Get Started!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To provide you with accurate pregnancy tracking, we need to know your Last Menstrual Period (LMP) date.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.pink.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _showLMPSelectionDialog,
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Set LMP Date'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pregnancyData = _currentWeek != null
        ? PregnancyData.getDataForWeek(_currentWeek!)
        : PregnancyData.getDataForWeek(20);

    debugPrint('Attempting to load image: ${pregnancyData.imagePath}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hello, Mama! 👋",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your pregnancy journey at a glance",
                      style: TextStyle(fontSize: 16, color: Colors.pink.shade600),
                    ),
                  ],
                ),
              ),
              if (_dueDate != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.pink.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Due Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.pink.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.pink.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
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
                  setState(() {
                    _selectedIndex = 1;
                  });
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
                  child: const Text(
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
                          onPressed: () async {
                            try {
                              await _firestore
                                  .collection('users')
                                  .doc(_deviceId)
                                  .collection('reminders')
                                  .doc(reminder.id)
                                  .delete();
                              await _flutterLocalNotificationsPlugin
                                  .cancel('${reminder.id}_${reminder.dateTime.millisecondsSinceEpoch}'.hashCode);
                              setState(() {
                                reminders.remove(reminder);
                              });
                            } catch (e, stackTrace) {
                              debugPrint('Error deleting reminder: $e\n$stackTrace');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error deleting reminder: $e')),
                              );
                            }
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

  // Add a mock notification method for instant notification (does not save to Firestore or reminders list)
  Future<void> _showMockNotificationNow({String? title, String? description}) async {
    final androidDetails = fln.AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Notifications for upcoming reminders',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      ticker: 'Reminder',
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    );
    final platformDetails = fln.NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    try {
      await _flutterLocalNotificationsPlugin.show(
        99999, // Unique test ID
        title ?? 'Reminder',
        description ?? 'This is a reminder notification.',
        platformDetails,
        payload: 'test_reminder',
      );
      debugPrint('Mock notification shown immediately.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock notification triggered!')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error showing mock notification: $e\n$stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error showing mock notification: $e')),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
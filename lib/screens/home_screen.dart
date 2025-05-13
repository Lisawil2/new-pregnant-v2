import 'package:flutter/material.dart';
import 'tracker_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
        _buildMainHomeTab(),
        TrackerScreen(),
        ChatScreen(),
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
          Text(
            "This Week’s Baby Update 👶",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: ListTile(
              leading: Image.asset('assets/images/baby1.jpg', height: 60),
              title: const Text("Week 20 - Size of a Banana 🍌"),
              subtitle:
                  const Text("Your baby is growing rapidly and can hear sounds now."),
            ),
          ),

          const SizedBox(height: 30),

          // Upcoming Reminders
          Text(
            "Upcoming Reminders 📅",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.local_hospital, color: Colors.pink),
              title: const Text("Prenatal Check-up"),
              subtitle: const Text("May 20, 2025 • 10:00 AM"),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.vaccines, color: Colors.pink),
              title: const Text("Iron Supplement"),
              subtitle: const Text("Daily at 8:00 AM"),
            ),
          ),
        ],
      ),
    );
  }
}

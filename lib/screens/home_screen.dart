import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: Text(
          "BloomMama",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pink.shade400,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              "Hello, Mama! 👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.pink.shade800),
            ),
            SizedBox(height: 16),

            // Quick Access Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                HomeIconButton(
                  icon: Icons.calendar_month,
                  label: 'Reminders',
                  onTap: () => Navigator.pushNamed(context, '/reminder'),
                ),
                HomeIconButton(
                  icon: Icons.pregnant_woman,
                  label: 'Tracker',
                  onTap: () => Navigator.pushNamed(context, '/tracker'),
                ),
                HomeIconButton(
                  icon: Icons.chat,
                  label: 'Chat',
                  onTap: () => Navigator.pushNamed(context, '/chat'),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Baby Development Card
            Text(
              "This Week’s Baby Update 👶",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: ListTile(
                leading: Image.asset('assets/images/baby1.jpg', height: 60),
                title: Text("Week 20 - Size of a Banana 🍌"),
                subtitle: Text("Your baby is growing rapidly and can hear sounds now."),
              ),
            ),

            SizedBox(height: 30),

            // Upcoming Reminders
            Text(
              "Upcoming Reminders 📅",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.local_hospital, color: Colors.pink),
                title: Text("Prenatal Check-up"),
                subtitle: Text("May 20, 2025 • 10:00 AM"),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.vaccines, color: Colors.pink),
                title: Text("Iron Supplement"),
                subtitle: Text("Daily at 8:00 AM"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HomeIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.pink.shade200,
            radius: 28,
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: Colors.pink.shade700),
          ),
        ],
      ),
    );
  }
}

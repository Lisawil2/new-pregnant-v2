import 'package:flutter/material.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  // Let's assume total pregnancy weeks = 40
  final int currentWeek = 20;

  @override
  Widget build(BuildContext context) {
    double progress = currentWeek / 40;

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text(
          "Pregnancy Tracker",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink.shade400,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregnancy Week Info
            Center(
              child: Text(
                "You're in Week $currentWeek 🎉",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink.shade700),
              ),
            ),
            const SizedBox(height: 20),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.pink.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text("${(progress * 100).toStringAsFixed(1)}% completed",
                textAlign: TextAlign.center),

            const SizedBox(height: 30),

            // Baby Size Info
            _buildCard(
              title: "Baby’s Size 🍌",
              content: "Your baby is about the size of a banana and measures around 6.5 inches. Their hearing is developing, and they might even respond to your voice.",
              image: 'assets/images/baby1.jpg',
            ),

            const SizedBox(height: 20),

            // Mom’s Body Changes
            _buildCard(
              title: "Your Body 🤰",
              content: "You may notice increased appetite, stretch marks, or changes in skin tone. Continue eating a balanced diet and stay hydrated.",
              icon: Icons.female,
            ),

            const SizedBox(height: 20),

            // Health Tips
            _buildCard(
              title: "Health Tips 💡",
              content: "• Take your prenatal vitamins.\n• Stay active with light exercises.\n• Sleep on your side for better circulation.\n• Drink plenty of water.",
              icon: Icons.favorite,
            ),

            const SizedBox(height: 30),

            // Back to Home Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // returns to previous screen (e.g., home)
                },
                icon: const Icon(Icons.home),
                label: const Text("Back to Home"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String content,
    IconData? icon,
    String? image,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, color: Colors.pink, size: 40)
            else if (image != null)
              Image.asset(image, height: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(content,
                      style: const TextStyle(fontSize: 14, color: Colors.black87)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

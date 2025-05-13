import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/pregwoman1.jpg",
      "title": "Welcome to BloomMama",
      "subtitle": "Your companion for a healthy and joyful pregnancy journey."
    },
    {
      "image": "assets/images/pregwoman4.jpg",
      "title": "Track Your Pregnancy",
      "subtitle": "Get week-by-week updates, reminders, and health tips."
    },
    {
      "image": "assets/images/pregwoman9.jpg",
      "title": "Feel Supported",
      "subtitle": "Connect with our chatbot for guidance and emotional support."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (value) {
                setState(() {
                  _currentPage = value;
                });
              },
              itemBuilder: (context, index) => OnboardingContent(
                image: onboardingData[index]['image']!,
                title: onboardingData[index]['title']!,
                subtitle: onboardingData[index]['subtitle']!,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: _currentPage == onboardingData.length - 1
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Get Started", style: TextStyle(fontSize: 18)),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      onboardingData.length,
                      (index) => buildDot(index),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 20 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.pink : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String image, title, subtitle;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 250),
          SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.pink.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

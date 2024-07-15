import 'package:flutter/material.dart';
import 'login_screen.dart'; // Make sure to import your LoginScreen

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  PageController _pageController = PageController(initialPage: 0);

  List<Widget> _pages = [
    OnboardingPage(
      title: 'Online Learning',
      description: 'We Provide Classes Online Classes and Pre Recorded Lectures!',
      image: 'assets/images/Capture.PNG',
    ),
    OnboardingPage(
      title: 'Choose your course',
      description: 'Choose the course of your choice and gain industry knowledge and experience in it.',
      image: 'assets/images/Capture2.PNG',
    ),
    OnboardingPage(
      title: 'Get Online Certificate',
      description: 'Start learning and get certified after your training to get a lucrative job',
      image: 'assets/images/Capture3.PNG',
      // Add a button on the last page to navigate to the LoginScreen
      showButton: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen())),
            child: Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: List.generate(_pages.length, (index) => BottomNavigationBarItem(
          icon: Icon(Icons.circle, color: index == _currentPage ? Colors.blue : Colors.grey),
          label: '',
        )),
        onTap: (index) {
          _pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final bool showButton;

  // Make title, description, and image required
  OnboardingPage({required this.title, required this.description, required this.image, this.showButton = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image),
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(description, textAlign: TextAlign.center),
        ),
        if (showButton)
          ElevatedButton(
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen())),
            child: Text('Get Started'),
          )
      ],
    );
  }
}

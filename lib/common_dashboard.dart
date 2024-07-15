import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'CourseDetailScreen.dart'; // Ensure you have this import
import 'search_screen.dart'; // Import the search screen
import 'my_courses_screen.dart'; // Import the my courses screen
import 'profile_screen.dart'; // Import the profile screen

class CommonDashboard extends StatefulWidget {
  @override
  _CommonDashboardState createState() => _CommonDashboardState();
}

class _CommonDashboardState extends State<CommonDashboard> {
  final _auth = FirebaseAuth.instance;
  User? _currentUser;
  String _role = '';
  String _name = '';
  String _profileImageUrl = '';
  int _selectedIndex = 0; // Index for bottom navigation bar

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _getUserRole();
    _getUserInfo();
  }

  Future<void> _getUserRole() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (mounted) {
        setState(() {
          _role = (userDoc.data() as Map<String, dynamic>)['role'] ?? '';
        });
      }
    }
  }

  Future<void> _getUserInfo() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (mounted) {
        setState(() {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          _name = userData['name'] ?? 'No Name';
          _profileImageUrl = userData.containsKey('profileImageUrl') ? userData['profileImageUrl'] : '';
        });
      }
    }
  }

  Widget _buildUpcomingClasses() {
    DateTime now = DateTime.now();
    DateTime twoDaysLater = now.add(Duration(days: 2));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .where('dateTime', isGreaterThanOrEqualTo: now.toIso8601String())
          .where('dateTime', isLessThanOrEqualTo: twoDaysLater.toIso8601String())
          .orderBy('dateTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        List<Widget> classWidgets = [];
        for (var doc in snapshot.data!.docs) {
          var classData = doc.data() as Map<String, dynamic>;
          DateTime classDateTime = DateTime.parse(classData['dateTime']);
          String formattedDate = DateFormat.yMd().add_jm().format(classDateTime);
          classWidgets.add(
            Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: ListTile(
                title: Text(classData['name']),
                subtitle: Text(formattedDate),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Handle class tap
                },
              ),
            ),
          );
        }

        if (classWidgets.isEmpty) {
          return Center(child: Text('No upcoming classes in the next 2 days'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Upcoming Classes',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Column(children: classWidgets),
          ],
        );
      },
    );
  }

  Widget _buildCourseList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        List<Widget> courseWidgets = [];
        for (var doc in snapshot.data!.docs) {
          var courseData = doc.data() as Map<String, dynamic>;
          if (courseData['imageUrl'] != null && courseData['imageUrl'].toString().isNotEmpty) {
            courseWidgets.add(
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailScreen(courseId: doc.id),
                    ),
                  );
                },
                child: _buildCourseCard(
                  courseData['name'] ?? 'No Title',
                  courseData['imageUrl'] ?? 'https://via.placeholder.com/150',
                  courseData['rating']?.toDouble() ?? 0.0,
                  courseData['studentCount'] ?? 0,
                ),
              ),
            );
          }
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Top Picks',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: courseWidgets,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCourseCard(String title, String imageUrl, double rating, int studentCount) {
    return Container(
      width: 160,
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imageUrl, height: 100, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  Text(rating.toString()),
                  SizedBox(width: 10),
                  Text('$studentCount Students'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_role.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<Widget> _pages = [
      Column(
        children: [
          _buildUpcomingClasses(),
          Expanded(child: _buildCourseList()),
        ],
      ),
      SearchScreen(),
      MyCoursesScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        title: Text('LMS'),
        backgroundColor: Colors.green, // Change top bar color here
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _selectedIndex = 1;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              // Implement favorite functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Implement notifications functionality
            },
          ),
        ],
      )
          : null,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_name),
              accountEmail: Text(_currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl) as ImageProvider
                    : AssetImage('assets/images/Capture5.PNG'),
              ),
              decoration: BoxDecoration(color: Colors.green), // Make the whole header blue
            ),
            ListTile(
              leading: Icon(Icons.class_),
              title: Text('Classes'),
              onTap: () {
                Navigator.pushNamed(context, '/classes');
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('History'),
              onTap: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
            ListTile(
              leading: Icon(Icons.book),
              title: Text('Resources'),
              onTap: () {
                Navigator.pushNamed(context, '/resources');
              },
            ),
            ListTile(
              leading: Icon(Icons.payment),
              title: Text('Payments'),
              onTap: () {
                Navigator.pushNamed(context, '/payments');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                await _auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'My Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex, // Update based on the selected tab
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.greenAccent, // Change bottom tab color here
        selectedItemColor: Colors.greenAccent, // Selected item color
        unselectedItemColor: Colors.grey, // Unselected item color
      ),
    );
  }
}

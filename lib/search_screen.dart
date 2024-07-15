import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CourseDetailScreen.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _hasSearched = false;

  final List<String> exampleKeywords = [
    "Adobe Photoshop",
    "Coding",
    "Social Media",
    "Camera",
    "Motivation",
    "Web Design",
    "Programming",
    "Figma",
    "Flutter",
    "Marketing"
  ];

  void _searchCourses(String query) async {
    if (query.isNotEmpty) {
      var result = await FirebaseFirestore.instance
          .collection('courses')
          .where('keywords', arrayContains: query.toLowerCase())
          .get();

      setState(() {
        _searchResults = result.docs;
        _hasSearched = true;
      });
    } else {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search Course',
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _searchCourses(_searchController.text);
              },
            ),
          ),
          onSubmitted: (value) {
            _searchCourses(value);
          },
        ),
        backgroundColor: Colors.green,
      ),
      body: _hasSearched ? _buildSearchResults() : _buildExampleKeywords(),
    );
  }

  Widget _buildExampleKeywords() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: exampleKeywords.map((keyword) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = keyword;
                  _searchCourses(keyword);
                },
                child: Chip(
                  label: Text(keyword),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20),
          Text(
            'All Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // Add your category widgets here
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(child: Text('No courses available for the searched keyword'));
    }

    return ListView(
      children: _searchResults.map((doc) {
        var courseData = doc.data() as Map<String, dynamic>;
        return GestureDetector(
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
        );
      }).toList(),
    );
  }

  Widget _buildCourseCard(String title, String imageUrl, double rating, int studentCount) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'CourseDetailScreen.dart';
import 'keyword_generator.dart'; // Import the keyword generator

class MyCoursesScreen extends StatefulWidget {
  @override
  _MyCoursesScreenState createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final _auth = FirebaseAuth.instance;
  User? _currentUser;
  String _role = '';
  List<String> _enrolledCourseIds = [];
  final _formKey = GlobalKey<FormState>();
  String _courseName = '';
  String _courseDescription = '';
  File? _imageFile;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      setState(() {
        _role = userDoc['role'] ?? '';
        if (_role == 'student') {
          _getEnrolledCourses();
        }
      });
    }
  }

  Future<void> _getEnrolledCourses() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      setState(() {
        _enrolledCourseIds = List<String>.from(userDoc['enrolledCourses'] ?? []);
      });
    }
  }

  Future<void> _addCourse() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      List<String> keywords = generateKeywords(_courseName);

      if (_imageFile != null) {
        String imageUrl = await _uploadImage(_imageFile!);
        await FirebaseFirestore.instance.collection('courses').add({
          'name': _courseName,
          'description': _courseDescription,
          'imageUrl': imageUrl,
          'teacherId': _currentUser!.uid,
          'keywords': keywords,
        });
      }

      Navigator.of(context).pop();
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('course_images/${DateTime.now().millisecondsSinceEpoch}');
    UploadTask uploadTask = storageReference.putFile(imageFile);
    TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => {});
    String downloadUrl = await storageSnapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Courses'),
        backgroundColor: Colors.green,
      ),
      body: _role.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _role == 'teacher'
          ? _buildTeacherCourses()
          : _buildStudentCourses(),
      floatingActionButton: _role == 'teacher' ? _buildAddCourseButton() : null,
    );
  }

  Widget _buildTeacherCourses() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('teacherId', isEqualTo: _currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No courses found'));
        }

        List<Widget> courseWidgets = [];
        for (var doc in snapshot.data!.docs) {
          var courseData = doc.data() as Map<String, dynamic>;
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

        return ListView(children: courseWidgets);
      },
    );
  }

  Widget _buildStudentCourses() {
    return _enrolledCourseIds.isEmpty
        ? Center(child: Text('No enrolled courses'))
        : StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where(FieldPath.documentId, whereIn: _enrolledCourseIds.isNotEmpty ? _enrolledCourseIds : ["dummy"])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No courses found'));
        }

        List<Widget> courseWidgets = [];
        for (var doc in snapshot.data!.docs) {
          var courseData = doc.data() as Map<String, dynamic>;
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

        return ListView(children: courseWidgets);
      },
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

  Widget _buildAddCourseButton() {
    return FloatingActionButton(
      onPressed: () {
        _showAddCourseDialog();
      },
      child: Icon(Icons.add),
      backgroundColor: Colors.blue,
    );
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Course'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Course Name'),
                  onSaved: (value) => _courseName = value!,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a course name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Description'),
                  onSaved: (value) => _courseDescription = value!,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: _pickImage,
                      child: Text('Pick Image'),
                    ),
                    _imageFile != null
                        ? Image.file(_imageFile!, width: 50, height: 50)
                        : Container(),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addCourse();
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

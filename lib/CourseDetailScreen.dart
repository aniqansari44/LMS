import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  CourseDetailScreen({required this.courseId});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final _auth = FirebaseAuth.instance;
  User? _currentUser;
  String _role = '';
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
      });
    }
  }

  Future<void> _enrollCourse(BuildContext context) async {
    if (_currentUser != null) {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).update({
        'enrolledCourses': FieldValue.arrayUnion([widget.courseId])
      });
      await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).update({
        'students': FieldValue.arrayUnion([_currentUser!.uid])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enrolled successfully')),
      );

      Navigator.pop(context);
    }
  }

  Future<bool> _isEnrolled() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      List<String> enrolledCourses = List<String>.from(userDoc['enrolledCourses'] ?? []);
      return enrolledCourses.contains(widget.courseId);
    }
    return false;
  }

  Future<void> _editCourse(BuildContext context, Map<String, dynamic> courseData) async {
    setState(() {
      _courseName = courseData['name'] ?? 'No Title';
      _courseDescription = courseData['description'] ?? 'No Description';
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Course'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: _courseName,
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
                  initialValue: _courseDescription,
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
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  String imageUrl = courseData['imageUrl'];
                  if (_imageFile != null) {
                    imageUrl = await _uploadImage(_imageFile!);
                  }
                  await FirebaseFirestore.instance.collection('courses').doc(widget.courseId).update({
                    'name': _courseName,
                    'description': _courseDescription,
                    'imageUrl': imageUrl,
                  });

                  Navigator.of(context).pop();
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
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

  Future<List<Map<String, dynamic>>> _getStudentDetails(List<String> studentIds) async {
    List<Map<String, dynamic>> studentDetails = [];
    for (String id in studentIds) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      studentDetails.add(userDoc.data() as Map<String, dynamic>);
    }
    return studentDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Course Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('courses').doc(widget.courseId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var courseData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(
                  courseData['imageUrl'] ?? 'https://via.placeholder.com/150',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                SizedBox(height: 10),
                Text(
                  courseData['name'] ?? 'No Title',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    Text(courseData['rating']?.toString() ?? '0.0'),
                    SizedBox(width: 10),
                    Text('${courseData['studentCount'] ?? 0} Students'),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  courseData['description'] ?? 'No Description',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Text(
                  'Created By ${courseData['creatorName'] ?? 'Unknown'}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16),
                    SizedBox(width: 5),
                    Text('Last Updated: ${courseData['lastUpdated'] ?? 'Unknown'}'),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.language, size: 16),
                    SizedBox(width: 5),
                    Text('Language: ${courseData['language'] ?? 'Unknown'}'),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16),
                    SizedBox(width: 5),
                    Text('Duration: ${courseData['duration'] ?? 'Unknown'}'),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.library_books, size: 16),
                    SizedBox(width: 5),
                    Text('Lessons: ${courseData['lessonsCount'] ?? 'Unknown'}'),
                  ],
                ),
                SizedBox(height: 20),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getStudentDetails(List<String>.from(courseData['students'] ?? [])),
                  builder: (context, studentSnapshot) {
                    if (!studentSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    List<Map<String, dynamic>> studentDetails = studentSnapshot.data!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Students Enrolled (${studentDetails.length})',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        ...studentDetails.map((student) => Text(student['name'] ?? 'Unknown')).toList(),
                      ],
                    );
                  },
                ),
                SizedBox(height: 20),
                _role == 'student'
                    ? FutureBuilder<bool>(
                  future: _isEnrolled(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    bool isEnrolled = snapshot.data!;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          courseData['price']?.toString() ?? 'FREE',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        ElevatedButton(
                          onPressed: isEnrolled ? null : () => _enrollCourse(context),
                          child: Text(isEnrolled ? 'Start Course' : 'Enroll Now'),
                        ),
                      ],
                    );
                  },
                )
                    : ElevatedButton(
                  onPressed: () => _editCourse(context, courseData),
                  child: Text('Edit Course'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

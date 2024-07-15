import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ClassesScreen extends StatefulWidget {
  @override
  _ClassesScreenState createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  User? _currentUser;
  String _role = '';
  String _className = '';
  DateTime? _classDate;
  TimeOfDay? _classTime;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _getUserRole();
  }

  Future<void> _getUserRole() async {
    if (_currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      setState(() {
        _role = userDoc['role'] ?? '';
      });
    }
  }

  Future<void> _createClass() async {
    if (_className.isNotEmpty && _classDate != null && _classTime != null && _currentUser != null) {
      DateTime classDateTime = DateTime(
        _classDate!.year,
        _classDate!.month,
        _classDate!.day,
        _classTime!.hour,
        _classTime!.minute,
      );

      await _firestore.collection('classes').add({
        'name': _className,
        'dateTime': classDateTime.toIso8601String(),
        'teacherId': _currentUser!.uid,
        'students': [],
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Class created')));
    }
  }

  Future<void> _joinClass(String classId, String className, DateTime dateTime, String teacherId) async {
    if (_currentUser != null) {
      await _firestore.collection('classes').doc(classId).update({
        'students': FieldValue.arrayUnion([_currentUser!.uid]),
      });

      await _firestore.collection('users').doc(_currentUser!.uid).collection('classHistory').add({
        'classId': classId,
        'className': className,
        'dateTime': dateTime.toIso8601String(),
        'teacherId': teacherId,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined class')));
    }
  }

  Future<void> _selectClassDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _classDate = pickedDate;
      });
    }
  }

  Future<void> _selectClassTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        _classTime = pickedTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Classes'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          if (_role == 'teacher') _buildTeacherSection(),
          _buildClassesList(),
        ],
      ),
    );
  }

  Widget _buildTeacherSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(labelText: 'Class Name'),
            onChanged: (value) {
              setState(() {
                _className = value;
              });
            },
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Class Date'),
            readOnly: true,
            onTap: _selectClassDate,
            controller: TextEditingController(text: _classDate != null ? DateFormat.yMd().format(_classDate!) : ''),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Class Time'),
            readOnly: true,
            onTap: _selectClassTime,
            controller: TextEditingController(text: _classTime != null ? _classTime!.format(context) : ''),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _createClass,
            child: Text('Create Class'),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('classes').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final classes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: classes.length,
            itemBuilder: (context, index) {
              var classDoc = classes[index];
              var classData = classDoc.data() as Map<String, dynamic>;
              String name = classData['name'] ?? 'No Name';
              DateTime dateTime = DateTime.parse(classData['dateTime'] ?? DateTime.now().toIso8601String());
              String formattedDate = DateFormat.yMd().add_jm().format(dateTime);

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(formattedDate),
                  trailing: ElevatedButton(
                    onPressed: () => _joinClass(classDoc.id, name, dateTime, classData['teacherId']),
                    child: Text('Join'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

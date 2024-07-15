import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
  }

  Widget _buildHistoryList() {
    if (_currentUser == null) {
      return Center(child: Text('No user logged in.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('classHistory')
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('An error occurred while fetching history.'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No history records found.'));
        }

        final historyRecords = snapshot.data!.docs;

        return ListView.builder(
          itemCount: historyRecords.length,
          itemBuilder: (context, index) {
            var record = historyRecords[index];
            var recordData = record.data() as Map<String, dynamic>;
            DateTime dateTime = DateTime.parse(recordData['dateTime']);
            String formattedDate = DateFormat.yMd().add_jm().format(dateTime);

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: ListTile(
                title: Text(recordData['className']),
                subtitle: Text(formattedDate),
                trailing: Text('Teacher: ${recordData['teacherId']}'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History'),
        backgroundColor: Colors.green,
      ),
      body: _buildHistoryList(),
    );
  }
}
